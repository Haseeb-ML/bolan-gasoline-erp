import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';

class CashBankScreen extends StatefulWidget {
  const CashBankScreen({super.key, required this.store});

  final ErpStore store;

  @override
  State<CashBankScreen> createState() => _CashBankScreenState();
}

class _CashBankScreenState extends State<CashBankScreen> {
  String _methodFilter = 'all'; // 'all' | 'Cash' | 'Bank Transfer'
  String _period = 'all';
  DateTimeRange? _customRange;

  List<CashBankEntry> get _filteredEntries {
    final q = widget.store.searchQuery;
    var list = widget.store.cashBankEntries;
    if (_methodFilter != 'all') {
      list = list.where((e) => e.method == _methodFilter).toList();
    }
    if (q.isNotEmpty) {
      list = list.where((e) {
        final text =
            '${e.id} ${e.method} ${e.sourceEn} ${e.sourceUr} ${e.detailEn} ${e.detailUr} ${e.note}'
                .toLowerCase();
        return text.contains(q);
      }).toList();
    }
    return filterByPeriod(
      items: list,
      getDate: (e) => e.date,
      period: _period,
      customRange: _customRange,
    );
  }

  Future<void> _downloadExcel(List<CashBankEntry> rows) async {
    final isUrdu = widget.store.isUrdu;
    final buf = StringBuffer();
    buf.writeln(
      'Entry ID,Date,Account,Flow,Source,Detail,Amount (Rs),Note',
    );
    for (final e in rows) {
      buf.writeln(
        '${e.id},${e.date.toIso8601String().split('T').first},${e.method},${e.isInflow ? 'IN (+)' : 'OUT (-)'},${e.sourceEn.replaceAll(',', ' ')},${e.detailEn.replaceAll(',', ' ')},${e.amount.round()},${e.note.replaceAll(',', ' ')}',
      );
    }
    await openExcelSheetViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_cash_bank_$_period.csv',
      sheetTitle: tr(
        isUrdu,
        'Cash & Bank Ledger — Excel Sheet View',
        'کیش اور بینک کھاتہ — ایکسل شیٹ ویو',
      ),
      csvContent: buf.toString(),
    );
  }

  Future<void> _downloadPdf(List<CashBankEntry> rows) async {
    final isUrdu = widget.store.isUrdu;
    final totalIn =
        rows.where((e) => e.isInflow).fold<double>(0, (s, e) => s + e.amount);
    final totalOut =
        rows.where((e) => !e.isInflow).fold<double>(0, (s, e) => s + e.amount);
    await openPdfReportViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_cash_bank_$_period.pdf',
      reportTitle: 'CASH & BANK ACCOUNT LEDGER REPORT',
      subtitle:
          'Account: ${_methodFilter == 'all' ? 'ALL (CASH + BANK)' : _methodFilter.toUpperCase()}  |  Period: ${_period.toUpperCase()}  |  Records: ${rows.length}',
      summaryItems: [
        'Total Inflow (+): Rs. ${totalIn.round()}',
        'Total Outflow (-): Rs. ${totalOut.round()}',
        'Cash Balance: Rs. ${widget.store.totalCashInHand.round()}',
        'Bank Balance: Rs. ${widget.store.totalBankBalance.round()}',
      ],
      headers: const [
        'ID',
        'DATE',
        'ACCOUNT',
        'FLOW',
        'SOURCE',
        'DETAIL',
        'AMOUNT RS',
      ],
      rows: rows
          .map((e) => [
                e.id,
                formatDateShort(e.date),
                e.method == 'Bank Transfer' ? 'BANK' : 'CASH',
                e.isInflow ? 'IN (+)' : 'OUT (-)',
                e.sourceEn,
                e.detailEn,
                'Rs.${e.amount.round()}',
              ])
          .toList(),
    );
  }

  Future<void> _showTransferDialog() async {
    final isUrdu = widget.store.isUrdu;
    final amountCtrl = TextEditingController(text: '50000');
    final noteCtrl = TextEditingController();
    String fromAccount = 'Cash';
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final erp = ctx.erp;
          final toAccount =
              fromAccount == 'Cash' ? 'Bank Transfer' : 'Cash';
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, color: erp.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr(isUrdu, 'Cash <-> Bank Transfer',
                                  'کیش اور بینک آپس میں ٹرانسفر'),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: erp.textMain,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(tr(isUrdu, 'Cash -> Bank (Deposit)',
                                'کیش سے بینک میں جمع')),
                            selected: fromAccount == 'Cash',
                            onSelected: (_) =>
                                setDlgState(() => fromAccount = 'Cash'),
                          ),
                          ChoiceChip(
                            label: Text(tr(isUrdu, 'Bank -> Cash (Withdraw)',
                                'بینک سے کیش نکالنا')),
                            selected: fromAccount == 'Bank Transfer',
                            onSelected: (_) => setDlgState(
                                () => fromAccount = 'Bank Transfer'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText:
                              tr(isUrdu, 'Amount (Rs.)', 'رقم (روپے)'),
                        ),
                        validator: (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          return (n == null || n <= 0)
                              ? tr(isUrdu, 'Enter valid amount',
                                  'درست رقم درج کریں')
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteCtrl,
                        decoration: InputDecoration(
                          labelText:
                              tr(isUrdu, 'Note (Optional)', 'نوٹ (اختیاری)'),
                          hintText: tr(isUrdu, 'e.g. Daily counter deposit',
                              'مثلاً کاؤنٹر کیش بینک میں جمع'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ErpDateEntryField(
                        isUrdu: isUrdu,
                        initialDate: selectedDate,
                        isEdit: false,
                        onChanged: (d) => selectedDate = d,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(tr(isUrdu, 'Cancel', 'بند کریں')),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: erp.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              widget.store.addCashBankTransfer(
                                fromAccount: fromAccount,
                                toAccount: toAccount,
                                amount: double.parse(amountCtrl.text.trim()),
                                note: noteCtrl.text.trim(),
                                date: selectedDate,
                              );
                              Navigator.of(ctx).pop();
                              showErpSnackBar(
                                context,
                                tr(isUrdu, 'Cash/Bank transfer saved!',
                                    'کیش/بینک ٹرانسفر محفوظ ہو گیا!'),
                              );
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(tr(isUrdu, 'Save Transfer', 'محفوظ کریں')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    final list = _filteredEntries;
    final cashBal = widget.store.totalCashInHand;
    final bankBal = widget.store.totalBankBalance;
    final totalBal = widget.store.totalLiquidFunds;
    final isMobile = MediaQuery.sizeOf(context).width < 640;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (_, constraints) {
            final cols = constraints.maxWidth >= 820 ? 3 : 1;
            final compact = constraints.maxWidth < 600;
            final cards = [
              KpiStatCard(
                compact: compact,
                icon: Icons.payments_rounded,
                iconBg: erp.success,
                pillText: tr(isUrdu, 'Cash Counter', 'نقد کیش'),
                pillBg: erp.successSoft,
                pillColor: erp.success,
                valueText: formatRs(cashBal),
                label: tr(isUrdu, 'Cash in Hand Balance',
                    'موجودہ نقد کیش بیلنس'),
              ),
              KpiStatCard(
                compact: compact,
                icon: Icons.account_balance_rounded,
                iconBg: erp.dieselColor,
                pillText: tr(isUrdu, 'Bank / Online', 'بینک اکاؤنٹ'),
                pillBg: erp.dieselSoft,
                pillColor: erp.dieselColor,
                valueText: formatRs(bankBal),
                label: tr(isUrdu, 'Bank Account Balance',
                    'موجودہ بینک بیلنس'),
              ),
              KpiStatCard(
                compact: compact,
                icon: Icons.account_balance_wallet_rounded,
                iconBg: erp.primary,
                pillText: tr(isUrdu, 'Cash + Bank', 'کل رقم'),
                pillBg: erp.primarySoft,
                pillColor: erp.primary,
                valueText: formatRs(totalBal),
                label: tr(isUrdu, 'Total Liquid Funds',
                    'مجموعی کیش اور بینک'),
              ),
            ];
            if (cols == 1) {
              return Column(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    cards[i],
                  ],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
                const SizedBox(width: 14),
                Expanded(child: cards[2]),
              ],
            );
          },
        ),
        SizedBox(height: isMobile ? 14 : 18),
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
                          'Cash & Bank Transactions Ledger',
                          'کیش اور بینک لین دین رجسٹر',
                        ),
                        style: TextStyle(
                          fontSize: isMobile ? 15.5 : 17,
                          fontWeight: FontWeight.w800,
                          color: erp.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr(
                          isUrdu,
                          'Walk-in Bank Transfers, Cash Sales, Khata Recoveries, Supplier Payments & Expenses.',
                          'واک ان بینک ٹرانسفر، کیش فروخت، کھاتہ وصولیاں، سپلائر ادائیگیاں اور اخراجات۔',
                        ),
                        style: TextStyle(fontSize: 12, color: erp.textMuted),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(tr(isUrdu, 'All', 'سب')),
                        selected: _methodFilter == 'all',
                        onSelected: (_) =>
                            setState(() => _methodFilter = 'all'),
                      ),
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(tr(isUrdu, 'Cash', 'نقد کیش')),
                        selected: _methodFilter == 'Cash',
                        onSelected: (_) =>
                            setState(() => _methodFilter = 'Cash'),
                      ),
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(tr(isUrdu, 'Bank', 'بینک')),
                        selected: _methodFilter == 'Bank Transfer',
                        onSelected: (_) =>
                            setState(() => _methodFilter = 'Bank Transfer'),
                      ),
                      if (widget.store.canCreateIn(ErpModule.cashBank))
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: erp.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: _showTransferDialog,
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: Text(
                            tr(isUrdu, 'Cash <-> Bank', 'کیش / بینک ٹرانسفر'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PeriodFilterBar(
                selectedPeriod: _period,
                customRange: _customRange,
                isUrdu: isUrdu,
                onSelectPeriod: (p) => setState(() => _period = p),
                onPickCalendar: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _customRange,
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      _customRange = picked;
                      _period = 'custom';
                    });
                  }
                },
                onDownloadPdf: () => _downloadPdf(list),
                onDownloadReport: () => _downloadExcel(list),
              ),
              const SizedBox(height: 14),
              if (list.isEmpty)
                EmptyStateView(
                  icon: Icons.account_balance_outlined,
                  title: tr(isUrdu, 'No Cash/Bank transactions found',
                      'کوئی کیش یا بینک ریکارڈ نہیں ملا'),
                  subtitle: tr(
                    isUrdu,
                    'Sales, recoveries, expenses and transfers appear here automatically.',
                    'فروخت، وصولیاں، اخراجات اور ٹرانسفر خود بخود یہاں آتے ہیں۔',
                  ),
                )
              else
                LayoutBuilder(
                  builder: (_, constraints) =>
                      _buildTable(list, constraints.maxWidth),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<CashBankEntry> list, double availableWidth) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: availableWidth > 760 ? availableWidth : 760,
        ),
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 68,
          columnSpacing: 16,
          horizontalMargin: 10,
          columns: [
            DataColumn(label: Text(tr(isUrdu, 'ID / DATE', 'نمبر / تاریخ'))),
            DataColumn(label: Text(tr(isUrdu, 'ACCOUNT', 'اکاؤنٹ'))),
            DataColumn(label: Text(tr(isUrdu, 'SOURCE', 'ذریعہ'))),
            DataColumn(label: Text(tr(isUrdu, 'DETAIL', 'تفصیل'))),
            DataColumn(label: Text(tr(isUrdu, 'AMOUNT', 'رقم'))),
            DataColumn(label: Text(tr(isUrdu, 'ACTIONS', 'عمل'))),
          ],
          rows: list.map((e) {
            final isBank = e.method == 'Bank Transfer';
            final isTransfer = e.id.startsWith('TRF-');
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LtrText(e.id,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: erp.textMain)),
                      LtrText(formatDateShort(e.date),
                          style:
                              TextStyle(fontSize: 11, color: erp.textMuted)),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBank ? erp.dieselSoft : erp.successSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isBank
                          ? tr(isUrdu, 'Bank', 'بینک')
                          : tr(isUrdu, 'Cash', 'کیش'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isBank ? erp.dieselColor : erp.success,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    tr(isUrdu, e.sourceEn, e.sourceUr),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: erp.textMain),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      tr(isUrdu, e.detailEn, e.detailUr),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: erp.textMuted),
                    ),
                  ),
                ),
                DataCell(
                  LtrText(
                    '${e.isInflow ? '+' : '-'} ${formatRs(e.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: e.isInflow ? erp.success : erp.danger,
                    ),
                  ),
                ),
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
                          title: tr(isUrdu, e.sourceEn, e.sourceUr),
                          recordId: e.id,
                          date: e.date,
                          statusLabel: e.isInflow ? 'INFLOW (+)' : 'OUTFLOW (-)',
                          statusColor: e.isInflow ? erp.success : erp.danger,
                          fields: [
                            RecordDetailField(
                              label: tr(isUrdu, 'Account', 'اکاؤنٹ'),
                              value: e.method,
                              isBold: true,
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Detail', 'تفصیل'),
                              value: tr(isUrdu, e.detailEn, e.detailUr),
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Amount', 'رقم'),
                              value: formatRs(e.amount),
                              valueColor:
                                  e.isInflow ? erp.success : erp.danger,
                              isBold: true,
                            ),
                            if (e.note.isNotEmpty)
                              RecordDetailField(
                                label: tr(isUrdu, 'Note', 'نوٹ'),
                                value: e.note,
                              ),
                          ],
                        ),
                      ),
                      if (isTransfer &&
                          widget.store.canDeleteIn(ErpModule.cashBank))
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr(isUrdu, 'Delete Transfer', 'حذف کریں'),
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 18, color: erp.danger),
                          onPressed: () async {
                            final ok = await confirmDeleteDialog(context,
                                isUrdu: isUrdu, count: 1);
                            if (!ok || !mounted) return;
                            widget.store.deleteCashBankTransfers([e.id]);
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
