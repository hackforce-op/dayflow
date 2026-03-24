/// ============================================================================
/// DayFlow - 用户资料领域模型
/// ============================================================================
///
/// 该文件定义了认证模块的核心领域模型 [UserProfile]，包括：
/// - 用户基本信息（ID、邮箱、昵称、头像）
/// - 用户个性化设置（以 Map 形式存储）
/// - 从 Supabase [User] 对象的工厂构造函数
/// - JSON 序列化 / 反序列化支持
///
/// [UserProfile] 是应用层面的用户抽象，与 Supabase 的 [User] 解耦，
/// 使得未来更换后端服务时只需修改工厂方法，不影响业务逻辑。
/// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

/// 用户资料领域模型
///
/// 表示应用中的一个用户，包含身份信息和个性化设置。
/// 该类是不可变的（immutable），修改时需通过 [copyWith] 创建新实例。
///
/// 创建示例：
/// ```dart
/// final profile = UserProfile(
///   id: 'uuid-123',
///   email: 'user@example.com',
///   displayName: '张三',
///   createdAt: DateTime.now(),
/// );
/// ```
class UserProfile {
  /// 用户的唯一标识符
  ///
  /// 对应 Supabase Auth 中的 user ID（UUID 格式）。
  /// 用于关联用户的所有数据（日记、任务等）。
  final String id;

  /// 用户的注册邮箱
  ///
  /// 用于登录认证和找回密码。
  /// 来自 Supabase Auth 的 email 字段。
  final String email;

  /// 用户显示名称（昵称）
  ///
  /// 可选字段，用户可以在注册时或之后设置。
  /// 在 UI 中作为用户的可读标识显示。
  /// 如果为 null，UI 层应回退显示邮箱地址。
  final String? displayName;

  /// 用户头像 URL
  ///
  /// 可选字段，支持以下来源：
  /// - Supabase Storage 中的自定义上传头像
  /// - OAuth 提供商（Google、GitHub）返回的头像链接
  /// 如果为 null，UI 层应显示默认头像。
  final String? avatarUrl;

  /// 用户个性化设置
  ///
  /// 以键值对形式存储各类偏好设置，例如：
  /// - 'theme': 'dark'（主题偏好）
  /// - 'language': 'zh'（语言偏好）
  /// - 'notifications': true（通知开关）
  ///
  /// 使用 Map 而非固定字段，便于灵活扩展设置项。
  final Map<String, dynamic> settings;

  /// 用户账号的创建时间
  ///
  /// 记录用户首次注册的时间，用于显示"加入 DayFlow xx 天"等信息。
  final DateTime createdAt;

  /// 构造函数
  ///
  /// [id] 必填，用户唯一标识
  /// [email] 必填，用户邮箱
  /// [displayName] 可选，显示名称
  /// [avatarUrl] 可选，头像地址
  /// [settings] 可选，默认为空 Map
  /// [createdAt] 必填，账号创建时间
  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.settings = const {},
    required this.createdAt,
  });

  // ============================================================
  // 工厂构造函数
  // ============================================================

  /// 从 Supabase [User] 对象创建 [UserProfile]
  ///
  /// 将 Supabase Auth 返回的用户数据映射到应用领域模型。
  /// Supabase 的 [User.userMetadata] 中可能包含以下字段：
  /// - 'display_name' 或 'full_name'：用户名称（注册时填写或 OAuth 返回）
  /// - 'avatar_url'：用户头像（OAuth 登录时由提供商返回）
  ///
  /// [user] Supabase Auth 返回的用户对象
  factory UserProfile.fromSupabaseUser(User user) {
    // 从用户元数据中提取显示名称
    // OAuth 登录时可能使用 'full_name'，邮箱注册时可能使用 'display_name'
    final metadata = user.userMetadata ?? {};
    final displayName =
        metadata['display_name'] as String? ??
        metadata['full_name'] as String?;

    // 从用户元数据中提取头像 URL（通常由 OAuth 提供商返回）
    final avatarUrl = metadata['avatar_url'] as String?;

    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      displayName: displayName,
      avatarUrl: avatarUrl,
      settings: {},
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  /// 从 JSON 数据创建 [UserProfile]
  ///
  /// 用于从本地缓存或远程 API 响应中恢复用户资料。
  /// JSON 键名采用 snake_case 格式。
  ///
  /// [json] JSON 对象
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ============================================================
  // 序列化方法
  // ============================================================

  /// 将用户资料转换为 JSON 格式
  ///
  /// 用于向远程 API 发送数据或保存到本地缓存。
  /// 输出的键名采用 snake_case 格式。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'settings': settings,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ============================================================
  // 实用方法
  // ============================================================

  /// 创建当前对象的副本，并允许修改部分字段
  ///
  /// 由于 [UserProfile] 是不可变的，修改时需要创建新实例。
  /// 未指定的字段将保留原始值。
  ///
  /// 示例：
  /// ```dart
  /// final updated = profile.copyWith(displayName: '新昵称');
  /// ```
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, '
        'displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.avatarUrl == avatarUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, displayName, avatarUrl, createdAt);
  }
}
