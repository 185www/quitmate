import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/usecase/user_usecase.dart';
import '../../core/notifications/notification_service.dart';
import '../../presentation/shell/shell_screen.dart';
import '../../presentation/onboarding/assessment/assessment_screen.dart';
import '../../presentation/onboarding/education/education_screen.dart';
import '../../presentation/onboarding/motivation/motivation_screen.dart';
import '../../presentation/preparation/quit_date_wizard/quit_date_wizard_screen.dart';
import '../../presentation/action/dashboard/dashboard_screen.dart';
import '../../presentation/action/urge_toolkit/urge_toolkit_screen.dart';
import '../../presentation/action/daily_log/daily_log_screen.dart';
import '../../presentation/action/skills_lab/skills_lab_screen.dart';
import '../../presentation/maintenance/relapse_plan/relapse_plan_screen.dart';
import '../../presentation/maintenance/lifestyle/lifestyle_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/profile/settings_screen.dart';
import '../../presentation/profile/export_screen.dart';
import '../../presentation/profile/about_screen.dart';

class AppRouter {
  final UserUseCase _userUseCase;
  final NotificationService _notificationService;

  AppRouter({
    required UserUseCase userUseCase,
    required NotificationService notificationService,
  })  : _userUseCase = userUseCase,
        _notificationService = notificationService;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/action', builder: (context, state) => const ActionTabScreen()),
          GoRoute(path: '/maintenance', builder: (context, state) => const MaintenanceTabScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileTabScreen()),
        ],
      ),
      GoRoute(path: '/onboarding/assessment', builder: (context, state) => const AssessmentScreen()),
      GoRoute(path: '/onboarding/education', builder: (context, state) => const EducationScreen()),
      GoRoute(path: '/onboarding/motivation', builder: (context, state) => const MotivationScreen()),
      GoRoute(path: '/preparation/quit-date', builder: (context, state) => const QuitDateWizardScreen()),
      GoRoute(path: '/action/urge-toolkit', builder: (context, state) => const UrgeToolkitScreen()),
      GoRoute(path: '/action/daily-log', builder: (context, state) => const DailyLogScreen()),
      GoRoute(path: '/action/skills-lab', builder: (context, state) => const SkillsLabScreen()),
      GoRoute(path: '/maintenance/relapse-plan', builder: (context, state) => const RelapsePlanScreen()),
      GoRoute(path: '/maintenance/lifestyle', builder: (context, state) => const LifestyleScreen()),
      GoRoute(path: '/profile/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/profile/export', builder: (context, state) => const ExportScreen()),
      GoRoute(path: '/profile/about', builder: (context, state) => const AboutScreen()),
    ],
  );
}