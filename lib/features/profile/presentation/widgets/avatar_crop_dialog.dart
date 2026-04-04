library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:dayflow/shared/widgets/blur_dialog.dart';

/// 头像裁剪前预缩放的最大边长（像素）
///
/// 头像最终用于头像显示，不需要超高分辨率。
/// 预缩放到此尺寸以内可显著提升裁剪交互流畅度，尤其在 Web 端。
const int _kMaxPreCropDimension = 1024;

class PickedAvatarImage {
  const PickedAvatarImage({
    required this.bytes,
    required this.fileExtension,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileExtension;
  final String mimeType;
}

Future<PickedAvatarImage?> pickAndCropAvatarImage(BuildContext context) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );
  if (picked == null || picked.files.isEmpty) {
    return null;
  }

  final file = picked.files.single;
  final rawBytes = file.bytes ??
      (file.path != null ? await File(file.path!).readAsBytes() : null);
  if (rawBytes == null || rawBytes.isEmpty || !context.mounted) {
    return null;
  }

  // 预缩放大图以提升裁剪控件流畅度（尤其 Web 端显著改善）
  final resizedBytes = await _resizeImageIfNeeded(rawBytes);
  if (!context.mounted) {
    return null;
  }

  final croppedBytes = await showBlurDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '裁剪头像',
    builder: (_) => _AvatarCropDialog(
      imageBytes: resizedBytes,
    ),
  );

  if (croppedBytes == null || croppedBytes.isEmpty) {
    return null;
  }

  // cropCircle() 始终输出 PNG 格式（圆形裁剪需要透明通道），
  // 因此无论原始文件格式如何，上传时统一使用 PNG。
  return PickedAvatarImage(
    bytes: croppedBytes,
    fileExtension: 'png',
    mimeType: 'image/png',
  );
}

/// 在传入 Crop 控件前对过大图片做预缩放
///
/// 使用 Flutter 内置的 `dart:ui` 编解码器将图片缩放到
/// [_kMaxPreCropDimension] 以内，输出 PNG 格式。
/// 如果图片已经在阈值以内则直接原样返回。
Future<Uint8List> _resizeImageIfNeeded(Uint8List rawBytes) async {
  try {
    final codec = await ui.instantiateImageCodec(rawBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final origWidth = image.width;
    final origHeight = image.height;

    // 图片已经足够小，无需缩放
    if (origWidth <= _kMaxPreCropDimension &&
        origHeight <= _kMaxPreCropDimension) {
      image.dispose();
      return rawBytes;
    }

    // 计算等比缩放后的目标尺寸
    final scale = _kMaxPreCropDimension /
        (origWidth > origHeight ? origWidth : origHeight);
    final targetWidth = (origWidth * scale).round();
    final targetHeight = (origHeight * scale).round();

    // 使用指定尺寸重新解码（利用引擎内部硬件加速缩放）
    image.dispose();
    final scaledCodec = await ui.instantiateImageCodec(
      rawBytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final scaledFrame = await scaledCodec.getNextFrame();
    final scaledImage = scaledFrame.image;

    final byteData =
        await scaledImage.toByteData(format: ui.ImageByteFormat.png);
    scaledImage.dispose();

    if (byteData == null) {
      return rawBytes;
    }
    return byteData.buffer.asUint8List();
  } catch (_) {
    // 缩放失败时降级为原始图片
    return rawBytes;
  }
}

class _AvatarCropDialog extends StatefulWidget {
  const _AvatarCropDialog({
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  @override
  State<_AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<_AvatarCropDialog> {
  final CropController _cropController = CropController();
  bool _cropping = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('裁剪头像'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 360,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _cropController,
                  aspectRatio: 1,
                  withCircleUi: true,
                  interactive: true,
                  radius: 18,
                  baseColor: theme.colorScheme.surfaceContainerLowest,
                  maskColor: theme.colorScheme.scrim.withAlpha(110),
                  initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                    size: 0.82,
                    aspectRatio: 1,
                  ),
                  progressIndicator: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  onCropped: (result) {
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        if (!mounted) {
                          return;
                        }
                        Navigator.of(context).pop(croppedImage);
                      case CropFailure(:final cause):
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _cropping = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('裁剪失败: $cause')),
                        );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '拖动并缩放图片，调整头像显示范围。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _cropping
              ? null
              : () {
                  setState(() {
                    _cropping = true;
                  });
                  _cropController.cropCircle();
                },
          icon: _cropping
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: const Text('使用此头像'),
        ),
      ],
    );
  }
}
