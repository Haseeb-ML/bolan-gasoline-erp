import 'package:flutter/material.dart';

import '../../core/storage/file_transfer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_generator.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';
import '../widgets/sale_form_dialog.dart';
import 'purchaser_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key, required this.store});

  final ErpStore store;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final Set<String> _selectedIds = {};
  String _period = 'all';
  DateTimeRange? _customRange;

  List<FuelSale> get _filteredSales {
    final q = widget.store.searchQuery;
    final base = q.isEmpty
        ? widget.store.sales
        : widget.store.sales.where((s) {
            final p = widget.store.findPurchaser(s.purchaserId);
            final text =
                '${s.id} ${s.fuel.key} ${p?.nameEn ?? ''} ${p?.nameUr ?? ''} ${s.note}'
                    .toLowerCase();
            return text.contains(q);
          }).toList();
    return filterByPeriod(
      items: base,
      getDate: (s) => s.date,
      period: _period,
      customRange: _customRange,
    );
  }

  Future<void> _downloadSalesReport(List<FuelSale> rows) async {
    final isUrdu = widget.store.isUrdu;
    final buf = StringBuffer();
    buf.writeln('Bill ID,Date,Purchaser,Fuel,Liters,Rate (Rs),Total Bill (Rs),Paid (Rs),Due (Rs),Note');
    for (final s in rows) {
      final pName =
          (widget.store.findPurchaser(s.purchaserId)?.nameEn ?? s.purchaserId)
              .replaceAll(',', ' ');
      buf.writeln(
        '${s.id},${s.date.toIso8601String().split('T').first},$pName,${s.fuel.key},${s.liters.round()},${s.rateUsed.round()},${s.totalAmount.round()},${s.paidNow.round()},${s.dueAmount.round()},${s.note.replaceAll(',', ' ')}',
      );
    }
    final csv = buf.toString();
    await openExcelSheetViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_sales_$_period.csv',
      sheetTitle: tr(
        isUrdu,
        'Fuel Sales Register — Excel Sheet View',
        'تیل فروخت رجسٹر — ایکسل شیٹ ویو',
      ),
      csvContent: csv,
    );
  }

  Future<void> _downloadSalesPdf(List<FuelSale> rows) async {
    final isUrdu = widget.store.isUrdu;
    final totalLiters = rows.fold<double>(0, (s, e) => s + e.liters);
    final totalBill = rows.fold<double>(0, (s, e) => s + e.totalAmount);
    final totalPaid = rows.fold<double>(0, (s, e) => s + e.paidNow);
    final pdfBytes = ErpPdfGenerator.buildTableReportPdf(
      reportTitle: 'FUEL SALES REGISTER REPORT',
      subtitle:
          'Period: ${_period.toUpperCase()}  |  Records: ${rows.length}  |  Generated: ${formatDateShort(DateTime.now())}',
      summaryItems: [
        'Total Volume: ${totalLiters.round()} L',
        'Total Billed: Rs. ${totalBill.round()}',
        'Total Paid: Rs. ${totalPaid.round()}',
        'Balance Due: Rs. ${(totalBill - totalPaid).round()}',
      ],
      headers: const [
        'BILL ID',
        'DATE',
        'PURCHASER',
        'FUEL',
        'LITERS',
        'RATE',
        'TOTAL RS',
        'PAID RS',
      ],
      rows: rows.map((s) {
        final pName =
            widget.store.findPurchaser(s.purchaserId)?.nameEn ?? s.purchaserId;
        return [
          s.id,
          formatDateShort(s.date),
          pName,
          s.fuel.key.toUpperCase(),
          '${s.liters.round()} L',
          'Rs.${s.rateUsed.round()}',
          'Rs.${s.totalAmount.round()}',
          'Rs.${s.paidNow.round()}',
        ];
      }).toList(),
    );
    await downloadBinaryFile(
      filename: 'bolan_sales_$_period.pdf',
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );
    if (!mounted) return;
    showErpSnackBar(
      context,
      tr(isUrdu, 'Sales PDF report downloaded (.pdf)!',
          'فروخت پی ڈی ایف رپورٹ ڈاؤن لوڈ ہو گئی (.pdf)!'),
    );
  }

  Future<void> _deleteSelected(List<FuelSale> currentList) async {
    final valid =
        _selectedIds.where((id) => currentList.any((s) => s.id == id)).toList();
    if (valid.isEmpty) return;
    final confirmed = await confirmDeleteDialog(
      context,
      isUrdu: widget.store.isUrdu,
      count: valid.length,
    );
    if (!confirmed || !mounted) return;
    widget.store.deleteFuelSales(valid);
    setState(() => _selectedIds.clear());
    showErpSnackBar(
      context,
      tr(widget.store.isUrdu, '${valid.length} sale(s) deleted & stock restored.',
          '${valid.length} فروخت ریکارڈ حذف کر دیے گئے اور اسٹاک بحال ہو گیا۔'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    final list = _filteredSales;
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
                    tr(isUrdu,
                        'Fuel Sales Register (Cash & Per-Purchaser Rate)',
                        'تیل فروخت رجسٹر (نقد کیش اور ہر پرچیزر کا الگ ریٹ)'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: erp.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(
                      isUrdu,
                      'Select checkboxes for bulk delete, or edit/delete any bill individually.',
                      'متعدد بل حذف کرنے کے لیے چیک باکس منتخب کریں، یا کسی بھی بل میں ترمیم/حذف کریں۔',
                    ),
                    style: TextStyle(fontSize: 12, color: erp.textMuted),
                  ),
                ],
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
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    tr(isUrdu, 'New Fuel Sale', 'نیا تیل فروخت بل'),
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
            onDownloadPdf: () => _downloadSalesPdf(list),
            onDownloadReport: () => _downloadSalesReport(list),
          ),
          const SizedBox(height: 14),
          if (widget.store.canDeleteIn(ErpModule.sales))
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
              icon: Icons.local_gas_station_outlined,
              title: tr(isUrdu, 'No sales records found',
                  'کوئی فروخت ریکارڈ نہیں ملا'),
              subtitle: tr(isUrdu, 'Add a new fuel sale or clear your search.',
                  'نیا تیل فروخت بل شامل کریں یا تلاش صاف کریں۔'),
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
    List<FuelSale> list,
    bool allSelected,
    double availableWidth,
  ) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: availableWidth > 780 ? availableWidth : 780,
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
            DataColumn(label: Text(tr(isUrdu, 'ID / DATE', 'نمبر / تاریخ'))),
            DataColumn(
                label: Text(tr(isUrdu, 'PURCHASER / CASH', 'پرچیزر / کیش'))),
            DataColumn(label: Text(tr(isUrdu, 'UNIT', 'یونٹ'))),
            DataColumn(label: Text(tr(isUrdu, 'LITERS', 'لیٹر'))),
            DataColumn(label: Text(tr(isUrdu, 'RATE', 'ریٹ'))),
            DataColumn(label: Text(tr(isUrdu, 'TOTAL', 'کل بل'))),
            DataColumn(label: Text(tr(isUrdu, 'PAID', 'وصول'))),
            DataColumn(label: Text(tr(isUrdu, 'ACTIONS', 'عمل'))),
          ],
          rows: list.map((s) {
            final p = widget.store.findPurchaser(s.purchaserId);
            final checked = _selectedIds.contains(s.id);
            return DataRow(
              selected: checked,
              cells: [
                DataCell(
                  Checkbox(
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.add(s.id);
                        } else {
                          _selectedIds.remove(s.id);
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
                      LtrText(s.id,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: erp.textMain)),
                      LtrText(formatDateShort(s.date),
                          style:
                              TextStyle(fontSize: 11, color: erp.textMuted)),
                    ],
                  ),
                ),
                DataCell(
                  InkWell(
                    onTap: (p != null && !p.isCashCounter)
                        ? () => openPurchaserDetail(context, widget.store, p.id)
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p?.displayName(isUrdu) ?? s.purchaserId,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: (p != null && !p.isCashCounter)
                                ? erp.primary
                                : erp.textMain,
                          ),
                        ),
                        if (s.note.isNotEmpty)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              s.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(fontSize: 11, color: erp.textMuted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                DataCell(FuelBadge(fuel: s.fuel, isUrdu: isUrdu)),
                DataCell(LtrText(formatLiters(s.liters),
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: erp.textMain))),
                DataCell(LtrText('Rs. ${s.rateUsed.round()}/L',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: erp.success))),
                DataCell(LtrText(formatRs(s.totalAmount),
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: erp.textMain))),
                DataCell(LtrText(formatRs(s.paidNow),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: erp.success))),
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
                          title: tr(isUrdu, 'Fuel Sale Bill Receipt',
                              'تیل فروخت بل رسید'),
                          recordId: s.id,
                          date: s.date,
                          statusLabel: s.dueAmount <= 0
                              ? tr(isUrdu, 'PAID IN FULL', 'مکمل وصول')
                              : tr(isUrdu, 'BALANCE DUE', 'بقایا باقی'),
                          statusColor:
                              s.dueAmount <= 0 ? erp.success : erp.danger,
                          fields: [
                            RecordDetailField(
                              label: tr(isUrdu, 'Purchaser / Account',
                                  'پرچیزر / کسٹمر'),
                              value: p?.displayName(isUrdu) ?? s.purchaserId,
                              isBold: true,
                            ),
                            if (p != null && p.phone.isNotEmpty)
                              RecordDetailField(
                                label: tr(isUrdu, 'Phone', 'فون نمبر'),
                                value: p.phone,
                              ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Fuel Unit', 'تیل کی قسم'),
                              value: s.fuel.label(isUrdu),
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Quantity (Liters)',
                                  'مقدار (لیٹر)'),
                              value: formatLiters(s.liters),
                              isBold: true,
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Rate / Liter', 'فی لیٹر ریٹ'),
                              value: 'Rs. ${s.rateUsed.round()}/L',
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Total Bill Amount', 'کل بل رقم'),
                              value: formatRs(s.totalAmount),
                              isBold: true,
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Cash Paid Now', 'وصول شدہ رقم'),
                              value: formatRs(s.paidNow),
                              valueColor: erp.success,
                              isBold: true,
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Remaining Balance Due',
                                  'بقایا واجب الادا'),
                              value: formatRs(s.dueAmount),
                              valueColor:
                                  s.dueAmount > 0 ? erp.danger : erp.success,
                              isBold: true,
                            ),
                            if (s.note.isNotEmpty)
                              RecordDetailField(
                                label: tr(isUrdu, 'Note', 'نوٹ / تفصیل'),
                                value: s.note,
                              ),
                          ],
                        ),
                      ),
                      if (widget.store.canUpdateIn(ErpModule.sales))
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr(isUrdu, 'Edit', 'ترمیم'),
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: erp.primary),
                          onPressed: () => showSaleFormDialog(
                              context, widget.store,
                              existing: s),
                        ),
                      if (widget.store.canDeleteIn(ErpModule.sales))
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr(isUrdu, 'Delete', 'حذف'),
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 18, color: erp.danger),
                          onPressed: () async {
                            final ok = await confirmDeleteDialog(context,
                                isUrdu: isUrdu, count: 1);
                            if (!ok || !mounted) return;
                            widget.store.deleteFuelSales([s.id]);
                            showErpSnackBar(
                              context,
                              tr(isUrdu, 'Sale deleted & stock restored.',
                                  'فروخت حذف ہو گئی اور اسٹاک بحال ہو گیا۔'),
                            );
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
