import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../data/repository/log_repository_impl.dart';
import '../../data/repository/badge_repository_impl.dart';
import '../../data/repository/plan_repository_impl.dart';
import '../../data/repository/craving_repository_impl.dart';
import '../../data/repository/game_repository_impl.dart';
import '../../domain/usecase/user_usecase.dart';
import '../../domain/usecase/log_usecase.dart';
import '../../domain/usecase/badge_usecase.dart';
import '../../domain/usecase/plan_usecase.dart';
import '../../domain/usecase/craving_usecase.dart';
import '../../domain/usecase/game_usecase.dart';
import '../../core/theme/app_theme.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/security/encryption_service.dart';
import '../../data/source/content_loader.dart';
import '../../core/router/app_router.dart';
import '../../core/health/health_data_service.dart';
import '../../core/privacy/pipl_consent_service.dart';
import '../../core/relapse/relapse_tolerance_service.dart';
import '../../core/llm/llm_policy.dart';
import '../../core/llm/llm_usage_tracker.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/data_encryption.dart';
import '../../core/export/fhir_exporter.dart';
import '../../core/export/medical_interface.dart';
import '../../core/content/ota_content_manager.dart';
import '../../core/enterprise/eap_service.dart';
import '../../core/enterprise/enterprise_challenge.dart';
import '../../core/subscription/subscription_service.dart';
import '../../core/api/open_api_service.dart';
import '../../core/wearable/wearable_service.dart';

final appDatabaseProvider = Provider((ref) => AppDatabase());
final encryptionServiceProvider = Provider((ref) => EncryptionService());
final contentLoaderProvider = Provider((ref) => ContentLoader());

final userRepositoryProvider = Provider((ref) => UserRepository(
    ref.read(appDatabaseProvider), ref.read(encryptionServiceProvider)));
final logRepositoryProvider =
    Provider((ref) => LogRepository(ref.read(appDatabaseProvider)));
final badgeRepositoryProvider =
    Provider((ref) => BadgeRepository(ref.read(appDatabaseProvider)));
final planRepositoryProvider =
    Provider((ref) => PlanRepository(ref.read(appDatabaseProvider)));
final cravingRepositoryProvider =
    Provider((ref) => CravingRepository(ref.read(appDatabaseProvider)));
final gameRepositoryProvider =
    Provider((ref) => GameRepository(ref.read(appDatabaseProvider)));

final userUseCaseProvider =
    Provider((ref) => UserUseCase(ref.read(userRepositoryProvider)));
final logUseCaseProvider = Provider((ref) => LogUseCase(
    ref.read(logRepositoryProvider),
    ref.read(badgeRepositoryProvider),
    ref.read(userRepositoryProvider)));
final badgeUseCaseProvider =
    Provider((ref) => BadgeUseCase(ref.read(badgeRepositoryProvider)));
final planUseCaseProvider =
    Provider((ref) => PlanUseCase(ref.read(planRepositoryProvider)));
final cravingUseCaseProvider = Provider((ref) => CravingUseCase(
    ref.read(cravingRepositoryProvider), ref.read(userRepositoryProvider)));
final gameUseCaseProvider =
    Provider((ref) => GameUseCase(ref.read(gameRepositoryProvider)));

final notificationServiceProvider =
    Provider((ref) => NotificationService.instance);
final appThemeProvider = Provider((ref) => AppTheme());

final healthServiceProvider = Provider((ref) {
  final db = ref.read(appDatabaseProvider);
  return SelfReportHealthService(db);
});

final piplConsentServiceProvider = Provider((ref) {
  final db = ref.read(appDatabaseProvider);
  return PiplConsentService(db);
});

final relapseToleranceServiceProvider =
    Provider((ref) => RelapseToleranceService());

final llmPolicyProvider = Provider((ref) {
  final db = ref.read(appDatabaseProvider);
  return LlmPolicy(db);
});

// ──────────────────────────────────────────────────────────
// AI Agent — LlmServiceProvider & shared LLM infrastructure
// ──────────────────────────────────────────────────────────

/// Shared LlmUsageTracker singleton for cost monitoring.
final llmUsageTrackerProvider = Provider((ref) => LlmUsageTracker.instance);

// AI agent and daily insight providers are in ai_providers.dart
// (imported separately to avoid circular dependencies)

// ──────────────────────────────────────────────────────────
// Phase 3 — Ecosystem Extension Providers
// ──────────────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  return LocalOnlySyncService();
});

final zeroKnowledgeEncryptorProvider = Provider((ref) {
  return ZeroKnowledgeEncryptor(ref.read(encryptionServiceProvider));
});

final fhirExporterProvider = Provider((ref) {
  return FhirExporter();
});

final medicalInterfaceProvider = Provider<MedicalInterface>((ref) {
  return LocalMedicalInterface();
});

final otaContentManagerProvider = Provider((ref) {
  return OtaContentManager(ref.read(appDatabaseProvider));
});

// ──────────────────────────────────────────────────────────
// Phase 4 — 商业化探索 Providers
// ──────────────────────────────────────────────────────────

/// 企业EAP服务（本地占位实现）
final eapServiceProvider = Provider<EapService>((ref) {
  return LocalEapService();
});

/// 企业挑战管理器
final enterpriseChallengeManagerProvider = Provider((ref) {
  return EnterpriseChallengeManager();
});

/// 订阅服务（默认免费版）
final subscriptionServiceProvider = Provider((ref) {
  final db = ref.read(appDatabaseProvider);
  return SubscriptionService(db);
});

/// 开放平台API服务（本地占位实现）
final openApiServiceProvider = Provider<OpenApiService>((ref) {
  return LocalOpenApiService();
});

/// 可穿戴设备服务（本地占位实现）
final wearableServiceProvider = Provider<WearableService>((ref) {
  return LocalWearableService();
});

final appRouterProvider = Provider((ref) {
  return AppRouter(
    userUseCase: ref.read(userUseCaseProvider),
    notificationService: ref.read(notificationServiceProvider),
  );
});

// ──────────────────────────────────────────────────────────
// Reactive Theme Mode Provider
// ──────────────────────────────────────────────────────────
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final UserUseCase _userUseCase;
  ThemeModeNotifier(this._userUseCase) : super(ThemeMode.light) {
    _loadMode();
  }

  Future<void> _loadMode() async {
    try {
      final prefs = await _userUseCase.getPreferences();
      final dark = prefs['dark_mode'] as bool? ?? false;
      state = dark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  Future<void> setMode(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await _userUseCase.getPreferences();
      prefs['dark_mode'] = isDark;
      await _userUseCase.savePreferences(prefs);
    } catch (_) {}
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(userUseCaseProvider));
});
