class FileModel {
  final String name;
  final String path;
  final List<FileModel>? children;

  bool get isFolder => children != null;

  bool get isFile => children == null;

  FileModel({
    required this.name,
    required this.path,
    required this.children,
  });
}
