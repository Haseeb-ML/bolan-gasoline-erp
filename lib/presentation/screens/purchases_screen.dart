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
import 'supplier_detail_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key, required this.store});

  final ErpStore store;

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final Set<String> _selectedIds = {};
  String _period = 'all';
  DateTimeRange? _customRange;

  List<FuelPurchase> get _filteredPurchases {
    final q = widget.store.searchQuery;
    final base = q.isEmpty
        ? widget.store.purchases
        : widget.store.purchases.where((p) {
            final sup = widget.store.findSupplier(p.supplierId);
            final text =
                '${p.id} ${p.fuel.key} ${sup?.nameEn ?? ''} ${sup?.nameUr ?? ''} ${p.note}'
                    .toLowerCase();
            return text.contains(q);
          }).toList();
    return filterByPeriod(
      items: base,
      getDate: (p) => p.date,
      period: _period,
      customRange: _customRange,
    );
  }

  Future<void> _downloadPurchasesReport(List<FuelPurchase> rows) async {
    final isUrdu = widget.store.isUrdu;
    final buf = StringBuffer();
    buf.writeln('PO ID,Date,Supplier,Fuel,Liters,Purchase Rate (Rs),Total Bill (Rs),Paid (Rs),Balance (Rs),Note');
    for (final p in rows) {
      final sName =
          (widget.store.findSupplier(p.supplierId)?.nameEn ?? p.supplierId)
              .replaceAll(',', ' ');
      buf.writeln(
        '${p.id},${p.date.toIso8601String().split('T').first},$sName,${p.fuel.key},${p.liters.round()},${p.rate.round()},${p.totalCost.round()},${p.paid.round()},${p.balance.round()},${p.note.replaceAll(',', ' ')}',
      );
    }
    final csv = buf.toString();
    await openExcelSheetViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_purchases_$_period.csv',
      sheetTitle: tr(
        isUrdu,
        'Fuel Tanker Purchases — Excel Sheet View',
        'تیل ٹینکر خریداری — ایکسل شیٹ ویو',
      ),
      csvContent: csv,
    );
  }

  Future<void> _downloadPurchasesPdf(List<FuelPurchase> rows) async {
    final isUrdu = widget.store.isUrdu;
    final totalLiters = rows.fold<double>(0, (s, e) => s + e.liters);
    final totalCost = rows.fold<double>(0, (s, e) => s + e.totalCost);
    final totalPaid = rows.fold<double>(0, (s, e) => s + e.paid);
    final pdfBytes = ErpPdfGenerator.buildTableReportPdf(
      reportTitle: 'FUEL STOCK ARRIVALS & TANKER PURCHASES REPORT',
      subtitle:
          'Period: ${_period.toUpperCase()}  |  Records: ${rows.length}  |  Generated: ${formatDateShort(DateTime.now())}',
      summaryItems: [
        'Total Liters: ${totalLiters.round()} L',
        'Total Cost: Rs. ${totalCost.round()}',
        'Total Paid: Rs. ${totalPaid.round()}',
        'Payable Balance: Rs. ${(totalCost - totalPaid).round()}',
      ],
      headers: const [
        'PO ID',
        'DATE',
        'SUPPLIER',
        'FUEL',
        'LITERS',
        'RATE',
        'TOTAL RS',
        'BALANCE RS',
      ],
      rows: rows.map((p) {
        final sName =
            widget.store.findSupplier(p.supplierId)?.nameEn ?? p.supplierId;
        return [
          p.id,
          formatDateShort(p.date),
          sName,
          p.fuel.key.toUpperCase(),
          '${p.liters.round()} L',
          'Rs.${p.rate.round()}',
          'Rs.${p.totalCost.round()}',
          'Rs.${p.balance.round()}',
        ];
      }).toList(),
    );
    await downloadBinaryFile(
      filename: 'bolan_purchases_$_period.pdf',
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );
    if (!mounted) return;
    showErpSnackBar(
      context,
      tr(isUrdu, 'Purchases PDF report downloaded (.pdf)!',
          'خریداری پی ڈی ایف رپورٹ ڈاؤن لوڈ ہو گئی (.pdf)!'),
    );
  }

  Future<void> _deleteSelected(List<FuelPurchase> list) async {
    final valid =
        _selectedIds.where((id) => list.any((p) => p.id == id)).toList();
    if (valid.isEmpty) return;
    final ok = await confirmDeleteDialog(context,
        isUrdu: widget.store.isUrdu, count: valid.length);
    if (!ok || !mounted) return;
    widget.store.deleteFuelPurchases(valid);
    setState(() => _selectedIds.clear());
    showErpSnackBar(
      context,
      tr(widget.store.isUrdu, '${valid.length} purchase(s) deleted.',
          '${valid.length} خریداری ریکارڈ حذف کر دیے گئے۔'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    final petrol = widget.store.fuelStocks[FuelType.petrol]!;
    final diesel = widget.store.fuelStocks[FuelType.diesel]!;
    final list = _filteredPurchases;
    _selectedIds.removeWhere((id) => !list.any((e) => e.id == id));
    final allSelected = list.isNotEmpty && _selectedIds.length == list.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (_, constraints) {
            final twoCol = constraints.maxWidth >= 720;
            final pCard = TankStockCard(
              stock: petrol,
              isUrdu: isUrdu,
              stockValueRs: widget.store.fuelStockValueRs(FuelType.petrol),
              onEditTank: widget.store.canUpdateIn(ErpModule.purchases)
                  ? () =>
                      showTankSettingsDialog(context, widget.store, petrol)
                  : null,
            );
            final dCard = TankStockCard(
              stock: diesel,
              isUrdu: isUrdu,
              stockValueRs: widget.store.fuelStockValueRs(FuelType.diesel),
              onEditTank: widget.store.canUpdateIn(ErpModule.purchases)
                  ? () =>
                      showTankSettingsDialog(context, widget.store, diesel)
                  : null,
            );
            if (twoCol) {
              return Row(
                children: [
                  Expanded(child: pCard),
                  const SizedBox(width: 16),
                  Expanded(child: dCard),
                ],
              );
            }
            return Column(
              children: [pCard, const SizedBox(height: 14), dCard],
            );
          },
        ),
        const SizedBox(height: 18),
        Container(
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
                        tr(isUrdu, 'Fuel Stock Arrivals (Tanker Purchases)',
                            'تیل کی خریداری اور اسٹاک آمد (ٹینکرز)'),
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: erp.textMain),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr(isUrdu,
                            'Track supplier tankers, purchase rate, stock added & balance.',
                            'سپلائر سے آنے والا تیل، خرید ریٹ، اسٹاک اور بقایا ریکارڈ۔'),
                        style: TextStyle(fontSize: 12, color: erp.textMuted),
                      ),
                    ],
                  ),
                  if (widget.store.canCreateIn(ErpModule.purchases))
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: erp.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      onPressed: () =>
                          showPurchaseFormDialog(context, widget.store),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        tr(isUrdu, 'Record Fuel Purchase',
                            'نیا تیل آیا درج کریں'),
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
                onDownloadPdf: () => _downloadPurchasesPdf(list),
                onDownloadReport: () => _downloadPurchasesReport(list),
              ),
              const SizedBox(height: 14),
              if (widget.store.canDeleteIn(ErpModule.purchases))
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
                  icon: Icons.local_shipping_outlined,
                  title: tr(isUrdu, 'No purchases found',
                      'کوئی خریداری ریکارڈ نہیں ملا'),
                  subtitle: tr(isUrdu, 'Record a fuel tanker arrival to add stock.',
                      'اسٹاک شامل کرنے کے لیے نیا تیل ٹینکر درج کریں۔'),
                )
              else
                LayoutBuilder(
                  builder: (_, constraints) => _buildDesktopTable(
                      list, allSelected, constraints.maxWidth),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(
    List<FuelPurchase> list,
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
            DataColumn(label: Text(tr(isUrdu, 'PO / DATE', 'نمبر / تاریخ'))),
            DataColumn(label: Text(tr(isUrdu, 'SUPPLIER', 'سپلائر'))),
            DataColumn(label: Text(tr(isUrdu, 'UNIT', 'قسم'))),
            DataColumn(label: Text(tr(isUrdu, 'LITERS', 'لیٹر'))),
            DataColumn(label: Text(tr(isUrdu, 'RATE', 'خرید ریٹ'))),
            DataColumn(label: Text(tr(isUrdu, 'TOTAL', 'کل رقم'))),
            DataColumn(label: Text(tr(isUrdu, 'BALANCE', 'بقایا'))),
            DataColumn(label: Text(tr(isUrdu, 'ACTIONS', 'عمل'))),
          ],
          rows: list.map((p) {
            final sup = widget.store.findSupplier(p.supplierId);
            final checked = _selectedIds.contains(p.id);
            return DataRow(
              selected: checked,
              cells: [
                DataCell(
                  Checkbox(
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.add(p.id);
                        } else {
                          _selectedIds.remove(p.id);
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
                      LtrText(p.id,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: erp.textMain)),
                      LtrText(formatDateShort(p.date),
                          style:
                              TextStyle(fontSize: 11, color: erp.textMuted)),
                    ],
                  ),
                ),
                DataCell(
                  InkWell(
                    onTap: sup != null
                        ? () => openSupplierDetail(context, widget.store, sup.id)
                        : null,
                    child: Text(
                      sup?.displayName(isUrdu) ?? p.supplierId,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: erp.primary),
                    ),
                  ),
                ),
                DataCell(FuelBadge(fuel: p.fuel, isUrdu: isUrdu)),
                DataCell(LtrText(formatLiters(p.liters),
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: erp.textMain))),
                DataCell(LtrText('Rs. ${p.rate.round()}/L',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: erp.textMuted))),
                DataCell(LtrText(formatRs(p.totalCost),
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: erp.textMain))),
                DataCell(LtrText(
                  formatRs(p.balance),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: p.balance > 0 ? erp.danger : erp.success,
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
                          title: tr(isUrdu, 'Fuel Tanker Purchase Voucher',
                              'ٹینکر خریداری واؤچر'),
                          recordId: p.id,
                          date: p.date,
                          statusLabel: p.balance <= 0
                              ? tr(isUrdu, 'CLEARED', 'مکمل ادا شدہ')
                              : tr(isUrdu, 'PAYABLE DUE', 'بقایا دینا ہے'),
                          statusColor:
                              p.balance <= 0 ? erp.success : erp.danger,
                          fields: [
                            RecordDetailField(
                              label: tr(isUrdu, 'Supplier', 'سپلائر کمپنی'),
                              value: sup?.displayName(isUrdu) ?? p.supplierId,
                              isBold: true,
                            ),
                            if (sup != null && sup.phone.isNotEmpty)
                              RecordDetailField(
                                label: tr(isUrdu, 'Phone', 'فون نمبر'),
                                value: sup.phone,
                              ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Fuel Type', 'تیل کی قسم'),
                              value: p.fuel.label(isUrdu),
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Quantity (Liters)',
                                  'مقدار (لیٹر)'),
                              value: formatLiters(p.liters),
                              isBold: true,
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Purchase Rate / L',
                                  'خرید ریٹ فی لیٹر'),
                              value: 'Rs. ${p.rate.round()}/L',
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Total Purchase Cost',
                                  'کل خریداری بل'),
                              value: formatRs(p.totalCost),
                              isBold: true,
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Paid Amount', 'ادا شدہ رقم'),
                              value: formatRs(p.paid),
                              valueColor: erp.success,
                              isBold: true,
                            ),
                            RecordDetailField(
                              label: tr(isUrdu, 'Payable Balance',
                                  'بقایا واجب الادا'),
                              value: formatRs(p.balance),
                              valueColor:
                                  p.balance > 0 ? erp.danger : erp.success,
                              isBold: true,
                            ),
                            if (p.note.isNotEmpty)
                              RecordDetailField(
                                label: tr(isUrdu, 'Note', 'نوٹ / تفصیل'),
                                value: p.note,
                              ),
                          ],
                        ),
                      ),
                      if (widget.store.canUpdateIn(ErpModule.purchases))
                        IconButton(
                          tooltip: tr(isUrdu, 'Edit', 'ترمیم'),
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: erp.primary),
                          onPressed: () => showPurchaseFormDialog(
                              context, widget.store,
                              existing: p),
                        ),
                      if (widget.store.canDeleteIn(ErpModule.purchases))
                        IconButton(
                          tooltip: tr(isUrdu, 'Delete', 'حذف'),
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 18, color: erp.danger),
                          onPressed: () async {
                            final ok = await confirmDeleteDialog(context,
                                isUrdu: isUrdu, count: 1);
                            if (!ok || !mounted) return;
                            widget.store.deleteFuelPurchases([p.id]);
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
