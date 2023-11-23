class RepositoryModel {
  final String name;
  final String path;

  RepositoryModel({required this.name, required this.path});
  factory RepositoryModel.fromPath(String path) {
    return RepositoryModel(
      name: path.contains('/') ? path.split('/').last : path.split('\\').last,
      path: path,
    );
  }
}
