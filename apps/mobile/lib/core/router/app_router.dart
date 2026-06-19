import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/shell/shell_screen.dart';
import '../../presentation/onboarding/welcome_screen.dart';
import '../../presentation/onboarding/reality_check_screen.dart';
import '../../presentation/onboarding/assessment/assessment_screen.dart';
import '../../presentation/onboarding/education/education_screen.dart';
import '../../presentation/onboarding/motivation/motivation_screen.dart';
import '../../presentation/preparation/quit_date_wizard/quit_date_wizard_screen.dart';
import '../../presentation/action/urge_toolkit/urge_toolkit_screen.dart';
import '../../presentation/action/daily_log/daily_log_screen.dart';
import '../../presentation/action/skills_lab/skills_lab_screen.dart';
import '../../presentation/maintenance/relapse_plan/relapse_plan_screen.dart';
import '../../presentation/maintenance/lifestyle/lifestyle_screen.dart';
import '../../presentation/profile/settings_screen.dart';
import '../../presentation/profile/export_screen.dart';
import '../../presentation/profile/about_screen.dart';
import '../../presentation/profile/analysis_report/analysis_report_screen.dart';
import '../../domain/usecase/user_usecase.dart';
import '../../core/notifications/notification_service.dart';

class AppRouter {
  final UserUseCase _userUseCase;
  final NotificationService _notificationService;

  AppRouter({required UserUseCase userUseCase, required NotificationService notificationService})
    : _userUseCase = userUseCase, _notificationService = notificationService;

  /// Tracks whether we've checked the user state to avoid redirect loops
  bool _initialCheckDone = false;
  bool _hasUser = false;

  Future<bool> _checkHasUser() async {
    if (!_initialCheckDone) {
      final user = await _userUseCase.getCurrentUser();
      _hasUser = user != null;
      _initialCheckDone = true;
    }
    return _hasUser;
  }

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final loc = state.uri.toString();
      // Onboarding paths — never redirect away from these
      if (loc.startsWith('/onboarding') ||
          loc.startsWith('/action/urge-toolkit')) {
        return null;
      }
      // If no user exists and we're trying to go to a main tab, redirect to welcome
      final hasUser = await _checkHasUser();
      if (!hasUser && (loc == '/' || loc.startsWith('/action') || loc.startsWith('/maintenance') || loc.startsWith('/profile'))) {
        return '/welcome';
      }
      return null;
    },
    routes: [
      // New user entry
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/reality-check', builder: (_, __) => const RealityCheckScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardTab()),
          GoRoute(path: '/action', builder: (_, __) => const ActionTabScreen()),
          GoRoute(path: '/maintenance', builder: (_, __) => const MaintenanceTabScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileTabScreen()),
        ],
      ),

      // Onboarding / preparation paths
      GoRoute(path: '/onboarding/assessment', builder: (_, __) => const AssessmentScreen()),
      GoRoute(path: '/onboarding/education', builder: (_, __) => const EducationScreen()),
      GoRoute(path: '/onboarding/motivation', builder: (_, __) => const MotivationScreen()),
      GoRoute(path: '/preparation/quit-date', builder: (_, __) => const QuitDateWizardScreen()),

      // Action tools
      GoRoute(path: '/action/urge-toolkit', builder: (_, __) => const UrgeToolkitScreen()),
      GoRoute(path: '/action/daily-log', builder: (_, __) => const DailyLogScreen()),
      GoRoute(path: '/action/skills-lab', builder: (_, __) => const SkillsLabScreen()),

      // Maintenance tools
      GoRoute(path: '/maintenance/relapse-plan', builder: (_, __) => const RelapsePlanScreen()),
      GoRoute(path: '/maintenance/lifestyle', builder: (_, __) => const LifestyleScreen()),

      // Profile sub-pages
      GoRoute(path: '/profile/analysis', builder: (_, __) => const AnalysisReportScreen()),
      GoRoute(path: '/profile/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/profile/export', builder: (_, __) => const ExportScreen()),
      GoRoute(path: '/profile/about', builder: (_, __) => const AboutScreen()),
    ],
  );
}
