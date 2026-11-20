import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../screens/dashboard_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/purchasers_screen.dart';
import '../screens/purchases_screen.dart';
import '../screens/sales_screen.dart';
import '../screens/settings_admin_screen.dart';
import '../screens/suppliers_screen.dart';
import '../widgets/common_widgets.dart';
import '../widgets/party_and_expense_dialogs.dart';
import '../widgets/purchase_form_dialog.dart';
import '../widgets/sale_form_dialog.dart';

class ErpShell extends StatefulWidget {
  const ErpShell({super.key, required this.store});

  final ErpStore store;

  @override
  State<ErpShell> createState() => _ErpShellState();
}

class _ErpShellState extends State<ErpShell> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_NavItem> _navItems(bool isUrdu) {
    final all = [
      _NavItem(
        module: ErpModule.dashboard,
        icon: Icons.grid_view_rounded,
        label: tr(isUrdu, 'Dashboard', 'ڈیش بورڈ (خلاصہ)'),
      ),
      _NavItem(
        module: ErpModule.sales,
        icon: Icons.local_gas_station_rounded,
        label: tr(isUrdu, 'Fuel Sales (Cash & Rate)',
            'تیل فروخت (کیش اور الگ ریٹ)'),
      ),
      _NavItem(
        module: ErpModule.purchases,
        icon: Icons.local_shipping_rounded,
        label: tr(isUrdu, 'Fuel Stock & Purchase', 'اسٹاک اور تیل خریداری'),
      ),
      _NavItem(
        module: ErpModule.purchasers,
        icon: Icons.people_alt_rounded,
        label: tr(
          isUrdu,
          'Purchasers Khata (${widget.store.creditPurchasers.length})',
          'پرچیزرز کھاتہ (${widget.store.creditPurchasers.length})',
        ),
      ),
      _NavItem(
        module: ErpModule.suppliers,
        icon: Icons.warehouse_rounded,
        label: tr(isUrdu, 'Suppliers Ledger', 'سپلائرز کھاتہ (ٹینکرز)'),
      ),
      _NavItem(
        module: ErpModule.expenses,
        icon: Icons.receipt_long_rounded,
        label: tr(isUrdu, 'Expenses & Salaries', 'اخراجات اور تنخواہیں'),
      ),
      _NavItem(
        module: ErpModule.settings,
        icon: Icons.admin_panel_settings_rounded,
        label: tr(isUrdu, 'Roles & Data Backup', 'رولز اور ڈیٹا بیک اپ'),
      ),
    ];
    return all.where((i) => widget.store.canAccessModule(i.module)).toList();
  }

  (String, String) _moduleTitle(ErpModule mod, bool isUrdu) {
    switch (mod) {
      case ErpModule.dashboard:
        return (
          tr(isUrdu, 'Bolan Gasoline — Petrol & Diesel ERP',
              'بولان گیسولین — پٹرول اور ڈیزل پمپ ڈیش بورڈ'),
          tr(
            isUrdu,
            '2 Fuel Units (Petrol & Diesel) • Per-Purchaser Rates • Personal Account History',
            'صرف 2 یونٹس (پٹرول اور ڈیزل) • ہر پرچیزر کا الگ ریٹ • ذاتی کھاتہ ہسٹری',
          ),
        );
      case ErpModule.sales:
        return (
          tr(isUrdu, 'Fuel Sales (Cash & Custom-Rate Purchasers)',
              'تیل کی فروخت (نقد کیش اور الگ الگ پرچیزر ریٹ)'),
          tr(
            isUrdu,
            'Every entry confirms the exact rate for that purchaser — never locked to one price!',
            'ہر انٹری پر پرچیزر کے حساب سے الگ ریٹ درج ہوتا ہے!',
          ),
        );
      case ErpModule.purchases:
        return (
          tr(isUrdu, 'Petrol & Diesel Tank Stock & Purchases',
              'پٹرول اور ڈیزل اسٹاک اور ٹینکر خریداری'),
          tr(
            isUrdu,
            'Track remaining liters in tanks, supplier bills & purchase rates',
            'ٹینک میں موجود لیٹر، سپلائر کا نام اور خرید ریٹ دیکھیں',
          ),
        );
      case ErpModule.purchasers:
        return (
          tr(isUrdu, 'Purchasers Khata & Individual Ledgers',
              'پرچیزرز کھاتہ اور ہر گاہک کی مکمل ہسٹری'),
          tr(
            isUrdu,
            'Click any purchaser to view their complete personal account & daily history',
            'کسی بھی پرچیزر پر کلک کر کے اس کا مکمل ذاتی کھاتہ اور روزانہ ہسٹری دیکھیں',
          ),
        );
      case ErpModule.suppliers:
        return (
          tr(isUrdu, 'Fuel Suppliers Ledger', 'تیل سپلائرز کھاتہ'),
          tr(
            isUrdu,
            'Track fuel tankers received from suppliers, payments made & payable balance',
            'سپلائر سے آنے والا تیل، ادا کی گئی رقم اور بقایا کھاتہ',
          ),
        );
      case ErpModule.expenses:
        return (
          tr(isUrdu, 'Pump Expenses & Boys Salaries',
              'پمپ اخراجات اور لڑکوں کی تنخواہیں'),
          tr(
            isUrdu,
            'All pump expenses including staff salaries, generator & daily costs',
            'پمپ کے لڑکوں کی تنخواہیں اور دیگر تمام اخراجات ایک جگہ',
          ),
        );
      case ErpModule.settings:
        return (
          tr(isUrdu, 'Roles, Employees & Data Management',
              'رولز، ملازمین اور ڈیٹا مینجمنٹ'),
          tr(
            isUrdu,
            'Zero-Zero data reset, JSON/CSV backup import/export & employee permissions',
            'ڈیٹا زیرو ری سیٹ، بیک اپ امپورٹ/ایکسپورٹ اور ملازمین کے اختیارات',
          ),
        );
    }
  }

  Widget _buildActiveModule() {
    switch (widget.store.activeModule) {
      case ErpModule.dashboard:
        return DashboardScreen(store: widget.store);
      case ErpModule.sales:
        return SalesScreen(store: widget.store);
      case ErpModule.purchases:
        return PurchasesScreen(store: widget.store);
      case ErpModule.purchasers:
        return PurchasersScreen(store: widget.store);
      case ErpModule.suppliers:
        return SuppliersScreen(store: widget.store);
      case ErpModule.expenses:
        return ExpensesScreen(store: widget.store);
      case ErpModule.settings:
        return SettingsAdminScreen(store: widget.store);
    }
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isMobile = width < 680;
    final (title, subtitle) = _moduleTitle(widget.store.activeModule, isUrdu);
    final showKpis = isDesktop || widget.store.activeModule == ErpModule.dashboard;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: erp.appBg,
      drawer: isDesktop
          ? null
          : Drawer(
              width: 276,
              backgroundColor: erp.sidebarBg,
              child: _SidebarContent(
                store: widget.store,
                navItems: _navItems(isUrdu),
                onSelect: (m) {
                  widget.store.setModule(m);
                  Navigator.of(context).pop();
                },
              ),
            ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(isUrdu),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 264,
              child: _SidebarContent(
                store: widget.store,
                navItems: _navItems(isUrdu),
                onSelect: widget.store.setModule,
              ),
            ),
          Expanded(
            child: Column(
              children: [
                if (isMobile)
                  _buildMobileHeader(isUrdu: isUrdu)
                else
                  _buildTopHeader(
                    isDesktop: isDesktop,
                    isUrdu: isUrdu,
                    title: title,
                    subtitle: subtitle,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 12,
                      vertical: isDesktop ? 18 : 12,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1380),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isMobile)
                              _buildMobileSearchAndActions(isUrdu)
                            else
                              _buildSearchAndActions(isUrdu),
                            if (showKpis) ...[
                              SizedBox(height: isMobile ? 12 : 16),
                              _buildKpiRow(isUrdu, isMobile: isMobile),
                            ],
                            SizedBox(height: isMobile ? 14 : 18),
                            _buildActiveModule(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileThemeSheet(bool isUrdu) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.erp.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final erp = ctx.erp;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: erp.cardBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  tr(isUrdu, 'Choose App Theme & Color',
                      'ایپ تھیم اور رنگ منتخب کریں'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: erp.textMain,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kErpThemes.map((t) {
                    final active = widget.store.themeId == t.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        widget.store.setTheme(t.id);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? erp.primarySoft : erp.subtleBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active ? erp.primary : erp.cardBorder,
                            width: active ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: t.swatchColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUrdu ? t.labelUr : t.labelEn,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: erp.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader({required bool isUrdu}) {
    final erp = context.erp;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: erp.cardBg,
        border: Border(bottom: BorderSide(color: erp.cardBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              tooltip: tr(isUrdu, 'Menu', 'مینو'),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: Icon(Icons.menu_rounded, color: erp.textMain),
              visualDensity: VisualDensity.compact,
            ),
            const BolanLogoBadge(size: 34),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(isUrdu, 'BOLAN GASOLINE', 'بولان گیسولین'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: erp.textMain,
                      letterSpacing: 0.1,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      widget.store.toggleOfflineMode();
                      showErpSnackBar(
                        context,
                        widget.store.isOfflineMode
                            ? tr(isUrdu, 'Offline Mode Enabled',
                                'آف لائن موڈ فعال ہو گیا')
                            : tr(isUrdu, 'Cloud Synced Live!',
                                'کلاؤڈ لائیو سنک ہو گیا!'),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: widget.store.isOfflineMode
                                ? erp.warning
                                : erp.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            widget.store.isOfflineMode
                                ? tr(isUrdu, 'Offline Mode', 'آف لائن موڈ')
                                : widget.store.isCloudSyncing
                                    ? tr(isUrdu, 'Syncing...', 'سنک...')
                                    : tr(isUrdu, 'Cloud Synced', 'لائیو سنک'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: widget.store.isOfflineMode
                                  ? erp.warning
                                  : erp.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: tr(isUrdu, 'Change Theme', 'تھیم تبدیل کریں'),
              onPressed: () => _showMobileThemeSheet(isUrdu),
              icon: Icon(Icons.palette_outlined, color: erp.primary, size: 21),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 2),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                widget.store.toggleLanguage();
                showErpSnackBar(
                  context,
                  widget.store.isUrdu
                      ? 'پورا سافٹ ویئر اردو میں تبدیل ہو گیا!'
                      : 'Switched to English!',
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: erp.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: erp.primaryBorder),
                ),
                child: Text(
                  isUrdu ? 'EN' : 'اردو',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: erp.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSearchAndActions(bool isUrdu) {
    final erp = context.erp;
    final actionTiles = <Widget>[
      if (widget.store.canCreateIn(ErpModule.sales))
        Expanded(
          child: _MobileQuickTile(
            icon: Icons.local_gas_station_rounded,
            label: tr(isUrdu, '+ Sale', '+ فروخت'),
            bg: erp.primary,
            fg: Colors.white,
            onTap: () => showSaleFormDialog(context, widget.store),
          ),
        ),
      if (widget.store.canCreateIn(ErpModule.purchases))
        Expanded(
          child: _MobileQuickTile(
            icon: Icons.arrow_downward_rounded,
            label: tr(isUrdu, '+ Stock', '+ اسٹاک'),
            bg: erp.success,
            fg: Colors.white,
            onTap: () => showPurchaseFormDialog(context, widget.store),
          ),
        ),
      if (widget.store.canCreateIn(ErpModule.expenses))
        Expanded(
          child: _MobileQuickTile(
            icon: Icons.receipt_long_rounded,
            label: tr(isUrdu, '+ Expense', '+ خرچہ'),
            bg: erp.cardBg,
            fg: erp.danger,
            borderColor: erp.cardBorder,
            onTap: () => showExpenseFormDialog(context, widget.store),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actionTiles.isNotEmpty) ...[
          Row(
            children: [
              for (int i = 0; i < actionTiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actionTiles[i],
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 44,
          child: TextField(
            controller: _searchCtrl,
            onChanged: widget.store.setSearchQuery,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              hintText: tr(
                isUrdu,
                'Search Arsalan, Petrol, Diesel, Supplier...',
                'تلاش کریں: ارسلان، پٹرول، ڈیزل، سپلائر...',
              ),
              prefixIcon:
                  Icon(Icons.search_rounded, size: 19, color: erp.textMuted),
              suffixIcon: widget.store.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        widget.store.setSearchQuery('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 17),
                    )
                  : null,
              fillColor: erp.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: erp.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: erp.cardBorder),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader({
    required bool isDesktop,
    required bool isUrdu,
    required String title,
    required String subtitle,
  }) {
    final erp = context.erp;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: erp.cardBg,
        border: Border(bottom: BorderSide(color: erp.cardBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDesktop) ...[
                  IconButton(
                    tooltip: tr(isUrdu, 'Menu', 'مینو'),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: Icon(Icons.menu_rounded, color: erp.textMain),
                  ),
                  const BolanLogoBadge(size: 34),
                  const SizedBox(width: 10),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isDesktop ? 480 : 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isDesktop ? 17 : 15,
                          fontWeight: FontWeight.w800,
                          color: erp.textMain,
                        ),
                      ),
                      if (isDesktop)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: erp.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 6 Themes Swatch Bar
                _ThemeSwitcherBar(store: widget.store, compact: !isDesktop),

                // Online / Offline Auto-Sync Toggle
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    widget.store.toggleOfflineMode();
                    showErpSnackBar(
                      context,
                      widget.store.isOfflineMode
                          ? tr(
                              isUrdu,
                              'Offline Mode: Entries save locally & auto-sync when internet returns!',
                              'آف لائن موڈ: انٹریز محفوظ رہیں گی اور نیٹ آتے ہی سنک ہو جائیں گی!',
                            )
                          : tr(
                              isUrdu,
                              'All offline pump entries synced live!',
                              'تمام آف لائن انٹریز لائیو سنک ہو گئیں!',
                            ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: widget.store.isOfflineMode
                          ? erp.warningSoft
                          : erp.successSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.store.isOfflineMode
                              ? Icons.cloud_off_rounded
                              : Icons.wifi_rounded,
                          size: 14,
                          color: widget.store.isOfflineMode
                              ? erp.warning
                              : erp.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.store.isOfflineMode
                              ? tr(
                                  isUrdu,
                                  'Offline (${widget.store.offlinePendingCount})',
                                  'آف لائن (${widget.store.offlinePendingCount})',
                                )
                              : widget.store.isCloudSyncing
                                  ? tr(isUrdu, 'Syncing...', 'سنک ہو رہا ہے...')
                                  : tr(isUrdu, 'Cloud Synced', 'کلاؤڈ لائیو سنک'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: widget.store.isOfflineMode
                                ? erp.warning
                                : erp.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Language Toggle (EN <-> اردو)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: erp.primarySoft,
                    foregroundColor: erp.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: () {
                    widget.store.toggleLanguage();
                    showErpSnackBar(
                      context,
                      widget.store.isUrdu
                          ? 'پورا سافٹ ویئر اردو میں تبدیل ہو گیا!'
                          : 'Switched to English!',
                    );
                  },
                  icon: const Icon(Icons.translate_rounded, size: 16),
                  label: Text(
                    isUrdu ? 'English' : 'اردو',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSearchAndActions(bool isUrdu) {
    final erp = context.erp;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            controller: _searchCtrl,
            onChanged: widget.store.setSearchQuery,
            decoration: InputDecoration(
              hintText: tr(
                isUrdu,
                'Search Petrol, Diesel, Arsalan, Purchaser, Supplier...',
                'تلاش کریں: پٹرول، ڈیزل، ارسلان، پرچیزر یا سپلائر...',
              ),
              prefixIcon: Icon(Icons.search_rounded, color: erp.textMuted),
              suffixIcon: widget.store.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        widget.store.setSearchQuery('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    )
                  : null,
              fillColor: erp.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(color: erp.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(color: erp.cardBorder),
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.store.canCreateIn(ErpModule.purchases))
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: erp.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () => showPurchaseFormDialog(context, widget.store),
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                label: Text(
                  tr(isUrdu, '+ Fuel Stock In', '+ نیا تیل آیا'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            if (widget.store.canCreateIn(ErpModule.expenses))
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: erp.cardBg,
                  foregroundColor: erp.textMain,
                  side: BorderSide(color: erp.cardBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () => showExpenseFormDialog(context, widget.store),
                icon: Icon(Icons.receipt_long_rounded,
                    size: 16, color: erp.danger),
                label: Text(
                  tr(isUrdu, '+ Expense / Salary', '+ خرچہ / تنخواہ'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            if (widget.store.canCreateIn(ErpModule.sales))
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: erp.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () => showSaleFormDialog(context, widget.store),
                icon: const Icon(Icons.local_gas_station_rounded, size: 16),
                label: Text(
                  tr(isUrdu, '+ New Fuel Sale', '+ نیا تیل فروخت'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiRow(bool isUrdu, {bool isMobile = false}) {
    final erp = context.erp;
    final perms = widget.store.activePermissions;
    final petrol = widget.store.fuelStocks[FuelType.petrol]!;
    final diesel = widget.store.fuelStocks[FuelType.diesel]!;
    final petrolWorth = widget.store.fuelStockValueRs(FuelType.petrol);
    final dieselWorth = widget.store.fuelStockValueRs(FuelType.diesel);

    final cards = <Widget>[
      if (perms.viewDashboard || perms.manageSales || perms.managePurchases)
        KpiStatCard(
          compact: isMobile,
          icon: Icons.local_gas_station_rounded,
          iconBg: erp.petrolColor,
          pillText: tr(isUrdu, 'Rs.${petrol.cashSaleRate.round()}/L',
              'Rs.${petrol.cashSaleRate.round()}'),
          pillBg: erp.petrolSoft,
          pillColor: erp.petrolColor,
          valueText: formatLiters(petrol.remainingLiters),
          label: tr(
            isUrdu,
            'Petrol Stock • Value: ${formatRs(petrolWorth)}',
            'پٹرول اسٹاک • مالیت: ${formatRs(petrolWorth)}',
          ),
          onTap: perms.managePurchases
              ? () => widget.store.setModule(ErpModule.purchases)
              : null,
        ),
      if (perms.viewDashboard || perms.manageSales || perms.managePurchases)
        KpiStatCard(
          compact: isMobile,
          icon: Icons.oil_barrel_rounded,
          iconBg: erp.dieselColor,
          pillText: tr(isUrdu, 'Rs.${diesel.cashSaleRate.round()}/L',
              'Rs.${diesel.cashSaleRate.round()}'),
          pillBg: erp.dieselSoft,
          pillColor: erp.dieselColor,
          valueText: formatLiters(diesel.remainingLiters),
          label: tr(
            isUrdu,
            'Diesel Stock • Value: ${formatRs(dieselWorth)}',
            'ڈیزل اسٹاک • مالیت: ${formatRs(dieselWorth)}',
          ),
          onTap: perms.managePurchases
              ? () => widget.store.setModule(ErpModule.purchases)
              : null,
        ),
      if (perms.managePurchasers)
        KpiStatCard(
          compact: isMobile,
          icon: Icons.people_alt_rounded,
          iconBg: erp.success,
          pillText: tr(
            isUrdu,
            '${widget.store.creditPurchasers.length} Buyers',
            '${widget.store.creditPurchasers.length} کھاتے',
          ),
          pillBg: erp.successSoft,
          pillColor: erp.success,
          valueText: formatRs(widget.store.totalPurchasersReceivable),
          label: tr(isUrdu, 'Purchasers Receivable', 'پرچیزرز بقایا وصولی'),
          onTap: () => widget.store.setModule(ErpModule.purchasers),
        ),
      if (perms.manageExpenses)
        KpiStatCard(
          compact: isMobile,
          icon: Icons.receipt_long_rounded,
          iconBg: erp.danger,
          pillText: perms.manageSuppliers
              ? tr(
                  isUrdu,
                  'Sup: ${formatRs(widget.store.totalSuppliersPayable)}',
                  'سپلائر: ${formatRs(widget.store.totalSuppliersPayable)}',
                )
              : tr(
                  isUrdu,
                  '${widget.store.expenses.length} Entries',
                  '${widget.store.expenses.length} انٹریز',
                ),
          pillBg: erp.dangerSoft,
          pillColor: erp.danger,
          valueText: formatRs(widget.store.totalExpensesAmount),
          label: tr(isUrdu, 'Expenses & Salaries', 'اخراجات اور تنخواہیں'),
          onTap: () => widget.store.setModule(ErpModule.expenses),
        ),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = constraints.maxWidth >= 1040
            ? cards.length.clamp(1, 4)
            : cards.length.clamp(1, 2);
        final gap = isMobile ? 10.0 : 14.0;
        final rows = <Widget>[];
        for (int i = 0; i < cards.length; i += cols) {
          final slice = cards.sublist(i, (i + cols).clamp(0, cards.length));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int j = 0; j < slice.length; j++) ...[
                    if (j > 0) SizedBox(width: gap),
                    Expanded(child: slice[j]),
                  ],
                ],
              ),
            ),
          );
          if (i + cols < cards.length) rows.add(SizedBox(height: gap));
        }
        return Column(children: rows);
      },
    );
  }

  Widget? _buildMobileBottomNav(bool isUrdu) {
    final erp = context.erp;
    final candidates = [
      (
        ErpModule.dashboard,
        NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined, size: 21),
          selectedIcon:
              Icon(Icons.grid_view_rounded, size: 21, color: erp.primary),
          label: tr(isUrdu, 'Home', 'ہوم'),
        ),
      ),
      (
        ErpModule.sales,
        NavigationDestination(
          icon: const Icon(Icons.local_gas_station_outlined, size: 21),
          selectedIcon: Icon(Icons.local_gas_station_rounded,
              size: 21, color: erp.primary),
          label: tr(isUrdu, 'Sales', 'فروخت'),
        ),
      ),
      (
        ErpModule.purchasers,
        NavigationDestination(
          icon: const Icon(Icons.people_outline_rounded, size: 21),
          selectedIcon:
              Icon(Icons.people_alt_rounded, size: 21, color: erp.primary),
          label: tr(isUrdu, 'Khata', 'کھاتہ'),
        ),
      ),
      (
        ErpModule.purchases,
        NavigationDestination(
          icon: const Icon(Icons.local_shipping_outlined, size: 21),
          selectedIcon:
              Icon(Icons.local_shipping_rounded, size: 21, color: erp.primary),
          label: tr(isUrdu, 'Stock', 'اسٹاک'),
        ),
      ),
      (
        ErpModule.expenses,
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined, size: 21),
          selectedIcon:
              Icon(Icons.receipt_long_rounded, size: 21, color: erp.primary),
          label: tr(isUrdu, 'Expense', 'خرچہ'),
        ),
      ),
    ];

    final allowed =
        candidates.where((c) => widget.store.canAccessModule(c.$1)).toList();
    if (allowed.length < 2) return null;

    final currentIdx =
        allowed.indexWhere((c) => c.$1 == widget.store.activeModule);

    return Container(
      decoration: BoxDecoration(
        color: erp.cardBg,
        border: Border(top: BorderSide(color: erp.cardBorder)),
      ),
      child: NavigationBar(
        height: 64,
        backgroundColor: erp.cardBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: erp.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: currentIdx >= 0 ? currentIdx : 0,
        onDestinationSelected: (idx) =>
            widget.store.setModule(allowed[idx].$1),
        destinations: allowed.map((c) => c.$2).toList(),
      ),
    );
  }
}

class _MobileQuickTile extends StatelessWidget {
  const _MobileQuickTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.module,
    required this.icon,
    required this.label,
  });

  final ErpModule module;
  final IconData icon;
  final String label;
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.store,
    required this.navItems,
    required this.onSelect,
  });

  final ErpStore store;
  final List<_NavItem> navItems;
  final ValueChanged<ErpModule> onSelect;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = store.isUrdu;

    return Container(
      color: erp.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            // Bolan Gasoline Brand Header with REAL Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  const BolanLogoBadge(size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(isUrdu, 'BOLAN GASOLINE', 'بولان گیسولین'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(isUrdu, 'Petrol & Diesel Pump ERP',
                              'پٹرول اور ڈیزل پمپ سسٹم'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 6 Modules List
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                itemCount: navItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, idx) {
                  final item = navItems[idx];
                  final active = store.activeModule == item.module;
                  return Material(
                    color: active ? erp.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onSelect(item.module),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 19,
                              color: active
                                  ? Colors.white
                                  : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom User Role Badge + Logout Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: erp.primary,
                        child: Icon(
                          store.isOwner
                              ? Icons.shield_rounded
                              : Icons.badge_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          store.currentUser?.name ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: tr(isUrdu, 'Logout', 'لاگ آؤٹ'),
                        onPressed: store.logout,
                        icon: const Icon(Icons.logout_rounded,
                            size: 18, color: Color(0xFFFCA5A5)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwitcherBar extends StatelessWidget {
  const _ThemeSwitcherBar({required this.store, required this.compact});

  final ErpStore store;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: erp.subtleBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: erp.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: kErpThemes.map((t) {
          final active = store.themeId == t.id;
          return Tooltip(
            message: store.isUrdu ? t.labelUr : t.labelEn,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => store.setTheme(t.id),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 5 : 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: active ? erp.cardBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? erp.primaryBorder : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: t.swatchColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    if (!compact && active) ...[
                      const SizedBox(width: 5),
                      Text(
                        store.isUrdu ? t.labelUr : t.labelEn,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: erp.textMain,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
