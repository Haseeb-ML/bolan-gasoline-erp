import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bolan_gasoline_erp/core/storage/local_storage_stub.dart';
import 'package:bolan_gasoline_erp/core/theme/app_theme.dart';
import 'package:bolan_gasoline_erp/data/repository/erp_store.dart';
import 'package:bolan_gasoline_erp/main.dart';

const _outDir =
    r'C:\Users\Haseeb\.gemini\antigravity\brain\669fbdda-83db-4616-a99e-aff1482ed6cb\screenshots';

Future<void> _saveShot(WidgetTester tester, GlobalKey boundaryKey, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_outDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('$_outDir${Platform.pathSeparator}$name.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('Full E2E Interactive UI Flow + Screenshot Capture', (tester) async {
    final boundaryKey = GlobalKey();
    final store = ErpStore(
      storage: MemoryStorageAdapter(),
      autoLoginOwner: true,
    );

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: BolanGasolineApp(store: store),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Desktop Dashboard (English, Bolan Red)
    expect(find.text('BOLAN GASOLINE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _saveShot(tester, boundaryKey, '01_desktop_dashboard_en');

    // 2. Open + New Fuel Sale dialog, save a sale, verify count increases
    final salesBefore = store.sales.length;
    await tester.tap(find.text('+ New Fuel Sale').first);
    await tester.pumpAndSettle();
    expect(find.text('New Fuel Sale'), findsOneWidget);
    await tester.tap(find.text('Save Sale'));
    await tester.pumpAndSettle();
    expect(store.sales.length, salesBefore + 1);
    expect(tester.takeException(), isNull);

    // 3. Go to Fuel Sales, select 2 checkboxes -> verify Bulk Delete bar -> Bulk Delete!
    store.setModule(ErpModule.sales);
    await tester.pumpAndSettle();
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsWidgets);
    // Index 0 is Select All; tap row 1 and row 2 checkboxes
    await tester.ensureVisible(checkboxes.at(2));
    await tester.pumpAndSettle();
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(checkboxes.at(2));
    await tester.pumpAndSettle();
    await tester.tap(checkboxes.at(2));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Delete Selected (2)'), findsOneWidget);
    await _saveShot(tester, boundaryKey, '02_sales_bulk_select_desktop');

    // Execute Bulk Delete & confirm
    final countBeforeBulk = store.sales.length;
    await tester.tap(find.text('Delete Selected (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(store.sales.length, countBeforeBulk - 2);
    expect(tester.takeException(), isNull);

    // 4. Open Purchasers Khata -> Tap Arsalan -> Verify Personal Account History
    store.setModule(ErpModule.purchasers);
    await tester.pumpAndSettle();
    final arsalan = find.text('Arsalan (Daily Purchaser)');
    await tester.ensureVisible(arsalan);
    await tester.pumpAndSettle();
    await tester.tap(arsalan);
    await tester.pumpAndSettle();
    expect(find.textContaining('Complete Account History'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _saveShot(tester, boundaryKey, '03_arsalan_personal_ledger_desktop');

    // Test Receive Payment inside Arsalan's Personal Account
    final arsalanBalBefore = store.purchaserSummary('PR-00').balance;
    await tester.tap(find.text('Receive Payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Payment'));
    await tester.pumpAndSettle();
    expect(store.purchaserSummary('PR-00').balance, lessThan(arsalanBalBefore));
    expect(tester.takeException(), isNull);

    // Navigate back to main shell
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 5. Switch to Urdu RTL + Dark Theme -> Screenshot
    store.setModule(ErpModule.dashboard);
    store.toggleLanguage();
    store.setTheme(ErpThemeId.dark);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _saveShot(tester, boundaryKey, '04_desktop_dashboard_urdu_dark');

    // 6. Switch to Mobile 390x844 (English, Emerald Theme) -> Screenshot
    store.toggleLanguage();
    store.setTheme(ErpThemeId.emerald);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _saveShot(tester, boundaryKey, '05_mobile_dashboard_emerald');
  });
}
