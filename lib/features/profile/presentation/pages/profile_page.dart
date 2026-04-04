/// DayFlow - 个人资料页面
///
/// 支持修改显示名称和通过文件选择器上传头像。
/// 头像文件上传到 Supabase Storage（avatars bucket），
/// 需要在 Supabase 控制台手动创建名为 "avatars" 的公开 bucket。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dayflow/features/profile/data/profile_repository.dart';
import 'package:dayflow/features/profile/presentation/widgets/avatar_crop_dialog.dart';
import 'package:dayflow/features/profile/providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();

  /// 当前头像 URL（网络地址，可能来自数据库或刚上传后设置）
  String? _avatarUrl;

  bool _bound = false;
  bool _saving = false;

  /// 头像上传 loading 状态
  bool _uploadingAvatar = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
      ),
      body: profileState.when(
        data: (profile) {
          // 首次加载时绑定数据（后续不再覆盖输入框内容）
          if (!_bound) {
            _bound = true;
            _nameController.text = profile.displayName;
            _avatarUrl = profile.avatarUrl;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 头像区域
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // 圆形头像
                    CircleAvatar(
                      radius: 48,
                      backgroundImage:
                          _avatarUrl != null && _avatarUrl!.trim().isNotEmpty
                              ? NetworkImage(_avatarUrl!)
                              : null,
                      child: _avatarUrl == null || _avatarUrl!.trim().isEmpty
                          ? Text(
                              _nameController.text.trim().isNotEmpty
                                  ? _nameController.text
                                      .trim()
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : profile.email.substring(0, 1).toUpperCase(),
                              style: theme.textTheme.headlineMedium,
                            )
                          : null,
                    ),
                    // 上传按钮（右下角浮动图标）
                    GestureDetector(
                      onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: _uploadingAvatar
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: theme.colorScheme.onPrimary,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 提示用户点击相机图标上传
              Center(
                child: Text(
                  '点击相机图标更换头像',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '显示名称',
                  hintText: '输入你想显示的名字',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : () => _saveProfile(profile),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('保存资料'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载资料失败: $error')),
      ),
    );
  }

  /// 选取头像、裁剪并上传到 Supabase Storage avatars bucket
  Future<void> _pickAndUploadAvatar() async {
    final pickedImage = await pickAndCropAvatarImage(context);
    if (pickedImage == null) {
      return;
    }

    setState(() => _uploadingAvatar = true);

    try {
      final profileState = ref.read(profileDataProvider);
      final profile = profileState.value;
      if (profile == null) {
        return;
      }

      final publicUrl = await ref.read(profileRepositoryProvider).uploadAvatar(
            userId: profile.userId,
            bytes: pickedImage.bytes,
            fileExtension: pickedImage.fileExtension,
            mimeType: pickedImage.mimeType,
          );

      setState(() => _avatarUrl = publicUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像上传成功，记得点"保存资料"以确认更改')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '头像上传失败: $e\n请确认已在 Supabase 控制台创建名为 avatars 的公开 Storage bucket',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _saveProfile(ProfileData profile) async {
    final displayName = _nameController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('显示名称不能为空')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            userId: profile.userId,
            displayName: displayName,
            avatarUrl: _avatarUrl,
          );

      ref.invalidate(profileDataProvider);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('资料更新成功')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
