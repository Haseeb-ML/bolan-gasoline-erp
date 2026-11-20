import 'package:flutter/material.dart';

import '../../core/storage/file_transfer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_generator.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';
import '../widgets/party_and_expense_dialogs.dart';
import '../widgets/purchase_form_dialog.dart';

Future<void> openSupplierDetail(
  BuildContext context,
  ErpStore store,
  String supplierId,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SupplierDetailScreen(
        store: store,
        supplierId: supplierId,
      ),
    ),
  );
}

class SupplierDetailScreen extends StatefulWidget {
  const SupplierDetailScreen({
    super.key,
    required this.store,
    required this.supplierId,
  });

  final ErpStore store;
  final String supplierId;

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final Set<String> _selectedRowIds = {};
  String _filterKind = 'all'; // 'all' | 'purchase' | 'payment'
  String _periodFilter = 'all'; // 'all' | 'today' | 'week' | 'month' | 'year' | 'custom'
  DateTimeRange? _customRange;

  List<LedgerHistoryRow> _applyPeriodFilter(List<LedgerHistoryRow> input) {
    return filterByPeriod(
      items: input,
      getDate: (r) => r.date,
      period: _periodFilter,
      customRange: _customRange,
    );
  }

  Future<void> _pickCalendarRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customRange,
    );
    if (picked != null && mounted) {
      setState(() {
        _customRange = picked;
        _periodFilter = 'custom';
      });
    }
  }

  Future<void> _downloadSupplierReport(
    FuelSupplier supplier,
    List<LedgerHistoryRow> filteredRows,
  ) async {
    final isUrdu = widget.store.isUrdu;
    final csv = widget.store.exportPartyLedgerCsv(
      partyName: supplier.nameEn,
      partyPhone: supplier.phone,
      periodLabel: _periodFilter,
      rows: filteredRows,
    );
    final safeId = supplier.id.toLowerCase();
    await openExcelSheetViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_supplier_${safeId}_$_periodFilter.csv',
      sheetTitle: tr(
        isUrdu,
        '${supplier.nameEn} Statement — Excel Sheet View',
        '${supplier.nameUr} کھاتہ اسٹیٹمنٹ — ایکسل شیٹ ویو',
      ),
      csvContent: csv,
    );
  }

  Future<void> _downloadSupplierPdf(
    FuelSupplier supplier,
    List<LedgerHistoryRow> filteredRows,
  ) async {
    final isUrdu = widget.store.isUrdu;
    final totalDebit = filteredRows.fold<double>(0, (s, r) => s + r.debit);
    final totalCredit = filteredRows.fold<double>(0, (s, r) => s + r.credit);
    final totalLiters =
        filteredRows.fold<double>(0, (s, r) => s + (r.liters ?? 0));
    final latestBal =
        filteredRows.isNotEmpty ? filteredRows.first.runningBalance : 0.0;

    final pdfBytes = ErpPdfGenerator.buildTableReportPdf(
      reportTitle: 'SUPPLIER ACCOUNT & TANKER STATEMENT - ${supplier.nameEn}',
      subtitle:
          'Supplier ID: ${supplier.id}  |  Phone: ${supplier.phone}  |  Period: ${_periodFilter.toUpperCase()}',
      summaryItems: [
        'Total Tanker Liters: ${totalLiters.round()} L',
        'Total Purchased: Rs. ${totalDebit.round()}',
        'Total Paid: Rs. ${totalCredit.round()}',
        'Payable Balance: Rs. ${latestBal.round()}',
      ],
      headers: const [
        'ID',
        'DATE',
        'TYPE',
        'DESCRIPTION',
        'PURCHASED (DR)',
        'PAID (CR)',
        'PAYABLE BAL',
      ],
      rows: filteredRows
          .map((r) => [
                r.id,
                formatDateShort(r.date),
                r.kind.toUpperCase(),
                '${r.titleEn} (${r.detailEn})',
                r.debit > 0 ? 'Rs.${r.debit.round()}' : '-',
                r.credit > 0 ? 'Rs.${r.credit.round()}' : '-',
                'Rs.${r.runningBalance.round()}',
              ])
          .toList(),
    );
    final safeId = supplier.id.toLowerCase();
    await downloadBinaryFile(
      filename: 'bolan_supplier_${safeId}_$_periodFilter.pdf',
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );
    if (!mounted) return;
    showErpSnackBar(
      context,
      tr(isUrdu, 'Supplier PDF report downloaded (.pdf)!',
          'سپلائر پی ڈی ایف رپورٹ ڈاؤن لوڈ ہو گئی (.pdf)!'),
    );
  }

  Future<void> _deleteSelectedRows(List<LedgerHistoryRow> rows) async {
    final chosen =
        rows.where((r) => _selectedRowIds.contains(r.id)).toList();
    if (chosen.isEmpty) return;
    final ok = await confirmDeleteDialog(context,
        isUrdu: widget.store.isUrdu, count: chosen.length);
    if (!ok || !mounted) return;

    final purIds = chosen
        .where((r) => r.kind == 'purchase')
        .map((r) => r.id)
        .toList();
    final payIds = chosen
        .where((r) => r.kind == 'payment')
        .map((r) => r.id)
        .toList();
    if (purIds.isNotEmpty) widget.store.deleteFuelPurchases(purIds);
    if (payIds.isNotEmpty) widget.store.deleteLedgerPayments(payIds);
    setState(() => _selectedRowIds.clear());
    showErpSnackBar(
      context,
      tr(widget.store.isUrdu, '${chosen.length} ledger entry(s) deleted.',
          '${chosen.length} کھاتہ انٹریز حذف کر دی گئیں۔'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final erp = context.erp;
        final isUrdu = widget.store.isUrdu;
        final supplier = widget.store.findSupplier(widget.supplierId);
        if (supplier == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tr(isUrdu, 'Supplier', 'سپلائر'))),
            body: Center(
              child: Text(tr(isUrdu, 'Supplier not found', 'سپلائر نہیں ملا')),
            ),
          );
        }

        final summary = widget.store.supplierSummary(supplier.id);
        final allRows = widget.store.supplierLedgerHistory(supplier.id);
        final kindRows = _filterKind == 'all'
            ? allRows
            : allRows.where((r) => r.kind == _filterKind).toList();
        final rows = _applyPeriodFilter(kindRows);
        _selectedRowIds.removeWhere((id) => !rows.any((r) => r.id == id));
        final allSelected =
            rows.isNotEmpty && _selectedRowIds.length == rows.length;
        final isMobile = MediaQuery.sizeOf(context).width < 640;

        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: erp.appBg,
            appBar: AppBar(
              backgroundColor: erp.cardBg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 8,
              title: Row(
                children: [
                  const BolanLogoBadge(size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.displayName(isUrdu),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: erp.textMain),
                        ),
                        Text(
                          tr(isUrdu, 'Supplier Account & Tanker History',
                              'سپلائر کھاتہ اور ٹینکر ہسٹری'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: erp.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                if (widget.store.canUpdateIn(ErpModule.suppliers))
                  IconButton(
                    tooltip: tr(isUrdu, 'Edit Supplier Info',
                        'سپلائر معلومات ترمیم'),
                    onPressed: () => showSupplierFormDialog(
                      context,
                      widget.store,
                      existing: supplier,
                    ),
                    icon: Icon(Icons.edit_outlined, color: erp.primary),
                  ),
                const SizedBox(width: 6),
              ],
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile & Quick Action Header Card
                      Container(
                        padding: EdgeInsets.all(isMobile ? 14 : 20),
                        decoration: BoxDecoration(
                          color: erp.cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: erp.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 14,
                              runSpacing: 12,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: erp.primarySoft,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: LtrText(
                                        supplier.id,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: erp.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(Icons.phone_outlined,
                                        size: 14, color: erp.textMuted),
                                    const SizedBox(width: 4),
                                    LtrText(
                                      supplier.phone,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: erp.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isMobile)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: erp.success,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999)),
                                        ),
                                        onPressed: () =>
                                            showPurchaseFormDialog(
                                          context,
                                          widget.store,
                                          lockedSupplierId: supplier.id,
                                        ),
                                        icon: const Icon(
                                            Icons.local_shipping_rounded,
                                            size: 17),
                                        label: Text(
                                          tr(isUrdu, '+ Fuel Tanker In',
                                              '+ نیا ٹینکر آیا'),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: erp.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999)),
                                        ),
                                        onPressed: () =>
                                            showLedgerPaymentDialog(
                                          context,
                                          widget.store,
                                          partyType: 'supplier',
                                          partyId: supplier.id,
                                        ),
                                        icon: const Icon(
                                            Icons.payments_rounded,
                                            size: 17),
                                        label: Text(
                                          tr(isUrdu, 'Pay Supplier',
                                              'ادائیگی کریں'),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            if (isMobile) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: erp.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999)),
                                      ),
                                      onPressed: () => showPurchaseFormDialog(
                                        context,
                                        widget.store,
                                        lockedSupplierId: supplier.id,
                                      ),
                                      icon: const Icon(
                                          Icons.local_shipping_rounded,
                                          size: 16),
                                      label: Text(
                                        tr(isUrdu, '+ Tanker In',
                                            '+ نیا ٹینکر آیا'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: erp.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999)),
                                      ),
                                      onPressed: () => showLedgerPaymentDialog(
                                        context,
                                        widget.store,
                                        partyType: 'supplier',
                                        partyId: supplier.id,
                                      ),
                                      icon: const Icon(Icons.payments_rounded,
                                          size: 16),
                                      label: Text(
                                        tr(isUrdu, 'Pay Supplier',
                                            'ادائیگی کریں'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // 4 Summary Cards (2x2 compact grid on mobile, 4-col on desktop)
                      LayoutBuilder(
                        builder: (_, constraints) {
                          final cols = constraints.maxWidth >= 900 ? 4 : 2;
                          final compactCard = constraints.maxWidth < 600;
                          final isFiltered =
                              _periodFilter != 'all' || _filterKind != 'all';
                          final dispPurchased = isFiltered
                              ? rows.fold<double>(0, (s, r) => s + r.debit)
                              : summary.totalBilled;
                          final dispPaid = isFiltered
                              ? rows.fold<double>(0, (s, r) => s + r.credit)
                              : summary.totalPaid;
                          final dispLiters = isFiltered
                              ? rows.fold<double>(
                                  0, (s, r) => s + (r.liters ?? 0))
                              : summary.totalLiters;
                          final dispCount =
                              isFiltered ? rows.length : summary.transactionCount;

                          final cards = [
                            KpiStatCard(
                              compact: compactCard,
                              icon: Icons.local_shipping_rounded,
                              iconBg: erp.primary,
                              pillText:
                                  '$dispCount ${tr(isUrdu, 'Entries', 'انٹریز')}',
                              pillBg: erp.primarySoft,
                              pillColor: erp.primary,
                              valueText: formatRs(dispPurchased),
                              label: tr(isUrdu, 'Total Fuel Purchased',
                                  'کل خریداری بل'),
                            ),
                            KpiStatCard(
                              compact: compactCard,
                              icon: Icons.check_circle_rounded,
                              iconBg: erp.success,
                              pillText: tr(isUrdu, 'Paid', 'ادا شدہ'),
                              pillBg: erp.successSoft,
                              pillColor: erp.success,
                              valueText: formatRs(dispPaid),
                              label: tr(isUrdu, 'Total Paid Amount',
                                  'کل ادا شدہ رقم'),
                            ),
                            KpiStatCard(
                              compact: compactCard,
                              icon: Icons.account_balance_wallet_rounded,
                              iconBg: erp.danger,
                              pillText: tr(isUrdu, 'Payable Due', 'بقایا'),
                              pillBg: erp.dangerSoft,
                              pillColor: erp.danger,
                              valueText: formatRs(summary.balance),
                              label: tr(isUrdu, 'Remaining Payable Balance',
                                  'باقی دینے والی رقم'),
                            ),
                            KpiStatCard(
                              compact: compactCard,
                              icon: Icons.oil_barrel_rounded,
                              iconBg: erp.dieselColor,
                              pillText: tr(isUrdu, 'Tanker Volume', 'مجموعی تیل'),
                              pillBg: erp.dieselSoft,
                              pillColor: erp.dieselColor,
                              valueText: formatLiters(dispLiters),
                              label: tr(isUrdu, 'Total Tanker Liters',
                                  'کل خریدا گیا تیل (لیٹر)'),
                            ),
                          ];
                          return _SupplierCardGrid(cols: cols, cards: cards);
                        },
                      ),
                      SizedBox(height: isMobile ? 14 : 18),

                      // Complete Supplier Statement Table
                      Container(
                        padding: EdgeInsets.all(isMobile ? 14 : 20),
                        decoration: BoxDecoration(
                          color: erp.cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: erp.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr(isUrdu, 'Supplier Statement History',
                                          'سپلائر کھاتہ ہسٹری / اسٹیٹمنٹ'),
                                      style: TextStyle(
                                          fontSize: isMobile ? 15 : 16,
                                          fontWeight: FontWeight.w800,
                                          color: erp.textMain),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr(
                                        isUrdu,
                                        'Every fuel tanker arrival, purchase rate, payment made, and payable balance.',
                                        'ہر ٹینکر کی آمد، خرید ریٹ، ادا کی گئی رقم اور بقایا بیلنس۔',
                                      ),
                                      style: TextStyle(
                                          fontSize: 12, color: erp.textMuted),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    ChoiceChip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(tr(isUrdu, 'All', 'سب')),
                                      selected: _filterKind == 'all',
                                      onSelected: (_) =>
                                          setState(() => _filterKind = 'all'),
                                    ),
                                    ChoiceChip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(tr(
                                          isUrdu, 'Tankers', 'ٹینکر خریداری')),
                                      selected: _filterKind == 'purchase',
                                      onSelected: (_) => setState(
                                          () => _filterKind = 'purchase'),
                                    ),
                                    ChoiceChip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(
                                          tr(isUrdu, 'Payments', 'ادائیگیاں')),
                                      selected: _filterKind == 'payment',
                                      onSelected: (_) => setState(
                                          () => _filterKind = 'payment'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            PeriodFilterBar(
                              selectedPeriod: _periodFilter,
                              customRange: _customRange,
                              isUrdu: isUrdu,
                              onSelectPeriod: (p) =>
                                  setState(() => _periodFilter = p),
                              onPickCalendar: _pickCalendarRange,
                              onDownloadPdf: () =>
                                  _downloadSupplierPdf(supplier, rows),
                              onDownloadReport: () =>
                                  _downloadSupplierReport(supplier, rows),
                            ),
                            const SizedBox(height: 12),
                            if (widget.store.canDeleteIn(ErpModule.suppliers))
                              BulkSelectionBar(
                                selectedCount: _selectedRowIds.length,
                                totalCount: rows.length,
                                isUrdu: isUrdu,
                                onSelectAllToggle: () {
                                  setState(() {
                                    if (allSelected) {
                                      _selectedRowIds.clear();
                                    } else {
                                      _selectedRowIds
                                          .addAll(rows.map((e) => e.id));
                                    }
                                  });
                                },
                                onClear: () =>
                                    setState(() => _selectedRowIds.clear()),
                                onDeleteSelected: () =>
                                    _deleteSelectedRows(rows),
                              ),
                            if (rows.isEmpty)
                              EmptyStateView(
                                icon: Icons.receipt_long_outlined,
                                title: tr(isUrdu, 'No entries yet',
                                    'کوئی انٹری موجود نہیں'),
                                subtitle: tr(
                                    isUrdu,
                                    'Record a fuel tanker purchase or payment.',
                                    'تیل خریداری یا ادائیگی درج کریں۔'),
                              )
                            else
                              LayoutBuilder(
                                builder: (_, constraints) =>
                                    _buildSupplierTable(
                                  rows,
                                  allSelected,
                                  isUrdu,
                                  constraints.maxWidth,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupplierTable(
    List<LedgerHistoryRow> rows,
    bool allSelected,
    bool isUrdu,
    double availableWidth,
  ) {
    final erp = context.erp;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: availableWidth > 760 ? availableWidth : 760,
        ),
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 70,
          columnSpacing: 16,
          horizontalMargin: 10,
          columns: [
            DataColumn(
              label: Checkbox(
                value: allSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedRowIds.addAll(rows.map((e) => e.id));
                    } else {
                      _selectedRowIds.clear();
                    }
                  });
                },
              ),
            ),
            DataColumn(label: Text(tr(isUrdu, 'DATE / ID', 'تاریخ / نمبر'))),
            DataColumn(label: Text(tr(isUrdu, 'DESCRIPTION', 'تفصیل'))),
            DataColumn(
                label: Text(tr(isUrdu, 'PURCHASED (DR)', 'خریداری بل'))),
            DataColumn(label: Text(tr(isUrdu, 'PAID (CR)', 'ادا شدہ رقم'))),
            DataColumn(label: Text(tr(isUrdu, 'PAYABLE BAL', 'بقایا'))),
            DataColumn(label: Text(tr(isUrdu, 'ACTIONS', 'عمل'))),
          ],
          rows: rows.map((r) {
            final checked = _selectedRowIds.contains(r.id);
            return DataRow(
              selected: checked,
              cells: [
                DataCell(
                  Checkbox(
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedRowIds.add(r.id);
                        } else {
                          _selectedRowIds.remove(r.id);
                        }
                      });
                    },
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LtrText(formatDateShort(r.date),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: erp.textMain)),
                      LtrText(r.id,
                          style:
                              TextStyle(fontSize: 11, color: erp.textMuted)),
                    ],
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(isUrdu, r.titleEn, r.titleUr),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: erp.textMain),
                        ),
                        Text(
                          tr(isUrdu, r.detailEn, r.detailUr),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 11, color: erp.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(LtrText(
                  r.debit > 0 ? formatRs(r.debit) : '—',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: r.debit > 0 ? erp.textMain : erp.textMuted,
                  ),
                )),
                DataCell(LtrText(
                  r.credit > 0 ? formatRs(r.credit) : '—',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: r.credit > 0 ? erp.success : erp.textMuted,
                  ),
                )),
                DataCell(LtrText(
                  formatRs(r.runningBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: r.runningBalance > 0 ? erp.danger : erp.success,
                  ),
                )),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: tr(isUrdu, 'View Details', 'تفصیل دیکھیں'),
                        icon: Icon(Icons.visibility_outlined,
                            size: 18, color: erp.textMuted),
                        onPressed: () => showRecordDetailDialog(
                          context,
                          isUrdu: isUrdu,
                          title: tr(isUrdu, r.titleEn, r.titleUr),
                          recordId: r.id,
                          date: r.date,
                          statusLabel: r.kind.toUpperCase(),
                          statusColor:
                              r.kind == 'payment' ? erp.success : erp.primary,
                          fields: [
                            RecordDetailField(
                              label: tr(isUrdu, 'Description', 'تفصیل'),
                              value: tr(isUrdu, r.detailEn, r.detailUr),
                              isBold: true,
                            ),
                            RecordDetailField(
                              label:
                                  tr(isUrdu, 'Purchased (Debit)', 'خریداری بل'),
                              value:
                                  r.debit > 0 ? formatRs(r.debit) : '—',
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Paid (Credit)', 'ادا شدہ رقم'),
                              value:
                                  r.credit > 0 ? formatRs(r.credit) : '—',
                              valueColor: erp.success,
                            ),
                            RecordDetailField(
                              label:
                                  tr(isUrdu, 'Running Payable', 'بقایا بیلنس'),
                              value: formatRs(r.runningBalance),
                              valueColor: r.runningBalance > 0
                                  ? erp.danger
                                  : erp.success,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      if (widget.store.canUpdateIn(ErpModule.suppliers))
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr(isUrdu, 'Edit', 'ترمیم'),
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: erp.primary),
                          onPressed: () {
                            if (r.purchase != null) {
                              showPurchaseFormDialog(context, widget.store,
                                  existing: r.purchase);
                            } else if (r.payment != null) {
                              showLedgerPaymentDialog(
                                context,
                                widget.store,
                                partyType: 'supplier',
                                partyId: widget.supplierId,
                                existing: r.payment,
                              );
                            }
                          },
                        ),
                      if (widget.store.canDeleteIn(ErpModule.suppliers))
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr(isUrdu, 'Delete', 'حذف'),
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 18, color: erp.danger),
                          onPressed: () async {
                            final ok = await confirmDeleteDialog(context,
                                isUrdu: isUrdu, count: 1);
                            if (!ok || !mounted) return;
                            if (r.kind == 'purchase') {
                              widget.store.deleteFuelPurchases([r.id]);
                            } else {
                              widget.store.deleteLedgerPayments([r.id]);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SupplierCardGrid extends StatelessWidget {
  const _SupplierCardGrid({required this.cols, required this.cards});

  final int cols;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    if (cols == 1) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
        ],
      );
    }
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += cols) {
      final slice = cards.sublist(i, (i + cols).clamp(0, cards.length));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int j = 0; j < slice.length; j++) ...[
              if (j > 0) const SizedBox(width: 12),
              Expanded(child: slice[j]),
            ],
          ],
        ),
      );
      if (i + cols < cards.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}
