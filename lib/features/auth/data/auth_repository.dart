/// ============================================================================
/// DayFlow - 认证数据仓库
/// ============================================================================
///
/// 该文件封装了所有与用户认证相关的数据操作，包括：
/// - 邮箱 + 密码登录 / 注册
/// - Google OAuth 第三方登录
/// - 登出操作
/// - 获取当前用户信息
/// - 监听认证状态变化流
///
/// 使用 [AuthRepository] 将 Supabase Auth SDK 的具体实现
/// 与业务逻辑层（Provider / Notifier）解耦。
/// 所有异常通过 [AuthException] 统一封装，方便上层处理错误。
///
/// Riverpod Provider：
/// - [authRepositoryProvider]：全局认证仓库实例
/// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dayflow/core/supabase/supabase_client.dart';

// ============================================================
// 自定义异常
// ============================================================

/// 认证异常
///
/// 封装认证过程中可能出现的各种错误，提供统一的错误处理接口。
/// 通过 [message] 传递人类可读的错误描述，
/// 通过 [code] 传递可选的错误代码（来自 Supabase Auth）。
///
/// 示例：
/// ```dart
/// throw AuthException('邮箱或密码错误', code: 'invalid_credentials');
/// ```
class AuthException implements Exception {
  /// 人类可读的错误描述信息
  ///
  /// 可直接在 UI 中展示给用户（建议使用中文）。
  final String message;

  /// 可选的错误代码
  ///
  /// 来自 Supabase Auth SDK 的原始错误代码，
  /// 用于程序化地区分不同类型的错误。
  final String? code;

  /// 创建认证异常
  ///
  /// [message] 必填，错误描述
  /// [code] 可选，Supabase 错误代码
  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException(message: $message, code: $code)';
}

// ============================================================
// 认证仓库
// ============================================================

/// 认证数据仓库
///
/// 封装 Supabase Auth 的所有操作，提供简洁的 API 给上层使用。
/// 所有方法在失败时抛出 [AuthException]，调用方应使用 try-catch 处理。
///
/// 设计原则：
/// - 单一职责：只处理认证相关逻辑，不涉及用户资料的 CRUD
/// - 错误转换：将 Supabase 原始异常转换为应用层的 [AuthException]
/// - 可测试性：通过构造函数注入 [GoTrueClient]，便于单元测试时 mock
class AuthRepository {
  /// Supabase 认证客户端
  ///
  /// 通过构造函数注入，支持依赖注入和单元测试。
  final GoTrueClient _auth;

  /// 创建认证仓库
  ///
  /// [auth] Supabase 的 [GoTrueClient] 实例，
  /// 通常通过 Riverpod Provider 注入。
  AuthRepository(this._auth);

  String _buildRedirectUrl() {
    if (kIsWeb) {
      return Uri.base.removeFragment().replace(queryParameters: {}).toString();
    }

    return 'io.supabase.dayflow://login-callback/';
  }

  // ============================================================
  // 登录方法
  // ============================================================

