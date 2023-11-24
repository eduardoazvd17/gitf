import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:gitf/models/file_model.dart';
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

  static List<FileModel> listFiles(String path) {
    try {
      final List<FileModel> files = [];
      final List<FileSystemEntity> rawFiles = Directory(path).listSync();
      _filesMapping(path, rawFiles, files);

      files.sort((a, b) {
        if (a.children == null && b.children != null) {
          return 1;
        } else if (a.children != null && b.children == null) {
          return -1;
        } else {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
      });

      return files;
    } catch (_) {
      return [];
    }
  }

  static void _filesMapping(
    String path,
    List<FileSystemEntity> rawFiles,
    List<FileModel> files,
  ) {
    for (final rawFile in rawFiles) {
      final String name = rawFile.path.replaceAll('$path/', '');
      if (rawFile.statSync().type == FileSystemEntityType.directory) {
        final List<FileModel> children = [];
        final List<FileSystemEntity> rawChildren =
            Directory(rawFile.path).listSync();
        _filesMapping(rawFile.path, rawChildren, children);
        files.add(
          FileModel(name: name, path: rawFile.path, children: children),
        );
      } else {
        files.add(
          FileModel(name: name, path: rawFile.path, children: null),
        );
      }
    }
  }
}
