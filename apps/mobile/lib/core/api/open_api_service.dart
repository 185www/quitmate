/// 开放平台 API 服务
///
/// 为第三方集成提供REST API抽象层。
/// 允许授权的第三方应用通过API密钥访问用户的匿名健康数据。
/// 当前为本地占位实现，未来可对接API网关。
library;

/// API 端点定义
class ApiEndpoint {
  /// 端点路径
  final String path;

  /// HTTP 方法
  final String method;

  /// 端点描述
  final String description;

  /// 是否需要认证
  final bool auth;

  const ApiEndpoint({
    required this.path,
    required this.method,
    required this.description,
    required this.auth,
  });
}

/// 开放平台 API 服务接口
///
/// 定义第三方集成的API管理功能。
abstract class OpenApiService {
  /// 生成用户API密钥（用于第三方访问授权）
  ///
  /// 返回生成的API密钥，失败时返回 null。
  Future<String?> generateApiKey();

  /// 撤销当前API密钥
  Future<void> revokeApiKey();

  /// 验证API请求是否合法
  ///
  /// [apiKey] API密钥
  /// [endpoint] 请求的端点路径
  /// 返回 true 表示请求合法，false 表示拒绝。
  Future<bool> validateRequest(String apiKey, String endpoint);

  /// 可用的API端点列表
  static const List<ApiEndpoint> availableEndpoints = [
    ApiEndpoint(
      path: '/v1/health/summary',
      method: 'GET',
      description: '用户健康摘要',
      auth: true,
    ),
    ApiEndpoint(
      path: '/v1/progress/timeline',
      method: 'GET',
      description: '戒断进度时间线',
      auth: true,
    ),
    ApiEndpoint(
      path: '/v1/cravings',
      method: 'GET',
      description: '渴望记录列表',
      auth: true,
    ),
    ApiEndpoint(
      path: '/v1/cravings',
      method: 'POST',
      description: '记录新的渴望',
      auth: true,
    ),
  ];
}

/// 本地实现（无实际API服务器）
///
/// 纯本地占位实现，所有API功能均返回默认值。
/// 未来可替换为真实的API网关客户端。
class LocalOpenApiService implements OpenApiService {
  /// 本地实现始终返回 null（无法生成API密钥）
  @override
  Future<String?> generateApiKey() async {
    // 占位实现：未来对接API网关生成真实密钥
    return null;
  }

  /// 本地实现为空操作
  @override
  Future<void> revokeApiKey() async {
    // 占位实现：未来对接API网关撤销密钥
  }

  /// 本地实现始终返回 false（所有请求均不通过验证）
  @override
  Future<bool> validateRequest(String apiKey, String endpoint) async {
    // 占位实现：未来对接API网关进行真实验证
    return false;
  }
}