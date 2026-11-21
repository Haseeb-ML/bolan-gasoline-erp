import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import 'common_widgets.dart';

Future<void> showSaleFormDialog(
  BuildContext context,
  ErpStore store, {
  FuelSale? existing,
  String? lockedPurchaserId,
}) async {
  final isUrdu = store.isUrdu;
  final isEdit = existing != null;

  String selectedPurchaserId = existing?.purchaserId ??
      lockedPurchaserId ??
      store.purchasers.first.id;
  if (store.findPurchaser(selectedPurchaserId) == null) {
    selectedPurchaserId = store.purchasers.first.id;
  }

  FuelType selectedFuel = existing?.fuel ?? FuelType.diesel;
  String selectedMethod =
      ErpStore.normalizeMethod(existing?.paymentMethod ?? 'Cash');
  DateTime selectedDate = existing?.date ?? DateTime.now();
  final initialPurchaser = store.findPurchaser(selectedPurchaserId)!;
  final initialRate = existing?.rateUsed ?? initialPurchaser.rateFor(selectedFuel);
  final initialLiters = existing?.liters ?? 200;
  final initialPaid =
      existing?.paidNow ?? (initialLiters * initialRate).roundToDouble();

  final rateCtrl = TextEditingController(text: initialRate.toStringAsFixed(0));
  final litersCtrl =
      TextEditingController(text: initialLiters.toStringAsFixed(0));
  final paidCtrl = TextEditingController(text: initialPaid.toStringAsFixed(0));
  final noteCtrl = TextEditingController(text: existing?.note ?? '');
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final erp = ctx.erp;
        final liters = double.tryParse(litersCtrl.text.trim()) ?? 0;
        final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
        final total = (liters * rate).round();

        void syncSuggestedRate() {
          final p = store.findPurchaser(selectedPurchaserId);
          if (p != null) {
            final r = p.rateFor(selectedFuel);
            rateCtrl.text = r.toStringAsFixed(0);
            if (p.isCashCounter) {
              final l = double.tryParse(litersCtrl.text.trim()) ?? 0;
              paidCtrl.text = (l * r).round().toString();
            }
          }
        }

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(isUrdu, 'DYNAMIC RATE ENTRY',
                                    'ہر پرچیزر کا الگ ریٹ'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: erp.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit
                                    ? tr(isUrdu, 'Edit Fuel Sale (${existing.id})',
                                        'تیل فروخت بل ترمیم (${existing.id})')
                                    : tr(isUrdu, 'New Fuel Sale',
                                        'نیا تیل فروخت بل'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: erp.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      tr(isUrdu, '1. Select Walk-in or Purchaser',
                          '1. واک ان یا پرچیزر منتخب کریں'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: erp.textMain),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPurchaserId,
                      isExpanded: true,
                      items: store.purchasers
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.displayName(isUrdu),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: lockedPurchaserId != null
                          ? null
                          : (val) {
                              if (val == null) return;
                              setState(() {
                                selectedPurchaserId = val;
                                syncSuggestedRate();
                              });
                            },
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (_, constraints) {
                        final twoCol = constraints.maxWidth > 400;
                        final fuelField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(isUrdu, '2. Fuel Unit', '2. تیل کا یونٹ'),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: erp.textMain),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<FuelType>(
                              initialValue: selectedFuel,
                              isExpanded: true,
                              items: FuelType.values
                                  .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f.label(isUrdu)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  selectedFuel = val;
                                  syncSuggestedRate();
                                });
                              },
                            ),
                          ],
                        );
                        final rateField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(isUrdu, '3. Rate / Liter (Rs.)',
                                  '3. فی لیٹر ریٹ (روپے)'),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: erp.primary),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: rateCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (_) => setState(() {
                                if (selectedPurchaserId == 'CASH') {
                                  final l =
                                      double.tryParse(litersCtrl.text.trim()) ??
                                          0;
                                  final r =
                                      double.tryParse(rateCtrl.text.trim()) ??
                                          0;
                                  paidCtrl.text = (l * r).round().toString();
                                }
                              }),
                              validator: (v) {
                                final n = double.tryParse(v?.trim() ?? '');
                                if (n == null || n <= 0) {
                                  return tr(isUrdu, 'Enter valid rate',
                                      'درست ریٹ درج کریں');
                                }
                                return null;
                              },
                            ),
                          ],
                        );
                        if (twoCol) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: fuelField),
                              const SizedBox(width: 12),
                              Expanded(child: rateField),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            fuelField,
                            const SizedBox(height: 12),
                            rateField,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (_, constraints) {
                        final twoCol = constraints.maxWidth > 400;
                        final litersField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(isUrdu, '4. Quantity (Liters)',
                                  '4. مقدار (لیٹر)'),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: erp.textMain),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: litersCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (_) => setState(() {
                                if (selectedPurchaserId == 'CASH') {
                                  final l =
                                      double.tryParse(litersCtrl.text.trim()) ??
                                          0;
                                  final r =
                                      double.tryParse(rateCtrl.text.trim()) ??
                                          0;
                                  paidCtrl.text = (l * r).round().toString();
                                }
                              }),
                              validator: (v) {
                                final n = double.tryParse(v?.trim() ?? '');
                                if (n == null || n <= 0) {
                                  return tr(isUrdu, 'Enter liters',
                                      'لیٹر درج کریں');
                                }
                                return null;
                              },
                            ),
                          ],
                        );
                        final paidField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(isUrdu, '5. Paid Now (Rs.)',
                                  '5. ابھی وصول شدہ رقم (روپے)'),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: erp.success),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: paidCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) {
                                final n = double.tryParse(v?.trim() ?? '');
                                if (n == null || n < 0) {
                                  return tr(isUrdu, 'Enter amount',
                                      'رقم درج کریں');
                                }
                                return null;
                              },
                            ),
                          ],
                        );
                        if (twoCol) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: litersField),
                              const SizedBox(width: 12),
                              Expanded(child: paidField),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            litersField,
                            const SizedBox(height: 12),
                            paidField,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr(isUrdu, '6. Payment Method (Cash / Bank Account)',
                          '6. ادائیگی کا طریقہ (کیش / بینک اکاؤنٹ)'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: erp.textMain),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          avatar: Icon(Icons.payments_rounded,
                              size: 16,
                              color: selectedMethod == 'Cash'
                                  ? erp.success
                                  : erp.textMuted),
                          label: Text(tr(isUrdu, 'Cash', 'نقد کیش')),
                          selected: selectedMethod == 'Cash',
                          onSelected: (_) =>
                              setState(() => selectedMethod = 'Cash'),
                        ),
                        ChoiceChip(
                          avatar: Icon(Icons.account_balance_rounded,
                              size: 16,
                              color: selectedMethod == 'Bank Transfer'
                                  ? erp.primary
                                  : erp.textMuted),
                          label: Text(
                              tr(isUrdu, 'Bank Transfer', 'بینک ٹرانسفر')),
                          selected: selectedMethod == 'Bank Transfer',
                          onSelected: (_) =>
                              setState(() => selectedMethod = 'Bank Transfer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ErpDateEntryField(
                      isUrdu: isUrdu,
                      initialDate: selectedDate,
                      isEdit: isEdit,
                      onChanged: (d) => selectedDate = d,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr(isUrdu, 'Note (Optional)', 'نوٹ / تفصیل (اختیاری)'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: erp.textMain),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        hintText: tr(isUrdu, 'e.g. Boat #4 morning refill',
                            'مثلاً بوٹ نمبر 4 صبح کی بھرائی'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(isUrdu, 'TOTAL FUEL BILL', 'کل بل رقم'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                LtrText(
                                  '${formatNumber(liters)} L × Rs. ${rate.round()}/L',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          LtrText(
                            formatRs(total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final l = double.parse(litersCtrl.text.trim());
                            final r = double.parse(rateCtrl.text.trim());
                            final p = double.parse(paidCtrl.text.trim());
                            if (isEdit) {
                              store.updateFuelSale(
                                existing.copyWith(
                                  date: selectedDate,
                                  purchaserId: selectedPurchaserId,
                                  fuel: selectedFuel,
                                  liters: l,
                                  rateUsed: r,
                                  paidNow: p,
                                  paymentMethod: selectedMethod,
                                  note: noteCtrl.text.trim(),
                                ),
                              );
                            } else {
                              store.addFuelSale(
                                purchaserId: selectedPurchaserId,
                                fuel: selectedFuel,
                                liters: l,
                                rateUsed: r,
                                paidNow: p,
                                paymentMethod: selectedMethod,
                                note: noteCtrl.text.trim(),
                                date: selectedDate,
                              );
                            }
                            Navigator.of(ctx).pop();
                            showErpSnackBar(
                              context,
                              isEdit
                                  ? tr(isUrdu, 'Fuel sale updated!',
                                      'تیل فروخت بل اپڈیٹ ہو گیا!')
                                  : tr(
                                      isUrdu,
                                      'Saved ${l.round()}L ${selectedFuel.key} @ Rs. ${r.round()}/L!',
                                      '${l.round()} لیٹر ${selectedFuel.label(true)} محفوظ ہو گیا!',
                                    ),
                            );
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            isEdit
                                ? tr(isUrdu, 'Update Sale', 'اپڈیٹ کریں')
                                : tr(isUrdu, 'Save Sale', 'بل محفوظ کریں'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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
