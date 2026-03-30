import 'package:win32/win32.dart';

import '../quill_native_bridge_windows.dart';

const _kHtmlFormatName = 'HTML Format';

int? _cfHtml;

extension ClipboardHtmlFormatExt on QuillNativeBridgeWindows {
  int? get cfHtml {
    _cfHtml ??= _registerHtmlFormat();
    return _cfHtml;
  }

  int? _registerHtmlFormat() {
    final htmlFormatPointer = TEXT(_kHtmlFormatName);
    final htmlFormatId = RegisterClipboardFormat(htmlFormatPointer);
    free(htmlFormatPointer);

    if (htmlFormatId == NULL) {
      return null;
    }
    return htmlFormatId;
  }
}