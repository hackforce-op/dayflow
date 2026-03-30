const _kStartBodyTag = '<body>';
const _kEndBodyTag = '</body>';

const _kStartHtmlTag = '<html>';
const _kEndHtmlTag = '</html>';

const _kStartFragmentComment = '<!--StartFragment-->';
const _kEndFragmentComment = '<!--EndFragment-->';

String constructWindowsHtmlDescriptionHeaders(String html) {
  final htmlBodyContent = _extractBodyContent(html);

  const version = '1.0';

  final invalidHeaderHtmlTemplate = '''
Version:$version
StartHTML:0001
EndHTML:0002
StartFragment:0003
EndFragment:0004
<html>$_kStartFragmentComment<body>$htmlBodyContent</body>$_kEndFragmentComment</html>
''';

  final startHtmlPos = invalidHeaderHtmlTemplate.indexOf(_kStartHtmlTag) +
      _kStartHtmlTag.length;
  final endHtmlPos = invalidHeaderHtmlTemplate.indexOf(_kEndHtmlTag);

  final startFragment =
      invalidHeaderHtmlTemplate.indexOf(_kStartFragmentComment) +
          _kStartFragmentComment.length;
  final endFragment = invalidHeaderHtmlTemplate.indexOf(_kEndFragmentComment);

  return invalidHeaderHtmlTemplate
      .replaceFirst('0001', _formatPosition(startHtmlPos))
      .replaceFirst('0002', _formatPosition(endHtmlPos))
      .replaceFirst('0003', _formatPosition(startFragment))
      .replaceFirst('0004', _formatPosition(endFragment));
}

String _formatPosition(int position) {
  if (position == -1) {
    return position.toString();
  }
  return position.toString().padLeft(4, '0');
}

String _extractBodyContent(String html) {
  final startBodyIndex = html.toLowerCase().indexOf(_kStartBodyTag);
  final endBodyIndex = html.toLowerCase().indexOf(_kEndBodyTag);

  final bodyTagFound = startBodyIndex != -1 && endBodyIndex != -1;
  if (bodyTagFound) {
    final bodyContentStartIndex = startBodyIndex + _kStartBodyTag.length;
    final bodyContent =
        html.substring(bodyContentStartIndex, endBodyIndex).trim();
    return bodyContent;
  }

  return html.trim();
}