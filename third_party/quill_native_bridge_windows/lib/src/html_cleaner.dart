const _kWindowsDescriptionHeaders = {
  'Version',
  'StartHTML',
  'EndHTML',
  'StartFragment',
  'EndFragment',
  'StartSelection',
  'EndSelection'
};

String stripWindowsHtmlDescriptionHeaders(String html) {
  final lines = html.split('\n');
  final cleanedLines = [...lines];

  for (final line in lines) {
    if (line.toLowerCase().startsWith('<html>')) {
      break;
    }

    final isWindowsHtmlDescriptionHeader = _kWindowsDescriptionHeaders
        .any((metadataKey) => line.startsWith('$metadataKey:'));
    if (isWindowsHtmlDescriptionHeader) {
      cleanedLines.remove(line);
      continue;
    }
  }

  return cleanedLines.join('\n');
}