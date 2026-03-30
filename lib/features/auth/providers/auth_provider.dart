/// ============================================================================
/// DayFlow - 认证状态管理
/// ============================================================================
///
/// 该文件使用 Riverpod 的 [StateNotifier] 管理应用的认证状态，包括：
/// - [AuthState]：认证状态的密封类，表示所有可能的认证状态
/// - [AuthNotifier]：状态管理器，处理登录、注册、登出等业务流程
/// - [authProvider]：全局 StateNotifierProvider
///
/// 状态流转：
/// ```
/// initial → loading → authenticated（登录成功）
///                    → unauthenticated（未登录 / 登出）
///                    → error（操作失败）
/// ```
///
/// [AuthNotifier] 在创建时自动监听 Supabase 的认证状态变化，
/// 确保应用在 token 刷新、会话过期等场景下能正确更新 UI。
/// ============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:dayflow/features/auth/data/auth_repository.dart' as auth_data;
import 'package:dayflow/features/auth/domain/user_profile.dart';

// ============================================================
// 认证状态（密封类）
// ============================================================

/// 认证状态基类（密封类）
///
/// 使用密封类（sealed class）表示认证的所有可能状态，
/// 配合 Dart 3 的模式匹配，在 UI 层可以安全地处理每种状态。
///
/// 可能的状态：
/// - [AuthStateInitial]：初始状态，尚未检查认证
/// - [AuthStateLoading]：正在执行认证操作（登录、注册等）
/// - [AuthStateAuthenticated]：已登录，携带用户资料
/// - [AuthStateUnauthenticated]：未登录
/// - [AuthStateError]：操作失败，携带错误信息
///
/// UI 层使用示例：
/// ```dart
/// final state = ref.watch(authProvider);
/// switch (state) {
///   case AuthStateInitial():
///   case AuthStateLoading():
///     return LoadingWidget();
///   case AuthStateAuthenticated(:final userProfile):
///     return HomePage(user: userProfile);
///   case AuthStateUnauthenticated():
///     return LoginPage();
///   case AuthStateError(:final message):
///     return ErrorWidget(message: message);
/// }
/// ```
sealed class AuthState {
  const AuthState();
}

/// 初始状态
///
/// 应用刚启动、尚未检查本地存储的认证会话时处于此状态。
/// 通常对应闪屏页（Splash Page）的显示时机。
class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

/// 加载中状态
///
/// 正在执行认证相关的异步操作时处于此状态，包括：
/// - 登录请求进行中
/// - 注册请求进行中
/// - 登出请求进行中
///
/// UI 层应在此状态下显示加载指示器，并禁用操作按钮。
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// 已认证状态
///
/// 用户已成功登录，携带用户资料信息。
/// [userProfile] 包含用户的 ID、邮箱、昵称等信息，
/// UI 层可以用来显示用户信息和个性化内容。
class AuthStateAuthenticated extends AuthState {
  /// 当前已登录用户的资料信息
  final UserProfile userProfile;

  /// 创建已认证状态
  ///
  /// [userProfile] 必填，当前用户的资料
  const AuthStateAuthenticated(this.userProfile);
}

/// 未认证状态
///
/// 用户未登录或已主动登出。
/// 路由守卫检测到此状态时，应将用户重定向到登录页面。
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// 错误状态
///
/// 认证操作失败时进入此状态。
/// [message] 包含用户可读的错误描述（中文），
/// UI 层应通过 SnackBar 或对话框展示给用户。
class AuthStateError extends AuthState {
  /// 错误描述信息
  final String message;

  /// 创建错误状态
  ///
  /// [message] 必填，人类可读的错误描述
  const AuthStateError(this.message);
}

// ============================================================
// 认证状态管理器
// ============================================================

