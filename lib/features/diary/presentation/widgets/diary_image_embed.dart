library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

const double kDiaryImageMinWidth = 120;
const double kDiaryImageDefaultWidth = 320;

/// 兼容多种历史/当前图片 embed 数据格式，统一解析出真正的图片地址。
///
/// 这里同时兼容：
/// - 直接字符串 URL
/// - `{"image": "https://..."}`
/// - `{"source": "https://..."}`
/// - 被序列化成 JSON 字符串的图片对象
String? resolveDiaryImageSource(Object? rawImageSource) {
  if (rawImageSource == null) {
    return null;
  }

  if (rawImageSource is Map) {
    final imageMap = Map<String, dynamic>.from(rawImageSource);
    final candidates = <Object?>[
      imageMap[BlockEmbed.imageType],
      imageMap['image'],
      imageMap['source'],
      imageMap['src'],
      imageMap['url'],
      imageMap['data'],
      if (imageMap.length == 1) imageMap.values.first,
    ];

    for (final candidate in candidates) {
      final resolved = resolveDiaryImageSource(candidate);
      if (resolved != null) {
        return resolved;
      }
    }
    return null;
  }

  final source = rawImageSource.toString().trim();
  if (source.isEmpty) {
    return null;
  }
  if (source.startsWith('data:image/')) {
    return source;
  }

  if (source.startsWith('{') && source.endsWith('}')) {
    try {
      final decoded = jsonDecode(source);
      return resolveDiaryImageSource(decoded);
    } catch (_) {
      // 不是合法 JSON 时按普通字符串继续处理。
    }
  }

  if (source.contains('base64') && !source.startsWith('http')) {
    final parts = source.split(',');
    return 'data:image/png;base64,${parts.last.trim()}';
  }

  final uri = Uri.tryParse(source);
  if (uri?.hasScheme == true) {
    return source;
  }
  return null;
}

/// 判断图片地址是否仍为本地 data URI。
bool isDiaryImageDataUri(String imageSource) {
  return imageSource.startsWith('data:image/');
}

/// 从日记内容 JSON 中提取图片地址列表。
///
/// 这里直接解析最终保存到数据库的 Delta JSON，确保卡片缩略图与详情页
/// 读取的是同一份数据源，避免 `imageUrls` 与 `content` 不一致时出现丢图。
List<String> extractDiaryImageSourcesFromContent(
  String content, {
  int? maxCount,
}) {
  if (content.trim().isEmpty) {
    return const [];
  }

  try {
    final decoded = jsonDecode(content);
    if (decoded is! List) {
      return const [];
    }

    final sources = <String>[];
    for (final operation in decoded) {
      if (operation is! Map) {
        continue;
      }

      final insert = operation['insert'];
      if (insert is! Map) {
        continue;
      }

      final imageSource = resolveDiaryImageSource(
        insert[BlockEmbed.imageType] ?? insert['image'] ?? insert,
      );
      if (imageSource == null || imageSource.isEmpty) {
        continue;
      }

      sources.add(imageSource);
      if (maxCount != null && sources.length >= maxCount) {
        break;
      }
    }

    return sources;
  } catch (_) {
    return const [];
  }
}

/// 将历史 delta 中的图片 insert 统一归一化为 Quill 当前可稳定回读的格式。
///
/// 同时确保每个 BlockEmbed（图片）独占一行：前面必须以 \n 结尾，后面必须跟 \n，
/// 否则 Document.fromJson 在解析时可能静默丢弃嵌入块。
List<dynamic> normalizeDiaryDeltaImageInserts(List<dynamic> rawDelta) {
  final result = <dynamic>[];

  for (var i = 0; i < rawDelta.length; i++) {
    final operation = rawDelta[i];
    if (operation is! Map) {
      result.add(operation);
      continue;
    }

    final normalizedOperation = Map<String, dynamic>.from(operation);
    final insert = normalizedOperation['insert'];

    // 非 Map 的 insert（纯文本）直接保留
    if (insert is! Map) {
      result.add(normalizedOperation);
      continue;
    }

    final insertMap = Map<String, dynamic>.from(insert);
    final rawImage = insertMap[BlockEmbed.imageType] ?? insertMap['image'];
    final normalizedSource = resolveDiaryImageSource(rawImage);
    if (normalizedSource == null) {
      // 非图片类 embed，直接保留
      result.add(normalizedOperation);
      continue;
    }

    // ── 归一化图片 embed ──
    normalizedOperation['insert'] = <String, dynamic>{
      BlockEmbed.imageType: normalizedSource,
    };

    // ── 确保图片 embed 前面以 \n 结尾（独占一行的要求） ──
    if (result.isNotEmpty) {
      final prev = result.last;
      if (prev is Map) {
        final prevInsert = prev['insert'];
        if (prevInsert is String && prevInsert.isNotEmpty && !prevInsert.endsWith('\n')) {
          result[result.length - 1] = <String, dynamic>{
            ...Map<String, dynamic>.from(prev),
            'insert': '$prevInsert\n',
          };
        }
      }
    }

    result.add(normalizedOperation);

    // ── 确保图片 embed 后面紧跟 \n ──
    final next = i + 1 < rawDelta.length ? rawDelta[i + 1] : null;
    final needsTrailingNewline = next == null ||
        (next is Map && next['insert'] is Map) ||
        (next is Map && next['insert'] is String && !(next['insert'] as String).startsWith('\n'));
    if (needsTrailingNewline) {
      result.add(<String, dynamic>{'insert': '\n'});
    }
  }

  return result;
}

enum DiaryImageAlignment {
  left,
  center,
  right,
}

class DiaryImageStyle {
  const DiaryImageStyle({
    required this.width,
    required this.alignment,
  });

