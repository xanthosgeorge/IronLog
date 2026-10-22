import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_controller.dart';
import 'data/api_client.dart';
import 'data/session_store.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'ui.dart';
import 'config.dart';
import 'preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = AppPreferences(storage: SharedPreferencesAsync());
  try {
    await preferences.load();
  } catch (_) {/* Use defaults if local storage is unavailable. */}
  final controller = AppController(ApiClient(baseUrl: AppConfig.apiBaseUrl),
      const SecureSessionStore(namespace: AppConfig.apiBaseUrl),
      preferences: preferences);
  runApp(IronLogApp(controller: controller));
  controller.restore();
}

class IronLogApp extends StatefulWidget {
  const IronLogApp({super.key, required this.controller});
  final AppController controller;
  @override
  State<IronLogApp> createState() => _IronLogAppState();
}

class _IronLogAppState extends State<IronLogApp> {
  final navigator = GlobalKey<NavigatorState>();
  bool wasAuthenticated = false;
  AppController get controller => widget.controller;
  @override
  void initState() {
    super.initState();
    wasAuthenticated = controller.session != null;
    controller.addListener(sessionChanged);
  }

  void sessionChanged() {
    final authenticated = controller.session != null;
    if (wasAuthenticated && !authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navigator.currentState?.popUntil((route) => route.isFirst);
      });
    }
    wasAuthenticated = authenticated;
  }

  @override
  void dispose() {
    controller.removeListener(sessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([controller, controller.preferences]),
        builder: (context, _) => MaterialApp(
          navigatorKey: navigator,
          title: 'IronLog',
          debugShowCheckedModeBanner: false,
          locale: Locale(controller.preferences.language),
          builder: (context, child) => PreferenceScope(
              preferences: controller.preferences, child: child!),
          supportedLocales: const [Locale('el'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ironTheme(controller.preferences.palette),
          home: controller.restoring
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : controller.session == null
                  ? AuthScreen(controller: controller)
                  : HomeScreen(controller: controller),
        ),
      );
}
