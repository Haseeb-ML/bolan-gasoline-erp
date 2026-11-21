import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import 'common_widgets.dart';

Future<void> showPurchaserFormDialog(
  BuildContext context,
  ErpStore store, {
  Purchaser? existing,
}) async {
  final isUrdu = store.isUrdu;
  final isEdit = existing != null;
  final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
  final nameUrCtrl = TextEditingController(text: existing?.nameUr ?? '');
  final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
  final petrolCtrl = TextEditingController(
      text: (existing?.petrolRate ?? 260).toStringAsFixed(0));
  final dieselCtrl = TextEditingController(
      text: (existing?.dieselRate ?? 268).toStringAsFixed(0));
  final openingCtrl = TextEditingController(
      text: (existing?.openingBilled ?? 0).toStringAsFixed(0));
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final erp = ctx.erp;
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
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
                        child: Text(
                          isEdit
                              ? tr(isUrdu, 'Edit Purchaser Account',
                                  'پرچیزر اکاؤنٹ ترمیم کریں')
                              : tr(isUrdu, 'Add New Purchaser Account',
                                  'نیا پرچیزر اکاؤنٹ بنائیں'),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: erp.textMain),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  TextFormField(
                    controller: nameEnCtrl,
                    decoration: InputDecoration(
                      labelText: tr(isUrdu, 'Purchaser Name (English)',
                          'پرچیزر کا نام (انگلش)'),
                      hintText: 'e.g. Arsalan / Al-Bahr Launch',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? tr(isUrdu, 'Name is required', 'نام درج کریں')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameUrCtrl,
                    decoration: InputDecoration(
                      labelText: tr(isUrdu, 'Purchaser Name (Urdu - Optional)',
                          'پرچیزر کا نام (اردو - اختیاری)'),
                      hintText: 'مثلاً ارسلان',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: tr(isUrdu, 'Phone Number', 'فون نمبر'),
                      hintText: '0300-1234567',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: petrolCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: tr(isUrdu, 'Petrol Rate (Rs/L)',
                                'پٹرول ریٹ (روپے)'),
                          ),
                          validator: (v) {
                            final n = double.tryParse(v?.trim() ?? '');
                            return (n == null || n <= 0)
                                ? tr(isUrdu, 'Invalid', 'غلط')
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: dieselCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: tr(isUrdu, 'Diesel Rate (Rs/L)',
                                'ڈیزل ریٹ (روپے)'),
                          ),
                          validator: (v) {
                            final n = double.tryParse(v?.trim() ?? '');
                            return (n == null || n <= 0)
                                ? tr(isUrdu, 'Invalid', 'غلط')
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: openingCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr(isUrdu, 'Opening Balance Due (Rs.)',
                            'سابقہ بقایا کھاتہ (روپے)'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
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
                          final pr = double.parse(petrolCtrl.text.trim());
                          final dr = double.parse(dieselCtrl.text.trim());
                          if (isEdit) {
                            store.updatePurchaser(
                              existing.copyWith(
                                nameEn: nameEnCtrl.text.trim(),
                                nameUr: nameUrCtrl.text.trim().isEmpty
                                    ? nameEnCtrl.text.trim()
                                    : nameUrCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                petrolRate: pr,
                                dieselRate: dr,
                              ),
                            );
                          } else {
                            store.addPurchaser(
                              nameEn: nameEnCtrl.text.trim(),
                              nameUr: nameUrCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              petrolRate: pr,
                              dieselRate: dr,
                              openingBalance:
                                  double.tryParse(openingCtrl.text.trim()) ?? 0,
                            );
                          }
                          Navigator.of(ctx).pop();
                          showErpSnackBar(
                            context,
                            isEdit
                                ? tr(isUrdu, 'Purchaser updated!',
                                    'پرچیزر اپڈیٹ ہو گیا!')
                                : tr(isUrdu, 'New purchaser added!',
                                    'نیا پرچیزر شامل ہو گیا!'),
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(isEdit
                            ? tr(isUrdu, 'Update', 'اپڈیٹ کریں')
                            : tr(isUrdu, 'Save Purchaser', 'محفوظ کریں')),
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
  );
}

Future<void> showSupplierFormDialog(
  BuildContext context,
  ErpStore store, {
  FuelSupplier? existing,
}) async {
  final isUrdu = store.isUrdu;
  final isEdit = existing != null;
  final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
  final nameUrCtrl = TextEditingController(text: existing?.nameUr ?? '');
  final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
  final openingCtrl = TextEditingController(
      text: (existing?.openingPurchased ?? 0).toStringAsFixed(0));
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final erp = ctx.erp;
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
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
                        child: Text(
                          isEdit
                              ? tr(isUrdu, 'Edit Supplier', 'سپلائر ترمیم کریں')
                              : tr(isUrdu, 'Add New Supplier',
                                  'نیا سپلائر شامل کریں'),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: erp.textMain),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  TextFormField(
                    controller: nameEnCtrl,
                    decoration: InputDecoration(
                      labelText: tr(isUrdu, 'Supplier Name (English)',
                          'سپلائر کا نام (انگلش)'),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? tr(isUrdu, 'Name required', 'نام درج کریں')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameUrCtrl,
                    decoration: InputDecoration(
                      labelText: tr(isUrdu, 'Supplier Name (Urdu - Optional)',
                          'سپلائر کا نام (اردو - اختیاری)'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: tr(isUrdu, 'Phone Number', 'فون نمبر'),
                    ),
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: openingCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr(isUrdu, 'Opening Payable Balance (Rs.)',
                            'سابقہ بقایا ادائیگی (روپے)'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
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
                          if (isEdit) {
                            store.updateSupplier(
                              existing.copyWith(
                                nameEn: nameEnCtrl.text.trim(),
                                nameUr: nameUrCtrl.text.trim().isEmpty
                                    ? nameEnCtrl.text.trim()
                                    : nameUrCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                              ),
                            );
                          } else {
                            store.addSupplier(
                              nameEn: nameEnCtrl.text.trim(),
                              nameUr: nameUrCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              openingBalance:
                                  double.tryParse(openingCtrl.text.trim()) ?? 0,
                            );
                          }
                          Navigator.of(ctx).pop();
                          showErpSnackBar(
                            context,
                            isEdit
                                ? tr(isUrdu, 'Supplier updated!',
                                    'سپلائر اپڈیٹ ہو گیا!')
                                : tr(isUrdu, 'Supplier added!',
                                    'نیا سپلائر شامل ہو گیا!'),
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(isEdit
                            ? tr(isUrdu, 'Update', 'اپڈیٹ کریں')
                            : tr(isUrdu, 'Save Supplier', 'محفوظ کریں')),
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
  );
}

Future<void> showExpenseFormDialog(
  BuildContext context,
  ErpStore store, {
  PumpExpense? existing,
}) async {
  final isUrdu = store.isUrdu;
  final isEdit = existing != null;

  if (existing != null &&
      !store.expenseCategories.any((c) => c['en'] == existing.categoryEn)) {
    store.addExpenseCategory(existing.categoryEn, nameUr: existing.categoryUr);
  }

  String selectedCatEn = existing?.categoryEn ??
      (store.expenseCategories.isNotEmpty
          ? store.expenseCategories.first['en']!
          : 'Pump Misc Expense');

  bool showAddCatBox = false;
  final newCatCtrl = TextEditingController();

  final titleCtrl = TextEditingController(
      text: existing != null
          ? existing.title(isUrdu)
          : tr(isUrdu, 'Pump Attendant Salary / Advance',
              'پمپ کے لڑکے کی تنخواہ / ایڈوانس'));
  final amountCtrl = TextEditingController(
      text: (existing?.amount ?? 15000).toStringAsFixed(0));
  String selectedMethod =
      ErpStore.normalizeMethod(existing?.paymentMethod ?? 'Cash');
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final erp = ctx.erp;
        final categories = store.expenseCategories;
        if (!categories.any((c) => c['en'] == selectedCatEn) &&
            categories.isNotEmpty) {
          selectedCatEn = categories.first['en']!;
        }

        void submitNewCategory() {
          final raw = newCatCtrl.text.trim();
          if (raw.isEmpty) return;
          final addedKey = store.addExpenseCategory(raw, nameUr: raw);
          setState(() {
            selectedCatEn = addedKey;
            newCatCtrl.clear();
            showAddCatBox = false;
          });
        }

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
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
                          child: Text(
                            isEdit
                                ? tr(isUrdu, 'Edit Expense / Salary',
                                    'خرچہ / تنخواہ ترمیم کریں')
                                : tr(isUrdu, 'Add Expense or Staff Salary',
                                    'نیا خرچہ یا لڑکوں کی تنخواہ درج کریں'),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: erp.textMain),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                                '${categories.length}_$selectedCatEn'),
                            initialValue: selectedCatEn,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: tr(isUrdu, 'Category', 'قسم / مد'),
                            ),
                            items: categories
                                .map((c) => DropdownMenuItem<String>(
                                      value: c['en']!,
                                      child: Text(
                                        isUrdu ? (c['ur'] ?? c['en']!) : c['en']!,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => selectedCatEn = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: erp.primarySoft,
                            foregroundColor: erp.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () =>
                              setState(() => showAddCatBox = !showAddCatBox),
                          icon: Icon(
                            showAddCatBox
                                ? Icons.close_rounded
                                : Icons.add_rounded,
                            size: 18,
                          ),
                          label: Text(
                            tr(isUrdu, 'New', 'نیا'),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    if (showAddCatBox) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: erp.primarySoft.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: erp.primaryBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: newCatCtrl,
                                autofocus: true,
                                onSubmitted: (_) => submitNewCategory(),
                                decoration: InputDecoration(
                                  isDense: true,
                                  fillColor: erp.cardBg,
                                  hintText: tr(
                                    isUrdu,
                                    'e.g. Tea/Food, Rent, Nozzle Repair...',
                                    'مثلاً چائے کھانا، کرایہ، نوزل مرمت...',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: erp.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: submitNewCategory,
                              child: Text(
                                tr(isUrdu, 'Add', 'شامل کریں'),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: tr(isUrdu, 'Description / Detail', 'تفصیل'),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? tr(isUrdu, 'Enter detail', 'تفصیل درج کریں')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr(isUrdu, 'Amount (Rs.)', 'رقم (روپے)'),
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
                    const SizedBox(height: 20),
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
                            backgroundColor: erp.danger,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final catMap = categories.firstWhere(
                              (c) => c['en'] == selectedCatEn,
                              orElse: () => {
                                'en': selectedCatEn,
                                'ur': selectedCatEn,
                              },
                            );
                            final amt = double.parse(amountCtrl.text.trim());
                            final detail = titleCtrl.text.trim();
                            if (isEdit) {
                              store.updateExpense(
                                existing.copyWith(
                                  categoryEn: catMap['en']!,
                                  categoryUr: catMap['ur'] ?? catMap['en']!,
                                  titleEn: detail,
                                  titleUr: detail,
                                  amount: amt,
                                  paymentMethod: selectedMethod,
                                ),
                              );
                            } else {
                              store.addExpense(
                                categoryEn: catMap['en']!,
                                categoryUr: catMap['ur'] ?? catMap['en']!,
                                titleEn: detail,
                                titleUr: detail,
                                amount: amt,
                                paymentMethod: selectedMethod,
                              );
                            }
                            Navigator.of(ctx).pop();
                            showErpSnackBar(
                              context,
                              isEdit
                                  ? tr(isUrdu, 'Expense updated!',
                                      'خرچہ اپڈیٹ ہو گیا!')
                                  : tr(isUrdu, 'Expense saved!',
                                      'خرچہ محفوظ ہو گیا!'),
                            );
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(isEdit
                              ? tr(isUrdu, 'Update', 'اپڈیٹ کریں')
                              : tr(isUrdu, 'Save Expense', 'محفوظ کریں')),
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

Future<void> showLedgerPaymentDialog(
  BuildContext context,
  ErpStore store, {
  required String partyType, // 'purchaser' | 'supplier'
  required String partyId,
  LedgerPayment? existing,
}) async {
  final isUrdu = store.isUrdu;
  final isPurchaser = partyType == 'purchaser';
  final isEdit = existing != null;

  final partyName = isPurchaser
      ? (store.findPurchaser(partyId)?.displayName(isUrdu) ?? partyId)
      : (store.findSupplier(partyId)?.displayName(isUrdu) ?? partyId);
  final currentBal = isPurchaser
      ? store.purchaserSummary(partyId).balance
      : store.supplierSummary(partyId).balance;

  final amountCtrl = TextEditingController(
    text: (existing?.amount ?? (currentBal > 0 ? currentBal : 10000))
        .toStringAsFixed(0),
  );
  final noteCtrl = TextEditingController(text: existing?.note ?? '');
  String method = existing?.method ?? 'Cash';
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final erp = ctx.erp;
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
                        Expanded(
                          child: Text(
                            isEdit
                                ? tr(isUrdu, 'Edit Payment', 'رقم ترمیم کریں')
                                : (isPurchaser
                                    ? tr(isUrdu,
                                        'Receive Cash from Purchaser',
                                        'پرچیزر سے رقم وصول کریں')
                                    : tr(isUrdu, 'Pay Balance to Supplier',
                                        'سپلائر کو رقم ادا کریں')),
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: erp.textMain),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: erp.subtleBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: erp.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(partyName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: erp.textMain)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${tr(isUrdu, 'Current Balance:', 'موجودہ بقایا:')} ',
                                style: TextStyle(
                                    fontSize: 12, color: erp.textMuted),
                              ),
                              LtrText(
                                formatRs(currentBal),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: erp.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr(isUrdu, 'Amount (Rs.)', 'رقم (روپے)'),
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
                    DropdownButtonFormField<String>(
                      initialValue: method,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText:
                            tr(isUrdu, 'Payment Method', 'ادائیگی کا طریقہ'),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Cash',
                            child: Text('Cash / نقد',
                                overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'Bank',
                            child: Text('Bank Transfer / بینک',
                                overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'Online',
                            child: Text('Easypaisa / JazzCash / آن لائن',
                                overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => method = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        labelText:
                            tr(isUrdu, 'Note (Optional)', 'نوٹ (اختیاری)'),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                            backgroundColor:
                                isPurchaser ? erp.success : erp.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final amt = double.parse(amountCtrl.text.trim());
                            if (isEdit) {
                              store.updateLedgerPayment(
                                existing.copyWith(
                                  amount: amt,
                                  method: method,
                                  note: noteCtrl.text.trim(),
                                ),
                              );
                            } else {
                              store.addLedgerPayment(
                                partyType: partyType,
                                partyId: partyId,
                                amount: amt,
                                method: method,
                                note: noteCtrl.text.trim(),
                              );
                            }
                            Navigator.of(ctx).pop();
                            showErpSnackBar(
                              context,
                              tr(isUrdu, 'Khata balance updated!',
                                  'کھاتہ بیلنس اپڈیٹ ہو گیا!'),
                            );
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(tr(isUrdu, 'Save Payment', 'محفوظ کریں')),
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

Future<void> showTankSettingsDialog(
  BuildContext context,
  ErpStore store,
  FuelStock stock,
) async {
  final isUrdu = store.isUrdu;
  final capCtrl =
      TextEditingController(text: stock.capacityLiters.toStringAsFixed(0));
  final remCtrl =
      TextEditingController(text: stock.remainingLiters.toStringAsFixed(0));
  final cashRateCtrl =
      TextEditingController(text: stock.cashSaleRate.toStringAsFixed(0));
  final purRateCtrl =
      TextEditingController(text: stock.lastPurchaseRate.toStringAsFixed(0));
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final erp = ctx.erp;
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
                  Text(
                    '${stock.type.label(isUrdu)} — ${tr(isUrdu, 'Tank Settings', 'ٹینک سیٹنگز')}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: erp.textMain),
                  ),
                  const Divider(height: 20),
                  TextFormField(
                    controller: remCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr(
                          isUrdu, 'Remaining Stock (Liters)', 'موجودہ تیل (لیٹر)'),
                    ),
                    validator: (v) =>
                        (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: capCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr(
                          isUrdu, 'Tank Capacity (Liters)', 'ٹینک گنجائش (لیٹر)'),
                    ),
                    validator: (v) =>
                        (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: purRateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                tr(isUrdu, 'Purchase Rate', 'خرید ریٹ'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: cashRateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: tr(isUrdu, 'Cash Sale Rate', 'کیش ریٹ'),
                          ),
                        ),
                      ),
                    ],
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
                      FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          store.updateTankSettings(
                            stock.copyWith(
                              remainingLiters: double.parse(remCtrl.text.trim()),
                              capacityLiters: double.parse(capCtrl.text.trim()),
                              lastPurchaseRate:
                                  double.tryParse(purRateCtrl.text.trim()) ??
                                      stock.lastPurchaseRate,
                              cashSaleRate:
                                  double.tryParse(cashRateCtrl.text.trim()) ??
                                      stock.cashSaleRate,
                            ),
                          );
                          Navigator.of(ctx).pop();
                          showErpSnackBar(
                            context,
                            tr(isUrdu, 'Tank settings updated!',
                                'ٹینک سیٹنگز اپڈیٹ ہو گئیں!'),
                          );
                        },
                        child: Text(tr(isUrdu, 'Save', 'محفوظ کریں')),
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
  );
}
