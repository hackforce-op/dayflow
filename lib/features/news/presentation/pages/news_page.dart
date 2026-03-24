/// DayFlow - 新闻摘要列表页面（占位）
///
/// Phase 2 实现，当前为占位页面。
library;

import 'package:flutter/material.dart';

/// 新闻摘要页面（占位）
///
/// 将在 Phase 2 中实现完整的新闻列表、分类筛选和收藏功能。
class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('每日新闻')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.newspaper, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('新闻摘要功能即将上线', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('将在 Phase 2 中实现', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
