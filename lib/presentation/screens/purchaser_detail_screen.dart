import 'package:flutter/material.dart';

import '../../core/storage/file_transfer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_generator.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';
import '../widgets/party_and_expense_dialogs.dart';
import '../widgets/sale_form_dialog.dart';

Future<void> openPurchaserDetail(
  BuildContext context,
  ErpStore store,
  String purchaserId,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PurchaserDetailScreen(
        store: store,
        purchaserId: purchaserId,
      ),
    ),
  );
}

class PurchaserDetailScreen extends StatefulWidget {
  const PurchaserDetailScreen({
    super.key,
    required this.store,
    required this.purchaserId,
  });

  final ErpStore store;
  final String purchaserId;

  @override
  State<PurchaserDetailScreen> createState() => _PurchaserDetailScreenState();
}

class _PurchaserDetailScreenState extends State<PurchaserDetailScreen> {
  final Set<String> _selectedRowIds = {};
  String _filterKind = 'all'; // 'all' | 'sale' | 'payment'
  String _periodFilter = 'all'; // 'all' | 'week' | 'month' | 'year' | 'custom'
  DateTimeRange? _customRange;

  List<LedgerHistoryRow> _applyPeriodFilter(List<LedgerHistoryRow> input) {
    return filterByPeriod(
      items: input,
      getDate: (r) => r.date,
      period: _periodFilter,
      customRange: _customRange,
    );
  }

  String _periodLabel(bool isUrdu) {
    switch (_periodFilter) {
      case 'today':
        return tr(isUrdu, 'Today', 'آج');
      case 'week':
        return tr(isUrdu, 'Weekly (Last 7 Days)', 'ہفتہ وار (7 دن)');
      case 'month':
        return tr(isUrdu, 'Monthly', 'ماہانہ');
      case 'year':
        return tr(isUrdu, 'Yearly', 'سالانہ');
      case 'custom':
        if (_customRange != null) {
          return '${formatDateShort(_customRange!.start)} - ${formatDateShort(_customRange!.end)}';
        }
        return tr(isUrdu, 'Custom Range', 'منتخب تاریخ');
      default:
        return tr(isUrdu, 'All History', 'مکمل ہسٹری');
    }
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

  Future<void> _downloadKhataReport(
    Purchaser purchaser,
    List<LedgerHistoryRow> filteredRows,
  ) async {
    final isUrdu = widget.store.isUrdu;
    final csv = widget.store.exportPartyLedgerCsv(
      partyName: purchaser.nameEn,
      partyPhone: purchaser.phone,
      periodLabel: _periodLabel(false),
      rows: filteredRows,
    );
    final safeId = purchaser.id.toLowerCase();
    await openExcelSheetViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_khata_${safeId}_$_periodFilter.csv',
      sheetTitle: tr(
        isUrdu,
        '${purchaser.nameEn} Khata Statement — Excel Sheet View',
        '${purchaser.nameUr} کھاتہ اسٹیٹمنٹ — ایکسل شیٹ ویو',
      ),
      csvContent: csv,
    );
  }

