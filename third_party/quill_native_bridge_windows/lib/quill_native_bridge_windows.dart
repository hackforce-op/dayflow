import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:quill_native_bridge_platform_interface/quill_native_bridge_platform_interface.dart';
import 'package:win32/win32.dart';

import 'src/clipboard_html_format.dart';
import 'src/html_cleaner.dart';
import 'src/html_formatter.dart';
import 'src/image_saver.dart';

class QuillNativeBridgeWindows extends QuillNativeBridgePlatform {
  static void registerWith() {
    QuillNativeBridgePlatform.instance = QuillNativeBridgeWindows();
  }

  @override
  Future<bool> isSupported(QuillNativeBridgeFeature feature) async => {
        QuillNativeBridgeFeature.getClipboardHtml,
        QuillNativeBridgeFeature.copyHtmlToClipboard,
        QuillNativeBridgeFeature.saveImage,
      }.contains(feature);

  @override
  Future<String?> getClipboardHtml() async {
    if (OpenClipboard(NULL) == FALSE) {
      assert(
        false,
        'Unknown error while opening the clipboard. Error code: ${GetLastError()}',
      );
      return null;
    }

    try {
      final htmlFormatId = cfHtml;

      if (htmlFormatId == null) {
        assert(false, 'Failed to register clipboard HTML format.');
        return null;
      }

      if (IsClipboardFormatAvailable(htmlFormatId) == FALSE) {
        return null;
      }

      final clipboardDataHandle = GetClipboardData(htmlFormatId);
      if (clipboardDataHandle == NULL) {
        assert(
          false,
          'Failed to get clipboard data. Error code: ${GetLastError()}',
        );
        return null;
      }

      final clipboardDataPointer = Pointer.fromAddress(clipboardDataHandle);
      final lockedMemoryPointer = GlobalLock(clipboardDataPointer);
      if (lockedMemoryPointer == nullptr) {
        assert(
          false,
          'Failed to lock global memory. Error code: ${GetLastError()}',
        );
        return null;
      }

      final windowsHtmlWithMetadata =
          lockedMemoryPointer.cast<Utf8>().toDartString();
      GlobalUnlock(clipboardDataPointer);

      final cleanedHtml =
          stripWindowsHtmlDescriptionHeaders(windowsHtmlWithMetadata);

      return cleanedHtml;
    } finally {
      CloseClipboard();
    }
  }

  @override
  Future<void> copyHtmlToClipboard(String html) async {
    if (OpenClipboard(NULL) == FALSE) {
      assert(
        false,
        'Unknown error while opening the clipboard. Error code: ${GetLastError()}',
      );
      return;
    }

    final windowsClipboardHtml = constructWindowsHtmlDescriptionHeaders(html);
    final htmlPointer = windowsClipboardHtml.toNativeUtf8();

    try {
      if (EmptyClipboard() == FALSE) {
        assert(
          false,
          'Failed to empty the clipboard. Error code: ${GetLastError()}',
        );
        return;
      }

      final htmlFormatId = cfHtml;

      if (htmlFormatId == null) {
        assert(
          false,
          'Failed to register clipboard HTML format. Error code: ${GetLastError()}',
        );
        return;
      }

      final unitSize = sizeOf<Uint8>();
      final htmlSize = (htmlPointer.length + 1) * unitSize;

      final clipboardMemoryHandle = GlobalAlloc(GMEM_MOVABLE, htmlSize);
      if (clipboardMemoryHandle == nullptr) {
        assert(
          false,
          'Failed to allocate memory for the clipboard content. Error code: ${GetLastError()}',
        );
        return;
      }

      final lockedMemoryPointer = GlobalLock(clipboardMemoryHandle);
      if (lockedMemoryPointer == nullptr) {
        GlobalFree(clipboardMemoryHandle);
        assert(
          false,
          'Failed to lock global memory. Error code: ${GetLastError()}',
        );
        return;
      }

      final targetMemoryPointer = lockedMemoryPointer.cast<Uint8>();
      final sourcePointer = htmlPointer.cast<Uint8>();

      for (var i = 0; i < htmlPointer.length; i++) {
        targetMemoryPointer[i] = (sourcePointer + i).value;
      }

      (targetMemoryPointer + htmlPointer.length).value = NULL;

      GlobalUnlock(clipboardMemoryHandle);

      if (SetClipboardData(htmlFormatId, clipboardMemoryHandle.address) ==
          NULL) {
        GlobalFree(clipboardMemoryHandle);
        assert(
          false,
          'Failed to set the clipboard data: ${GetLastError()}',
        );
      }
    } finally {
      CloseClipboard();
      calloc.free(htmlPointer);
    }
  }

  @visibleForTesting
  static ImageSaver imageSaver = ImageSaver();

  @override
  Future<ImageSaveResult> saveImage(
    Uint8List imageBytes, {
    required ImageSaveOptions options,
  }) async {
    final typeGroup = XTypeGroup(
      label: 'Images',
      extensions: [options.fileExtension],
    );

    final saveLocation = await imageSaver.fileSelector.getSaveLocation(
      options: SaveDialogOptions(
        suggestedName: '${options.name}.${options.fileExtension}',
        initialDirectory: imageSaver.picturesDirectoryPath,
      ),
      acceptedTypeGroups: [typeGroup],
    );
    final imageFilePath = saveLocation?.path;
    if (imageFilePath == null) {
      return ImageSaveResult.io(filePath: null);
    }
    final imageFile = File(imageFilePath);
    await imageFile.writeAsBytes(imageBytes);

    return ImageSaveResult.io(filePath: imageFile.path);
  }

  @override
  Future<void> openGalleryApp() async {
    final uriPtr = TEXT('ms-photos:');
    final openPtr = 'open'.toNativeUtf16();

    ShellExecute(NULL, openPtr, uriPtr, nullptr, nullptr, SW_SHOWNORMAL);

    free(uriPtr);
    free(openPtr);
  }
}