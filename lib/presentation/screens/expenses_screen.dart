import 'package:flutter/material.dart';

import '../../core/storage/file_transfer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_generator.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';
import '../widgets/party_and_expense_dialogs.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.store});

  final ErpStore store;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final Set<String> _selectedIds = {};
  String _period = 'all';
  DateTimeRange? _customRange;

  List<PumpExpense> get _filteredExpenses {
    final q = widget.store.searchQuery;
    final base = q.isEmpty
        ? widget.store.expenses
        : widget.store.expenses.where((e) {
            final text =
                '${e.id} ${e.categoryEn} ${e.categoryUr} ${e.titleEn} ${e.titleUr}'
                    .toLowerCase();
            return text.contains(q);
          }).toList();
    return filterByPeriod(
      items: base,
      getDate: (e) => e.date,
      period: _period,
      customRange: _customRange,
    );
  }

  Future<void> _downloadExpensesReport(List<PumpExpense> rows) async {
    final isUrdu = widget.store.isUrdu;
    final buf = StringBuffer();
    buf.writeln('Expense ID,Date,Category,Description,Amount (Rs)');
    for (final e in rows) {
      buf.writeln(
        '${e.id},${e.date.toIso8601String().split('T').first},${e.categoryEn.replaceAll(',', ' ')},${e.titleEn.replaceAll(',', ' ')},${e.amount.round()}',
      );
    }
    final csv = buf.toString();
    await openExcelSheetViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_expenses_$_period.csv',
      sheetTitle: tr(
        isUrdu,
        'Pump Expenses & Salaries — Excel Sheet View',
        'پمپ اخراجات اور تنخواہیں — ایکسل شیٹ ویو',
      ),
      csvContent: csv,
    );
  }

  Future<void> _downloadExpensesPdf(List<PumpExpense> rows) async {
    final isUrdu = widget.store.isUrdu;
    final totalAmt = rows.fold<double>(0, (s, e) => s + e.amount);
    final pdfBytes = ErpPdfGenerator.buildTableReportPdf(
      reportTitle: 'PUMP EXPENSES & STAFF SALARIES REPORT',
      subtitle:
          'Period: ${_period.toUpperCase()}  |  Records: ${rows.length}  |  Generated: ${formatDateShort(DateTime.now())}',
      summaryItems: [
        'Total Entries: ${rows.length}',
        'Total Expenses Amount: Rs. ${totalAmt.round()}',
      ],
      headers: const [
        'EXP ID',
        'DATE',
        'CATEGORY',
        'DESCRIPTION',
        'AMOUNT RS',
      ],
      rows: rows
          .map((e) => [
                e.id,
                formatDateShort(e.date),
                e.categoryEn,
                e.titleEn,
                'Rs. ${e.amount.round()}',
              ])
          .toList(),
    );
    await downloadBinaryFile(
      filename: 'bolan_expenses_$_period.pdf',
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );
    if (!mounted) return;
    showErpSnackBar(
      context,
      tr(isUrdu, 'Expenses PDF report downloaded (.pdf)!',
          'اخراجات پی ڈی ایف رپورٹ ڈاؤن لوڈ ہو گئی (.pdf)!'),
    );
  }

  Future<void> _deleteSelected(List<PumpExpense> list) async {
    final valid =
        _selectedIds.where((id) => list.any((e) => e.id == id)).toList();
    if (valid.isEmpty) return;
    final ok = await confirmDeleteDialog(context,
        isUrdu: widget.store.isUrdu, count: valid.length);
    if (!ok || !mounted) return;
    widget.store.deleteExpenses(valid);
    setState(() => _selectedIds.clear());
    showErpSnackBar(
      context,
      tr(widget.store.isUrdu, '${valid.length} expense(s) deleted.',
          '${valid.length} اخراجات حذف کر دیے گئے۔'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    final list = _filteredExpenses;
    _selectedIds.removeWhere((id) => !list.any((e) => e.id == id));
    final allSelected = list.isNotEmpty && _selectedIds.length == list.length;

    return Container(
      padding: const EdgeInsets.all(20),
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
                    tr(isUrdu, 'Pump Expenses (Includes Staff Salaries)',
                        'پمپ کے اخراجات (لڑکوں کی تنخواہیں اور دیگر خرچ)'),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: erp.textMain),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(isUrdu,
                        'Track staff salaries, generator/power bills & daily pump expenses.',
                        'پمپ پر کام کرنے والے لڑکوں کی تنخواہ اور روزمرہ اخراجات کا ریکارڈ۔'),
                    style: TextStyle(fontSize: 12, color: erp.textMuted),
                  ),
                ],
              ),
              if (widget.store.canCreateIn(ErpModule.expenses))
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: erp.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: () => showExpenseFormDialog(context, widget.store),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    tr(isUrdu, 'Add Expense / Salary', 'نیا خرچہ / تنخواہ'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
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
            onDownloadPdf: () => _downloadExpensesPdf(list),
            onDownloadReport: () => _downloadExpensesReport(list),
          ),
          const SizedBox(height: 14),
          if (widget.store.canDeleteIn(ErpModule.expenses))
            BulkSelectionBar(
              selectedCount: _selectedIds.length,
              totalCount: list.length,
              isUrdu: isUrdu,
              onSelectAllToggle: () {
                setState(() {
                  if (allSelected) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(list.map((e) => e.id));
                  }
                });
              },
              onClear: () => setState(() => _selectedIds.clear()),
              onDeleteSelected: () => _deleteSelected(list),
            ),
          if (list.isEmpty)
            EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: tr(isUrdu, 'No expenses recorded',
                  'کوئی خرچہ ریکارڈ نہیں ملا'),
              subtitle: tr(isUrdu, 'Add staff salary or pump expense.',
                  'تنخواہ یا پمپ کا خرچہ شامل کریں۔'),
            )
          else
            LayoutBuilder(
              builder: (_, constraints) =>
                  _buildDesktopTable(list, allSelected, constraints.maxWidth),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    List<PumpExpense> list,
    bool allSelected,
    double availableWidth,
  ) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: availableWidth > 720 ? availableWidth : 720,
        ),
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 68,
          columnSpacing: 18,
          horizontalMargin: 10,
          columns: [
            DataColumn(
              label: Checkbox(
                value: allSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedIds.addAll(list.map((e) => e.id));
                    } else {
                      _selectedIds.clear();
                    }
                  });
                },
              ),
            ),
            DataColumn(label: Text(tr(isUrdu, 'DATE', 'تاریخ'))),
            DataColumn(label: Text(tr(isUrdu, 'CATEGORY', 'مد / قسم'))),
            DataColumn(label: Text(tr(isUrdu, 'DESCRIPTION', 'تفصیل'))),
            DataColumn(label: Text(tr(isUrdu, 'AMOUNT', 'رقم'))),
            DataColumn(label: Text(tr(isUrdu, 'ACTIONS', 'عمل'))),
          ],
          rows: list.map((e) {
            final checked = _selectedIds.contains(e.id);
            return DataRow(
              selected: checked,
              cells: [
                DataCell(
                  Checkbox(
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.add(e.id);
                        } else {
                          _selectedIds.remove(e.id);
                        }
                      });
                    },
                  ),
                ),
                DataCell(LtrText(formatDateShort(e.date),
                    style: TextStyle(fontSize: 12, color: erp.textMuted))),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: erp.dangerSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      e.category(isUrdu),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: erp.danger),
                    ),
                  ),
                ),
                DataCell(Text(e.title(isUrdu),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: erp.textMain))),
                DataCell(LtrText(formatRs(e.amount),
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: erp.danger))),
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
                          title: tr(isUrdu, 'Pump Expense / Salary Voucher',
                              'خرچہ / تنخواہ واؤچر'),
                          recordId: e.id,
                          date: e.date,
                          statusLabel: e.category(isUrdu),
                          statusColor: erp.danger,
                          fields: [
                            RecordDetailField(
                              label: tr(isUrdu, 'Expense Category', 'مد / قسم'),
                              value: e.category(isUrdu),
                              isBold: true,
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Description', 'تفصیل'),
                              value: e.title(isUrdu),
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Expense Amount', 'خرچ شدہ رقم'),
                              value: formatRs(e.amount),
                              valueColor: erp.danger,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      if (widget.store.canUpdateIn(ErpModule.expenses))
                        IconButton(
                          tooltip: tr(isUrdu, 'Edit', 'ترمیم'),
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: erp.primary),
                          onPressed: () => showExpenseFormDialog(
                              context, widget.store,
                              existing: e),
                        ),
                      if (widget.store.canDeleteIn(ErpModule.expenses))
                        IconButton(
                          tooltip: tr(isUrdu, 'Delete', 'حذف'),
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 18, color: erp.danger),
                          onPressed: () async {
                            final ok = await confirmDeleteDialog(context,
                                isUrdu: isUrdu, count: 1);
                            if (!ok || !mounted) return;
                            widget.store.deleteExpenses([e.id]);
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
