import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:open_dir/open_dir.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RepositoryUtils {
  static void openDirectory(String path) async {
    try {
      final openDir = OpenDir();
      await openDir.openNativeDir(path: path);
    } catch (_) {}
  }

  static Future<String?> select() async {
    try {
      return await FilePicker.platform.getDirectoryPath();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> validate(String path) async {
    try {
      final dir = Directory.fromUri(Uri.directory('$path/.git'));
      return await dir.exists();
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveRecents(List<String> recents) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('Recents', recents);
    } catch (_) {}
  }

  static Future<List<String>> loadRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('Recents') ?? [];
    } catch (_) {
      return [];
    }
  }
}
