import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sentryDsn = AppConfig.sentryDsn;

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = AppConfig.envLabel.toLowerCase();
        options.tracesSampleRate = AppConfig.isProduction ? 0.2 : 1.0;
        options.debug = AppConfig.isDebug;
      },
      appRunner: () => runApp(const ProviderScope(child: NelnaMaintenanceApp())),
    );
  } else {
    // No Sentry DSN — run without error monitoring
    runApp(const ProviderScope(child: NelnaMaintenanceApp()));
  }
}

class NelnaMaintenanceApp extends ConsumerWidget {
  const NelnaMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Nelna Maintenance System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
