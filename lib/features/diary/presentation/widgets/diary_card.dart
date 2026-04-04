/// DayFlow - 日记卡片组件
///
/// 在日记列表中展示单条日记摘要。
/// 布局：
/// - 左侧：星期几 / 几日 / 具体时间（精确到秒）
/// - 中间：日记内容文字预览（前 2-3 行）
/// - 右侧：第一张图片缩略图（若有）
/// - 底部：位置信息（若有）
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';
import 'package:dayflow/features/diary/presentation/widgets/diary_image_embed.dart';
import 'package:dayflow/shared/utils/date_utils.dart';

/// 日记卡片组件
///
/// 支持点击进入详情和滑动删除。
class DiaryCard extends StatelessWidget {
  static const double _dateColumnWidth = 58;
  static const double _contentInset = 79;
  static const double _thumbnailWidth = 72;
  static const double _collageGap = 3;

  /// 日记条目数据
  final DiaryEntry entry;

  /// 点击卡片的回调
  final VoidCallback? onTap;

  /// 滑动删除的回调
  final VoidCallback? onDelete;

  /// 是否为当天第一条日记（控制左侧日期列是否显示完整日期信息）
  final bool isFirstOfDay;

  /// 是否为当天最后一条日记（控制卡片底部圆角和间距）
  final bool isLastOfDay;

  const DiaryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
    this.isFirstOfDay = true,
    this.isLastOfDay = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 从 imageUrls 字段取出图片 URL（最多 4 张）
    final imageUrls = _extractImageUrls();

    // 提取纯文本预览（兼容 Quill Delta JSON 和旧版纯文本）
    final textPreview = _extractTextPreview();
    final locationLabel = _displayLocationLabel();

    // 同一天的卡片：首条有顶部间距，非首条紧贴上方卡片
    final topMargin = isFirstOfDay ? 4.0 : 0.0;
    // 末尾卡片有底部间距
    final bottomMargin = isLastOfDay ? 4.0 : 0.0;

    // 圆角：顶部圆角仅首条有，底部圆角仅末条有
    final borderRadius = BorderRadius.only(
      topLeft: isFirstOfDay ? const Radius.circular(12) : Radius.zero,
      topRight: isFirstOfDay ? const Radius.circular(12) : Radius.zero,
      bottomLeft: isLastOfDay ? const Radius.circular(12) : Radius.zero,
      bottomRight: isLastOfDay ? const Radius.circular(12) : Radius.zero,
    );

