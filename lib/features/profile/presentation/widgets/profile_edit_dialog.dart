library;

import 'package:flutter/material.dart';

import 'package:dayflow/features/profile/data/profile_repository.dart';
import 'package:dayflow/features/profile/presentation/widgets/avatar_crop_dialog.dart';

class ProfileEditResult {
  const ProfileEditResult({
    required this.displayName,
    required this.avatarUrl,
  });

  final String displayName;
  final String? avatarUrl;
}

class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({
    required this.profile,
    required this.onUploadAvatar,
    required this.onSave,
    super.key,
  });

  final ProfileData profile;
  final Future<String> Function(PickedAvatarImage image) onUploadAvatar;
  final Future<void> Function(String displayName, String? avatarUrl) onSave;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late String _displayName;
  late String? _avatarUrl;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayName = widget.profile.displayName;
    _avatarUrl = widget.profile.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDialogHeight = (MediaQuery.sizeOf(context).height - 32)
        .clamp(320.0, 720.0)
        .toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 460,
        maxHeight: maxDialogHeight,
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '个人资料',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _saving ? null : _closeDialog,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundImage:
                                _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                            child: _avatarUrl == null || _avatarUrl!.isEmpty
                                ? Text(
                                    _initialOf(
                                      _displayName.trim(),
                                      widget.profile.email,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap:
                                  _uploading || _saving ? null : _handleUploadAvatar,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: theme.colorScheme.primary,
                                child: _uploading
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.crop,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '先裁剪再上传头像',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // 使用无控制器输入框，避免弹窗关闭动画期间出现已释放控制器报错。
                      TextFormField(
                        initialValue: _displayName,
                        enabled: !_saving,
                        onChanged: (value) {
                          setState(() {
                            _displayName = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: '显示名称',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: widget.profile.email,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '邮箱',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : _closeDialog,
                    child: const Text('取消'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving ? null : _handleSave,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUploadAvatar() async {
    final pickedImage = await pickAndCropAvatarImage(context);
    if (!mounted || pickedImage == null) {
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      final uploadedUrl = await widget.onUploadAvatar(pickedImage);
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarUrl = uploadedUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像上传成功，点击保存后生效')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('头像上传失败: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    final displayName = _displayName.trim();
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
      await widget.onSave(displayName, _avatarUrl);
      if (!mounted) {
        return;
      }
      _closeDialog(
        ProfileEditResult(
          displayName: displayName,
          avatarUrl: _avatarUrl,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('资料更新失败: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _closeDialog<T extends Object?>([T? result]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(result);
  }

  String _initialOf(String displayName, String email) {
    final source = displayName.isNotEmpty ? displayName : email;
    return source.substring(0, 1).toUpperCase();
  }
}