/// 认证状态管理器
///
/// 继承 [StateNotifier<AuthState>]，管理应用全局的认证状态。
/// 核心职责：
/// 1. 在创建时检查已有的认证会话（自动恢复登录状态）
/// 2. 监听 Supabase 的认证状态变化流（实时响应登入/登出事件）
/// 3. 提供登录、注册、登出等方法供 UI 层调用
/// 4. 将所有认证操作的结果统一映射为 [AuthState]
///
/// 生命周期：
/// - 创建时：自动调用 [_initialize] 检查现有会话
/// - 运行中：持续监听 [AuthRepository.onAuthStateChange]
/// - 销毁时：自动取消流订阅（通过 [dispose]）
class AuthNotifier extends StateNotifier<AuthState> {
  /// 认证数据仓库，封装 Supabase Auth 操作
  final auth_data.AuthRepository _authRepository;

  /// 认证状态变化流的订阅
  ///
  /// 在 [_initialize] 中创建，在 [dispose] 中取消，
  /// 确保不会产生内存泄漏。
  StreamSubscription<supabase.AuthState>? _authSubscription;

  /// 创建认证状态管理器
  ///
  /// [authRepository] 认证数据仓库实例
  ///
  /// 构造时自动执行初始化逻辑：
  /// 1. 设置初始状态为 [AuthStateInitial]
  /// 2. 检查已有的认证会话
  /// 3. 开始监听认证状态变化
  AuthNotifier(this._authRepository) : super(const AuthStateInitial()) {
    _initialize();
  }

  /// 初始化认证状态
  ///
  /// 执行以下操作：
  /// 1. 检查本地是否存在有效的认证会话（自动登录）
  /// 2. 订阅 Supabase 的认证状态变化流
  ///
  /// 如果发现已有有效会话，自动切换到 [AuthStateAuthenticated]；
  /// 否则切换到 [AuthStateUnauthenticated]。
  void _initialize() {
    // 步骤 1：检查当前认证状态
    final currentUser = _authRepository.getCurrentUser();
    if (currentUser != null) {
      // 存在已登录用户，构建用户资料并设置为已认证状态
      state = AuthStateAuthenticated(
        UserProfile.fromSupabaseUser(currentUser),
      );
    } else {
      // 无已登录用户
      state = const AuthStateUnauthenticated();
    }

    // 步骤 2：监听认证状态变化流
    // 注意：这里的 AuthState 是 Supabase 的 AuthState（已在导入时隐藏）
    _authSubscription = _authRepository.onAuthStateChange.listen(
      _handleAuthStateChange,
    );
  }

  /// 处理 Supabase 认证状态变化事件
  ///
  /// 根据不同的认证事件类型更新应用状态：
  /// - signedIn / tokenRefreshed：提取用户信息，切换到已认证状态
  /// - signedOut：切换到未认证状态
  /// - 其他事件（如 userUpdated）：根据是否有用户更新状态
  ///
  /// [authState] Supabase Auth 发出的认证状态事件
  void _handleAuthStateChange(supabase.AuthState authState) {
    // 注意：此处 AuthState 是 supabase_flutter 包中的类型
    // 因为我们在导入时隐藏了它，这里通过参数类型接收

    switch (authState.event) {
      case supabase.AuthChangeEvent.signedIn:
      case supabase.AuthChangeEvent.tokenRefreshed:
        // 用户登录成功或 token 已刷新
        final user = authState.session?.user;
        if (user != null) {
          state = AuthStateAuthenticated(
            UserProfile.fromSupabaseUser(user),
          );
        }
        return;
      case supabase.AuthChangeEvent.signedOut:
        // 用户已登出
        state = const AuthStateUnauthenticated();
        return;
      case supabase.AuthChangeEvent.userUpdated:
        // 用户信息已更新，刷新本地用户资料
        final user = authState.session?.user;
        if (user != null) {
          state = AuthStateAuthenticated(
            UserProfile.fromSupabaseUser(user),
          );
        }
        return;
      default:
        // 其他事件（如 initialSession、passwordRecovery 等），暂不处理
        return;
    }
  }

  // ============================================================
  // 公开方法 - 供 UI 层调用
  // ============================================================

  /// 邮箱密码登录
  ///
  /// 执行流程：
  /// 1. 设置状态为 [AuthStateLoading]（UI 显示加载中）
  /// 2. 调用仓库的登录方法
  /// 3. 成功 → 设置为 [AuthStateAuthenticated]
  /// 4. 失败 → 设置为 [AuthStateError]
  ///
  /// [email] 用户邮箱
  /// [password] 用户密码
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // 设置加载状态
    state = const AuthStateLoading();

