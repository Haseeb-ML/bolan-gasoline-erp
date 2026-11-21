import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';
import '../widgets/party_and_expense_dialogs.dart';
import 'purchaser_detail_screen.dart';

class PurchasersScreen extends StatefulWidget {
  const PurchasersScreen({super.key, required this.store});

  final ErpStore store;

  @override
  State<PurchasersScreen> createState() => _PurchasersScreenState();
}

class _PurchasersScreenState extends State<PurchasersScreen> {
  final Set<String> _selectedIds = {};

  List<Purchaser> get _filteredPurchasers {
    final q = widget.store.searchQuery;
    final list = widget.store.creditPurchasers;
    if (q.isEmpty) return list;
    return list.where((p) {
      final text = '${p.id} ${p.nameEn} ${p.nameUr} ${p.phone}'.toLowerCase();
      return text.contains(q);
    }).toList();
  }

  Future<void> _downloadPurchasersExcel(List<Purchaser> rows) async {
    final isUrdu = widget.store.isUrdu;
    final buf = StringBuffer();
    buf.writeln(
      'Purchaser ID,Name,Phone,Petrol Rate (Rs),Diesel Rate (Rs),Total Billed (Rs),Total Paid (Rs),Balance Due (Rs)',
    );
    for (final p in rows) {
      final sum = widget.store.purchaserSummary(p.id);
      buf.writeln(
        '${p.id},${p.nameEn.replaceAll(',', ' ')},${p.phone},${p.petrolRate.round()},${p.dieselRate.round()},${sum.totalBilled.round()},${sum.totalPaid.round()},${sum.balance.round()}',
      );
    }
    final csv = buf.toString();
    await openExcelSheetViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_purchasers_khata.csv',
      sheetTitle: tr(
        isUrdu,
        'Purchasers Khata Summary — Excel Sheet View',
        'پرچیزرز کھاتہ خلاصہ — ایکسل شیٹ ویو',
      ),
      csvContent: csv,
    );
  }

  Future<void> _downloadPurchasersPdf(List<Purchaser> rows) async {
    final isUrdu = widget.store.isUrdu;
    double totalBilled = 0;
    double totalPaid = 0;
    double totalBalance = 0;
    final pdfRows = <List<String>>[];
    for (final p in rows) {
      final sum = widget.store.purchaserSummary(p.id);
      totalBilled += sum.totalBilled;
      totalPaid += sum.totalPaid;
      totalBalance += sum.balance;
      pdfRows.add([
        p.id,
        p.nameEn,
        p.phone,
        'P:${p.petrolRate.round()} / D:${p.dieselRate.round()}',
        'Rs.${sum.totalBilled.round()}',
        'Rs.${sum.totalPaid.round()}',
        'Rs.${sum.balance.round()}',
      ]);
    }
    await openPdfReportViewer(
      context,
      isUrdu: isUrdu,
      filename: 'bolan_purchasers_khata.pdf',
      reportTitle: 'PURCHASERS KHATA & RECEIVABLE LEDGER SUMMARY',
      subtitle:
          'Total Credit Purchasers: ${rows.length}  |  Generated: ${formatDateShort(DateTime.now())}',
      summaryItems: [
        'Total Billed: Rs. ${totalBilled.round()}',
        'Total Received: Rs. ${totalPaid.round()}',
        'Net Receivable Due: Rs. ${totalBalance.round()}',
      ],
      headers: const [
        'ID',
        'PURCHASER',
        'PHONE',
        'RATES (P/D)',
        'TOTAL BILLED',
        'PAID',
        'BALANCE DUE',
      ],
      rows: pdfRows,
    );
  }

  Future<void> _deleteSelected(List<Purchaser> list) async {
    final valid =
        _selectedIds.where((id) => list.any((p) => p.id == id)).toList();
    if (valid.isEmpty) return;
    final ok = await confirmDeleteDialog(context,
        isUrdu: widget.store.isUrdu, count: valid.length);
    if (!ok || !mounted) return;
    widget.store.deletePurchasers(valid);
    setState(() => _selectedIds.clear());
    showErpSnackBar(
      context,
      tr(widget.store.isUrdu, '${valid.length} purchaser(s) deleted.',
          '${valid.length} پرچیزر حذف کر دیے گئے۔'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    final list = _filteredPurchasers;
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
                    tr(
                      isUrdu,
                      'Purchasers Khata & Personal Ledgers (${list.length})',
                      'پرچیزرز کھاتہ اور ذاتی ہسٹری (${list.length})',
                    ),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: erp.textMain),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(
                      isUrdu,
                      'Click any purchaser name or "History" to open their complete personal account ledger.',
                      'کسی بھی پرچیزر کے نام یا "ہسٹری" پر کلک کریں تو ان کا مکمل ذاتی کھاتہ کھل جائے گا۔',
                    ),
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
                    onDownloadPdf: () => _downloadPurchasersPdf(list),
                    onDownloadExcel: () => _downloadPurchasersExcel(list),
                  ),
                  if (widget.store.canCreateIn(ErpModule.purchasers))
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: erp.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      onPressed: () =>
                          showPurchaserFormDialog(context, widget.store),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text(
                        tr(isUrdu, 'Add Purchaser', 'نیا پرچیزر شامل کریں'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.store.canDeleteIn(ErpModule.purchasers))
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
              icon: Icons.people_outline_rounded,
              title: tr(isUrdu, 'No purchasers found', 'کوئی پرچیزر نہیں ملا'),
              subtitle: tr(isUrdu, 'Add a purchaser account to track their khata & history.',
                  'کھاتہ اور ہسٹری رکھنے کے لیے نیا پرچیزر شامل کریں۔'),
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
    List<Purchaser> list,
    bool allSelected,
    double availableWidth,
  ) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: availableWidth > 860 ? availableWidth : 860,
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
            DataColumn(label: Text(tr(isUrdu, 'PURCHASER', 'پرچیزر کا نام'))),
            DataColumn(label: Text(tr(isUrdu, 'RATES (P / D)', 'ریٹ (پٹرول / ڈیزل)'))),
            DataColumn(label: Text(tr(isUrdu, 'TOTAL BILLED', 'کل بل'))),
            DataColumn(label: Text(tr(isUrdu, 'PAID', 'وصول شدہ'))),
            DataColumn(label: Text(tr(isUrdu, 'BALANCE DUE', 'بقایا لینا ہے'))),
            DataColumn(label: Text(tr(isUrdu, 'LEDGER & ACTIONS', 'کھاتہ اور عمل'))),
          ],
          rows: list.map((p) {
            final summary = widget.store.purchaserSummary(p.id);
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
                  InkWell(
                    onTap: () =>
                        openPurchaserDetail(context, widget.store, p.id),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.displayName(isUrdu),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: erp.primary,
                          ),
                        ),
                        LtrText(p.phone,
                            style: TextStyle(
                                fontSize: 11, color: erp.textMuted)),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  LtrText(
                    'P: Rs.${p.petrolRate.round()} | D: Rs.${p.dieselRate.round()}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: erp.textMain),
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
                            openPurchaserDetail(context, widget.store, p.id),
                        icon: const Icon(Icons.history_edu_rounded, size: 15),
                        label: Text(
                          tr(isUrdu, 'History', 'ہسٹری'),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (widget.store.canCreateIn(ErpModule.purchasers)) ...[
                        const SizedBox(width: 6),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: erp.successSoft,
                            foregroundColor: erp.success,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: () => showLedgerPaymentDialog(
                            context,
                            widget.store,
                            partyType: 'purchaser',
                            partyId: p.id,
                          ),
                          child: Text(
                            tr(isUrdu, 'Receive', 'وصولی'),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                      if (widget.store.canUpdateIn(ErpModule.purchasers))
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr(isUrdu, 'Edit', 'ترمیم'),
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: erp.textMuted),
                          onPressed: () => showPurchaserFormDialog(
                              context, widget.store,
                              existing: p),
                        ),
                      if (widget.store.canDeleteIn(ErpModule.purchasers))
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr(isUrdu, 'Delete', 'حذف'),
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 18, color: erp.danger),
                          onPressed: () async {
                            final ok = await confirmDeleteDialog(context,
                                isUrdu: isUrdu, count: 1);
                            if (!ok || !mounted) return;
                            widget.store.deletePurchasers([p.id]);
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
