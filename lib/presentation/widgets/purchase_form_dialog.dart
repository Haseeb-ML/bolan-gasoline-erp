import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import 'common_widgets.dart';

Future<void> showPurchaseFormDialog(
  BuildContext context,
  ErpStore store, {
  FuelPurchase? existing,
  String? lockedSupplierId,
}) async {
  final isUrdu = store.isUrdu;
  final isEdit = existing != null;

  if (store.suppliers.isEmpty) {
    showErpSnackBar(
      context,
      tr(isUrdu, 'Please add a supplier first.',
          'پہلے کم از کم ایک سپلائر شامل کریں۔'),
    );
    return;
  }

  String selectedSupplierId = existing?.supplierId ??
      lockedSupplierId ??
      store.suppliers.first.id;
  if (store.findSupplier(selectedSupplierId) == null) {
    selectedSupplierId = store.suppliers.first.id;
  }

  FuelType selectedFuel = existing?.fuel ?? FuelType.petrol;
  String selectedMethod =
      ErpStore.normalizeMethod(existing?.paymentMethod ?? 'Cash');
  DateTime selectedDate = existing?.date ?? DateTime.now();
  final litersCtrl = TextEditingController(
      text: (existing?.liters ?? 5000).toStringAsFixed(0));
  final rateCtrl = TextEditingController(
      text: (existing?.rate ??
              store.fuelStocks[selectedFuel]!.lastPurchaseRate)
          .toStringAsFixed(0));
  final paidCtrl = TextEditingController(
      text: (existing?.paid ?? 1000000).toStringAsFixed(0));
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
                                tr(isUrdu, 'TANKER FUEL ARRIVAL',
                                    'نیا تیل آیا'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: erp.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit
                                    ? tr(isUrdu,
                                        'Edit Fuel Purchase (${existing.id})',
                                        'تیل خریداری ترمیم (${existing.id})')
                                    : tr(isUrdu,
                                        'Record Fuel Purchase from Supplier',
                                        'سپلائر سے آنے والے تیل کی انٹری'),
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
                      tr(isUrdu, 'Select Fuel Supplier',
                          'سپلائر منتخب کریں'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: erp.textMain),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSupplierId,
                      isExpanded: true,
                      items: store.suppliers
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.displayName(isUrdu),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: lockedSupplierId != null
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => selectedSupplierId = val);
                              }
                            },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(isUrdu, 'Fuel Unit', 'تیل کی قسم'),
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
                                    rateCtrl.text = store
                                        .fuelStocks[val]!.lastPurchaseRate
                                        .toStringAsFixed(0);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(isUrdu, 'Liters Received', 'کتنے لیٹر آیا؟'),
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
                                onChanged: (_) => setState(() {}),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(isUrdu, 'Purchase Rate / L (Rs.)',
                                    'خرید ریٹ فی لیٹر (روپے)'),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: erp.textMain),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: rateCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  final n = double.tryParse(v?.trim() ?? '');
                                  if (n == null || n <= 0) {
                                    return tr(isUrdu, 'Enter rate',
                                        'ریٹ درج کریں');
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(isUrdu, 'Paid to Supplier (Rs.)',
                                    'سپلائر کو ادا کردہ رقم'),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr(isUrdu, 'Payment Method (Cash / Bank Account)',
                          'ادائیگی کا طریقہ (کیش / بینک)'),
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
                      tr(isUrdu, 'Tanker / Slip Note', 'ٹینکر / پرچی نوٹ'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: erp.textMain),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        hintText: tr(isUrdu, 'e.g. Tanker #14 Karachi Dispatch',
                            'مثلاً ٹینکر نمبر 14 کراچی'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: erp.successSoft,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: erp.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr(isUrdu, 'Total Tanker Bill:', 'کل ٹینکر بل:'),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: erp.textMain),
                          ),
                          LtrText(
                            formatRs(total),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: erp.success,
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
                            backgroundColor: erp.success,
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
                              store.updateFuelPurchase(
                                existing.copyWith(
                                  date: selectedDate,
                                  supplierId: selectedSupplierId,
                                  fuel: selectedFuel,
                                  liters: l,
                                  rate: r,
                                  paid: p,
                                  paymentMethod: selectedMethod,
                                  note: noteCtrl.text.trim(),
                                ),
                              );
                            } else {
                              store.addFuelPurchase(
                                supplierId: selectedSupplierId,
                                fuel: selectedFuel,
                                liters: l,
                                rate: r,
                                paid: p,
                                paymentMethod: selectedMethod,
                                note: noteCtrl.text.trim(),
                                date: selectedDate,
                              );
                            }
                            Navigator.of(ctx).pop();
                            showErpSnackBar(
                              context,
                              isEdit
                                  ? tr(isUrdu, 'Purchase updated!',
                                      'خریداری اپڈیٹ ہو گئی!')
                                  : tr(isUrdu,
                                      'Fuel tank stock & supplier khata updated!',
                                      'تیل اسٹاک اور سپلائر کھاتہ اپڈیٹ ہو گیا!'),
                            );
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            isEdit
                                ? tr(isUrdu, 'Update Purchase', 'اپڈیٹ کریں')
                                : tr(isUrdu, 'Add to Tank Stock',
                                    'ٹینک اسٹاک میں جمع کریں'),
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
