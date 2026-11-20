import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bolan_gasoline_erp/core/storage/firestore_sync.dart';
import 'package:bolan_gasoline_erp/core/storage/local_storage_stub.dart';
import 'package:bolan_gasoline_erp/data/models/erp_models.dart';
import 'package:bolan_gasoline_erp/data/repository/erp_store.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  test('LIVE Firebase Cloud Firestore — Rapid Multi-Entry CRUD & Multi-Device Sync', () async {
    HttpOverrides.global = _RealHttpOverrides();
    final cloud = FirestoreSyncService(enabled: true);

    // 1. Device A loads LIVE state & cleans any prior QA records if present
    final deviceA = ErpStore(storage: MemoryStorageAdapter(), cloudSync: cloud);
    await deviceA.init();
    expect(deviceA.isCloudConnected, isTrue);

    final oldQaSales = deviceA.sales.where((s) => s.note.contains('QA_LIVE_')).map((s) => s.id).toList();
    if (oldQaSales.isNotEmpty) deviceA.deleteFuelSales(oldQaSales);
    final oldQaPur = deviceA.purchases.where((p) => p.note.contains('QA_LIVE_')).map((p) => p.id).toList();
    if (oldQaPur.isNotEmpty) deviceA.deleteFuelPurchases(oldQaPur);
    final oldQaPay = deviceA.payments.where((p) => p.note.contains('QA_LIVE_')).map((p) => p.id).toList();
    if (oldQaPay.isNotEmpty) deviceA.deleteLedgerPayments(oldQaPay);
    final oldQaExp = deviceA.expenses.where((e) => e.titleEn.contains('QA_LIVE_')).map((e) => e.id).toList();
    if (oldQaExp.isNotEmpty) deviceA.deleteExpenses(oldQaExp);
    final oldQaBuyers = deviceA.purchasers.where((p) => p.nameEn == 'QA Live Test Buyer').map((p) => p.id).toList();
    if (oldQaBuyers.isNotEmpty) deviceA.deletePurchasers(oldQaBuyers);
    final oldQaSups = deviceA.suppliers.where((s) => s.nameEn == 'QA Live Test Supplier').map((s) => s.id).toList();
    if (oldQaSups.isNotEmpty) deviceA.deleteSuppliers(oldQaSups);
    await deviceA.flushCloudSync();

    final origPetrol = deviceA.fuelStocks[FuelType.petrol]!.remainingLiters;
    final origDiesel = deviceA.fuelStocks[FuelType.diesel]!.remainingLiters;

    // 2. Rapid back-to-back entries (testing our serialized cloud push queue!)
    final newPurchaser = deviceA.addPurchaser(
      nameEn: 'QA Live Test Buyer',
      nameUr: 'کیو اے ٹیسٹ خریدار',
      phone: '0300-9999999',
      petrolRate: 260,
      dieselRate: 269,
    );
    final newSupplier = deviceA.addSupplier(
      nameEn: 'QA Live Test Supplier',
      nameUr: 'کیو اے ٹیسٹ سپلائر',
      phone: '0321-9999999',
    );
    deviceA.addFuelSale(
      purchaserId: newPurchaser.id,
      fuel: FuelType.diesel,
      liters: 100,
      rateUsed: 269,
      paidNow: 10000,
      note: 'QA_LIVE_SALE_CHECK',
    );
    final createdSale = deviceA.sales.first;
    deviceA.addFuelPurchase(
      supplierId: newSupplier.id,
      fuel: FuelType.petrol,
      liters: 500,
      rate: 245,
      paid: 50000,
      note: 'QA_LIVE_PURCHASE_CHECK',
    );
    final createdPurchase = deviceA.purchases.first;
    deviceA.addLedgerPayment(
      partyType: 'purchaser',
      partyId: newPurchaser.id,
      amount: 5000,
      method: 'Cash',
      note: 'QA_LIVE_PAYMENT_CHECK',
    );
    final createdPayment = deviceA.payments.first;
    deviceA.addExpense(
      categoryEn: 'Pump Misc Expense',
      categoryUr: 'دیگر پمپ اخراجات',
      titleEn: 'QA_LIVE_EXPENSE_CHECK',
      titleUr: 'کیو اے خرچہ',
      amount: 1200,
    );
    final createdExpense = deviceA.expenses.first;
    await deviceA.flushCloudSync();

    // 3. Brand-new Device B loads from LIVE Firebase Firestore and verifies EVERY entry!
    final deviceB = ErpStore(storage: MemoryStorageAdapter(), cloudSync: cloud);
    await deviceB.init();

    expect(deviceB.isCloudConnected, isTrue);
    expect(deviceB.findPurchaser(newPurchaser.id)?.nameEn, 'QA Live Test Buyer');
    expect(deviceB.findSupplier(newSupplier.id)?.nameEn, 'QA Live Test Supplier');
    expect(deviceB.sales.any((s) => s.id == createdSale.id && s.note == 'QA_LIVE_SALE_CHECK'), isTrue);
    expect(deviceB.purchases.any((p) => p.id == createdPurchase.id && p.note == 'QA_LIVE_PURCHASE_CHECK'), isTrue);
    expect(deviceB.payments.any((p) => p.id == createdPayment.id && p.note == 'QA_LIVE_PAYMENT_CHECK'), isTrue);
    expect(deviceB.expenses.any((e) => e.id == createdExpense.id && e.titleEn == 'QA_LIVE_EXPENSE_CHECK'), isTrue);
    expect(deviceB.fuelStocks[FuelType.diesel]!.remainingLiters, origDiesel - 100);
    expect(deviceB.fuelStocks[FuelType.petrol]!.remainingLiters, origPetrol + 500);
    expect(deviceB.purchaserLedgerHistory(newPurchaser.id).length, 2);
    expect(deviceB.purchaserSummary(newPurchaser.id).balance, 26900 - 10000 - 5000);

    // 4. EDIT on Device B -> verify Device C sees the Edit live!
    deviceB.updateFuelSale(createdSale.copyWith(liters: 150));
    await deviceB.flushCloudSync();

    final deviceC = ErpStore(storage: MemoryStorageAdapter(), cloudSync: cloud);
    await deviceC.init();
    expect(deviceC.sales.firstWhere((s) => s.id == createdSale.id).liters, 150);
    expect(deviceC.fuelStocks[FuelType.diesel]!.remainingLiters, origDiesel - 150);

    // 5. DELETE all QA test entries on Device C -> verify Device D sees clean live DB & restored stocks!
    deviceC.deleteFuelSales([createdSale.id]);
    deviceC.deleteFuelPurchases([createdPurchase.id]);
    deviceC.deleteLedgerPayments([createdPayment.id]);
    deviceC.deleteExpenses([createdExpense.id]);
    deviceC.deletePurchasers([newPurchaser.id]);
    deviceC.deleteSuppliers([newSupplier.id]);
    await deviceC.flushCloudSync();

    final deviceD = ErpStore(storage: MemoryStorageAdapter(), cloudSync: cloud);
    await deviceD.init();
    expect(deviceD.findPurchaser(newPurchaser.id), isNull);
    expect(deviceD.findSupplier(newSupplier.id), isNull);
    expect(deviceD.sales.any((s) => s.id == createdSale.id), isFalse);
    expect(deviceD.purchases.any((p) => p.id == createdPurchase.id), isFalse);
    expect(deviceD.expenses.any((e) => e.id == createdExpense.id), isFalse);
    expect(deviceD.fuelStocks[FuelType.diesel]!.remainingLiters, origDiesel);
    expect(deviceD.fuelStocks[FuelType.petrol]!.remainingLiters, origPetrol);

    deviceA.dispose();
    deviceB.dispose();
    deviceC.dispose();
    deviceD.dispose();
  });
}
