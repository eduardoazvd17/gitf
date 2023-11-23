import 'package:gitf/models/repository_model.dart';
import 'package:shell/shell.dart';

class GitUtils {
  final RepositoryModel repositoryModel;
  GitUtils({required this.repositoryModel});

  Future<String> checkout(String branch) async {
    return await _executeCommand('git checkout -b $branch');
  }

  Future<String> fetch() async {
    return await _executeCommand('git fetch');
  }

  Future<String> pull() async {
    return await _executeCommand('git pull');
  }

  Future<String> push() async {
    return await _executeCommand('git push');
  }

  Future<String> add([List<String>? files]) async {
    if (files != null) {
      String result = "";
      for (final String file in files) {
        result += '\n\n${await _executeCommand('git add $file')}';
      }
      return result;
    } else {
      return await _executeCommand('git add *');
    }
  }

  Future<String> commit(String message) async {
    return await _executeCommand('git commit -m "$message"');
  }

  Future<String> _executeCommand(String command) async {
    final shell = Shell(workingDirectory: repositoryModel.path);
    final processResult = await shell.run(command);
    return processResult.stdout.toString();
  }
}
