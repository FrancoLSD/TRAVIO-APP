import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versión de la app: '1.0 (1)', o '1.0' si no hay número de build.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
});

/// '26.0' de 'Version 26.0 (Build 23A341)'.
String iosVersion([String? raw]) {
  final text = raw ?? Platform.operatingSystemVersion;
  return RegExp(r'\d+(\.\d+)*').firstMatch(text)?.group(0) ?? text;
}
