import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:file_selector_windows/file_selector_windows.dart';

import 'environment_provider.dart';

class ImageSaver {
  FileSelectorPlatform fileSelector = FileSelectorWindows();

  static const String windowsUserHomeEnvKey = 'USERPROFILE';
  static const String picturesDirectoryName = 'Pictures';

  String? get userHome =>
      EnvironmentProvider.instance.environment[windowsUserHomeEnvKey];

  String? get picturesDirectoryPath {
    final userHome = this.userHome;
    if (userHome == null) return null;
    if (userHome.isEmpty) return null;
    return '$userHome\\$picturesDirectoryName';
  }
}