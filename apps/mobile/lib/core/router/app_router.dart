import 'package:go_router/go_router.dart';
import '../../presentation/shell/shell_screen.dart';
import '../../presentation/home/dashboard_screen.dart';
import '../../presentation/action/action_screen.dart';
import '../../presentation/maintenance/maintenance_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/onboarding/welcome_screen.dart';
import '../../presentation/onboarding/discovery_screen.dart';
import '../../presentation/onboarding/reality_check_screen.dart';
import '../../presentation/onboarding/assessment/assessment_screen.dart';
import '../../presentation/onboarding/education/education_screen.dart';
import '../../presentation/onboarding/motivation/motivation_screen.dart';
import '../../presentation/preparation/quit_date_wizard/quit_date_wizard_screen.dart';
import '../../presentation/action/urge_toolkit/urge_toolkit_screen.dart';
import '../../presentation/action/daily_log/daily_log_screen.dart';
import '../../presentation/action/skills_lab/skills_lab_screen.dart';
import '../../presentation/action/coach/chat_screen.dart';
import '../../presentation/action/challenge/challenge_screen.dart';
import '../../presentation/action/companion/companion_screen.dart';
import '../../presentation/maintenance/relapse_plan/relapse_plan_screen.dart';
import '../../presentation/maintenance/lifestyle/lifestyle_screen.dart';
import '../../presentation/profile/settings_screen.dart';
import '../../presentation/profile/export_screen.dart';
import '../../presentation/profile/about_screen.dart';
import '../../presentation/profile/badges_screen.dart';
import '../../presentation/profile/analysis_report/analysis_report_screen.dart';
import '../../presentation/profile/game_profile_screen.dart';
import '../../domain/usecase/user_usecase.dart';
import '../../core/notifications/notification_service.dart';

class AppRouter {
  final UserUseCase _userUseCase;

  AppRouter(
      {required UserUseCase userUseCase,
      required NotificationService notificationService})
      : _userUseCase = userUseCase;

  Future<bool> _isLoggedIn() async {
    final user = await _userUseCase.getCurrentUser();
    return user != null;
  }

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final loggedIn = await _isLoggedIn();
      final onBoardingRoutes = [
        '/welcome',
        '/onboarding/reality-check',
        '/onboarding/education',
        '/onboarding/motivation',
        '/onboarding/discovery',
        '/preparation/quit-date'
      ];
      if (onBoardingRoutes.any((r) => state.matchedLocation.startsWith(r)))
        return null;
      if (!loggedIn && state.matchedLocation != '/welcome') return '/welcome';
      if (loggedIn && state.matchedLocation == '/welcome') return '/';
      return null;
    },
    routes: [
      // New user entry
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(
          path: '/onboarding/reality-check',
          builder: (_, __) => const RealityCheckScreen()),

      GoRoute(
          path: '/onboarding/discovery',
          builder: (_, __) => const DiscoveryScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/action', builder: (_, __) => const ActionScreen()),
          GoRoute(
              path: '/maintenance',
              builder: (_, __) => const MaintenanceScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Onboarding / preparation paths
      GoRoute(
          path: '/onboarding/assessment',
          builder: (_, __) => const AssessmentScreen()),
      GoRoute(
          path: '/onboarding/education',
          builder: (_, __) => const EducationScreen()),
      GoRoute(
          path: '/onboarding/motivation',
          builder: (_, __) => const MotivationScreen()),
      GoRoute(
          path: '/preparation/quit-date',
          builder: (_, __) => const QuitDateWizardScreen()),

      // Action tools
      GoRoute(
          path: '/action/urge-toolkit',
          builder: (_, __) => const UrgeToolkitScreen()),
      GoRoute(
          path: '/action/daily-log',
          builder: (_, __) => const DailyLogScreen()),
      GoRoute(
          path: '/action/skills-lab',
          builder: (_, __) => const SkillsLabScreen()),
      GoRoute(path: '/action/coach', builder: (_, __) => const ChatScreen()),
      GoRoute(
          path: '/action/challenge',
          builder: (_, __) => const ChallengeScreen()),
      GoRoute(
          path: '/action/companion',
          builder: (_, __) => const CompanionScreen()),

      // Maintenance tools
      GoRoute(
          path: '/maintenance/relapse-plan',
          builder: (_, __) => const RelapsePlanScreen()),
      GoRoute(
          path: '/maintenance/lifestyle',
          builder: (_, __) => const LifestyleScreen()),

      // Profile sub-pages
      GoRoute(
          path: '/profile/analysis',
          builder: (_, __) => const AnalysisReportScreen()),
      GoRoute(
          path: '/profile/settings',
          builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/profile/export', builder: (_, __) => const ExportScreen()),
      GoRoute(path: '/profile/about', builder: (_, __) => const AboutScreen()),
      GoRoute(
          path: '/profile/badges', builder: (_, __) => const BadgesScreen()),
      GoRoute(
          path: '/profile/game-profile',
          builder: (_, __) => const GameProfileScreen()),
    ],
  );
}
