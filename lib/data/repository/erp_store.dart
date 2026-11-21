import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/storage/firestore_sync.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_theme.dart';
import '../models/erp_models.dart';
import 'erp_seed_data.dart';

enum ErpModule {
  dashboard,
  sales,
  purchases,
  purchasers,
  suppliers,
  expenses,
  cashBank,
  settings,
}

class ErpStore extends ChangeNotifier {
  ErpStore({
    LocalStorageAdapter? storage,
    FirestoreSyncService? cloudSync,
    bool autoLoginOwner = false,
  })  : _storage = storage ?? createLocalStorage(),
        _cloudSync = cloudSync ?? FirestoreSyncService(enabled: false) {
    _loadSeed();
    if (autoLoginOwner) {
      currentUser = users.firstWhere((u) => u.isOwner);
    }
  }

  static const _storageKey = 'bolan_gasoline_erp_v1';
  static const _sessionUserKey = 'bolan_gasoline_session_user_id';
  final LocalStorageAdapter _storage;
  final FirestoreSyncService _cloudSync;
  Timer? _pollTimer;

  // Auth & RBAC State
  late List<AppUser> users;
  AppUser? currentUser;
  int _userSeq = 3;

  bool get isLoggedIn => currentUser != null;
  bool get isOwner => currentUser?.isOwner ?? false;

  UserPermissions get activePermissions {
    if (currentUser == null) return const UserPermissions();
    if (currentUser!.isOwner) return UserPermissions.all();
    return currentUser!.permissions;
  }

  bool get canEdit => activePermissions.canEdit;
  bool get canDelete => activePermissions.canDelete;

  ModuleCrudPermission permFor(ErpModule mod) {
    if (currentUser == null) return const ModuleCrudPermission.none();
    if (isOwner) return const ModuleCrudPermission.full();
    final p = activePermissions;
    switch (mod) {
      case ErpModule.dashboard:
        return p.dashboard;
      case ErpModule.sales:
        return p.sales;
      case ErpModule.purchases:
        return p.purchases;
      case ErpModule.purchasers:
        return p.purchasers;
      case ErpModule.suppliers:
        return p.suppliers;
      case ErpModule.expenses:
        return p.expenses;
      case ErpModule.cashBank:
        return p.cashBank;
      case ErpModule.settings:
        return const ModuleCrudPermission.none();
    }
  }

  bool canCreateIn(ErpModule mod) => isOwner || permFor(mod).create;
  bool canUpdateIn(ErpModule mod) => isOwner || permFor(mod).update;
  bool canDeleteIn(ErpModule mod) => isOwner || permFor(mod).delete;

  bool canAccessModule(ErpModule mod) {
    if (currentUser == null) return false;
    if (isOwner) return true;
    final p = activePermissions;
    switch (mod) {
      case ErpModule.dashboard:
        return p.viewDashboard;
      case ErpModule.sales:
        return p.manageSales;
      case ErpModule.purchases:
        return p.managePurchases;
      case ErpModule.purchasers:
        return p.managePurchasers;
      case ErpModule.suppliers:
        return p.manageSuppliers;
      case ErpModule.expenses:
        return p.manageExpenses;
      case ErpModule.cashBank:
        return p.manageCashBank;
      case ErpModule.settings:
        return false; // Strictly Owner only
    }
  }

  List<ErpModule> get accessibleModules =>
      ErpModule.values.where(canAccessModule).toList();

  // App UI State
  ErpThemeId themeId = ErpThemeId.crimson;
  bool isUrdu = false;
  ErpModule activeModule = ErpModule.dashboard;
  String searchQuery = '';
  bool isOfflineMode = false;
  int offlinePendingCount = 0;
  int lastUpdatedAtMs = 0;
  bool isCloudSyncing = false;
  bool isCloudConnected = false;
  bool _hasQueuedCloudPush = false;
  Future<void>? _activeCloudPush;

  // Domain Data
  late Map<FuelType, FuelStock> fuelStocks;
  late List<Purchaser> purchasers;
  late List<FuelSupplier> suppliers;
  late List<FuelSale> sales;
  late List<FuelPurchase> purchases;
  late List<LedgerPayment> payments;
  late List<PumpExpense> expenses;
  late List<CashBankTransfer> cashBankTransfers;
  late List<Map<String, String>> expenseCategories;

  static const List<Map<String, String>> defaultExpenseCategories = [
    {'en': 'Pump Staff Salaries', 'ur': 'پمپ لڑکوں کی تنخواہیں (Staff Salary)'},
    {'en': 'Generator & Electricity', 'ur': 'جنریٹر ڈیزل اور بجلی'},
    {'en': 'Pump Misc Expense', 'ur': 'دیگر پمپ اخراجات'},
  ];

  int _saleSeq = 808;
  int _purchaseSeq = 403;
  int _purchaserSeq = 11;
  int _supplierSeq = 3;
  int _paymentSeq = 204;
  int _expenseSeq = 104;
  int _transferSeq = 101;

  void _loadSeed() {
    users = [
      AppUser(
        id: 'USR-01',
        name: 'Bolan Owner (Admin)',
        username: 'owner',
        password: '1234',
        role: UserRole.owner,
        isActive: true,
        permissions: UserPermissions.all(),
      ),
      AppUser(
        id: 'USR-02',
        name: 'Pump Operator (Ormara)',
        username: 'staff',
        password: '1234',
        role: UserRole.employee,
        isActive: true,
        permissions: UserPermissions.defaultEmployee(),
      ),
    ];
    fuelStocks = ErpSeedData.fuelStocks();
    purchasers = List.of(ErpSeedData.purchasers());
    suppliers = List.of(ErpSeedData.suppliers());
    sales = List.of(ErpSeedData.sales());
    purchases = List.of(ErpSeedData.purchases());
    payments = List.of(ErpSeedData.payments());
    expenses = List.of(ErpSeedData.expenses());
    cashBankTransfers = [];
    expenseCategories =
        defaultExpenseCategories.map((e) => Map<String, String>.from(e)).toList();
  }