  /// 使用邮箱和密码登录
  ///
  /// 调用 Supabase Auth 的 [signInWithPassword] 方法进行邮箱密码认证。
  /// 登录成功后返回 [AuthResponse]，其中包含会话信息和用户数据。
  ///
  /// [email] 用户注册时使用的邮箱地址
  /// [password] 用户密码
  ///
  /// 返回：[AuthResponse] 包含认证会话和用户信息
  ///
  /// 可能的异常：
  /// - 邮箱或密码错误
  /// - 账号未激活
  /// - 网络连接失败
  ///
  /// 示例：
  /// ```dart
  /// try {
  ///   final response = await repo.signInWithEmail(
  ///     email: 'user@example.com',
  ///     password: 'password123',
  ///   );
  ///   print('登录成功: ${response.user?.email}');
  /// } on AuthException catch (e) {
  ///   print('登录失败: ${e.message}');
  /// }
  /// ```
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthApiException catch (e) {
      // Supabase Auth API 返回的特定错误（如凭证无效）
      throw AuthException(
        _mapAuthError(e.message),
        code: e.code,
      );
    } catch (e) {
      // 其他异常（如网络错误）
      throw AuthException('登录失败，请检查网络连接后重试');
    }
  }

  /// 使用 Google 账号登录
  ///
  /// 调用 Supabase Auth 的 OAuth 流程，打开 Google 登录页面。
  /// 用户完成 Google 授权后，Supabase 自动创建或关联用户账号。
  ///
  /// 注意：此方法触发的是浏览器跳转流程，
  /// 实际的登录结果需要通过 [onAuthStateChange] 监听获取。
  ///
  /// 可能的异常：
  /// - OAuth 配置错误
  /// - 用户取消授权
  /// - 网络连接失败
  Future<void> signInWithGoogle() async {
    try {
      // 注意：redirectTo 使用的自定义 URL scheme 需要在以下位置配置：
      // - Android: android/app/src/main/AndroidManifest.xml（intent-filter）
      // - iOS: ios/Runner/Info.plist（CFBundleURLSchemes）
      // - Supabase 控制台: Authentication → URL Configuration → Redirect URLs
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _buildRedirectUrl(),
      );
    } on AuthApiException catch (e) {
      throw AuthException(
        _mapAuthError(e.message),
        code: e.code,
      );
    } catch (e) {
      throw AuthException('Google 登录失败，请稍后重试');
    }
  }

  // ============================================================
  // 注册方法
  // ============================================================

  /// 使用邮箱和密码注册新账号
  ///
  /// 调用 Supabase Auth 的 [signUp] 方法创建新用户。
  /// 注册成功后，Supabase 可能会发送验证邮件（取决于项目配置）。
  ///
  /// [email] 注册使用的邮箱地址
  /// [password] 用户设置的密码
  /// [displayName] 可选的用户显示名称，存储在 user_metadata 中
  ///
  /// 返回：[AuthResponse] 包含新创建的用户信息
  ///
  /// 可能的异常：
  /// - 邮箱已被注册
  /// - 密码不符合强度要求
  /// - 网络连接失败
  ///
  /// 示例：
  /// ```dart
  /// final response = await repo.signUpWithEmail(
  ///   email: 'new@example.com',
  ///   password: 'securePassword123',
  ///   displayName: '新用户',
  /// );
  /// ```
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _buildRedirectUrl(),
        // 将显示名称保存到 Supabase 的 user_metadata
        // 这些数据会在每次认证时自动返回
        data: displayName != null ? {'display_name': displayName} : null,
      );
      return response;
    } on AuthApiException catch (e) {
      throw AuthException(
        _mapAuthError(e.message),
        code: e.code,
      );
    } catch (e) {
      throw AuthException('注册失败，请检查网络连接后重试');
    }
  }

  // ============================================================
  // 登出方法
  // ============================================================

  /// 退出当前登录
  ///
  /// 清除本地存储的认证会话，并通知 Supabase 服务端使 token 失效。
  /// 登出后，[onAuthStateChange] 流会发出 signedOut 事件。
  ///
  /// 可能的异常：
  /// - 网络连接失败（本地会话仍会被清除）
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthApiException catch (e) {
      throw AuthException(
        _mapAuthError(e.message),
        code: e.code,
      );
    } catch (e) {
      throw AuthException('登出失败，请稍后重试');
    }
  }

  // ============================================================
  // 用户信息查询
  // ============================================================

  /// 获取当前已登录的用户
  ///
  /// 从本地存储的会话中获取当前用户信息。
  /// 如果用户未登录或会话已过期，返回 null。
  ///
  /// 注意：此方法不会发起网络请求，只读取本地缓存的用户数据。
  /// 如需获取最新的用户信息，应使用 Supabase 的 getUser() 方法。
  ///
  /// 返回：当前登录的 [User] 对象，或 null（未登录）
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ============================================================
  // 认证状态监听
  // ============================================================

  /// 监听认证状态变化
  ///
  /// 返回一个 [Stream]，在以下情况下发出事件：
  /// - 用户登录（signedIn）
  /// - 用户登出（signedOut）
  /// - Token 刷新（tokenRefreshed）
  /// - 用户信息更新（userUpdated）
  ///
  /// 通常在应用启动时开始监听，用于：
  /// - 自动跳转到登录页（登出时）
  /// - 更新 UI 中的用户信息（信息变化时）
  /// - 刷新本地数据（token 刷新后）
  ///
  /// 示例：
  /// ```dart
  /// repo.onAuthStateChange.listen((state) {
  ///   switch (state.event) {
  ///     case AuthChangeEvent.signedIn:
  ///       print('用户已登录');
  ///     case AuthChangeEvent.signedOut:
  ///       print('用户已登出');
  ///     default:
  ///       break;
  ///   }
  /// });
  /// ```
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  // ============================================================
  // 错误信息映射（私有方法）
  // ============================================================

  /// 将 Supabase Auth 的英文错误信息映射为中文
  ///
  /// Supabase 返回的错误信息是英文的，为了提供更好的用户体验，
  /// 将常见的错误信息翻译为中文。如果没有匹配的翻译，返回原始信息。
  ///
  /// [message] Supabase Auth 返回的原始错误信息
  /// 返回：对应的中文错误描述
  String _mapAuthError(String message) {
    // 将错误信息转为小写以便匹配
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid login credentials') ||
        lowerMessage.contains('invalid_credentials')) {
      return '邮箱或密码错误，请检查后重试';
    }
    if (lowerMessage.contains('email not confirmed')) {
      return '邮箱尚未验证，请查收验证邮件';
    }
    if (lowerMessage.contains('user already registered') ||
        lowerMessage.contains('already been registered')) {
      return '该邮箱已被注册，请直接登录或使用其他邮箱';
    }
    if (lowerMessage.contains('password')) {
      return '密码不符合要求，请使用至少 6 位字符';
    }
    if (lowerMessage.contains('rate limit') ||
        lowerMessage.contains('too many requests')) {
      return '操作过于频繁，请稍后再试';
    }
    if (lowerMessage.contains('network') ||
        lowerMessage.contains('connection')) {
      return '网络连接失败，请检查网络后重试';
    }

    // 没有匹配的翻译，返回通用错误信息
    return '操作失败：$message';
  }
}

// ============================================================
// Riverpod Provider（手动定义，非代码生成）
// ============================================================

/// 认证仓库 Provider
///
/// 提供全局单例的 [AuthRepository] 实例。
/// 依赖 [supabaseAuthProvider] 获取 Supabase 认证客户端。
///
/// 使用方式：
/// ```dart
/// final repo = ref.watch(authRepositoryProvider);
/// await repo.signInWithEmail(email: '...', password: '...');
/// ```
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return AuthRepository(auth);
});
