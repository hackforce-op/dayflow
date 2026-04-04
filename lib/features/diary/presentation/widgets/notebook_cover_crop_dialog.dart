/// DayFlow - 日记本封面裁剪对话框
///
/// 选取并裁剪日记本封面图片（长方形裁剪，3:4 比例）。
/// 复用头像裁剪的预缩放逻辑。
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:dayflow/shared/widgets/blur_dialog.dart';

/// 封面裁剪前预缩放的最大边长
const int _kMaxPreCropDimension = 1024;

/// 裁剪结果
class PickedCoverImage {
  const PickedCoverImage({
    required this.bytes,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String mimeType;
}

/// 选取并裁剪日记本封面
///
/// 返回裁剪后的 PNG 格式图片数据，或 null（用户取消）。
Future<PickedCoverImage?> pickAndCropCoverImage(BuildContext context) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );
  if (picked == null || picked.files.isEmpty) return null;

  final file = picked.files.single;
  final rawBytes = file.bytes ??
      (file.path != null ? await File(file.path!).readAsBytes() : null);
  if (rawBytes == null || rawBytes.isEmpty || !context.mounted) return null;

  // 预缩放大图
  final resizedBytes = await _resizeIfNeeded(rawBytes);
  if (!context.mounted) return null;

  final croppedBytes = await showBlurDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '裁剪封面',
    builder: (_) => _CoverCropDialog(imageBytes: resizedBytes),
  );

  if (croppedBytes == null || croppedBytes.isEmpty) return null;

  return PickedCoverImage(
    bytes: croppedBytes,
    mimeType: 'image/png',
  );
}

/// 预缩放大图
Future<Uint8List> _resizeIfNeeded(Uint8List rawBytes) async {
  try {
    final codec = await ui.instantiateImageCodec(rawBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    if (image.width <= _kMaxPreCropDimension &&
        image.height <= _kMaxPreCropDimension) {
      image.dispose();
      return rawBytes;
    }

    final scale = _kMaxPreCropDimension /
        (image.width > image.height ? image.width : image.height);
    final targetWidth = (image.width * scale).round();
    final targetHeight = (image.height * scale).round();

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

    return byteData?.buffer.asUint8List() ?? rawBytes;
  } catch (_) {
    return rawBytes;
  }
}

/// 封面裁剪对话框（3:4 长方形）
class _CoverCropDialog extends StatefulWidget {
  const _CoverCropDialog({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_CoverCropDialog> createState() => _CoverCropDialogState();
}

class _CoverCropDialogState extends State<_CoverCropDialog> {
  final CropController _cropController = CropController();
  bool _cropping = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('裁剪封面'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 400,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _cropController,
                  // 3:4 比例匹配日记本封面
                  aspectRatio: 3 / 4,
                  withCircleUi: false,
                  interactive: true,
                  radius: 12,
                  baseColor: theme.colorScheme.surfaceContainerLowest,
                  maskColor: theme.colorScheme.scrim.withAlpha(110),
                  initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                    size: 0.82,
                    aspectRatio: 3 / 4,
                  ),
                  progressIndicator: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  onCropped: (result) {
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        if (!mounted) return;
                        Navigator.of(context).pop(croppedImage);
                      case CropFailure(:final cause):
                        if (!mounted) return;
                        setState(() => _cropping = false);
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
              '拖动并缩放图片，调整封面显示范围。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _cropping
              ? null
              : () {
                  setState(() => _cropping = true);
                  _cropController.crop();
                },
          child: _cropping
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确定'),
        ),
      ],
    );
  }
}
