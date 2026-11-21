import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bolan_gasoline_erp/core/storage/local_storage_stub.dart';
import 'package:bolan_gasoline_erp/core/utils/pdf_generator.dart';
import 'package:bolan_gasoline_erp/data/models/erp_models.dart';
import 'package:bolan_gasoline_erp/data/repository/erp_store.dart';
import 'package:bolan_gasoline_erp/main.dart';

void main() {
  testWidgets('100% Full System E2E: Login, Employee RBAC, Owner Admin, Zero-Zero Reset, Custom Category & Zero Overflow', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = ErpStore(storage: MemoryStorageAdapter());
    await tester.pumpWidget(BolanGasolineApp(store: store));
    await tester.pumpAndSettle();

    // 1. Login Screen renders cleanly on Desktop EN & UR + Mobile 360x800
    expect(find.text('Sign In to ERP'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Check Login Screen in Urdu
    store.toggleLanguage();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    store.toggleLanguage(); // back to EN
    await tester.pumpAndSettle();

    // Check Login Screen on small Mobile 360x800
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();

    // 2. Test wrong password error message
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'owner');
    await tester.enterText(fields.at(1), '0000');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid username or password'), findsOneWidget);
    expect(store.isLoggedIn, isFalse);

    // 3. Login as Employee (staff / 1234)
    await tester.enterText(fields.at(0), 'staff');
    await tester.enterText(fields.at(1), '1234');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(store.isLoggedIn, isTrue);
    expect(store.isOwner, isFalse);

    // Verify restricted modules AND restricted KPI cards are HIDDEN from Employee!
    expect(find.text('Roles & Data Backup'), findsNothing);
    expect(find.text('Suppliers Ledger'), findsNothing);
    expect(find.text('Expenses & Salaries'), findsNothing);
    expect(find.textContaining('Sup:'), findsNothing);
    store.setModule(ErpModule.settings); // attempt bypass
    expect(store.activeModule, isNot(ErpModule.settings));

    // Employee goes to Sales -> Edit/Delete buttons & Bulk Delete bar must NOT show, but View icon MUST show & work!
    store.setModule(ErpModule.sales);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    final viewBtn = find.byIcon(Icons.visibility_outlined).first;
    await tester.ensureVisible(viewBtn);
    await tester.pumpAndSettle();
    await tester.tap(viewBtn);
    await tester.pumpAndSettle();
    expect(find.text('Fuel Sale Bill Receipt'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
    await tester.tap(find.text('Download PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 4. Logout via UI Logout button -> returns to Login Screen
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    expect(store.isLoggedIn, isFalse);
    expect(find.text('Sign In to ERP'), findsOneWidget);

    // 5. Login as Owner (owner / 1234)
    final ownerFields = find.byType(TextField);
    await tester.enterText(ownerFields.at(0), 'owner');
    await tester.enterText(ownerFields.at(1), '1234');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(store.isOwner, isTrue);
    expect(find.text('Roles & Data Backup'), findsOneWidget);

    // 5b. Verify Audio 5 feature: Dashboard shows Stock Value (Rs.) alongside Liters!
    store.setModule(ErpModule.dashboard);
    await tester.pumpAndSettle();
    expect(store.fuelStockValueRs(FuelType.petrol), greaterThan(0));
    expect(store.fuelStockValueRs(FuelType.diesel), greaterThan(0));
    expect(find.textContaining('Value: Rs.'), findsWidgets);

    // 5c. Verify PDF Generator produces valid Adobe PDF 1.4 binary with UNTRUNCATED Balance Due + test Download Report across all modules!
    final samplePdf = ErpPdfGenerator.buildTableReportPdf(
      reportTitle: 'PURCHASER PERSONAL KHATA STATEMENT',
      subtitle: 'Period: ALL',
      summaryItems: const [
        'Total Liters: 1200 L',
        'Total Billed: Rs. 319200',
        'Total Paid: Rs. 200000',
        'Balance Due: Rs. 225000',
      ],
      headers: const ['ID', 'NAME', 'AMOUNT'],
      rows: const [
        ['S-1001', 'Arsalan', 'Rs. 50,000'],
      ],
    );
    final pdfHeader = String.fromCharCodes(samplePdf.take(8));
    final pdfText = String.fromCharCodes(samplePdf);
    expect(pdfHeader, '%PDF-1.4');
    expect(pdfText.contains('BOLAN GASOLINE'), isTrue);
    expect(pdfText.contains('Total Paid: Rs. 200000'), isTrue);
    expect(pdfText.contains('Balance Due: Rs. 225000'), isTrue);
    expect(pdfText.trimRight().endsWith('%%EOF'), isTrue);

    // Test "Download Report" -> 2 options ("Download PDF (.pdf)" & "Download Excel (.csv)") on Sales, Purchases, Expenses, Purchasers, Suppliers & Cash/Bank screens
    for (final mod in [
      ErpModule.sales,
      ErpModule.purchases,
      ErpModule.expenses,
      ErpModule.purchasers,
      ErpModule.suppliers,
      ErpModule.cashBank,
    ]) {
      store.setModule(mod);
      await tester.pumpAndSettle();
      expect(find.text('Download Report'), findsOneWidget,
          reason: 'Missing Download Report button on ${mod.name}');
      await tester.tap(find.text('Download Report'));
      await tester.pumpAndSettle();
      expect(find.text('Download PDF (.pdf)'), findsOneWidget);
      expect(find.text('Download Excel (.csv)'), findsOneWidget);
      await tester.tap(find.text('Download PDF (.pdf)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download Report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download Excel (.csv)'));
      await tester.pumpAndSettle();
      // Verify In-App Excel Sheet Viewer opens inside the software with Download & Close buttons!
      expect(find.text('Download Excel File (.csv)'), findsOneWidget);
      await tester.tap(find.text('Download Excel File (.csv)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    // Test Purchaser Detail Screen Period Filters (including Today) + Mobile 360x800 + Download Report (PDF & Excel options)
    store.setModule(ErpModule.purchasers);
    await tester.pumpAndSettle();
    final arsalanRow = find.text('Arsalan (Daily Purchaser)');
    await tester.ensureVisible(arsalanRow);
    await tester.tap(arsalanRow);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Download Report'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download Report'));
    await tester.pumpAndSettle();
    expect(find.text('Download PDF (.pdf)'), findsOneWidget);
    expect(find.text('Download Excel (.csv)'), findsOneWidget);
    await tester.tap(find.text('Download PDF (.pdf)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download Excel (.csv)'));
    await tester.pumpAndSettle();
    expect(find.text('Download Excel File (.csv)'), findsOneWidget);
    await tester.tap(find.text('Download Excel File (.csv)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Verify Purchaser Detail Screen on Mobile 360x800 (EN & UR) with zero overflow!
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    store.toggleLanguage(); // Urdu RTL on Mobile 360x800
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    store.toggleLanguage(); // Back to EN
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Test Supplier Detail Screen Period Filters (including Today) + Mobile 360x800 + Download Report (PDF & Excel options)
    store.setModule(ErpModule.suppliers);
    await tester.pumpAndSettle();
    final supHistoryBtn = find.text('History').first;
    await tester.ensureVisible(supHistoryBtn);
    await tester.tap(supHistoryBtn);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Download Report'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download Report'));
    await tester.pumpAndSettle();
    expect(find.text('Download PDF (.pdf)'), findsOneWidget);
    expect(find.text('Download Excel (.csv)'), findsOneWidget);
    await tester.tap(find.text('Download PDF (.pdf)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download Excel (.csv)'));
    await tester.pumpAndSettle();
    expect(find.text('Download Excel File (.csv)'), findsOneWidget);
    await tester.tap(find.text('Download Excel File (.csv)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Verify Supplier Detail Screen on Mobile 360x800 (EN & UR) with zero overflow!
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    store.toggleLanguage(); // Urdu RTL on Mobile 360x800
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    store.toggleLanguage(); // Back to EN
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 6. Navigate to Roles & Data Backup -> Test Employee Permission Matrix Table + Zero-Zero Reset
    store.setModule(ErpModule.settings);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final addEmpBtn = find.text('+ Add Employee');
    await tester.ensureVisible(addEmpBtn);
    await tester.tap(addEmpBtn);
    await tester.pumpAndSettle();
    expect(find.text('MODULE'), findsOneWidget);
    expect(find.text('VIEW'), findsOneWidget);
    expect(find.text('CREATE'), findsOneWidget);
    expect(find.text('UPDATE'), findsOneWidget);
    expect(find.text('DELETE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final resetBtn = find.text('Reset All Data to Zero (0-0)');
    await tester.ensureVisible(resetBtn);
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    // Enter owner password '1234' in dialog
    final dlgPassField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dlgPassField, '1234');
    await tester.tap(find.text('Reset to Zero'));
    await tester.pumpAndSettle();

    expect(store.sales, isEmpty);
    expect(store.purchases, isEmpty);
    expect(store.creditPurchasers, isEmpty);
    expect(store.fuelStocks[FuelType.petrol]!.remainingLiters, 0);
    expect(store.fuelStocks[FuelType.diesel]!.remainingLiters, 0);

    // 7. Verify ALL 7 modules render cleanly in 0-0 Empty State on Desktop & Mobile!
    for (final mod in ErpModule.values) {
      store.setModule(mod);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Zero-Zero Desktop error in ${mod.name}');
    }
    tester.view.physicalSize = const Size(390, 844);
    for (final mod in ErpModule.values) {
      store.setModule(mod);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Zero-Zero Mobile error in ${mod.name}');
    }

    // 8. Test Custom Expense Category (+ New) via real UI dialog!
    tester.view.physicalSize = const Size(1440, 900);
    store.setModule(ErpModule.expenses);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Expense / Salary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();

    final catInput = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(catInput.first, 'Tea & Food');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(store.expenses.length, 1);
    expect(store.expenses.first.categoryEn, 'Tea & Food');
    expect(tester.takeException(), isNull);

    // 9. Test Walk-in Customer Bank Transfer Sale + Cash & Bank Ledger Module + Cash <-> Bank Transfer!
    final prevBank = store.totalBankBalance;
    final prevCash = store.totalCashInHand;
    store.addFuelSale(
      purchaserId: 'CASH',
      fuel: FuelType.diesel,
      liters: 100,
      rateUsed: 270,
      paidNow: 27000,
      paymentMethod: 'Bank Transfer',
      note: 'Walk-in Bank Transfer Test',
    );
    expect(store.totalBankBalance, prevBank + 27000);
    expect(store.totalCashInHand, prevCash);

    store.setModule(ErpModule.cashBank);
    await tester.pumpAndSettle();
    expect(find.text('Cash in Hand Balance'), findsOneWidget);
    expect(find.text('Bank Account Balance'), findsOneWidget);
    expect(find.text('Walk-in Fuel Sale'), findsWidgets);

    // Test Cash <-> Bank Transfer Dialog
    await tester.tap(find.text('Cash <-> Bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Transfer'));
    await tester.pumpAndSettle();
    expect(store.cashBankTransfers.length, 1);
    expect(tester.takeException(), isNull);

    // 10. Test Auto / Manual (dd-mm-yyyy with auto-dash) Date Option in New Fuel Sale!
    store.setModule(ErpModule.sales);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Fuel Sale'));
    await tester.pumpAndSettle();
    expect(find.text('Manual (dd-mm-yyyy)'), findsOneWidget);
    await tester.tap(find.text('Manual (dd-mm-yyyy)'));
    await tester.pumpAndSettle();
    final dateInput = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText?.contains('dd-mm-yyyy') ?? false),
    );
    expect(dateInput, findsOneWidget);
    await tester.enterText(dateInput, '15112026');
    await tester.pumpAndSettle();
    // Auto-dash formatter must format 15112026 -> 15-11-2026!
    expect(find.text('15-11-2026'), findsOneWidget);
    await tester.tap(find.text('Save Sale'));
    await tester.pumpAndSettle();
    expect(store.sales.first.date.year, 2026);
    expect(store.sales.first.date.month, 11);
    expect(store.sales.first.date.day, 15);
    expect(tester.takeException(), isNull);
  });
}
