import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';
import '../widgets/party_and_expense_dialogs.dart';
import 'supplier_detail_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key, required this.store});

  final ErpStore store;

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final Set<String> _selectedIds = {};
  int _currentPage = 1;
  static const int _pageSize = 15;

  List<FuelSupplier> get _filteredSuppliers {
    final q = widget.store.searchQuery;
    if (q.isEmpty) return widget.store.suppliers;
    return widget.store.suppliers.where((s) {
      final text = '${s.id} ${s.nameEn} ${s.nameUr} ${s.phone}'.toLowerCase();
      return text.contains(q);
    }).toList();
  }

  Future<void> _downloadSuppliersExcel(List<FuelSupplier> rows) async {
    final isUrdu = widget.store.isUrdu;
    final buf = StringBuffer();
    buf.writeln(
      'Supplier ID,Supplier Name,Phone,Total Purchased (Rs),Total Paid (Rs),Payable Balance (Rs)',
    );
    for (final s in rows) {
      final sum = widget.store.supplierSummary(s.id);
      buf.writeln(
        '${s.id},${s.nameEn.replaceAll(',', ' ')},${s.phone},${sum.totalBilled.round()},${sum.totalPaid.round()},${sum.balance.round()}',
      );
    }
    final csv = buf.toString();
    await openExcelSheetViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_suppliers_ledger.csv',
      sheetTitle: tr(
        isUrdu,
        'Fuel Suppliers Ledger — Excel Sheet View',
        'تیل سپلائرز کھاتہ — ایکسل شیٹ ویو',
      ),
      csvContent: csv,
    );
  }

  Future<void> _downloadSuppliersPdf(List<FuelSupplier> rows) async {
    final isUrdu = widget.store.isUrdu;
    double totalPurchased = 0;
    double totalPaid = 0;
    double totalPayable = 0;
    final pdfRows = <List<String>>[];
    for (final s in rows) {
      final sum = widget.store.supplierSummary(s.id);
      totalPurchased += sum.totalBilled;
      totalPaid += sum.totalPaid;
      totalPayable += sum.balance;
      pdfRows.add([
        s.id,
        s.nameEn,
        s.phone,
        'Rs.${sum.totalBilled.round()}',
        'Rs.${sum.totalPaid.round()}',
        'Rs.${sum.balance.round()}',
      ]);
    }
    await openPdfReportViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_suppliers_ledger.pdf',
      reportTitle: 'FUEL SUPPLIERS LEDGER & PAYABLE BALANCES',
      subtitle:
          'Total Suppliers: ${rows.length}  |  Generated: ${formatDateShort(DateTime.now())}',
      summaryItems: [
        'Total Purchased: Rs. ${totalPurchased.round()}',
        'Total Paid: Rs. ${totalPaid.round()}',
        'Net Payable Due: Rs. ${totalPayable.round()}',
      ],
      headers: const [
        'ID',
        'SUPPLIER NAME',
        'PHONE',
        'TOTAL PURCHASED',
        'PAID',
        'PAYABLE DUE',
      ],
      rows: pdfRows,
    );
  }

  Future<void> _deleteSelected(List<FuelSupplier> list) async {
    final valid =
        _selectedIds.where((id) => list.any((s) => s.id == id)).toList();
    if (valid.isEmpty) return;
    final ok = await confirmDeleteDialog(context,
        isUrdu: widget.store.isUrdu, count: valid.length);
    if (!ok || !mounted) return;
    widget.store.deleteSuppliers(valid);
    setState(() => _selectedIds.clear());
    showErpSnackBar(
      context,
      tr(widget.store.isUrdu, '${valid.length} supplier(s) deleted.',
          '${valid.length} سپلائر حذف کر دیے گئے۔'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    final list = _filteredSuppliers;
    _selectedIds.removeWhere((id) => !list.any((e) => e.id == id));
    final allSelected = list.isNotEmpty && _selectedIds.length == list.length;

    final isMobile = MediaQuery.sizeOf(context).width < 640;

    return Container(
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
                    tr(isUrdu, 'Fuel Suppliers Ledger (Payable Balances)',
                        'تیل سپلائرز کھاتہ (کمپنیوں کا حساب)'),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: erp.textMain),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(isUrdu,
                        'Click any supplier to view tanker arrival & payment history.',
                        'ٹینکر آمد اور ادائیگیوں کی مکمل ہسٹری دیکھنے کے لیے سپلائر پر کلک کریں۔'),
                    style: TextStyle(fontSize: 12, color: erp.textMuted),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ExportActionButtons(
                    isUrdu: isUrdu,
                    onDownloadPdf: () => _downloadSuppliersPdf(list),
                    onDownloadExcel: () => _downloadSuppliersExcel(list),
                  ),
                  if (widget.store.canCreateIn(ErpModule.suppliers))
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: erp.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      onPressed: () =>
                          showSupplierFormDialog(context, widget.store),
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: Text(
                        tr(isUrdu, 'Add Supplier', 'نیا سپلائر شامل کریں'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.store.canDeleteIn(ErpModule.suppliers))
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
              icon: Icons.warehouse_outlined,
              title: tr(isUrdu, 'No suppliers found', 'کوئی سپلائر نہیں ملا'),
              subtitle: tr(isUrdu, 'Add a fuel tanker supplier to track purchases.',
                  'تیل خریداری کے لیے سپلائر شامل کریں۔'),
            )
          else ...[
            LayoutBuilder(
              builder: (_, constraints) {
                final totalPages =
                    (list.length / _pageSize).ceil().clamp(1, 999999);
                final page = _currentPage.clamp(1, totalPages);
                final pagedList =
                    list.skip((page - 1) * _pageSize).take(_pageSize).toList();
                return _buildDesktopTable(
                    pagedList, allSelected, constraints.maxWidth);
              },
            ),
            ErpPaginationBar(
              currentPage: _currentPage.clamp(
                  1, (list.length / _pageSize).ceil().clamp(1, 999999)),
              totalItems: list.length,
              pageSize: _pageSize,
              isUrdu: isUrdu,
              onPageChanged: (p) => setState(() => _currentPage = p),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    List<FuelSupplier> list,
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
          dataRowMinHeight: 58,
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
                      _selectedIds.addAll(list.map((e) => e.id));
                    } else {
                      _selectedIds.clear();
                    }
                  });
                },
              ),
            ),
            DataColumn(label: Text(tr(isUrdu, 'SUPPLIER NAME', 'سپلائر کا نام'))),
            DataColumn(label: Text(tr(isUrdu, 'TOTAL PURCHASED', 'کل خریداری'))),
            DataColumn(label: Text(tr(isUrdu, 'PAID', 'ادا شدہ'))),
            DataColumn(label: Text(tr(isUrdu, 'PAYABLE', 'بقایا دینا ہے'))),
            DataColumn(label: Text(tr(isUrdu, 'ACTIONS', 'عمل'))),
          ],
          rows: list.map((s) {
            final summary = widget.store.supplierSummary(s.id);
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
                  InkWell(
                    onTap: () =>
                        openSupplierDetail(context, widget.store, s.id),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.displayName(isUrdu),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: erp.primary)),
                        LtrText(s.phone,
                            style: TextStyle(
                                fontSize: 11, color: erp.textMuted)),
                      ],
                    ),
                  ),
                ),
                DataCell(LtrText(formatRs(summary.totalBilled),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: erp.textMain))),
                DataCell(LtrText(formatRs(summary.totalPaid),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: erp.success))),
                DataCell(LtrText(
                  formatRs(summary.balance),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: summary.balance > 0 ? erp.danger : erp.success,
                  ),
                )),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          side: BorderSide(color: erp.primaryBorder),
                          foregroundColor: erp.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999)),
                        ),
                        onPressed: () =>
                            openSupplierDetail(context, widget.store, s.id),
                        icon: const Icon(Icons.history_edu_rounded, size: 15),
                        label: Text(tr(isUrdu, 'History', 'ہسٹری'),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                      if (widget.store.canCreateIn(ErpModule.suppliers)) ...[
                        const SizedBox(width: 6),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: erp.dangerSoft,
                            foregroundColor: erp.danger,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: () => showLedgerPaymentDialog(
                            context,
                            widget.store,
                            partyType: 'supplier',
                            partyId: s.id,
                          ),
                          child: Text(tr(isUrdu, 'Pay', 'ادائیگی'),
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                      if (widget.store.canUpdateIn(ErpModule.suppliers))
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr(isUrdu, 'Edit', 'ترمیم'),
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: erp.textMuted),
                          onPressed: () => showSupplierFormDialog(
                              context, widget.store,
                              existing: s),
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
                            widget.store.deleteSuppliers([s.id]);
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
