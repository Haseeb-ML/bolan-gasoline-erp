import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';
import '../widgets/party_and_expense_dialogs.dart';
import '../widgets/sale_form_dialog.dart';
import 'purchaser_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store});

  final ErpStore store;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = store.isUrdu;
    final petrol = store.fuelStocks[FuelType.petrol]!;
    final diesel = store.fuelStocks[FuelType.diesel]!;

    final recentSales = store.sales.take(6).toList();
    final topPurchasers = store.creditPurchasers.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2 Tank Stock Cards
        LayoutBuilder(
          builder: (_, constraints) {
            final twoCol = constraints.maxWidth >= 720;
            final petrolCard = TankStockCard(
              stock: petrol,
              isUrdu: isUrdu,
              stockValueRs: store.fuelStockValueRs(FuelType.petrol),
              onEditTank: store.canUpdateIn(ErpModule.dashboard)
                  ? () => showTankSettingsDialog(context, store, petrol)
                  : null,
            );
            final dieselCard = TankStockCard(
              stock: diesel,
              isUrdu: isUrdu,
              stockValueRs: store.fuelStockValueRs(FuelType.diesel),
              onEditTank: store.canUpdateIn(ErpModule.dashboard)
                  ? () => showTankSettingsDialog(context, store, diesel)
                  : null,
            );
            if (twoCol) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: petrolCard),
                  const SizedBox(width: 16),
                  Expanded(child: dieselCard),
                ],
              );
            }
            return Column(
              children: [
                petrolCard,
                const SizedBox(height: 14),
                dieselCard,
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Recent Sales + Top Purchasers Khata Summary (strictly filtered by RBAC permissions)
        if (store.activePermissions.manageSales ||
            store.activePermissions.managePurchasers)
          LayoutBuilder(
            builder: (_, constraints) {
              final showSales = store.activePermissions.manageSales;
              final showKhata = store.activePermissions.managePurchasers;
              final wide = constraints.maxWidth >= 960;

              final salesCard = _RecentSalesPanel(
                store: store,
                sales: recentSales,
                isUrdu: isUrdu,
              );
              final khataCard = _TopPurchasersPanel(
                store: store,
                purchasers: topPurchasers,
                isUrdu: isUrdu,
              );

              if (showSales && showKhata) {
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: salesCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: khataCard),
                    ],
                  );
                }
                return Column(
                  children: [
                    salesCard,
                    const SizedBox(height: 16),
                    khataCard,
                  ],
                );
              }
              return showSales ? salesCard : khataCard;
            },
          ),
        if (store.activePermissions.managePurchasers) ...[
          const SizedBox(height: 8),
          // Quick hint for tapping any purchaser
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: erp.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: erp.primaryBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.history_edu_rounded, color: erp.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(
                      isUrdu,
                      'Tip: Tap any Purchaser name (e.g. Arsalan) to open their complete Personal Ledger Account & daily fuel history.',
                      'مشورہ: کسی بھی پرچیزر (مثلاً ارسلان) کے نام پر کلک کریں تو ان کا مکمل ذاتی کھاتہ اور روزانہ تیل کی ہسٹری کھل جائے گی۔',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: erp.textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RecentSalesPanel extends StatelessWidget {
  const _RecentSalesPanel({
    required this.store,
    required this.sales,
    required this.isUrdu,
  });

  final ErpStore store;
  final List<FuelSale> sales;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
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
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(isUrdu, 'DYNAMIC RATE PER PURCHASER',
                        'ہر پرچیزر کا الگ الگ ریٹ'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: erp.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(isUrdu, 'Recent Fuel Sales (Cash & Credit)',
                        'تازہ تیل کی فروخت (کیش اور ادھار)'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: erp.textMain,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: erp.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () => showSaleFormDialog(context, store),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(
                  tr(isUrdu, 'New Sale', 'نئی فروخت'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (sales.isEmpty)
            EmptyStateView(
              icon: Icons.local_gas_station_outlined,
              title: tr(isUrdu, 'No sales yet', 'ابھی کوئی فروخت نہیں'),
              subtitle: tr(isUrdu, 'Tap + New Sale to record your first bill.',
                  'پہلا بل درج کرنے کے لیے نئی فروخت پر کلک کریں۔'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sales.length,
              separatorBuilder: (_, _) => Divider(height: 16, color: erp.cardBorder),
              itemBuilder: (_, idx) {
                final s = sales[idx];
                final p = store.findPurchaser(s.purchaserId);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (p != null && !p.isCashCounter) {
                      openPurchaserDetail(context, store, p.id);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p?.displayName(isUrdu) ?? s.purchaserId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: erp.textMain,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  FuelBadge(fuel: s.fuel, isUrdu: isUrdu),
                                  LtrText(
                                    '${formatLiters(s.liters)} @ Rs. ${s.rateUsed.round()}/L',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: erp.textMuted,
                                    ),
                                  ),
                                  LtrText(
                                    formatDateShort(s.date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: erp.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            LtrText(
                              formatRs(s.totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: erp.textMain,
                              ),
                            ),
                            Text(
                              s.syncStatus == 'Offline Queued'
                                  ? tr(isUrdu, 'Offline Saved', 'آف لائن محفوظ')
                                  : tr(isUrdu, 'Synced', 'سنک شدہ'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: s.syncStatus == 'Offline Queued'
                                    ? erp.warning
                                    : erp.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TopPurchasersPanel extends StatelessWidget {
  const _TopPurchasersPanel({
    required this.store,
    required this.purchasers,
    required this.isUrdu,
  });

  final ErpStore store;
  final List<Purchaser> purchasers;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(isUrdu, 'TOP CREDIT BALANCES', 'پرچیزرز بقایا کھاتہ'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: erp.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(isUrdu, 'Purchasers Khata Summary',
                          'پرچیزرز کا بیلنس'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: erp.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => store.setModule(ErpModule.purchasers),
                child: Text(
                  tr(isUrdu, 'View All →', 'سب دیکھیں ←'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: erp.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: purchasers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, idx) {
              final p = purchasers[idx];
              final summary = store.purchaserSummary(p.id);
              return Material(
                color: erp.subtleBg,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => openPurchaserDetail(context, store, p.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: erp.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.displayName(isUrdu),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: erp.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              LtrText(
                                'P: Rs.${p.petrolRate.round()} | D: Rs.${p.dieselRate.round()}',
                                style: TextStyle(
                                    fontSize: 11, color: erp.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            LtrText(
                              formatRs(summary.balance),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: summary.balance > 0
                                    ? erp.danger
                                    : erp.success,
                              ),
                            ),
                            InkWell(
                              onTap: () => showLedgerPaymentDialog(
                                context,
                                store,
                                partyType: 'purchaser',
                                partyId: p.id,
                              ),
                              child: Text(
                                tr(isUrdu, 'Receive Cash', 'رقم وصولی'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: erp.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
