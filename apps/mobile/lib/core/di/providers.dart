import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../data/repository/log_repository_impl.dart';
import '../../data/repository/badge_repository_impl.dart';
import '../../data/repository/plan_repository_impl.dart';
import '../../data/repository/content_repository_impl.dart';
import '../../data/source/content_loader.dart';
import '../../domain/usecase/user_usecase.dart';
import '../../domain/usecase/log_usecase.dart';
import '../../domain/usecase/badge_usecase.dart';
import '../../domain/usecase/plan_usecase.dart';
import '../../domain/usecase/content_usecase.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/security/encryption_service.dart';
import '../../core/content/content_manager.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

final contentLoaderProvider = Provider<ContentLoader>((ref) {
  return ContentLoader();
});

final contentManagerProvider = Provider<ContentManager>((ref) {
  return ContentManager(ref.watch(contentLoaderProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(appDatabaseProvider), ref.watch(encryptionServiceProvider));
});

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepositoryImpl(ref.watch(appDatabaseProvider));
});

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepositoryImpl(ref.watch(appDatabaseProvider));
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepositoryImpl(ref.watch(appDatabaseProvider));
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepositoryImpl(ref.watch(contentManagerProvider));
});

final userUseCaseProvider = Provider<UserUseCase>((ref) {
  return UserUseCase(ref.watch(userRepositoryProvider));
});

final logUseCaseProvider = Provider<LogUseCase>((ref) {
  return LogUseCase(
    ref.watch(logRepositoryProvider),
    ref.watch(badgeRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

final badgeUseCaseProvider = Provider<BadgeUseCase>((ref) {
  return BadgeUseCase(ref.watch(badgeRepositoryProvider), ref.watch(logRepositoryProvider));
});

final planUseCaseProvider = Provider<PlanUseCase>((ref) {
  return PlanUseCase(ref.watch(planRepositoryProvider));
});

final contentUseCaseProvider = Provider<ContentUseCase>((ref) {
  return ContentUseCase(ref.watch(contentRepositoryProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final appThemeProvider = Provider<AppTheme>((ref) {
  return AppTheme();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter(
    userUseCase: ref.watch(userUseCaseProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});