  final double width;
  final DiaryImageAlignment alignment;
}

DiaryImageStyle parseDiaryImageStyle(
  String? rawStyle, {
  String? rawWidth,
  double fallbackWidth = kDiaryImageDefaultWidth,
  double? maxWidth,
}) {
  final normalized = rawStyle?.toLowerCase() ?? '';
  final widthMatch = RegExp(
    r'width:\s*([0-9]+(?:\.[0-9]+)?)px',
    caseSensitive: false,
  ).firstMatch(normalized);
  final parsedWidth =
      widthMatch != null ? double.tryParse(widthMatch.group(1)!) : null;
  final widthFromAttribute = rawWidth != null
      ? double.tryParse(rawWidth.toLowerCase().replaceAll('px', '').trim())
      : null;

  return DiaryImageStyle(
    width: clampDiaryImageWidth(
      parsedWidth ?? widthFromAttribute ?? fallbackWidth,
      maxWidth: maxWidth,
    ),
    alignment: _parseDiaryImageAlignment(normalized),
  );
}

String buildDiaryImageStyleString({
  required double width,
  required DiaryImageAlignment alignment,
}) {
  final safeWidth = width < kDiaryImageMinWidth ? kDiaryImageMinWidth : width;
  final widthLabel = safeWidth == safeWidth.roundToDouble()
      ? safeWidth.toStringAsFixed(0)
      : safeWidth.toStringAsFixed(1);

  final marginStyle = switch (alignment) {
    DiaryImageAlignment.left => 'margin-left: 0; margin-right: auto;',
    DiaryImageAlignment.center => 'margin-left: auto; margin-right: auto;',
    DiaryImageAlignment.right => 'margin-left: auto; margin-right: 0;',
  };

  return 'display: block; width: ${widthLabel}px; $marginStyle';
}

double clampDiaryImageWidth(double width, {double? maxWidth}) {
  final safeWidth = width > 0 ? width : kDiaryImageDefaultWidth;
  if (maxWidth == null || maxWidth <= 0) {
    return safeWidth < kDiaryImageMinWidth ? kDiaryImageMinWidth : safeWidth;
  }

  final lowerBound =
      maxWidth < kDiaryImageMinWidth ? maxWidth : kDiaryImageMinWidth;
  return safeWidth.clamp(lowerBound, maxWidth).toDouble();
}

class DiaryImageEmbedBuilder extends EmbedBuilder {
  DiaryImageEmbedBuilder({
    this.onImageTap,
    this.defaultWidth = kDiaryImageDefaultWidth,
    this.maxHeight = 420,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final void Function(
    String imageUrl,
    int documentOffset,
    DiaryImageStyle style,
  )? onImageTap;
  final double defaultWidth;
  final double maxHeight;
  final BorderRadius borderRadius;

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final imageSource = resolveDiaryImageSource(embedContext.node.value.data);
    if (imageSource == null || imageSource.isEmpty) {
      return const SizedBox.shrink();
    }

    final rawStyle = embedContext
        .node.style.attributes[Attribute.style.key]?.value as String?;
    final rawWidth = embedContext
        .node.style.attributes[Attribute.width.key]?.value
        ?.toString();
    final imageTapHandler = onImageTap;
    final isInteractive = imageTapHandler != null && !embedContext.readOnly;
    final imageProvider = diaryImageProviderFor(imageSource);
    if (imageProvider == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 48;
        final imageStyle = parseDiaryImageStyle(
          rawStyle,
          rawWidth: rawWidth,
          fallbackWidth: defaultWidth,
          maxWidth: availableWidth,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Align(
            alignment: _alignmentFor(imageStyle.alignment),
            child: MouseRegion(
              cursor:
                  isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
              child: GestureDetector(
                onTap: isInteractive
                    ? () => imageTapHandler(
                          imageSource,
                          embedContext.node.documentOffset,
                          imageStyle,
                        )
                    : null,
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: availableWidth,
                      maxHeight: maxHeight,
                    ),
                    child: Image(
                      image: ResizeImage(
                        imageProvider,
                        width: (imageStyle.width * 2).round(),
                        policy: ResizeImagePolicy.fit,
                      ),
                      width: imageStyle.width,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Alignment _alignmentFor(DiaryImageAlignment alignment) {
    return switch (alignment) {
      DiaryImageAlignment.left => Alignment.centerLeft,
      DiaryImageAlignment.center => Alignment.center,
      DiaryImageAlignment.right => Alignment.centerRight,
    };
  }
}

/// 根据图片地址生成对应的图片 Provider。
///
/// 兼容远程 URL 与 data URI，供详情页、编辑页、列表卡片统一复用。
ImageProvider<Object>? diaryImageProviderFor(String imageSource) {
  if (isDiaryImageDataUri(imageSource)) {
    final separator = imageSource.indexOf(',');
    if (separator < 0) {
      return null;
    }
    try {
      return MemoryImage(base64Decode(imageSource.substring(separator + 1)));
    } catch (_) {
      return null;
    }
  }

  return NetworkImage(imageSource);
}

DiaryImageAlignment _parseDiaryImageAlignment(String normalizedStyle) {
  if (normalizedStyle.contains('margin: auto') ||
      normalizedStyle.contains('margin: 0 auto')) {
    return DiaryImageAlignment.center;
  }

  final hasLeftAuto = normalizedStyle.contains('margin-left: auto');
  final hasRightAuto = normalizedStyle.contains('margin-right: auto');
  if (hasLeftAuto && hasRightAuto) {
    return DiaryImageAlignment.center;
  }
  if (hasLeftAuto) {
    return DiaryImageAlignment.right;
  }
  if (hasRightAuto) {
    return DiaryImageAlignment.left;
  }
  return DiaryImageAlignment.center;
}
