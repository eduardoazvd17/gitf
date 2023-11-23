import '../enums/file_type.dart';

class FileModel {
  final String id;
  final String name;
  final String extension;
  final String size;
  final FileType fileType;

  FileModel({
    required this.id,
    required this.name,
    required this.extension,
    required this.size,
    required this.fileType,
  });
}
