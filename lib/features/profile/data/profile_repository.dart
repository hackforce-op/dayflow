library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dayflow/core/supabase/supabase_client.dart';
import 'package:dayflow/features/auth/domain/user_profile.dart';

class ProfileData {
  final String userId;
  final String email;
  final String displayName;
  final String? avatarUrl;

  const ProfileData({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
  });
}

class ProfileRepository {
  static const _avatarBucket = 'avatars';

  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileData> fetchProfile(UserProfile currentUser) async {
    final profile = await _client
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', currentUser.id)
        .maybeSingle();

    final displayName = profile?['display_name'] as String?;
    final avatarUrl = profile?['avatar_url'] as String?;

    return ProfileData(
      userId: currentUser.id,
      email: currentUser.email,
      displayName: (displayName?.trim().isNotEmpty ?? false)
          ? displayName!.trim()
          : (currentUser.displayName ?? currentUser.email),
      avatarUrl: (avatarUrl?.trim().isNotEmpty ?? false)
          ? avatarUrl!.trim()
          : currentUser.avatarUrl,
    );
  }

  Future<void> updateProfile({
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'display_name': displayName.trim(),
      'avatar_url': avatarUrl?.trim().isEmpty == true ? null : avatarUrl,
    });

    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'display_name': displayName.trim(),
          'avatar_url': avatarUrl?.trim().isEmpty == true ? null : avatarUrl,
        },
      ),
    );
  }

  Future<void> deleteProfile(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
  }

  /// 上传头像文件到 Supabase Storage，返回公开访问 URL。
  ///
  /// 每次上传都使用全新的文件名，彻底避免同一路径重复上传时的
  /// UPDATE / upsert 兼容性问题。上传成功后再尽力清理旧头像文件。
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
    required String mimeType,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw StateError('当前登录态已失效，请重新登录后再上传头像');
    }
    if (currentUserId != userId) {
      throw StateError('当前账号与资料所属账号不一致，请切换到正确账号后重试');
    }

    final extension = _normalizeAvatarExtension(fileExtension);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageFileName = 'avatar_$timestamp.$extension';
    final storagePath = '$userId/$storageFileName';

    // ── 第一步：上传新文件（始终作为全新 INSERT） ──
    try {
      await _client.storage.from(_avatarBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );
    } on StorageException catch (error) {
      if (_looksLikeAvatarPolicyError(error)) {
        throw StateError(
          '头像存储权限未配置完成。请在 Supabase 执行 `scripts/fix_rls_policies.sql`，'
          '并确认当前登录账号仍然有效。原始错误：${error.message}',
        );
      }
      rethrow;
    }

    // ── 第二步：尽力清理旧头像文件（失败不影响主流程） ──
    try {
      final objects = await _client.storage.from(_avatarBucket).list(
            path: userId,
          );
      final staleFiles = objects
          .map((item) => item.name.trim())
          .where((name) =>
              name.isNotEmpty &&
              name != '.emptyFolderPlaceholder' &&
              name != storageFileName)
          .map((name) => '$userId/$name')
          .toList(growable: false);
      if (staleFiles.isNotEmpty) {
        await _client.storage.from(_avatarBucket).remove(staleFiles);
        debugPrint('[ProfileRepository] 已清理 ${staleFiles.length} 个旧头像文件');
      }
    } catch (e) {
      debugPrint('[ProfileRepository] 清理旧头像时出错（可忽略）: $e');
    }

    // 返回公开 URL（附加时间戳避免浏览器缓存旧头像）
    final publicUrl =
        _client.storage.from(_avatarBucket).getPublicUrl(storagePath);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  bool _looksLikeAvatarPolicyError(StorageException error) {
    final message = error.message.toLowerCase();
    return error.statusCode == '403' ||
        message.contains('row-level security') ||
        message.contains('unauthorized');
  }

  String _normalizeAvatarExtension(String extension) {
    final normalized = extension.trim().toLowerCase().replaceFirst('.', '');
    return switch (normalized) {
      'jpeg' => 'jpg',
      'png' => 'png',
      'gif' => 'gif',
      'webp' => 'webp',
      'bmp' => 'bmp',
      _ => 'jpg',
    };
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});
