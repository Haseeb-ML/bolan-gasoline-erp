import 'dart:math';

enum FuelType { petrol, diesel }

extension FuelTypeX on FuelType {
  String get key => this == FuelType.petrol ? 'Petrol' : 'Diesel';
  String label(bool isUrdu) => this == FuelType.petrol
      ? (isUrdu ? 'پٹرول (Petrol)' : 'Petrol')
      : (isUrdu ? 'ڈیزل (Diesel)' : 'Diesel');

  static FuelType fromKey(String key) =>
      key.toLowerCase() == 'petrol' ? FuelType.petrol : FuelType.diesel;
}

class FuelStock {
  const FuelStock({
    required this.type,
    required this.capacityLiters,
    required this.remainingLiters,
    required this.lastPurchaseRate,
    required this.cashSaleRate,
  });

  final FuelType type;
  final double capacityLiters;
  final double remainingLiters;
  final double lastPurchaseRate;
  final double cashSaleRate;

  double get fillFraction =>
      capacityLiters <= 0 ? 0 : (remainingLiters / capacityLiters).clamp(0.0, 1.0);
  int get fillPercent => (fillFraction * 100).round();

  FuelStock copyWith({
    double? capacityLiters,
    double? remainingLiters,
    double? lastPurchaseRate,
    double? cashSaleRate,
  }) {
    return FuelStock(
      type: type,
      capacityLiters: capacityLiters ?? this.capacityLiters,
      remainingLiters: max(0, remainingLiters ?? this.remainingLiters),
      lastPurchaseRate: lastPurchaseRate ?? this.lastPurchaseRate,
      cashSaleRate: cashSaleRate ?? this.cashSaleRate,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.key,
        'capacityLiters': capacityLiters,
        'remainingLiters': remainingLiters,
        'lastPurchaseRate': lastPurchaseRate,
        'cashSaleRate': cashSaleRate,
      };

  factory FuelStock.fromJson(Map<String, dynamic> j) => FuelStock(
        type: FuelTypeX.fromKey(j['type'] as String? ?? 'Petrol'),
        capacityLiters: (j['capacityLiters'] as num?)?.toDouble() ?? 25000,
        remainingLiters: (j['remainingLiters'] as num?)?.toDouble() ?? 0,
        lastPurchaseRate: (j['lastPurchaseRate'] as num?)?.toDouble() ?? 250,
        cashSaleRate: (j['cashSaleRate'] as num?)?.toDouble() ?? 265,
      );
}

class Purchaser {
  const Purchaser({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.phone,
    required this.petrolRate,
    required this.dieselRate,
    this.openingBilled = 0,
    this.openingPaid = 0,
  });

  final String id;
  final String nameEn;
  final String nameUr;
  final String phone;
  final double petrolRate;
  final double dieselRate;
  final double openingBilled;
  final double openingPaid;

  bool get isCashCounter => id == 'CASH';
  String displayName(bool isUrdu) => isUrdu ? nameUr : nameEn;
  double rateFor(FuelType fuel) =>
      fuel == FuelType.petrol ? petrolRate : dieselRate;

  Purchaser copyWith({
    String? nameEn,
    String? nameUr,
    String? phone,
    double? petrolRate,
    double? dieselRate,
    double? openingBilled,
    double? openingPaid,
  }) {
    return Purchaser(
      id: id,
      nameEn: nameEn ?? this.nameEn,
      nameUr: nameUr ?? this.nameUr,
      phone: phone ?? this.phone,
      petrolRate: petrolRate ?? this.petrolRate,
      dieselRate: dieselRate ?? this.dieselRate,
      openingBilled: openingBilled ?? this.openingBilled,
      openingPaid: openingPaid ?? this.openingPaid,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameEn': nameEn,
        'nameUr': nameUr,
        'phone': phone,
        'petrolRate': petrolRate,
        'dieselRate': dieselRate,
        'openingBilled': openingBilled,
        'openingPaid': openingPaid,
      };

  factory Purchaser.fromJson(Map<String, dynamic> j) => Purchaser(
        id: j['id'] as String,
        nameEn: j['nameEn'] as String,
        nameUr: j['nameUr'] as String? ?? j['nameEn'] as String,
        phone: j['phone'] as String? ?? '',
        petrolRate: (j['petrolRate'] as num?)?.toDouble() ?? 260,
        dieselRate: (j['dieselRate'] as num?)?.toDouble() ?? 270,
        openingBilled: (j['openingBilled'] as num?)?.toDouble() ?? 0,
        openingPaid: (j['openingPaid'] as num?)?.toDouble() ?? 0,
      );
}

class FuelSupplier {
  const FuelSupplier({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.phone,
    this.openingPurchased = 0,
    this.openingPaid = 0,
  });

