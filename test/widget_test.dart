import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bolan_gasoline_erp/core/storage/local_storage_stub.dart';
import 'package:bolan_gasoline_erp/core/theme/app_theme.dart';
import 'package:bolan_gasoline_erp/data/models/erp_models.dart';
import 'package:bolan_gasoline_erp/data/repository/erp_store.dart';
import 'package:bolan_gasoline_erp/main.dart';

void main() {
  group('Bolan Gasoline ERP — Full Accounting & CRUD Tests', () {
    test('Fuel Sale Add, Edit & Bulk Delete accurately updates tank stock and purchaser khata', () {
      final store = ErpStore(
        storage: MemoryStorageAdapter(),
        autoLoginOwner: true,
      );
      final initialDiesel = store.fuelStocks[FuelType.diesel]!.remainingLiters;
      final initialArsalan = store.purchaserSummary('PR-00');

      // 1. Add Sale for Arsalan (500 L @ Rs. 270 = 135,000, paid 35,000 -> due 100,000)
      store.addFuelSale(
        purchaserId: 'PR-00',
        fuel: FuelType.diesel,
        liters: 500,
        rateUsed: 270,
        paidNow: 35000,
        note: 'Test Morning Boat',
      );

      expect(store.fuelStocks[FuelType.diesel]!.remainingLiters, initialDiesel - 500);
      final afterAdd = store.purchaserSummary('PR-00');
      expect(afterAdd.totalBilled, initialArsalan.totalBilled + 135000);
      expect(afterAdd.totalPaid, initialArsalan.totalPaid + 35000);
      expect(afterAdd.balance, initialArsalan.balance + 100000);

      // Verify personal ledger history includes the new sale
      final history = store.purchaserLedgerHistory('PR-00');
      expect(history.any((r) => r.detailEn == 'Test Morning Boat'), isTrue);

      // 2. Edit Sale to 600 L @ Rs. 270 = 162,000
      final createdSale = store.sales.first;
      store.updateFuelSale(createdSale.copyWith(liters: 600));
      expect(store.fuelStocks[FuelType.diesel]!.remainingLiters, initialDiesel - 600);

      // 3. Bulk Delete Sale -> restores stock and balance
      store.deleteFuelSales([createdSale.id]);
      expect(store.fuelStocks[FuelType.diesel]!.remainingLiters, initialDiesel);
      expect(store.purchaserSummary('PR-00').balance, initialArsalan.balance);
    });

    test('Fuel Purchase, Supplier Ledger, Payments & Expenses CRUD', () {
      final store = ErpStore(
        storage: MemoryStorageAdapter(),
        autoLoginOwner: true,
      );
      final initialPetrol = store.fuelStocks[FuelType.petrol]!.remainingLiters;

      // Add Purchase
      store.addFuelPurchase(
        supplierId: 'SUP-01',
        fuel: FuelType.petrol,
        liters: 4000,
        rate: 250,
        paid: 600000,
      );
      expect(store.fuelStocks[FuelType.petrol]!.remainingLiters, initialPetrol + 4000);

      // Pay Supplier
      final supBeforePay = store.supplierSummary('SUP-01').balance;
      store.addLedgerPayment(
        partyType: 'supplier',
        partyId: 'SUP-01',
        amount: 100000,
        method: 'Bank',
        note: 'Bank transfer',
      );
      expect(store.supplierSummary('SUP-01').balance, supBeforePay - 100000);

      // Delete Purchase -> reverses tank stock
      final purId = store.purchases.first.id;
      store.deleteFuelPurchases([purId]);
      expect(store.fuelStocks[FuelType.petrol]!.remainingLiters, initialPetrol);

      // Add, Edit, Bulk Delete Expenses
      final expCount = store.expenses.length;
      store.addExpense(
        categoryEn: 'Pump Staff Salaries',
        categoryUr: 'پمپ لڑکوں کی تنخواہیں',
        titleEn: 'Bonus for Attendant',
        titleUr: 'بونس',
        amount: 5000,
      );
      expect(store.expenses.length, expCount + 1);
      final exp = store.expenses.first;
      store.updateExpense(exp.copyWith(amount: 7500));
      expect(store.expenses.first.amount, 7500);
      store.deleteExpenses([exp.id]);
      expect(store.expenses.length, expCount);
    });

    test('Owner/Employee RBAC + Zero-Zero Reset + JSON Export & Import Backup', () {
      final store = ErpStore(storage: MemoryStorageAdapter());
      expect(store.isLoggedIn, isFalse);

      // Wrong password rejected
      expect(store.login('owner', 'wrong'), isNotNull);
      expect(store.isLoggedIn, isFalse);

      // Employee login auto-detects limited role
      expect(store.login('staff', '1234'), isNull);
      expect(store.isOwner, isFalse);
      expect(store.canAccessModule(ErpModule.sales), isTrue);
      expect(store.canAccessModule(ErpModule.settings), isFalse);
      expect(store.canDelete, isFalse);

      // Logout & login as Owner
      store.logout();
      expect(store.isLoggedIn, isFalse);
      expect(store.login('owner', '1234'), isNull);
      expect(store.isOwner, isTrue);
      expect(store.canAccessModule(ErpModule.settings), isTrue);
      expect(store.canDelete, isTrue);

      // Export full backup JSON + Sales CSV
      final backupJson = store.exportBackupJson();
      final salesCsv = store.exportSalesCsv();
      expect(backupJson.contains('Bolan Gasoline ERP'), isTrue);
      expect(salesCsv.contains('Bill ID,Date,Purchaser'), isTrue);

      // Reset All Data to Zero (0-0)
      store.resetAllDataToZero();
      expect(store.sales, isEmpty);
      expect(store.purchases, isEmpty);
      expect(store.creditPurchasers, isEmpty);
      expect(store.suppliers, isEmpty);
      expect(store.expenses, isEmpty);
      expect(store.fuelStocks[FuelType.petrol]!.remainingLiters, 0);
      expect(store.fuelStocks[FuelType.diesel]!.remainingLiters, 0);

      // Import Backup JSON restores everything cleanly!
      expect(store.importBackupJson(backupJson), isNull);
      expect(store.sales, isNotEmpty);
      expect(store.creditPurchasers, isNotEmpty);
      expect(store.fuelStocks[FuelType.petrol]!.remainingLiters, greaterThan(0));

      // Audio 5 Exact Example: Reset to 0-0, then purchase 200L@200 + 200L@250 + 200L@160
      store.resetAllDataToZero();
      final sup = store.addSupplier(
        nameEn: 'Test Tanker Co',
        nameUr: 'ٹیسٹ ٹینکر',
        phone: '0300-0000000',
      );
      store.addFuelPurchase(
        supplierId: sup.id,
        fuel: FuelType.petrol,
        liters: 200,
        rate: 200,
        paid: 40000,
      );
      store.addFuelPurchase(
        supplierId: sup.id,
        fuel: FuelType.petrol,
        liters: 200,
        rate: 250,
        paid: 50000,
      );
      store.addFuelPurchase(
        supplierId: sup.id,
        fuel: FuelType.petrol,
        liters: 200,
        rate: 160,
        paid: 32000,
      );
      expect(store.fuelStocks[FuelType.petrol]!.remainingLiters, 600);
      expect(store.fuelStockValueRs(FuelType.petrol), 122000);
    });
  });

  group('Bolan Gasoline ERP — Zero-Overflow UI Tests (Desktop & Mobile, EN & UR)', () {
    Future<void> pumpAllModulesAndThemes(
      WidgetTester tester,
      Size surfaceSize,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = surfaceSize;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final store = ErpStore(
        storage: MemoryStorageAdapter(),
        autoLoginOwner: true,
      );

      await tester.pumpWidget(BolanGasolineApp(store: store));
      await tester.pumpAndSettle();

      // Verify zero overflow across all 6 modules in English
      for (final mod in ErpModule.values) {
        store.setModule(mod);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'Exception in EN ${mod.name} at $surfaceSize');
      }

      // Switch to Urdu RTL and verify all 6 modules
      store.toggleLanguage();
      await tester.pumpAndSettle();
      for (final mod in ErpModule.values) {
        store.setModule(mod);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'Exception in UR ${mod.name} at $surfaceSize');
      }

      // Switch through all 6 Themes
      for (final theme in ErpThemeId.values) {
        store.setTheme(theme);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'Exception in theme ${theme.name} at $surfaceSize');
      }

      // Open Arsalan's Personal Account Ledger History screen
      store.toggleLanguage(); // back to EN
      store.setModule(ErpModule.purchasers);
      await tester.pumpAndSettle();
      final arsalanFinder = find.text('Arsalan (Daily Purchaser)');
      await tester.ensureVisible(arsalanFinder);
      await tester.pumpAndSettle();
      await tester.tap(arsalanFinder);
      await tester.pumpAndSettle();
      expect(find.textContaining('Complete Account History'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    testWidgets('Desktop 1440x900 — All 6 modules, 6 themes, EN/UR & Personal Ledger',
        (tester) async {
      await pumpAllModulesAndThemes(tester, const Size(1440, 900));
    });

    testWidgets('Mobile 390x844 — All 6 modules, 6 themes, EN/UR & Personal Ledger',
        (tester) async {
      await pumpAllModulesAndThemes(tester, const Size(390, 844));
    });
  });
}
