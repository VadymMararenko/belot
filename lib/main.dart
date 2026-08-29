import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_strings.dart';
import 'core/match_store.dart';
import 'ui/app_theme.dart';
import 'ui/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final store = MatchStore(preferences);
  await store.restore();
  runApp(KlaborApp(store: store));
}

class KlaborApp extends StatelessWidget {
  const KlaborApp({super.key, required this.store});

  final MatchStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final strings = AppStrings(store.language);
        return MaterialApp(
          title: strings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: HomeScreen(store: store),
        );
      },
    );
  }
}
