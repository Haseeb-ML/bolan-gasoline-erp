import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/storage/firestore_sync.dart';
import 'core/theme/app_theme.dart';
import 'data/repository/erp_store.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/shell/erp_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = ErpStore(
    cloudSync: FirestoreSyncService(enabled: true),
  );
  await store.init();
  runApp(BolanGasolineApp(store: store));
}

class BolanGasolineApp extends StatelessWidget {
  const BolanGasolineApp({super.key, required this.store});

  final ErpStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final locale = store.isUrdu ? const Locale('ur') : const Locale('en');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Bolan Gasoline — Petrol & Diesel Pump ERP',
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ur')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildErpTheme(store.themeId, isUrdu: store.isUrdu),
          home: Directionality(
            textDirection:
                store.isUrdu ? TextDirection.rtl : TextDirection.ltr,
            child: store.isLoggedIn
                ? ErpShell(store: store)
                : LoginScreen(store: store),
          ),
        );
      },
    );
  }
}