  void _applyJsonPayload(String raw, {required bool includeUiPrefs}) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (includeUiPrefs) {
      final themeName = map['themeId'] as String?;
      if (themeName != null) {
        themeId = ErpThemeId.values.firstWhere(
          (e) => e.name == themeName,
          orElse: () => ErpThemeId.crimson,
        );
      }
      isUrdu = map['isUrdu'] as bool? ?? false;
      isOfflineMode = map['isOfflineMode'] as bool? ?? false;
      offlinePendingCount = map['offlinePendingCount'] as int? ?? 0;
    }

    lastUpdatedAtMs = map['updatedAtMs'] as int? ?? lastUpdatedAtMs;

    if (map['fuelStocks'] is List) {
      final loaded = <FuelType, FuelStock>{};
      for (final item in map['fuelStocks'] as List) {
        final fs = FuelStock.fromJson(item as Map<String, dynamic>);
        loaded[fs.type] = fs;
      }
      if (loaded.containsKey(FuelType.petrol) &&
          loaded.containsKey(FuelType.diesel)) {
        fuelStocks = loaded;
      }
    }
    if (map['purchasers'] is List) {
      purchasers = (map['purchasers'] as List)
          .map((e) => Purchaser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (map['suppliers'] is List) {
      suppliers = (map['suppliers'] as List)
          .map((e) => FuelSupplier.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (map['sales'] is List) {
      sales = (map['sales'] as List)
          .map((e) => FuelSale.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (map['purchases'] is List) {
      purchases = (map['purchases'] as List)
          .map((e) => FuelPurchase.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (map['payments'] is List) {
      payments = (map['payments'] as List)
          .map((e) => LedgerPayment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (map['expenses'] is List) {
      expenses = (map['expenses'] as List)
          .map((e) => PumpExpense.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (map['cashBankTransfers'] is List) {
      cashBankTransfers = (map['cashBankTransfers'] as List)
          .whereType<Map<String, dynamic>>()
          .map(CashBankTransfer.fromJson)
          .toList();
    } else {
      cashBankTransfers = [];
    }
    if (map['expenseCategories'] is List) {
      final loadedCats = (map['expenseCategories'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => {
                'en': e['en']?.toString() ?? '',
                'ur': e['ur']?.toString() ?? e['en']?.toString() ?? '',
              })
          .where((e) => e['en']!.isNotEmpty)
          .toList();
      if (loadedCats.isNotEmpty) {
        expenseCategories = loadedCats;
      }
    }
    if (map['users'] is List) {
      final loadedUsers = (map['users'] as List)
          .whereType<Map<String, dynamic>>()
          .map(AppUser.fromJson)
          .toList();
      if (loadedUsers.any((u) => u.isOwner)) {
        users = loadedUsers;
      }
    }
    _userSeq = map['userSeq'] as int? ?? _userSeq;
    _refreshCurrentUserFromList();
    _saleSeq = map['saleSeq'] as int? ?? _saleSeq;
    _purchaseSeq = map['purchaseSeq'] as int? ?? _purchaseSeq;
    _purchaserSeq = map['purchaserSeq'] as int? ?? _purchaserSeq;
    _supplierSeq = map['supplierSeq'] as int? ?? _supplierSeq;
    _paymentSeq = map['paymentSeq'] as int? ?? _paymentSeq;
    _expenseSeq = map['expenseSeq'] as int? ?? _expenseSeq;
    _transferSeq = map['transferSeq'] as int? ?? _transferSeq;
  }

  String _encodePayload() {
    return jsonEncode({
      'themeId': themeId.name,
      'isUrdu': isUrdu,
      'isOfflineMode': isOfflineMode,
      'offlinePendingCount': offlinePendingCount,
      'updatedAtMs': lastUpdatedAtMs,
      'fuelStocks': fuelStocks.values.map((e) => e.toJson()).toList(),
      'purchasers': purchasers.map((e) => e.toJson()).toList(),
      'suppliers': suppliers.map((e) => e.toJson()).toList(),
      'sales': sales.map((e) => e.toJson()).toList(),
      'purchases': purchases.map((e) => e.toJson()).toList(),
      'payments': payments.map((e) => e.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'cashBankTransfers': cashBankTransfers.map((e) => e.toJson()).toList(),
      'expenseCategories': expenseCategories,
      'users': users.map((u) => u.toJson()).toList(),
      'userSeq': _userSeq,
      'saleSeq': _saleSeq,
      'purchaseSeq': _purchaseSeq,
      'purchaserSeq': _purchaserSeq,
      'supplierSeq': _supplierSeq,
      'paymentSeq': _paymentSeq,
      'expenseSeq': _expenseSeq,
      'transferSeq': _transferSeq,
    });
  }

  Future<void> init() async {
    try {
      final raw = await _storage.read(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _applyJsonPayload(raw, includeUiPrefs: true);
        notifyListeners();
      }
      final savedSessionId = await _storage.read(_sessionUserKey);
      if (savedSessionId != null && savedSessionId.isNotEmpty) {
        for (final u in users) {
          if (u.id == savedSessionId && u.isActive) {
            currentUser = u;
            _ensureAccessibleModule();
            break;
          }
        }
        notifyListeners();
      }
    } catch (_) {}

    if (_cloudSync.enabled) {
      await syncWithCloud();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _pollCloudIfOnline(),
      );
    }
  }

  Future<void> syncWithCloud() async {
    if (!_cloudSync.enabled || isOfflineMode) return;
    isCloudSyncing = true;
    notifyListeners();

    try {
      final remote = await _cloudSync.fetch();
      if (remote != null && remote.updatedAtMs >= lastUpdatedAtMs) {
        _applyJsonPayload(remote.payloadJson, includeUiPrefs: false);
        lastUpdatedAtMs = remote.updatedAtMs;
        await _storage.write(_storageKey, _encodePayload());
        isCloudConnected = true;
      } else {
        if (lastUpdatedAtMs == 0) {
          lastUpdatedAtMs = DateTime.now().millisecondsSinceEpoch;
        }
        final payload = _encodePayload();
        final ok = await _cloudSync.push(payload, lastUpdatedAtMs);
        isCloudConnected = ok;
      }
    } catch (_) {
      isCloudConnected = false;
    } finally {
      isCloudSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _pollCloudIfOnline() async {
    if (!_cloudSync.enabled || isOfflineMode || isCloudSyncing) return;
    try {
      final remote = await _cloudSync.fetch();
      if (remote != null && remote.updatedAtMs > lastUpdatedAtMs) {
        _applyJsonPayload(remote.payloadJson, includeUiPrefs: false);
        lastUpdatedAtMs = remote.updatedAtMs;
        await _storage.write(_storageKey, _encodePayload());
        isCloudConnected = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> flushCloudSync() async {
    final active = _activeCloudPush;
    if (active != null) {
      await active;
    }
  }

  Future<void> _persist({bool syncToCloud = true}) async {
    try {
      if (syncToCloud) {
        lastUpdatedAtMs = DateTime.now().millisecondsSinceEpoch;
      }
      final payload = _encodePayload();
      if (syncToCloud && _cloudSync.enabled && !isOfflineMode) {
        _scheduleSerializedCloudPush();
      }
      await _storage.write(_storageKey, payload);
    } catch (_) {}
  }

  void _scheduleSerializedCloudPush() {
    _hasQueuedCloudPush = true;
    if (_activeCloudPush != null) return;
    _activeCloudPush = _drainCloudPushQueue();
  }

  Future<void> _drainCloudPushQueue() async {
    isCloudSyncing = true;
    notifyListeners();
    try {
      while (_hasQueuedCloudPush && _cloudSync.enabled && !isOfflineMode) {
        _hasQueuedCloudPush = false;
        final snapPayload = _encodePayload();
        final snapTs = lastUpdatedAtMs;
        final ok = await _cloudSync.push(snapPayload, snapTs);
        isCloudConnected = ok;
      }
    } catch (_) {
      isCloudConnected = false;
    } finally {
      _activeCloudPush = null;
      isCloudSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI Controls
  // ---------------------------------------------------------------------------
  void setTheme(ErpThemeId id) {
    themeId = id;
    notifyListeners();
    _persist(syncToCloud: false);
  }

  void toggleLanguage() {
    isUrdu = !isUrdu;
    notifyListeners();
    _persist(syncToCloud: false);
  }

  void setModule(ErpModule module) {
    if (isLoggedIn && !canAccessModule(module)) return;
    activeModule = module;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void toggleOfflineMode() {
    isOfflineMode = !isOfflineMode;
    if (!isOfflineMode) {
      sales = sales
          .map((s) => s.syncStatus == 'Offline Queued'
              ? s.copyWith(syncStatus: 'Synced')
              : s)
          .toList();
      offlinePendingCount = 0;
    }
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // Computed Summaries & Lookups
  // ---------------------------------------------------------------------------
  Purchaser? findPurchaser(String id) {
    for (final p in purchasers) {
      if (p.id == id) return p;
    }
    return null;
  }

  FuelSupplier? findSupplier(String id) {
    for (final s in suppliers) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Purchaser> get creditPurchasers =>
      purchasers.where((p) => !p.isCashCounter).toList();

  PartyBalanceSummary purchaserSummary(String purchaserId) {
    final p = findPurchaser(purchaserId);
    if (p == null) {
      return const PartyBalanceSummary(
        totalBilled: 0,
        totalPaid: 0,
        balance: 0,
        totalLiters: 0,
        transactionCount: 0,
      );
    }
    final pSales = sales.where((s) => s.purchaserId == purchaserId).toList();
    final pPayments = payments
        .where((pay) =>
            pay.partyType == 'purchaser' && pay.partyId == purchaserId)
        .toList();

    final salesBilled = pSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final salesPaid = pSales.fold<double>(0, (sum, s) => sum + s.paidNow);
    final recoveryPaid =
        pPayments.fold<double>(0, (sum, pay) => sum + pay.amount);
    final liters = pSales.fold<double>(0, (sum, s) => sum + s.liters);

    final totalBilled = p.openingBilled + salesBilled;
    final totalPaid = p.openingPaid + salesPaid + recoveryPaid;
    final balance = max(0.0, totalBilled - totalPaid);

    return PartyBalanceSummary(
      totalBilled: totalBilled,
      totalPaid: totalPaid,
      balance: balance,
      totalLiters: liters,
      transactionCount: pSales.length + pPayments.length,
    );
  }

  PartyBalanceSummary supplierSummary(String supplierId) {
    final sup = findSupplier(supplierId);
    if (sup == null) {
      return const PartyBalanceSummary(
        totalBilled: 0,
        totalPaid: 0,
        balance: 0,
        totalLiters: 0,
        transactionCount: 0,
      );
    }
    final sPurchases =
        purchases.where((p) => p.supplierId == supplierId).toList();
    final sPayments = payments
        .where(
            (pay) => pay.partyType == 'supplier' && pay.partyId == supplierId)
        .toList();

    final purBilled =
        sPurchases.fold<double>(0, (sum, p) => sum + p.totalCost);
    final purPaid = sPurchases.fold<double>(0, (sum, p) => sum + p.paid);
    final ledgerPaid =
        sPayments.fold<double>(0, (sum, pay) => sum + pay.amount);
    final liters = sPurchases.fold<double>(0, (sum, p) => sum + p.liters);

    final totalBilled = sup.openingPurchased + purBilled;
    final totalPaid = sup.openingPaid + purPaid + ledgerPaid;
    final balance = max(0.0, totalBilled - totalPaid);

    return PartyBalanceSummary(
      totalBilled: totalBilled,
      totalPaid: totalPaid,
      balance: balance,
      totalLiters: liters,
      transactionCount: sPurchases.length + sPayments.length,
    );
  }

  /// Complete chronological Individual Purchaser Account History (client's #1 audio request!).
  List<LedgerHistoryRow> purchaserLedgerHistory(String purchaserId) {
    final p = findPurchaser(purchaserId);
    if (p == null) return const [];

    final rawItems = <({
      DateTime date,
      String id,
      String kind,
      String titleEn,
      String titleUr,
      String detailEn,
      String detailUr,
      double debit,
      double credit,
      FuelType? fuel,
      double? liters,
      double? rate,
      FuelSale? sale,
      LedgerPayment? payment,
    })>[];

    for (final s in sales.where((s) => s.purchaserId == purchaserId)) {
      rawItems.add((
        date: s.date,
        id: s.id,
        kind: 'sale',
        titleEn: '${s.fuel.key} Sale (${s.liters.round()} L @ Rs. ${s.rateUsed.round()}/L)',
        titleUr:
            '${s.fuel == FuelType.petrol ? 'پٹرول' : 'ڈیزل'} فروخت (${s.liters.round()} لیٹر @ Rs. ${s.rateUsed.round()})',
        detailEn: s.note.isNotEmpty ? s.note : 'Fuel Bill ${s.id}',
        detailUr: s.note.isNotEmpty ? s.note : 'تیل بل ${s.id}',
        debit: s.totalAmount,
        credit: s.paidNow,
        fuel: s.fuel,
        liters: s.liters,
        rate: s.rateUsed,
        sale: s,
        payment: null,
      ));
    }

    for (final pay in payments.where(
      (pay) => pay.partyType == 'purchaser' && pay.partyId == purchaserId,
    )) {
      rawItems.add((
        date: pay.date,
        id: pay.id,
        kind: 'payment',
        titleEn: 'Payment Received (${pay.method})',
        titleUr: 'رقم وصولی (${pay.method})',
        detailEn: pay.note.isNotEmpty ? pay.note : 'Khata Cash Recovery',
        detailUr: pay.note.isNotEmpty ? pay.note : 'کھاتہ رقم وصولی',
        debit: 0,
        credit: pay.amount,
        fuel: null,
        liters: null,
        rate: null,
        sale: null,
        payment: pay,
      ));
    }

    // Sort oldest -> newest to compute exact running balance
    rawItems.sort((a, b) => a.date.compareTo(b.date));
    double running = max(0, p.openingBilled - p.openingPaid);
    final rows = <LedgerHistoryRow>[];
    for (final item in rawItems) {
      running = max(0, running + item.debit - item.credit);
      rows.add(LedgerHistoryRow(
        id: item.id,
        date: item.date,
        kind: item.kind,
        titleEn: item.titleEn,
        titleUr: item.titleUr,
        detailEn: item.detailEn,
        detailUr: item.detailUr,
        debit: item.debit,
        credit: item.credit,
        runningBalance: running,
        fuel: item.fuel,
        liters: item.liters,
        rate: item.rate,
        sale: item.sale,
        payment: item.payment,
      ));
    }
    // Display newest first
    return rows.reversed.toList();
  }

  /// Complete chronological Individual Supplier Account History.
  List<LedgerHistoryRow> supplierLedgerHistory(String supplierId) {
    final sup = findSupplier(supplierId);
    if (sup == null) return const [];

    final rawItems = <({
      DateTime date,
      String id,
      String kind,
      String titleEn,
      String titleUr,
      String detailEn,
      String detailUr,
      double debit,
      double credit,
      FuelType? fuel,
      double? liters,
      double? rate,
      FuelPurchase? purchase,
      LedgerPayment? payment,
    })>[];

    for (final pu in purchases.where((x) => x.supplierId == supplierId)) {
      rawItems.add((
        date: pu.date,
        id: pu.id,
        kind: 'purchase',
        titleEn:
            '${pu.fuel.key} Tanker (${pu.liters.round()} L @ Rs. ${pu.rate.round()}/L)',
        titleUr:
            '${pu.fuel == FuelType.petrol ? 'پٹرول' : 'ڈیزل'} ٹینکر (${pu.liters.round()} لیٹر @ Rs. ${pu.rate.round()})',
        detailEn: pu.note.isNotEmpty ? pu.note : 'Fuel Arrival ${pu.id}',
        detailUr: pu.note.isNotEmpty ? pu.note : 'تیل آمد ${pu.id}',
        debit: pu.totalCost,
        credit: pu.paid,
        fuel: pu.fuel,
        liters: pu.liters,
        rate: pu.rate,
        purchase: pu,
        payment: null,
      ));
    }

    for (final pay in payments.where(
      (pay) => pay.partyType == 'supplier' && pay.partyId == supplierId,
    )) {
      rawItems.add((
        date: pay.date,
        id: pay.id,
        kind: 'payment',
        titleEn: 'Supplier Payment (${pay.method})',
        titleUr: 'سپلائر ادائیگی (${pay.method})',
        detailEn: pay.note.isNotEmpty ? pay.note : 'Khata Payment',
        detailUr: pay.note.isNotEmpty ? pay.note : 'کھاتہ ادائیگی',
        debit: 0,
        credit: pay.amount,
        fuel: null,
        liters: null,
        rate: null,
        purchase: null,
        payment: pay,
      ));
    }

    rawItems.sort((a, b) => a.date.compareTo(b.date));
    double running = max(0, sup.openingPurchased - sup.openingPaid);
    final rows = <LedgerHistoryRow>[];
    for (final item in rawItems) {
      running = max(0, running + item.debit - item.credit);
      rows.add(LedgerHistoryRow(
        id: item.id,
        date: item.date,
        kind: item.kind,
        titleEn: item.titleEn,
        titleUr: item.titleUr,
        detailEn: item.detailEn,
        detailUr: item.detailUr,
        debit: item.debit,
        credit: item.credit,
        runningBalance: running,
        fuel: item.fuel,
        liters: item.liters,
        rate: item.rate,
        purchase: item.purchase,
        payment: item.payment,
      ));
    }
    return rows.reversed.toList();
  }

  double get totalPurchasersReceivable => creditPurchasers.fold<double>(
        0,
        (sum, p) => sum + purchaserSummary(p.id).balance,
      );

  double get totalSuppliersPayable => suppliers.fold<double>(
        0,
        (sum, s) => sum + supplierSummary(s.id).balance,
      );

  double get totalExpensesAmount =>
      expenses.fold<double>(0, (sum, e) => sum + e.amount);

  /// Moving weighted-average purchase cost per liter for remaining tank stock.
  double fuelAvgPurchaseRate(FuelType type) {
    return fuelStocks[type]?.lastPurchaseRate ?? 0;
  }

  /// Total monetary value (worth in Rs.) of remaining fuel stock in tank.
  double fuelStockValueRs(FuelType type) {
    final stock = fuelStocks[type];
    if (stock == null || stock.remainingLiters <= 0) return 0;
    return (stock.remainingLiters * stock.lastPurchaseRate).roundToDouble();
  }

  String exportPartyLedgerCsv({
    required String partyName,
    required String partyPhone,
    required String periodLabel,
    required List<LedgerHistoryRow> rows,
  }) {
    final buf = StringBuffer();
    final cleanName = partyName.replaceAll(',', ' ');
    buf.writeln('Bolan Gasoline ERP - Account Statement');
    buf.writeln('Account,$cleanName,Phone,$partyPhone,Period,$periodLabel');
    buf.writeln('');
    buf.writeln(
        'Date,ID,Type,Description,Fuel,Liters,Rate (Rs),Billed / Debit (Rs),Paid / Credit (Rs),Running Balance (Rs)');
    for (final r in rows) {
      final dateStr = r.date.toIso8601String().split('T').first;
      final desc = r.titleEn.replaceAll(',', ' ');
      final fuel = r.fuel?.key ?? '-';
      final liters = r.liters != null ? r.liters!.round().toString() : '-';
      final rate = r.rate != null ? r.rate!.round().toString() : '-';
      buf.writeln(
        '$dateStr,${r.id},${r.kind.toUpperCase()},$desc,$fuel,$liters,$rate,${r.debit.round()},${r.credit.round()},${r.runningBalance.round()}',
      );
    }
    final totalDebit = rows.fold<double>(0, (s, r) => s + r.debit).round();
    final totalCredit = rows.fold<double>(0, (s, r) => s + r.credit).round();
    buf.writeln('');
    buf.writeln('TOTAL,,,,,,,"Rs. $totalDebit","Rs. $totalCredit",');
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // CASH & BANK LEDGER COMPUTATION + TRANSFERS
  // ---------------------------------------------------------------------------
  static String normalizeMethod(String raw) {
    final lower = raw.trim().toLowerCase();
    return (lower.contains('bank') || lower.contains('online'))
        ? 'Bank Transfer'
        : 'Cash';
  }

  List<CashBankEntry> get cashBankEntries {
    final entries = <CashBankEntry>[];

    for (final s in sales) {
      if (s.paidNow <= 0) continue;
      final p = findPurchaser(s.purchaserId);
      final isWalkIn = p?.isCashCounter ?? (s.purchaserId == 'CASH');
      final partyEn = p?.nameEn ?? s.purchaserId;
      final partyUr = p?.nameUr ?? s.purchaserId;
      final method = normalizeMethod(s.paymentMethod);
      entries.add(
        CashBankEntry(
          id: s.id,
          date: s.date,
          isInflow: true,
          method: method,
          sourceEn: isWalkIn ? 'Walk-in Fuel Sale' : 'Fuel Sale (Paid Now)',
          sourceUr: isWalkIn ? 'واک ان تیل فروخت' : 'تیل فروخت (نقد وصولی)',
          detailEn: '$partyEn • ${s.liters.round()} L ${s.fuel.key}',
          detailUr: '$partyUr • ${s.liters.round()} لیٹر ${s.fuel.label(true)}',
          amount: s.paidNow,
          note: s.note,
        ),
      );
    }

    for (final pay in payments) {
      if (pay.amount <= 0) continue;
      final isIn = pay.partyType == 'purchaser';
      final partyEn = isIn
          ? (findPurchaser(pay.partyId)?.nameEn ?? pay.partyId)
          : (findSupplier(pay.partyId)?.nameEn ?? pay.partyId);
      final partyUr = isIn
          ? (findPurchaser(pay.partyId)?.nameUr ?? pay.partyId)
          : (findSupplier(pay.partyId)?.nameUr ?? pay.partyId);
      final method = normalizeMethod(pay.method);
      entries.add(
        CashBankEntry(
          id: pay.id,
          date: pay.date,
          isInflow: isIn,
          method: method,
          sourceEn: isIn ? 'Khata Recovery' : 'Supplier Payment',
          sourceUr: isIn ? 'کھاتہ وصولی' : 'سپلائر ادائیگی',
          detailEn: partyEn,
          detailUr: partyUr,
          amount: pay.amount,
          note: pay.note,
        ),
      );
    }

    for (final pur in purchases) {
      if (pur.paid <= 0) continue;
      final sup = findSupplier(pur.supplierId);
      final method = normalizeMethod(pur.paymentMethod);
      entries.add(
        CashBankEntry(
          id: pur.id,
          date: pur.date,
          isInflow: false,
          method: method,
          sourceEn: 'Tanker Purchase (Paid)',
          sourceUr: 'ٹینکر خریداری (ادائیگی)',
          detailEn:
              '${sup?.nameEn ?? pur.supplierId} • ${pur.liters.round()} L ${pur.fuel.key}',
          detailUr:
              '${sup?.nameUr ?? pur.supplierId} • ${pur.liters.round()} لیٹر ${pur.fuel.label(true)}',
          amount: pur.paid,
          note: pur.note,
        ),
      );
    }

    for (final exp in expenses) {
      if (exp.amount <= 0) continue;
      final method = normalizeMethod(exp.paymentMethod);
      entries.add(
        CashBankEntry(
          id: exp.id,
          date: exp.date,
          isInflow: false,
          method: method,
          sourceEn: exp.categoryEn,
          sourceUr: exp.categoryUr,
          detailEn: exp.titleEn,
          detailUr: exp.titleUr,
          amount: exp.amount,
        ),
      );
    }

    for (final trf in cashBankTransfers) {
      if (trf.amount <= 0) continue;
      final from = normalizeMethod(trf.fromAccount);
      final to = normalizeMethod(trf.toAccount);
      entries.add(
        CashBankEntry(
          id: '${trf.id}-OUT',
          date: trf.date,
          isInflow: false,
          method: from,
          sourceEn: 'Transfer to $to',
          sourceUr: '$to میں ٹرانسفر',
          detailEn: trf.note.isEmpty ? '$from -> $to' : trf.note,
          detailUr: trf.note.isEmpty ? '$from -> $to' : trf.note,
          amount: trf.amount,
          note: trf.note,
        ),
      );
      entries.add(
        CashBankEntry(
          id: '${trf.id}-IN',
          date: trf.date,
          isInflow: true,
          method: to,
          sourceEn: 'Received from $from',
          sourceUr: '$from سے وصولی',
          detailEn: trf.note.isEmpty ? '$from -> $to' : trf.note,
          detailUr: trf.note.isEmpty ? '$from -> $to' : trf.note,
          amount: trf.amount,
          note: trf.note,
        ),
      );
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  double get totalCashInHand {
    double net = 0;
    for (final e in cashBankEntries) {
      if (e.method == 'Cash') {
        net += e.isInflow ? e.amount : -e.amount;
      }
    }
    return net;
  }

  double get totalBankBalance {
    double net = 0;
    for (final e in cashBankEntries) {
      if (e.method == 'Bank Transfer') {
        net += e.isInflow ? e.amount : -e.amount;
      }
    }
    return net;
  }

  double get totalLiquidFunds => totalCashInHand + totalBankBalance;

  void addCashBankTransfer({
    required String fromAccount,
    required String toAccount,
    required double amount,
    String note = '',
    DateTime? date,
  }) {
    cashBankTransfers.insert(
      0,
      CashBankTransfer(
        id: 'TRF-${_transferSeq++}',
        date: date ?? DateTime.now(),
        fromAccount: normalizeMethod(fromAccount),
        toAccount: normalizeMethod(toAccount),
        amount: amount,
        note: note.trim(),
      ),
    );
    notifyListeners();
    _persist();
  }

  void deleteCashBankTransfers(Iterable<String> ids) {
    final cleanIds = ids
        .map((id) => id.replaceAll('-IN', '').replaceAll('-OUT', ''))
        .toSet();
    cashBankTransfers.removeWhere((t) => cleanIds.contains(t.id));
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // CRUD: Fuel Sales
  // ---------------------------------------------------------------------------
  void addFuelSale({
    required String purchaserId,
    required FuelType fuel,
    required double liters,
    required double rateUsed,
    required double paidNow,
    String paymentMethod = 'Cash',
    String note = '',
    DateTime? date,
  }) {
    final sale = FuelSale(
      id: 'SL-${_saleSeq++}',
      date: date ?? DateTime.now(),
      purchaserId: purchaserId,
      fuel: fuel,
      liters: liters,
      rateUsed: rateUsed,
      paidNow: paidNow,
      paymentMethod: normalizeMethod(paymentMethod),
      syncStatus: isOfflineMode ? 'Offline Queued' : 'Synced',
      note: note,
    );
    sales.insert(0, sale);
    if (isOfflineMode) offlinePendingCount++;

    // Deduct stock
    final stock = fuelStocks[fuel]!;
    fuelStocks[fuel] =
        stock.copyWith(remainingLiters: stock.remainingLiters - liters);

    // Update purchaser's last custom rate
    final pIdx = purchasers.indexWhere((p) => p.id == purchaserId);
    if (pIdx != -1) {
      final p = purchasers[pIdx];
      purchasers[pIdx] = fuel == FuelType.petrol
          ? p.copyWith(petrolRate: rateUsed)
          : p.copyWith(dieselRate: rateUsed);
    }

    notifyListeners();
    _persist();
  }

  void updateFuelSale(FuelSale updated) {
    final idx = sales.indexWhere((s) => s.id == updated.id);
    if (idx == -1) return;
    final old = sales[idx];

    // Reverse old stock impact
    final oldStock = fuelStocks[old.fuel]!;
    fuelStocks[old.fuel] =
        oldStock.copyWith(remainingLiters: oldStock.remainingLiters + old.liters);

    // Apply new stock impact
    final newStock = fuelStocks[updated.fuel]!;
    fuelStocks[updated.fuel] = newStock.copyWith(
        remainingLiters: newStock.remainingLiters - updated.liters);

    sales[idx] = updated;
    notifyListeners();
    _persist();
  }

  void deleteFuelSales(Iterable<String> ids) {
    final idSet = ids.toSet();
    final toRemove = sales.where((s) => idSet.contains(s.id)).toList();
    for (final s in toRemove) {
      final stock = fuelStocks[s.fuel]!;
      fuelStocks[s.fuel] =
          stock.copyWith(remainingLiters: stock.remainingLiters + s.liters);
    }
    sales.removeWhere((s) => idSet.contains(s.id));
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // CRUD: Fuel Purchases & Tank Settings
  // ---------------------------------------------------------------------------
  void addFuelPurchase({
    required String supplierId,
    required FuelType fuel,
    required double liters,
    required double rate,
    required double paid,
    String paymentMethod = 'Cash',
    String note = '',
    DateTime? date,
  }) {
    final purchase = FuelPurchase(
      id: 'PUR-${_purchaseSeq++}',
      date: date ?? DateTime.now(),
      supplierId: supplierId,
      fuel: fuel,
      liters: liters,
      rate: rate,
      paid: paid,
      paymentMethod: normalizeMethod(paymentMethod),
      note: note,
    );
    purchases.insert(0, purchase);

    final stock = fuelStocks[fuel]!;
    final prevLiters = max(0.0, stock.remainingLiters);
    final newTotalLiters = prevLiters + liters;
    final weightedRate = newTotalLiters > 0
        ? ((prevLiters * stock.lastPurchaseRate) + (liters * rate)) /
            newTotalLiters
        : rate;
    fuelStocks[fuel] = stock.copyWith(
      remainingLiters: newTotalLiters,
      lastPurchaseRate: weightedRate,
    );

    notifyListeners();
    _persist();
  }

  void updateFuelPurchase(FuelPurchase updated) {
    final idx = purchases.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    final old = purchases[idx];

    final oldStock = fuelStocks[old.fuel]!;
    fuelStocks[old.fuel] =
        oldStock.copyWith(remainingLiters: oldStock.remainingLiters - old.liters);

    final newStock = fuelStocks[updated.fuel]!;
    fuelStocks[updated.fuel] = newStock.copyWith(
      remainingLiters: newStock.remainingLiters + updated.liters,
      lastPurchaseRate: updated.rate,
    );

    purchases[idx] = updated;
    notifyListeners();
    _persist();
  }

  void deleteFuelPurchases(Iterable<String> ids) {
    final idSet = ids.toSet();
    final toRemove = purchases.where((p) => idSet.contains(p.id)).toList();
    for (final p in toRemove) {
      final stock = fuelStocks[p.fuel]!;
      fuelStocks[p.fuel] =
          stock.copyWith(remainingLiters: stock.remainingLiters - p.liters);
    }
    purchases.removeWhere((p) => idSet.contains(p.id));
    notifyListeners();
    _persist();
  }

  void updateTankSettings(FuelStock updated) {
    fuelStocks[updated.type] = updated;
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // CRUD: Purchasers
  // ---------------------------------------------------------------------------
  Purchaser addPurchaser({
    required String nameEn,
    required String nameUr,
    required String phone,
    required double petrolRate,
    required double dieselRate,
    double openingBalance = 0,
  }) {
    final p = Purchaser(
      id: 'PR-${(_purchaserSeq++).toString().padLeft(2, '0')}',
      nameEn: nameEn.trim(),
      nameUr: nameUr.trim().isEmpty ? nameEn.trim() : nameUr.trim(),
      phone: phone.trim(),
      petrolRate: petrolRate,
      dieselRate: dieselRate,
      openingBilled: openingBalance,
      openingPaid: 0,
    );
    // Insert right after CASH counter so it's at the top
    final insertIndex =
        purchasers.isNotEmpty && purchasers.first.isCashCounter ? 1 : 0;
    purchasers.insert(insertIndex, p);
    notifyListeners();
    _persist();
    return p;
  }

  void updatePurchaser(Purchaser updated) {
    final idx = purchasers.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    purchasers[idx] = updated;
    notifyListeners();
    _persist();
  }

  void deletePurchasers(Iterable<String> ids) {
    final idSet = ids.where((id) => id != 'CASH').toSet();
    purchasers.removeWhere((p) => idSet.contains(p.id));
    payments.removeWhere(
        (pay) => pay.partyType == 'purchaser' && idSet.contains(pay.partyId));
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // CRUD: Suppliers
  // ---------------------------------------------------------------------------
  FuelSupplier addSupplier({
    required String nameEn,
    required String nameUr,
    required String phone,
    double openingBalance = 0,
  }) {
    final s = FuelSupplier(
      id: 'SUP-${(_supplierSeq++).toString().padLeft(2, '0')}',
      nameEn: nameEn.trim(),
      nameUr: nameUr.trim().isEmpty ? nameEn.trim() : nameUr.trim(),
      phone: phone.trim(),
      openingPurchased: openingBalance,
      openingPaid: 0,
    );
    suppliers.insert(0, s);
    notifyListeners();
    _persist();
    return s;
  }

  void updateSupplier(FuelSupplier updated) {
    final idx = suppliers.indexWhere((s) => s.id == updated.id);
    if (idx == -1) return;
    suppliers[idx] = updated;
    notifyListeners();
    _persist();
  }

  void deleteSuppliers(Iterable<String> ids) {
    final idSet = ids.toSet();
    suppliers.removeWhere((s) => idSet.contains(s.id));
    payments.removeWhere(
        (pay) => pay.partyType == 'supplier' && idSet.contains(pay.partyId));
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // CRUD: Ledger Payments (Purchaser Cash Recovery & Supplier Payments)
  // ---------------------------------------------------------------------------
  void addLedgerPayment({
    required String partyType,
    required String partyId,
    required double amount,
    String method = 'Cash',
    String note = '',
    DateTime? date,
  }) {
    if (amount <= 0) return;
    payments.insert(
      0,
      LedgerPayment(
        id: 'PAY-${_paymentSeq++}',
        date: date ?? DateTime.now(),
        partyType: partyType,
        partyId: partyId,
        amount: amount,
        method: method,
        note: note,
      ),
    );
    notifyListeners();
    _persist();
  }

  void updateLedgerPayment(LedgerPayment updated) {
    final idx = payments.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    payments[idx] = updated;
    notifyListeners();
    _persist();
  }

  void deleteLedgerPayments(Iterable<String> ids) {
    final idSet = ids.toSet();
    payments.removeWhere((p) => idSet.contains(p.id));
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // CRUD: Pump Expenses & Staff Salaries
  // ---------------------------------------------------------------------------
  void addExpense({
    required String categoryEn,
    required String categoryUr,
    required String titleEn,
    required String titleUr,
    required double amount,
    String paymentMethod = 'Cash',
    DateTime? date,
  }) {
    expenses.insert(
      0,
      PumpExpense(
        id: 'EXP-${_expenseSeq++}',
        date: date ?? DateTime.now(),
        categoryEn: categoryEn,
        categoryUr: categoryUr,
        titleEn: titleEn.trim(),
        titleUr: titleUr.trim().isEmpty ? titleEn.trim() : titleUr.trim(),
        amount: amount,
        paymentMethod: normalizeMethod(paymentMethod),
      ),
    );
    notifyListeners();
    _persist();
  }

  void updateExpense(PumpExpense updated) {
    final idx = expenses.indexWhere((e) => e.id == updated.id);
    if (idx == -1) return;
    expenses[idx] = updated;
    notifyListeners();
    _persist();
  }

  void deleteExpenses(Iterable<String> ids) {
    final idSet = ids.toSet();
    expenses.removeWhere((e) => idSet.contains(e.id));
    notifyListeners();
    _persist();
  }

  String addExpenseCategory(String nameEn, {String? nameUr}) {
    final cleanEn = nameEn.trim();
    if (cleanEn.isEmpty) return '';
    final existingIdx = expenseCategories.indexWhere(
      (c) => (c['en'] ?? '').toLowerCase() == cleanEn.toLowerCase(),
    );
    if (existingIdx != -1) {
      return expenseCategories[existingIdx]['en']!;
    }
    final cleanUr =
        (nameUr != null && nameUr.trim().isNotEmpty) ? nameUr.trim() : cleanEn;
    expenseCategories.add({'en': cleanEn, 'ur': cleanUr});
    notifyListeners();
    _persist();
    return cleanEn;
  }

  // ---------------------------------------------------------------------------
  // AUTH & ROLE-BASED ACCESS CONTROL (OWNER + EMPLOYEE)
  // ---------------------------------------------------------------------------
  void _refreshCurrentUserFromList() {
    if (currentUser == null) return;
    final match = users.where((u) => u.id == currentUser!.id).toList();
    if (match.isEmpty || !match.first.isActive) {
      currentUser = null;
      _storage.remove(_sessionUserKey);
    } else {
      currentUser = match.first;
      _ensureAccessibleModule();
    }
  }

  void _ensureAccessibleModule() {
    if (currentUser == null) return;
    if (!canAccessModule(activeModule)) {
      final allowed = accessibleModules;
      if (allowed.isNotEmpty) {
        activeModule = allowed.first;
      }
    }
  }

  /// Auto-detects Owner or Employee from Username + Password.
  /// Returns null on success, or localized error text on failure.
  String? login(String username, String password, {bool rememberMe = true}) {
    final cleanUser = username.trim().toLowerCase();
    final cleanPass = password.trim();
    if (cleanUser.isEmpty || cleanPass.isEmpty) {
      return isUrdu
          ? 'یوزر نیم اور پاس ورڈ درج کریں'
          : 'Please enter username and password';
    }
    AppUser? matched;
    for (final u in users) {
      if (u.username.toLowerCase() == cleanUser) {
        matched = u;
        break;
      }
    }
    if (matched == null || matched.password != cleanPass) {
      return isUrdu
          ? 'غلط یوزر نیم یا پاس ورڈ'
          : 'Invalid username or password';
    }
    if (!matched.isActive) {
      return isUrdu
          ? 'یہ اکاؤنٹ مالک کی طرف سے بند کر دیا گیا ہے'
          : 'This account has been disabled by the Owner';
    }
    currentUser = matched;
    _ensureAccessibleModule();
    if (rememberMe) {
      _storage.write(_sessionUserKey, matched.id);
    } else {
      _storage.remove(_sessionUserKey);
    }
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    _storage.remove(_sessionUserKey);
    notifyListeners();
  }

  AppUser addEmployee({
    required String name,
    required String username,
    required String password,
    required UserPermissions permissions,
    bool isActive = true,
  }) {
    final emp = AppUser(
      id: 'USR-${(_userSeq++).toString().padLeft(2, '0')}',
      name: name.trim(),
      username: username.trim().toLowerCase(),
      password: password.trim(),
      role: UserRole.employee,
      isActive: isActive,
      permissions: permissions,
    );
    users.add(emp);
    notifyListeners();
    _persist();
    return emp;
  }

  void updateUser(AppUser updated) {
    final idx = users.indexWhere((u) => u.id == updated.id);
    if (idx == -1) return;
    users[idx] = updated;
    _refreshCurrentUserFromList();
    notifyListeners();
    _persist();
  }

  void deleteUsers(Iterable<String> ids) {
    final idSet = ids.toSet();
    users.removeWhere((u) => !u.isOwner && idSet.contains(u.id));
    _refreshCurrentUserFromList();
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // DATA MANAGEMENT: ZERO-ZERO RESET, EXPORT JSON/CSV, IMPORT RESTORE
  // ---------------------------------------------------------------------------
  void resetAllDataToZero() {
    fuelStocks = {
      FuelType.petrol: fuelStocks[FuelType.petrol]!.copyWith(remainingLiters: 0),
      FuelType.diesel: fuelStocks[FuelType.diesel]!.copyWith(remainingLiters: 0),
    };
    purchasers = [
      Purchaser(
        id: 'CASH',
        nameEn: 'Cash Counter Sale (Walk-in)',
        nameUr: 'نقد کاؤنٹر سیل (کیش)',
        phone: 'Counter',
        petrolRate: fuelStocks[FuelType.petrol]!.cashSaleRate,
        dieselRate: fuelStocks[FuelType.diesel]!.cashSaleRate,
      ),
    ];
    suppliers = [];
    sales = [];
    purchases = [];
    payments = [];
    expenses = [];
    cashBankTransfers = [];
    _saleSeq = 101;
    _purchaseSeq = 101;
    _purchaserSeq = 1;
    _supplierSeq = 1;
    _paymentSeq = 101;
    _expenseSeq = 101;
    _transferSeq = 101;
    notifyListeners();
    _persist();
  }

  void loadDemoData() {
    fuelStocks = ErpSeedData.fuelStocks();
    purchasers = List.of(ErpSeedData.purchasers());
    suppliers = List.of(ErpSeedData.suppliers());
    sales = List.of(ErpSeedData.sales());
    purchases = List.of(ErpSeedData.purchases());
    payments = List.of(ErpSeedData.payments());
    expenses = List.of(ErpSeedData.expenses());
    cashBankTransfers = [];
    _saleSeq = 808;
    _purchaseSeq = 403;
    _purchaserSeq = 11;
    _supplierSeq = 3;
    _paymentSeq = 204;
    _expenseSeq = 104;
    _transferSeq = 101;
    notifyListeners();
    _persist();
  }

  String exportBackupJson() {
    final map = jsonDecode(_encodePayload()) as Map<String, dynamic>;
    map['exportedAt'] = DateTime.now().toIso8601String();
    map['app'] = 'Bolan Gasoline ERP';
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  String exportSalesCsv() {
    final buf = StringBuffer();
    buf.writeln('Bill ID,Date,Purchaser,Fuel,Liters,Rate (Rs),Total Bill (Rs),Paid (Rs),Due (Rs),Note');
    for (final s in sales) {
      final pName = (findPurchaser(s.purchaserId)?.nameEn ?? s.purchaserId)
          .replaceAll(',', ' ');
      final noteClean = s.note.replaceAll(',', ' ');
      buf.writeln(
        '${s.id},${s.date.toIso8601String().split('T').first},$pName,${s.fuel.key},${s.liters.round()},${s.rateUsed.round()},${s.totalAmount.round()},${s.paidNow.round()},${s.dueAmount.round()},$noteClean',
      );
    }
    return buf.toString();
  }

  String? importBackupJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return isUrdu ? 'غلط بیک اپ فائل فارمیٹ' : 'Invalid backup JSON format';
      }
      if (!decoded.containsKey('fuelStocks') && !decoded.containsKey('sales')) {
        return isUrdu
            ? 'یہ بولان گیسولین ERP بیک اپ فائل نہیں ہے'
            : 'Not a valid Bolan Gasoline ERP backup file';
      }
      _applyJsonPayload(rawJson, includeUiPrefs: false);
      notifyListeners();
      _persist();
      return null;
    } catch (_) {
      return isUrdu
          ? 'بیک اپ فائل پڑھنے میں خرابی آئی'
          : 'Failed to parse backup JSON file';
    }
  }
}