    try {
      final response = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );

      // 登录成功，从响应中提取用户信息
      final user = response.user;
      if (user != null) {
        state = AuthStateAuthenticated(
          UserProfile.fromSupabaseUser(user),
        );
      } else {
        state = const AuthStateError('登录成功但未获取到用户信息');
      }
    } on auth_data.AuthException catch (e) {
      // 认证异常（已转换为中文的错误信息）
      state = AuthStateError(e.message);
    }
  }

  /// 邮箱密码注册
  ///
  /// 执行流程：
  /// 1. 设置状态为 [AuthStateLoading]
  /// 2. 调用仓库的注册方法
  /// 3. 成功 → 设置为 [AuthStateAuthenticated]（如果无需邮箱验证）
  ///         或 [AuthStateUnauthenticated]（如果需要邮箱验证）
  /// 4. 失败 → 设置为 [AuthStateError]
  ///
  /// [email] 注册邮箱
  /// [password] 用户密码
  /// [displayName] 可选的显示名称
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AuthStateLoading();

    try {
      final response = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      // 判断注册后的状态：
      // - 如果 Supabase 配置了邮箱验证，注册后 session 为 null
      // - 如果未配置邮箱验证，注册后直接获得 session
      final user = response.user;
      if (response.session != null && user != null) {
        // 无需邮箱验证，直接登录
        state = AuthStateAuthenticated(
          UserProfile.fromSupabaseUser(user),
        );
      } else {
        // 需要邮箱验证，提示用户查收邮件
        state = const AuthStateUnauthenticated();
      }
    } on auth_data.AuthException catch (e) {
      state = AuthStateError(e.message);
    }
  }

  /// Google 第三方登录
  ///
  /// 触发 Google OAuth 认证流程。
  /// 实际的登录结果会通过 [_handleAuthStateChange] 自动处理。
  ///
  /// 执行流程：
  /// 1. 设置状态为 [AuthStateLoading]
  /// 2. 调用仓库的 Google 登录方法（打开浏览器）
  /// 3. 用户完成授权后，Supabase 发出 signedIn 事件
  /// 4. [_handleAuthStateChange] 处理事件并更新状态
  Future<void> signInWithGoogle() async {
    state = const AuthStateLoading();

    try {
      await _authRepository.signInWithGoogle();
      // 注意：OAuth 登录是异步流程，
      // 实际的状态更新会在 _handleAuthStateChange 中处理
    } on auth_data.AuthException catch (e) {
      state = AuthStateError(e.message);
    }
  }

  /// 退出登录
  ///
  /// 执行流程：
  /// 1. 设置状态为 [AuthStateLoading]
  /// 2. 调用仓库的登出方法
  /// 3. 成功 → 设置为 [AuthStateUnauthenticated]
  /// 4. 失败 → 设置为 [AuthStateError]
  Future<void> signOut() async {
    state = const AuthStateLoading();

    try {
      await _authRepository.signOut();
      state = const AuthStateUnauthenticated();
    } on auth_data.AuthException catch (e) {
      state = AuthStateError(e.message);
    }
  }

  /// 释放资源
  ///
  /// 取消认证状态变化流的订阅，防止内存泄漏。
  /// 由 Riverpod 在 Provider 销毁时自动调用。
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================
// Riverpod Provider（手动定义，非代码生成）
// ============================================================

/// 认证状态 Provider
///
/// 全局状态管理器，管理应用的认证状态 [AuthState]。
/// 依赖 [authRepositoryProvider] 获取认证仓库。
///
/// 读取状态：
/// ```dart
/// final authState = ref.watch(authProvider);
/// ```
///
/// 执行操作：
/// ```dart
/// ref.read(authProvider.notifier).signIn(
///   email: 'user@example.com',
///   password: 'password',
/// );
/// ```
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(auth_data.authRepositoryProvider);
  return AuthNotifier(repository);
});