    final card = Card(
      elevation: 1,
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: topMargin,
        bottom: bottomMargin,
      ),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 主内容行：左侧日期列 + 中间文字 + 右侧图片 ──
              // 使用 IntrinsicHeight 让缩略图高度与内容区域对齐
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: _dateColumnWidth,
                      child: Center(child: _buildDateColumn(theme)),
                    ),
                    // 竖向分隔线
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: 10),
                    // 内容列（心情 + 文字预览 + 位置信息）
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ..._buildContentChildren(
                            textPreview,
                            locationLabel,
                            theme,
                          ),
                        ],
                      ),
                    ),
                    // 右侧缩略图（高度自动拉伸与内容对齐）
                    if (imageUrls.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildImageSection(imageUrls),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 如果提供了删除回调，则包装 Dismissible 支持滑动删除
    if (onDelete != null) {
      return Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            top: topMargin,
            bottom: bottomMargin,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: borderRadius,
          ),
          child: Icon(Icons.delete, color: theme.colorScheme.onError),
        ),
        onDismissed: (_) => onDelete!(),
        child: card,
      );
    }
    return card;
  }

  /// 构建左侧日期列
  ///
  /// [isFirstOfDay] 为 true 时显示完整：星期几 / 几号 / 时间。
  /// 为 false 时只显示时间，避免同一天的日记重复显示日期。
  Widget _buildDateColumn(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFirstOfDay) ...[
            // 星期几（周一~周日）
            Text(
              AppDateUtils.formatWeekday(entry.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            // 几号（大字体，视觉重心）
            Text(
              entry.date.day.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
          ],
          // 时间精确到秒（始终显示）
          Text(
            AppDateUtils.formatTimeWithSeconds(entry.date),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域子组件列表（心情 + 文字预览 + 位置信息）
  List<Widget> _buildContentChildren(
    String preview,
    String? locationLabel,
    ThemeData theme,
  ) {
    return [
      // 情绪标签
      if (entry.mood != null)
        Text(
          '${entry.mood!.emoji} ${entry.mood!.label}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      if (entry.mood != null) const SizedBox(height: 4),
      // 内容预览文字
      Text(
        preview.isEmpty ? '（无内容）' : preview,
        style: theme.textTheme.bodyMedium,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      // 位置信息
      if (locationLabel != null) ...[
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on,
              size: 12,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                locationLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ];
  }

  String? _displayLocationLabel() {
    final rawLabel = entry.locationName?.trim();
    if (rawLabel == null || rawLabel.isEmpty) {
      return null;
    }
    if (_looksLikeCoordinates(rawLabel)) {
      return '当前位置附近';
    }
    return rawLabel;
  }

  bool _looksLikeCoordinates(String value) {
    return RegExp(r'^-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?$').hasMatch(value);
  }

  /// 构建右侧图片区域（单图或拼图）
  ///
  /// 高度随 IntrinsicHeight 自动拉伸，与内容区域对齐。
  Widget _buildImageSection(List<String> imageUrls) {
    if (imageUrls.length >= 2 && imageUrls.length <= 4) {
      return _buildImageCollage(imageUrls);
    }
    return _buildImageThumbnail(imageUrls.first);
  }

  /// 构建右侧单张图片缩略图（圆角，高度自适应）
  Widget _buildImageThumbnail(String imageUrl) {
    final imageProvider = diaryImageProviderFor(imageUrl);
    if (imageProvider == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _thumbnailWidth,
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// 构建拼图模式（2-4 张图片，高度自适应）
  Widget _buildImageCollage(List<String> imageUrls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _thumbnailWidth,
        child: _buildCollageLayout(imageUrls),
      ),
    );
  }

  Widget _buildCollageLayout(List<String> urls) {
    switch (urls.length) {
      case 2:
        // 上下并列
        return Column(
          children: [
            Expanded(child: _collageImage(urls[0])),
            SizedBox(height: _collageGap),
            Expanded(child: _collageImage(urls[1])),
          ],
        );
      case 3:
        // 上方两张，下方一张宽图
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _collageImage(urls[0])),
                  SizedBox(width: _collageGap),
                  Expanded(child: _collageImage(urls[1])),
                ],
              ),
            ),
            SizedBox(height: _collageGap),
            Expanded(child: _collageImage(urls[2])),
          ],
        );
      case 4:
        // 2x2 网格
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _collageImage(urls[0])),
                  SizedBox(width: _collageGap),
                  Expanded(child: _collageImage(urls[1])),
                ],
              ),
            ),
            SizedBox(height: _collageGap),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _collageImage(urls[2])),
                  SizedBox(width: _collageGap),
                  Expanded(child: _collageImage(urls[3])),
                ],
              ),
            ),
          ],
        );
      default:
        return _collageImage(urls[0]);
    }
  }

  /// 拼图中的单张图片（宽高由父级 Expanded 控制）
  Widget _collageImage(String url) {
    final imageProvider = diaryImageProviderFor(url);
    if (imageProvider == null) {
      return const SizedBox.expand();
    }

    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.expand(),
    );
  }

  /// 从 imageUrls 字段提取有效图片 URL（最多 4 张）
  ///
  /// imageUrls 存储格式为逗号分隔的 URL 字符串。
  /// 跳过空字符串和无效 URL；如果历史数据中的 `imageUrls` 已损坏，
  /// 则回退到 `content` Delta 中重新提取，保证缩略图仍可展示在右侧。
  List<String> _extractImageUrls() {
    final storedImageUrls = entry.imageUrls?.trim();
    if (storedImageUrls != null && storedImageUrls.isNotEmpty) {
      // data URI 自身含有逗号，不能再用逗号分隔字段解析，直接回退到 content。
      if (!storedImageUrls.contains('data:image/')) {
        final parts = storedImageUrls.split(',');
        final urls = <String>[];
        for (final part in parts) {
          final url = resolveDiaryImageSource(part);
          if (url != null) {
            urls.add(url);
            if (urls.length >= 4) {
              return urls;
            }
          }
        }
        if (urls.isNotEmpty) {
          return urls;
        }
      }
    }

    return extractDiaryImageSourcesFromContent(entry.content, maxCount: 4);
  }

  /// 提取纯文本预览内容
  ///
  /// 支持两种格式：
  /// 1. Quill Delta JSON（列表格式）→ 提取所有 insert 字符串
  /// 2. 旧版纯文本 → 直接返回
  String _extractTextPreview() {
    final content = entry.content;
    if (content.trim().isEmpty) return '';

    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        // Quill Delta JSON：提取所有 insert 字符串
        final sb = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op['insert'] is String) {
            sb.write(op['insert'] as String);
          }
        }
        return sb.toString().trim();
      }
    } catch (_) {
      // 非 JSON 格式，当作纯文本
    }
    return content.trim();
  }
}