  final String id;
  final String nameEn;
  final String nameUr;
  final String phone;
  final double openingPurchased;
  final double openingPaid;

  String displayName(bool isUrdu) => isUrdu ? nameUr : nameEn;

  FuelSupplier copyWith({
    String? nameEn,
    String? nameUr,
    String? phone,
    double? openingPurchased,
    double? openingPaid,
  }) {
    return FuelSupplier(
      id: id,
      nameEn: nameEn ?? this.nameEn,
      nameUr: nameUr ?? this.nameUr,
      phone: phone ?? this.phone,
      openingPurchased: openingPurchased ?? this.openingPurchased,
      openingPaid: openingPaid ?? this.openingPaid,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameEn': nameEn,
        'nameUr': nameUr,
        'phone': phone,
        'openingPurchased': openingPurchased,
        'openingPaid': openingPaid,
      };

  factory FuelSupplier.fromJson(Map<String, dynamic> j) => FuelSupplier(
        id: j['id'] as String,
        nameEn: j['nameEn'] as String,
        nameUr: j['nameUr'] as String? ?? j['nameEn'] as String,
        phone: j['phone'] as String? ?? '',
        openingPurchased: (j['openingPurchased'] as num?)?.toDouble() ?? 0,
        openingPaid: (j['openingPaid'] as num?)?.toDouble() ?? 0,
      );
}

class FuelSale {
  const FuelSale({
    required this.id,
    required this.date,
    required this.purchaserId,
    required this.fuel,
    required this.liters,
    required this.rateUsed,
    required this.paidNow,
    this.syncStatus = 'Synced',
    this.note = '',
  });

  final String id;
  final DateTime date;
  final String purchaserId;
  final FuelType fuel;
  final double liters;
  final double rateUsed;
  final double paidNow;
  final String syncStatus;
  final String note;

  bool get isCash => purchaserId == 'CASH';
  double get totalAmount => (liters * rateUsed).roundToDouble();
  double get dueAmount => max(0, totalAmount - paidNow);

  FuelSale copyWith({
    DateTime? date,
    String? purchaserId,
    FuelType? fuel,
    double? liters,
    double? rateUsed,
    double? paidNow,
    String? syncStatus,
    String? note,
  }) {
    return FuelSale(
      id: id,
      date: date ?? this.date,
      purchaserId: purchaserId ?? this.purchaserId,
      fuel: fuel ?? this.fuel,
      liters: liters ?? this.liters,
      rateUsed: rateUsed ?? this.rateUsed,
      paidNow: paidNow ?? this.paidNow,
      syncStatus: syncStatus ?? this.syncStatus,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'purchaserId': purchaserId,
        'fuel': fuel.key,
        'liters': liters,
        'rateUsed': rateUsed,
        'paidNow': paidNow,
        'syncStatus': syncStatus,
        'note': note,
      };

  factory FuelSale.fromJson(Map<String, dynamic> j) => FuelSale(
        id: j['id'] as String,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        purchaserId: j['purchaserId'] as String? ?? 'CASH',
        fuel: FuelTypeX.fromKey(j['fuel'] as String? ?? 'Diesel'),
        liters: (j['liters'] as num?)?.toDouble() ?? 0,
        rateUsed: (j['rateUsed'] as num?)?.toDouble() ?? 0,
        paidNow: (j['paidNow'] as num?)?.toDouble() ?? 0,
        syncStatus: j['syncStatus'] as String? ?? 'Synced',
        note: j['note'] as String? ?? '',
      );
}

class FuelPurchase {
  const FuelPurchase({
    required this.id,
    required this.date,
    required this.supplierId,
    required this.fuel,
    required this.liters,
    required this.rate,
    required this.paid,
    this.note = '',
  });

  final String id;
  final DateTime date;
  final String supplierId;
  final FuelType fuel;
  final double liters;
  final double rate;
  final double paid;
  final String note;

  double get totalCost => (liters * rate).roundToDouble();
  double get balance => max(0, totalCost - paid);

