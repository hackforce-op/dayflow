/// DayFlow - 日记本卡片组件
///
/// 展示单个日记本的封面和名称，支持右键/长按弹出交互菜单。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dayflow/features/diary/domain/notebook.dart';

/// 日记本卡片交互菜单操作
enum NotebookAction {
  /// 重命名
  rename,

  /// 更换封面
  changeCover,

  /// 移动至（调整排序位置）
  moveTo,

  /// 删除
  delete,
}

/// 日记本卡片组件
///
/// 布局：上方为封面图（3:4 比例），下方为日记本名称。
/// 桌面端右键、移动端长按弹出交互菜单。
class NotebookCard extends StatelessWidget {
  /// 日记本数据
  final Notebook notebook;

  /// 点击卡片回调
  final VoidCallback? onTap;

  /// 菜单操作回调
  final void Function(NotebookAction action)? onAction;

  const NotebookCard({
    super.key,
    required this.notebook,
    this.onTap,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 桌面端和 Web 端使用右键菜单，移动端使用长按菜单
    final useContextMenu = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        kIsWeb;

    return GestureDetector(
      onTap: onTap,
      // 移动端长按显示菜单
      onLongPressStart:
          useContextMenu ? null : (details) => _showMenu(context, details.globalPosition),
      // 桌面端/Web 右键菜单
      onSecondaryTapUp:
          useContextMenu ? (details) => _showMenu(context, details.globalPosition) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 封面区域（3:4 比例）
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHigh,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: notebook.coverUrl != null && notebook.coverUrl!.isNotEmpty
                  ? Image.network(
                      notebook.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildDefaultCover(theme),
                    )
                  : _buildDefaultCover(theme),
            ),
          ),
          const SizedBox(height: 8),
          // 日记本名称
          Text(
            notebook.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 默认封面（无图时显示图标）
  Widget _buildDefaultCover(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.book_outlined,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
      ),
    );
  }

  /// 弹出交互菜单
  Future<void> _showMenu(BuildContext context, Offset position) async {
    if (onAction == null) return;

    final result = await showMenu<NotebookAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: const [
        PopupMenuItem(
          value: NotebookAction.rename,
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('重命名'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: NotebookAction.changeCover,
          child: ListTile(
            leading: Icon(Icons.image_outlined),
            title: Text('更换封面'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: NotebookAction.moveTo,
          child: ListTile(
            leading: Icon(Icons.drive_file_move_outlined),
            title: Text('移动至'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: NotebookAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outlined, color: Colors.red),
            title: Text('删除', style: TextStyle(color: Colors.red)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );

    if (result != null) {
      onAction!(result);
    }
  }
}