  Future<void> _downloadKhataPdf(
    Purchaser purchaser,
    List<LedgerHistoryRow> filteredRows,
  ) async {
    final isUrdu = widget.store.isUrdu;
    final summary = widget.store.purchaserSummary(purchaser.id);
    final isAll = _periodFilter == 'all' && _filterKind == 'all';
    final totalDebit = isAll
        ? summary.totalBilled
        : filteredRows.fold<double>(0, (s, r) => s + r.debit);
    final totalCredit = isAll
        ? summary.totalPaid
        : filteredRows.fold<double>(0, (s, r) => s + r.credit);
    final totalLiters = isAll
        ? summary.totalLiters
        : filteredRows.fold<double>(0, (s, r) => s + (r.liters ?? 0));
    final latestBal = isAll
        ? summary.balance
        : (filteredRows.isNotEmpty ? filteredRows.first.runningBalance : 0.0);

    final pdfRows = filteredRows
        .map((r) => [
              r.id,
              formatDateShort(r.date),
              r.kind.toUpperCase(),
              '${r.titleEn} (${r.detailEn})',
              r.debit > 0 ? 'Rs.${r.debit.round()}' : '-',
              r.credit > 0 ? 'Rs.${r.credit.round()}' : '-',
              'Rs.${r.runningBalance.round()}',
            ])
        .toList();
    if (isAll && (purchaser.openingBilled > 0 || purchaser.openingPaid > 0)) {
      final openBal =
          (purchaser.openingBilled - purchaser.openingPaid).clamp(0, double.infinity);
      pdfRows.add([
        'OPEN',
        '-',
        'OPENING',
        'Opening Balance Brought Forward',
        purchaser.openingBilled > 0
            ? 'Rs.${purchaser.openingBilled.round()}'
            : '-',
        purchaser.openingPaid > 0 ? 'Rs.${purchaser.openingPaid.round()}' : '-',
        'Rs.${openBal.round()}',
      ]);
    }

    final pdfBytes = ErpPdfGenerator.buildTableReportPdf(
      reportTitle: 'PURCHASER PERSONAL KHATA STATEMENT - ${purchaser.nameEn}',
      subtitle:
          'Account ID: ${purchaser.id}  |  Phone: ${purchaser.phone}  |  Period: ${_periodLabel(false)}',
      summaryItems: [
        'Total Liters: ${totalLiters.round()} L',
        'Total Billed: Rs. ${totalDebit.round()}',
        'Total Paid: Rs. ${totalCredit.round()}',
        'Balance Due: Rs. ${latestBal.round()}',
      ],
      headers: const [
        'ID',
        'DATE',
        'TYPE',
        'DESCRIPTION',
        'BILLED (DR)',
        'PAID (CR)',
        'BALANCE',
      ],
      rows: pdfRows,
    );
    final safeId = purchaser.id.toLowerCase();
    await downloadBinaryFile(
      filename: 'bolan_khata_${safeId}_$_periodFilter.pdf',
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );
    if (!mounted) return;
    showErpSnackBar(
      context,
      tr(isUrdu, 'Khata PDF report downloaded (.pdf)!',
          'کھاتہ پی ڈی ایف رپورٹ ڈاؤن لوڈ ہو گئی (.pdf)!'),
    );
  }

