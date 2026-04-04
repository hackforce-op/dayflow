/// DayFlow - 设置页面
///
/// 提供主题切换、账户管理等设置项。
/// 可以通过路由显示为完整页面，也可以通过 [showSettingsDialog] 以模糊卡片弹窗形式展示。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/theme/app_theme.dart';
import 'package:dayflow/core/theme/theme_provider.dart';
import 'package:dayflow/core/theme/theme_style_provider.dart';
import 'package:dayflow/core/supabase/supabase_client.dart';
import 'package:dayflow/core/router/app_router.dart';
import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/diary/data/diary_repository.dart';
import 'package:dayflow/features/planner/data/task_repository.dart';
import 'package:dayflow/features/profile/data/profile_repository.dart';
import 'package:dayflow/shared/widgets/blur_dialog.dart';

// ============================================================
// 公开入口：以模糊卡片弹窗方式展示设置
// ============================================================

/// 弹出带背景模糊的设置卡片
///
/// 替代 context.push(RoutePaths.settings)，以弹窗覆盖当前页面，
/// 点击背景或按下 ESC 即可关闭。
Future<void> showSettingsDialog(BuildContext context) async {
  // 预加载偏好值，避免弹窗打开后异步 setState 导致的视觉闪烁
  final prefs = await SharedPreferences.getInstance();
  final tapToEdit = prefs.getBool(AppConstants.tapToEditPrefsKey) ?? false;
  if (!context.mounted) return;
  return showBlurDialog<void>(
    context: context,
    builder: (ctx) => _SettingsCard(initialTapToEdit: tapToEdit),
  );
}

// ============================================================
// 路由页面入口（保留，供 go_router 跳转使用）
// ============================================================

/// 设置页面（路由版本）
///
/// 当需要通过导航路由打开设置时使用。
/// 内容与弹窗版本完全一致，只是包裹了 Scaffold。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const _SettingsBody(),
    );
  }
}

// ============================================================
// 弹窗卡片容器
// ============================================================

/// 设置弹窗卡片容器
///
/// 将设置内容包裹在有最大宽度约束的卡片中，与弹窗背景融合。
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({this.initialTapToEdit});

  final bool? initialTapToEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        elevation: 8,
        shadowColor: theme.colorScheme.shadow.withAlpha(100),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.settings_outlined,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Text('设置', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            // 内容区域
            Flexible(child: _SettingsBody(initialTapToEdit: initialTapToEdit)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 设置内容组件（被页面版与弹窗版共用）
// ============================================================

/// 设置内容主体
///
/// 不含 Scaffold，可在页面或弹窗中任意复用。
class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody({this.initialTapToEdit});

  /// 由父级预加载的偏好值，避免异步加载导致弹窗闪烁
  final bool? initialTapToEdit;

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  /// 是否正在执行耗时账户操作（清除记录/删除账户）
  bool _processing = false;

  /// 「点击即可编辑」开关状态
  late bool _tapToEdit;

  @override
  void initState() {
    super.initState();
    _tapToEdit = widget.initialTapToEdit ?? false;
    if (widget.initialTapToEdit == null) {
      _loadTapToEditPref();
    }
  }

  /// 从 SharedPreferences 读取「点击即可编辑」偏好
  Future<void> _loadTapToEditPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _tapToEdit = prefs.getBool(AppConstants.tapToEditPrefsKey) ?? false;
      });
    }
  }

  /// 切换「点击即可编辑」并持久化
  Future<void> _toggleTapToEdit(bool value) async {
    setState(() => _tapToEdit = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.tapToEditPrefsKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final themePreset = ref.watch(themePresetProvider);
    final authState = ref.watch(authProvider);
    final userId =
        authState is AuthStateAuthenticated ? authState.userProfile.id : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      shrinkWrap: true,
      children: [
        // ── 显示模式 ──────────────────────────────────
        _SectionLabel('显示模式', theme),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _ModeChip(
              label: '跟随系统',
              icon: Icons.brightness_auto_outlined,
              selected: themeMode == ThemeMode.system,
              onSelected: () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.system),
            ),
            _ModeChip(
              label: '白天',
              icon: Icons.light_mode_outlined,
              selected: themeMode == ThemeMode.light,
              onSelected: () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.light),
            ),
            _ModeChip(
              label: '黑夜',
              icon: Icons.dark_mode_outlined,
              selected: themeMode == ThemeMode.dark,
              onSelected: () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.dark),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── 主题风格 ──────────────────────────────────
        _SectionLabel('主题风格', theme),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: ThemePreset.values
              .map(
                (preset) => _ThemePresetChip(
                  preset: preset,
                  selected: themePreset == preset,
                  onSelected: () =>
                      ref.read(themePresetProvider.notifier).setPreset(preset),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),

        // ── 编辑偏好 ──────────────────────────────────
        _SectionLabel('编辑偏好', theme),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('点击即可编辑'),
          subtitle: const Text('在日记详情页点击内容区域直接进入编辑'),
          value: _tapToEdit,
          onChanged: _toggleTapToEdit,
        ),
        const SizedBox(height: 16),

        // ── 账户与数据 ────────────────────────────────
        _SectionLabel('账户与数据', theme),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: userId == null || _processing ? null : _clearAllRecords,
          icon: const Icon(Icons.cleaning_services_outlined, size: 18),
          label: const Text('清空当前账户所有记录'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: _processing
              ? null
              : () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (mounted) context.go(RoutePaths.login);
                },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('退出当前账户'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: userId == null || _processing ? null : _deleteAccount,
          icon: const Icon(Icons.delete_forever_outlined, size: 18),
          label: const Text('删除当前账户'),
        ),
      ],
    );
  }

  Future<void> _clearAllRecords() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthStateAuthenticated) return;

    final confirmed = await showBlurDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空记录'),
        content: const Text('将清空当前账户的日记与规划记录，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _processing = true);

    try {
      final uid = authState.userProfile.id;
      await ref.read(diaryRepositoryProvider).clearAllEntriesForUser(uid);
      await ref.read(taskRepositoryProvider).clearAllTasksForUser(uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清空当前账户记录')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('清空失败: $error')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _deleteAccount() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthStateAuthenticated) return;

    final confirmed = await showBlurDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('二次确认删除账户'),
        content: const Text('将删除当前账户的所有数据，此操作不可撤销。确认吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _processing = true);

    try {
      final uid = authState.userProfile.id;
      await ref.read(diaryRepositoryProvider).clearAllEntriesForUser(uid);
      await ref.read(taskRepositoryProvider).clearAllTasksForUser(uid);
      await ref.read(profileRepositoryProvider).deleteProfile(uid);

      final supabase = ref.read(supabaseClientProvider);
      try {
        await supabase.rpc('delete_current_user');
      } catch (_) {
        // 后端未提供 RPC 时降级：仅清数据并退出
      }

      await ref.read(authProvider.notifier).signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('账户数据已删除，已退出登录')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('删除失败: $error')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}

// ============================================================
// 小型辅助组件
// ============================================================

/// 分区标签
class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// 显示模式选择 Chip
class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      avatar: Icon(icon, size: 16,
          color: selected
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}

/// 主题预设选择 Chip（带颜色小点）
class _ThemePresetChip extends StatelessWidget {
  final ThemePreset preset;
  final bool selected;
  final VoidCallback onSelected;

  const _ThemePresetChip({
    required this.preset,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(preset.label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}
