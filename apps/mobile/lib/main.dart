import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/di/providers.dart';
import 'core/error/app_error_handler.dart';
import 'core/notifications/notification_service.dart';
import 'core/widgets/widget_service.dart';
import 'core/widgets/widget_service_v2.dart';
import 'core/coach/ai_agent_service.dart';
import 'presentation/privacy/pipl_consent_screen.dart';

const _widgetChannel = MethodChannel('quitmate/widget');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppErrorHandler.initialize();
  // NotificationService.initialize() 只初始化插件和创建通道，不请求权限。
  // 权限请求应在用户完成 onboarding 后通过引导式弹窗触发（见 MotivationScreen）。
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
  bool _piplChecked = false;
  bool _piplConsented = false;

  @override
  void initState() {
    super.initState();
    _checkPiplConsent();
  }

  Future<void> _checkPiplConsent() async {
    final service = ref.read(piplConsentServiceProvider);
    final consented = await service.hasConsented();
    if (mounted) {
      setState(() {
        _piplChecked = true;
        _piplConsented = consented;
      });
      // PIPL 检查通过后，处理小组件路由
      if (consented) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleWidgetRoute());
      }
    }
  }

  Future<void> _handleWidgetRoute() async {
    try {
      final route =
          await _widgetChannel.invokeMethod<String>('getPendingRoute');
      if (route != null && route.isNotEmpty && mounted) {
        context.go(route);
      }
      // Initialize AiAgentService from user preferences
      final prefs = await ref.read(userUseCaseProvider).getPreferences();
      await AiAgentService.instance.initialize(preferences: prefs);

      // Use WidgetServiceV2 for enriched widget data
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      final gameProfile = user != null
          ? await ref.read(gameUseCaseProvider).getGameProfile(user.id)
          : null;
      final todayLog = await ref.read(logUseCaseProvider).getTodayLog();
      await WidgetServiceV2.updateWidgetData(
        user: user,
        gameProfile: gameProfile,
        todayLog: todayLog,
        llmService: AiAgentService.instance.llmService,
      );
    } catch (e) {
      debugPrint('Main: 处理小组件路由失败: $e');
    }
  }

  Future<void> _onPiplConsent() async {
    final service = ref.read(piplConsentServiceProvider);
    await service.setConsented();
    if (mounted) {
      setState(() => _piplConsented = true);
      // 同意后延迟一帧再处理小组件路由，确保路由已就绪
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleWidgetRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── 阶段 1：正在检查 PIPL 同意状态 ──
    if (!_piplChecked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _loadingTheme(Brightness.light),
        darkTheme: _loadingTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // ── 阶段 2：用户未同意隐私协议 → 展示 PIPL 同意页面 ──
    if (!_piplConsented) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ref.watch(appThemeProvider).lightTheme,
        darkTheme: ref.watch(appThemeProvider).darkTheme,
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
        home: PiplConsentScreen(
          onConsent: _onPiplConsent,
        ),
      );
    }

    // ── 阶段 3：已同意 → 正常启动应用 ──
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'QuitMate',
      debugShowCheckedModeBanner: false,
      routerConfig: router.router,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: themeMode,
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

  /// 加载阶段的简化主题（使用 fromSeed 避免手动填充全部 ColorScheme 参数）
  ThemeData _loadingTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seedColor = isDark ? const Color(0xFF4ECDC4) : const Color(0xFF2E7D6F);
    final background = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F8FA);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: background,
    );
  }
}