  Future<void> _deleteSelectedRows(List<LedgerHistoryRow> rows) async {
    final chosen =
        rows.where((r) => _selectedRowIds.contains(r.id)).toList();
    if (chosen.isEmpty) return;
    final ok = await confirmDeleteDialog(
      context,
      isUrdu: widget.store.isUrdu,
      count: chosen.length,
    );
    if (!ok || !mounted) return;

    final saleIds = chosen
        .where((r) => r.kind == 'sale')
        .map((r) => r.id)
        .toList();
    final payIds = chosen
        .where((r) => r.kind == 'payment')
        .map((r) => r.id)
        .toList();
    if (saleIds.isNotEmpty) widget.store.deleteFuelSales(saleIds);
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
        final purchaser = widget.store.findPurchaser(widget.purchaserId);

        if (purchaser == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tr(isUrdu, 'Account', 'اکاؤنٹ'))),
            body: Center(
              child: Text(tr(isUrdu, 'Purchaser not found', 'پرچیزر نہیں ملا')),
            ),
          );
        }

        final summary = widget.store.purchaserSummary(purchaser.id);
        final allRows = widget.store.purchaserLedgerHistory(purchaser.id);
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
                          purchaser.displayName(isUrdu),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: erp.textMain,
                          ),
                        ),
                        Text(
                          tr(
                            isUrdu,
                            'Personal Ledger Account & Complete History',
                            'ذاتی کھاتہ اکاؤنٹ اور مکمل روزانہ ہسٹری',
                          ),
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
                if (widget.store.canEdit)
                  IconButton(
                    tooltip: tr(isUrdu, 'Edit Purchaser Info & Rates',
                        'پرچیزر معلومات اور ریٹ ترمیم'),
                    onPressed: () => showPurchaserFormDialog(
                      context,
                      widget.store,
                      existing: purchaser,
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
                              spacing: 16,
                              runSpacing: 12,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            purchaser.id,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: erp.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        LtrText(
                                          purchaser.phone,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: erp.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _RateChip(
                                          label: tr(isUrdu, 'Petrol Rate',
                                              'پٹرول ریٹ'),
                                          value:
                                              'Rs. ${purchaser.petrolRate.round()}/L',
                                          color: erp.petrolColor,
                                          bg: erp.petrolSoft,
                                        ),
                                        _RateChip(
                                          label: tr(isUrdu, 'Diesel Rate',
                                              'ڈیزل ریٹ'),
                                          value:
                                              'Rs. ${purchaser.dieselRate.round()}/L',
                                          color: erp.dieselColor,
                                          bg: erp.dieselSoft,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (!isMobile)
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: erp.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999)),
                                        ),
                                        onPressed: () => showSaleFormDialog(
                                          context,
                                          widget.store,
                                          lockedPurchaserId: purchaser.id,
                                        ),
                                        icon: const Icon(
                                            Icons.local_gas_station_rounded,
                                            size: 18),
                                        label: Text(
                                          tr(isUrdu, '+ New Fuel Sale',
                                              '+ نیا تیل فروخت'),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: erp.success,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999)),
                                        ),
                                        onPressed: () =>
                                            showLedgerPaymentDialog(
                                          context,
                                          widget.store,
                                          partyType: 'purchaser',
                                          partyId: purchaser.id,
                                        ),
                                        icon: const Icon(
                                            Icons.payments_rounded,
                                            size: 18),
                                        label: Text(
                                          tr(isUrdu, 'Receive Payment',
                                              'رقم وصول کریں'),
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
                                        backgroundColor: erp.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999)),
                                      ),
                                      onPressed: () => showSaleFormDialog(
                                        context,
                                        widget.store,
                                        lockedPurchaserId: purchaser.id,
                                      ),
                                      icon: const Icon(
                                          Icons.local_gas_station_rounded,
                                          size: 16),
                                      label: Text(
                                        tr(isUrdu, '+ New Sale',
                                            '+ نیا تیل فروخت'),
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
                                        backgroundColor: erp.success,
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
                                        partyType: 'purchaser',
                                        partyId: purchaser.id,
                                      ),
                                      icon: const Icon(Icons.payments_rounded,
                                          size: 16),
                                      label: Text(
                                        tr(isUrdu, 'Receive Cash',
                                            'رقم وصول کریں'),
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
                          final dispBilled = isFiltered
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
                              icon: Icons.receipt_long_rounded,
                              iconBg: erp.primary,
                              pillText:
                                  '$dispCount ${tr(isUrdu, 'Entries', 'انٹریز')}',
                              pillBg: erp.primarySoft,
                              pillColor: erp.primary,
                              valueText: formatRs(dispBilled),
                              label: tr(isUrdu, 'Total Fuel Billed',
                                  'کل خریداری بل'),
                            ),
                            KpiStatCard(
                              compact: compactCard,
                              icon: Icons.check_circle_rounded,
                              iconBg: erp.success,
                              pillText: tr(isUrdu, 'Received', 'وصول شدہ'),
                              pillBg: erp.successSoft,
                              pillColor: erp.success,
                              valueText: formatRs(dispPaid),
                              label: tr(isUrdu, 'Total Paid Amount',
                                  'کل وصول شدہ رقم'),
                            ),
                            KpiStatCard(
                              compact: compactCard,
                              icon: Icons.account_balance_wallet_rounded,
                              iconBg: erp.danger,
                              pillText: tr(isUrdu, 'Balance Due', 'بقایا'),
                              pillBg: erp.dangerSoft,
                              pillColor: erp.danger,
                              valueText: formatRs(summary.balance),
                              label: tr(isUrdu, 'Remaining Balance Receivable',
                                  'باقی لینے والی رقم'),
                            ),
                            KpiStatCard(
                              compact: compactCard,
                              icon: Icons.local_gas_station_rounded,
                              iconBg: erp.dieselColor,
                              pillText: tr(isUrdu, 'Fuel Volume', 'مجموعی تیل'),
                              pillBg: erp.dieselSoft,
                              pillColor: erp.dieselColor,
                              valueText: formatLiters(dispLiters),
                              label: tr(isUrdu, 'Total Liters Purchased',
                                  'کل خریدا گیا تیل (لیٹر)'),
                            ),
                          ];
                          return _ResponsiveCardGrid(cols: cols, cards: cards);
                        },
                      ),
                      SizedBox(height: isMobile ? 14 : 18),

                      // Complete Ledger History Table
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
                                      tr(
                                        isUrdu,
                                        'Complete Account History / Ledger Statement',
                                        'مکمل کھاتہ ہسٹری / اکاؤنٹ اسٹیٹمنٹ',
                                      ),
                                      style: TextStyle(
                                        fontSize: isMobile ? 15 : 16,
                                        fontWeight: FontWeight.w800,
                                        color: erp.textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr(
                                        isUrdu,
                                        'Every fuel purchase, rate used, cash paid, and running balance for ${purchaser.nameEn}.',
                                        '${purchaser.nameUr} کی ہر تیل خریداری، لگایا گیا ریٹ، وصولی اور بقایا بیلنس۔',
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
                                      label: Text(
                                          tr(isUrdu, 'Fuel Sales', 'تیل بل')),
                                      selected: _filterKind == 'sale',
                                      onSelected: (_) =>
                                          setState(() => _filterKind = 'sale'),
                                    ),
                                    ChoiceChip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(
                                          tr(isUrdu, 'Payments', 'وصولیاں')),
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
                                  _downloadKhataPdf(purchaser, rows),
                              onDownloadReport: () =>
                                  _downloadKhataReport(purchaser, rows),
                            ),
                            const SizedBox(height: 14),
                            if (widget.store.canDelete)
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
                                title: tr(isUrdu, 'No ledger history yet',
                                    'ابھی کوئی ہسٹری موجود نہیں'),
                                subtitle: tr(
                                  isUrdu,
                                  'Add a fuel sale or receive a payment for this purchaser.',
                                  'اس پرچیزر کے لیے نیا تیل بل یا رقم وصولی درج کریں۔',
                                ),
                              )
                            else
                              LayoutBuilder(
                                builder: (_, constraints) =>
                                    _buildDesktopHistory(
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

  Widget _buildDesktopHistory(
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
            DataColumn(label: Text(tr(isUrdu, 'BILLED (DR)', 'بل رقم'))),
            DataColumn(label: Text(tr(isUrdu, 'PAID (CR)', 'وصول رقم'))),
            DataColumn(label: Text(tr(isUrdu, 'BALANCE', 'بقایا'))),
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
                              fontWeight: FontWeight.w700, color: erp.textMain),
                        ),
                        Text(
                          tr(isUrdu, r.detailEn, r.detailUr),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: erp.textMuted),
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
                    color:
                        r.runningBalance > 0 ? erp.danger : erp.success,
                  ),
                )),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
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
                              label: tr(isUrdu, 'Billed (Debit)', 'بل رقم'),
                              value: r.debit > 0 ? formatRs(r.debit) : '—',
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Paid (Credit)', 'وصول رقم'),
                              value: r.credit > 0 ? formatRs(r.credit) : '—',
                              valueColor: erp.success,
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Running Balance', 'بقایا بیلنس'),
                              value: formatRs(r.runningBalance),
                              valueColor: r.runningBalance > 0
                                  ? erp.danger
                                  : erp.success,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      if (widget.store.canEdit)
                        IconButton(
                          tooltip: tr(isUrdu, 'Edit', 'ترمیم'),
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: erp.primary),
                          onPressed: () {
                            if (r.sale != null) {
                              showSaleFormDialog(context, widget.store,
                                  existing: r.sale);
                            } else if (r.payment != null) {
                              showLedgerPaymentDialog(
                                context,
                                widget.store,
                                partyType: 'purchaser',
                                partyId: widget.purchaserId,
                                existing: r.payment,
                              );
                            }
                          },
                        ),
                      if (widget.store.canDelete)
                        IconButton(
                          tooltip: tr(isUrdu, 'Delete', 'حذف'),
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 18, color: erp.danger),
                          onPressed: () async {
                            final ok = await confirmDeleteDialog(context,
                                isUrdu: isUrdu, count: 1);
                            if (!ok || !mounted) return;
                            if (r.kind == 'sale') {
                              widget.store.deleteFuelSales([r.id]);
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

class _RateChip extends StatelessWidget {
  const _RateChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          LtrText(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({required this.cols, required this.cards});

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
