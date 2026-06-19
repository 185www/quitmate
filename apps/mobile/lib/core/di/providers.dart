import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../data/repository/log_repository_impl.dart';
import '../../data/repository/badge_repository_impl.dart';
import '../../data/repository/plan_repository_impl.dart';
import '../../data/repository/content_repository_impl.dart';
import '../../data/repository/craving_repository_impl.dart';
import '../../domain/usecase/user_usecase.dart';
import '../../domain/usecase/log_usecase.dart';
import '../../domain/usecase/badge_usecase.dart';
import '../../domain/usecase/plan_usecase.dart';
import '../../domain/usecase/content_usecase.dart';
import '../../domain/usecase/craving_usecase.dart';
import '../../core/theme/app_theme.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/security/encryption_service.dart';
import '../../data/source/content_loader.dart';
import '../../core/router/app_router.dart';

final appDatabaseProvider = Provider((ref) => AppDatabase());
final encryptionServiceProvider = Provider((ref) => EncryptionService());
final contentLoaderProvider = Provider((ref) => ContentLoader());

final userRepositoryProvider = Provider((ref) => UserRepository(ref.watch(appDatabaseProvider), ref.watch(encryptionServiceProvider)));
final logRepositoryProvider = Provider((ref) => LogRepository(ref.watch(appDatabaseProvider)));
final badgeRepositoryProvider = Provider((ref) => BadgeRepository(ref.watch(appDatabaseProvider)));
final planRepositoryProvider = Provider((ref) => PlanRepository(ref.watch(appDatabaseProvider)));
final contentRepositoryProvider = Provider((ref) => ContentRepositoryImpl(ref.watch(contentLoaderProvider)));
final cravingRepositoryProvider = Provider((ref) => CravingRepository(ref.watch(appDatabaseProvider)));

final userUseCaseProvider = Provider((ref) => UserUseCase(ref.watch(userRepositoryProvider)));
final logUseCaseProvider = Provider((ref) => LogUseCase(ref.watch(logRepositoryProvider), ref.watch(badgeRepositoryProvider), ref.watch(userRepositoryProvider)));
final badgeUseCaseProvider = Provider((ref) => BadgeUseCase(ref.watch(badgeRepositoryProvider)));
final planUseCaseProvider = Provider((ref) => PlanUseCase(ref.watch(planRepositoryProvider)));
final contentUseCaseProvider = Provider((ref) => ContentUseCase(ref.watch(contentRepositoryProvider)));
final cravingUseCaseProvider = Provider((ref) => CravingUseCase(ref.watch(cravingRepositoryProvider), ref.watch(userRepositoryProvider)));

final notificationServiceProvider = Provider((ref) => NotificationService.instance);
final appThemeProvider = Provider((ref) => AppTheme());

final appRouterProvider = Provider((ref) {
  return AppRouter(
    userUseCase: ref.watch(userUseCaseProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});
