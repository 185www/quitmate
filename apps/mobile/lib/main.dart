import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/di/providers.dart';
import 'core/error/app_error_handler.dart';
import 'core/notifications/notification_service.dart';
import 'core/widgets/widget_service.dart';

const _widgetChannel = MethodChannel('quitmate/widget');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppErrorHandler.initialize();
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: QuitMateApp(),
    ),
  );
}

class QuitMateApp extends ConsumerStatefulWidget {
  const QuitMateApp({super.key});

  @override
  ConsumerState<QuitMateApp> createState() => _QuitMateAppState();
}

class _QuitMateAppState extends ConsumerState<QuitMateApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleWidgetRoute());
  }

  Future<void> _handleWidgetRoute() async {
    try {
      final route = await _widgetChannel.invokeMethod<String>('getPendingRoute');
      if (route != null && route.isNotEmpty && mounted) {
        context.go(route);
      }
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      await WidgetService.updateWidget(user);
    } catch (e) {
      debugPrint('Main: 处理小组件路由失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      title: 'QuitMate',
      debugShowCheckedModeBanner: false,
      routerConfig: router.router,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
    );
  }
}