  FuelPurchase copyWith({
    DateTime? date,
    String? supplierId,
    FuelType? fuel,
    double? liters,
    double? rate,
    double? paid,
    String? note,
  }) {
    return FuelPurchase(
      id: id,
      date: date ?? this.date,
      supplierId: supplierId ?? this.supplierId,
      fuel: fuel ?? this.fuel,
      liters: liters ?? this.liters,
      rate: rate ?? this.rate,
      paid: paid ?? this.paid,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'supplierId': supplierId,
        'fuel': fuel.key,
        'liters': liters,
        'rate': rate,
        'paid': paid,
        'note': note,
      };

  factory FuelPurchase.fromJson(Map<String, dynamic> j) => FuelPurchase(
        id: j['id'] as String,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        supplierId: j['supplierId'] as String,
        fuel: FuelTypeX.fromKey(j['fuel'] as String? ?? 'Diesel'),
        liters: (j['liters'] as num?)?.toDouble() ?? 0,
        rate: (j['rate'] as num?)?.toDouble() ?? 0,
        paid: (j['paid'] as num?)?.toDouble() ?? 0,
        note: j['note'] as String? ?? '',
      );
}

class LedgerPayment {
  const LedgerPayment({
    required this.id,
    required this.date,
    required this.partyType, // 'purchaser' | 'supplier'
    required this.partyId,
    required this.amount,
    this.method = 'Cash',
    this.note = '',
  });

  final String id;
  final DateTime date;
  final String partyType;
  final String partyId;
  final double amount;
  final String method;
  final String note;

  LedgerPayment copyWith({
    DateTime? date,
    double? amount,
    String? method,
    String? note,
  }) {
    return LedgerPayment(
      id: id,
      date: date ?? this.date,
      partyType: partyType,
      partyId: partyId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'partyType': partyType,
        'partyId': partyId,
        'amount': amount,
        'method': method,
        'note': note,
      };

  factory LedgerPayment.fromJson(Map<String, dynamic> j) => LedgerPayment(
        id: j['id'] as String,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        partyType: j['partyType'] as String? ?? 'purchaser',
        partyId: j['partyId'] as String,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        method: j['method'] as String? ?? 'Cash',
        note: j['note'] as String? ?? '',
      );
}

class PumpExpense {
  const PumpExpense({
    required this.id,
    required this.date,
    required this.categoryEn,
    required this.categoryUr,
    required this.titleEn,
    required this.titleUr,
    required this.amount,
  });

  final String id;
  final DateTime date;
  final String categoryEn;
  final String categoryUr;
  final String titleEn;
  final String titleUr;
  final double amount;

  String category(bool isUrdu) => isUrdu ? categoryUr : categoryEn;
  String title(bool isUrdu) => isUrdu ? titleUr : titleEn;

  PumpExpense copyWith({
    DateTime? date,
    String? categoryEn,
    String? categoryUr,
    String? titleEn,
    String? titleUr,
    double? amount,
  }) {
    return PumpExpense(
      id: id,
      date: date ?? this.date,
      categoryEn: categoryEn ?? this.categoryEn,
      categoryUr: categoryUr ?? this.categoryUr,
      titleEn: titleEn ?? this.titleEn,
      titleUr: titleUr ?? this.titleUr,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'categoryEn': categoryEn,
        'categoryUr': categoryUr,
        'titleEn': titleEn,
        'titleUr': titleUr,
        'amount': amount,
      };

  factory PumpExpense.fromJson(Map<String, dynamic> j) => PumpExpense(
        id: j['id'] as String,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        categoryEn: j['categoryEn'] as String? ?? 'Pump Misc Expense',
        categoryUr: j['categoryUr'] as String? ?? 'دیگر پمپ اخراجات',
        titleEn: j['titleEn'] as String? ?? '',
        titleUr: j['titleUr'] as String? ?? j['titleEn'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
      );
}

class PartyBalanceSummary {
  const PartyBalanceSummary({
    required this.totalBilled,
    required this.totalPaid,
    required this.balance,
    required this.totalLiters,
    required this.transactionCount,
  });

  final double totalBilled;
  final double totalPaid;
  final double balance;
  final double totalLiters;
  final int transactionCount;
}

/// Chronological statement row for Individual Purchaser or Supplier Ledger History.
class LedgerHistoryRow {
  const LedgerHistoryRow({
    required this.id,
    required this.date,
    required this.kind, // 'sale' | 'purchase' | 'payment'
    required this.titleEn,
    required this.titleUr,
    required this.detailEn,
    required this.detailUr,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.fuel,
    this.liters,
    this.rate,
    this.sale,
    this.purchase,
    this.payment,
  });

  final String id;
  final DateTime date;
  final String kind;
  final String titleEn;
  final String titleUr;
  final String detailEn;
  final String detailUr;
  final double debit;
  final double credit;
  final double runningBalance;
  final FuelType? fuel;
  final double? liters;
  final double? rate;
  final FuelSale? sale;
  final FuelPurchase? purchase;
  final LedgerPayment? payment;
}

enum UserRole { owner, employee }

class ModuleCrudPermission {
  const ModuleCrudPermission({
    this.view = false,
    this.create = false,
    this.update = false,
    this.delete = false,
  });

  const ModuleCrudPermission.full()
      : view = true,
        create = true,
        update = true,
        delete = true;

  const ModuleCrudPermission.none()
      : view = false,
        create = false,
        update = false,
        delete = false;

  final bool view;
  final bool create;
  final bool update;
  final bool delete;

  ModuleCrudPermission withView(bool v) => v
      ? copyWith(view: true)
      : const ModuleCrudPermission.none();

  ModuleCrudPermission withCreate(bool v) =>
      copyWith(view: v ? true : view, create: v);

  ModuleCrudPermission withUpdate(bool v) =>
      copyWith(view: v ? true : view, update: v);

  ModuleCrudPermission withDelete(bool v) =>
      copyWith(view: v ? true : view, delete: v);

  ModuleCrudPermission copyWith({
    bool? view,
    bool? create,
    bool? update,
    bool? delete,
  }) {
    return ModuleCrudPermission(
      view: view ?? this.view,
      create: create ?? this.create,
      update: update ?? this.update,
      delete: delete ?? this.delete,
    );
  }

  Map<String, dynamic> toJson() => {
        'view': view,
        'create': create,
        'update': update,
        'delete': delete,
      };

  factory ModuleCrudPermission.fromJson(
    Map<String, dynamic>? j, {
    required bool fallbackView,
    required bool fallbackCreate,
    required bool fallbackUpdate,
    required bool fallbackDelete,
  }) {
    if (j == null) {
      return ModuleCrudPermission(
        view: fallbackView,
        create: fallbackCreate && fallbackView,
        update: fallbackUpdate && fallbackView,
        delete: fallbackDelete && fallbackView,
      );
    }
    final v = j['view'] as bool? ?? fallbackView;
    return ModuleCrudPermission(
      view: v,
      create: v && (j['create'] as bool? ?? fallbackCreate),
      update: v && (j['update'] as bool? ?? fallbackUpdate),
      delete: v && (j['delete'] as bool? ?? fallbackDelete),
    );
  }
}

class UserPermissions {
  const UserPermissions({
    this.dashboard = const ModuleCrudPermission(view: true),
    this.sales = const ModuleCrudPermission(view: true, create: true),
    this.purchases = const ModuleCrudPermission.none(),
    this.purchasers = const ModuleCrudPermission(view: true, create: true),
    this.suppliers = const ModuleCrudPermission.none(),
    this.expenses = const ModuleCrudPermission.none(),
  });

  factory UserPermissions.all() => const UserPermissions(
        dashboard: ModuleCrudPermission.full(),
        sales: ModuleCrudPermission.full(),
        purchases: ModuleCrudPermission.full(),
        purchasers: ModuleCrudPermission.full(),
        suppliers: ModuleCrudPermission.full(),
        expenses: ModuleCrudPermission.full(),
      );

  factory UserPermissions.defaultEmployee() => const UserPermissions(
        dashboard: ModuleCrudPermission(view: true, update: false),
        sales: ModuleCrudPermission(
            view: true, create: true, update: false, delete: false),
        purchases: ModuleCrudPermission.none(),
        purchasers: ModuleCrudPermission(
            view: true, create: true, update: false, delete: false),
        suppliers: ModuleCrudPermission.none(),
        expenses: ModuleCrudPermission.none(),
      );

  factory UserPermissions.none() => const UserPermissions(
        dashboard: ModuleCrudPermission.none(),
        sales: ModuleCrudPermission.none(),
        purchases: ModuleCrudPermission.none(),
        purchasers: ModuleCrudPermission.none(),
        suppliers: ModuleCrudPermission.none(),
        expenses: ModuleCrudPermission.none(),
      );

  final ModuleCrudPermission dashboard;
  final ModuleCrudPermission sales;
  final ModuleCrudPermission purchases;
  final ModuleCrudPermission purchasers;
  final ModuleCrudPermission suppliers;
  final ModuleCrudPermission expenses;

  // Backward-compatible module view getters
  bool get viewDashboard => dashboard.view;
  bool get manageSales => sales.view;
  bool get managePurchases => purchases.view;
  bool get managePurchasers => purchasers.view;
  bool get manageSuppliers => suppliers.view;
  bool get manageExpenses => expenses.view;

  // Any-module edit/delete summary getters
  bool get canEdit =>
      dashboard.update ||
      sales.update ||
      purchases.update ||
      purchasers.update ||
      suppliers.update ||
      expenses.update;

  bool get canDelete =>
      sales.delete ||
      purchases.delete ||
      purchasers.delete ||
      suppliers.delete ||
      expenses.delete;

  UserPermissions copyWith({
    ModuleCrudPermission? dashboard,
    ModuleCrudPermission? sales,
    ModuleCrudPermission? purchases,
    ModuleCrudPermission? purchasers,
    ModuleCrudPermission? suppliers,
    ModuleCrudPermission? expenses,
  }) {
    return UserPermissions(
      dashboard: dashboard ?? this.dashboard,
      sales: sales ?? this.sales,
      purchases: purchases ?? this.purchases,
      purchasers: purchasers ?? this.purchasers,
      suppliers: suppliers ?? this.suppliers,
      expenses: expenses ?? this.expenses,
    );
  }

  Map<String, dynamic> toJson() => {
        'dashboard': dashboard.toJson(),
        'sales': sales.toJson(),
        'purchases': purchases.toJson(),
        'purchasers': purchasers.toJson(),
        'suppliers': suppliers.toJson(),
        'expenses': expenses.toJson(),
        // Legacy keys for backward compatibility
        'viewDashboard': viewDashboard,
        'manageSales': manageSales,
        'managePurchases': managePurchases,
        'managePurchasers': managePurchasers,
        'manageSuppliers': manageSuppliers,
        'manageExpenses': manageExpenses,
        'canEdit': canEdit,
        'canDelete': canDelete,
      };

  factory UserPermissions.fromJson(Map<String, dynamic> j) {
    final legacyEdit = j['canEdit'] as bool? ?? false;
    final legacyDel = j['canDelete'] as bool? ?? false;
    return UserPermissions(
      dashboard: ModuleCrudPermission.fromJson(
        j['dashboard'] as Map<String, dynamic>?,
        fallbackView: j['viewDashboard'] as bool? ?? true,
        fallbackCreate: false,
        fallbackUpdate: legacyEdit,
        fallbackDelete: false,
      ),
      sales: ModuleCrudPermission.fromJson(
        j['sales'] as Map<String, dynamic>?,
        fallbackView: j['manageSales'] as bool? ?? true,
        fallbackCreate: j['manageSales'] as bool? ?? true,
        fallbackUpdate: legacyEdit,
        fallbackDelete: legacyDel,
      ),
      purchases: ModuleCrudPermission.fromJson(
        j['purchases'] as Map<String, dynamic>?,
        fallbackView: j['managePurchases'] as bool? ?? false,
        fallbackCreate: j['managePurchases'] as bool? ?? false,
        fallbackUpdate: legacyEdit,
        fallbackDelete: legacyDel,
      ),
      purchasers: ModuleCrudPermission.fromJson(
        j['purchasers'] as Map<String, dynamic>?,
        fallbackView: j['managePurchasers'] as bool? ?? true,
        fallbackCreate: j['managePurchasers'] as bool? ?? true,
        fallbackUpdate: legacyEdit,
        fallbackDelete: legacyDel,
      ),
      suppliers: ModuleCrudPermission.fromJson(
        j['suppliers'] as Map<String, dynamic>?,
        fallbackView: j['manageSuppliers'] as bool? ?? false,
        fallbackCreate: j['manageSuppliers'] as bool? ?? false,
        fallbackUpdate: legacyEdit,
        fallbackDelete: legacyDel,
      ),
      expenses: ModuleCrudPermission.fromJson(
        j['expenses'] as Map<String, dynamic>?,
        fallbackView: j['manageExpenses'] as bool? ?? false,
        fallbackCreate: j['manageExpenses'] as bool? ?? false,
        fallbackUpdate: legacyEdit,
        fallbackDelete: legacyDel,
      ),
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    this.isActive = true,
    required this.permissions,
  });

  final String id;
  final String name;
  final String username;
  final String password;
  final UserRole role;
  final bool isActive;
  final UserPermissions permissions;

  bool get isOwner => role == UserRole.owner;

  AppUser copyWith({
    String? name,
    String? username,
    String? password,
    UserRole? role,
    bool? isActive,
    UserPermissions? permissions,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'password': password,
        'role': role.name,
        'isActive': isActive,
        'permissions': permissions.toJson(),
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'User',
        username: j['username'] as String? ?? 'user',
        password: j['password'] as String? ?? '1234',
        role: (j['role'] as String?) == 'owner'
            ? UserRole.owner
            : UserRole.employee,
        isActive: j['isActive'] as bool? ?? true,
        permissions: j['permissions'] is Map<String, dynamic>
            ? UserPermissions.fromJson(j['permissions'] as Map<String, dynamic>)
            : ((j['role'] as String?) == 'owner'
                ? UserPermissions.all()
                : UserPermissions.defaultEmployee()),
      );
}
