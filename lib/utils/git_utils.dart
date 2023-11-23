import 'package:gitf/models/repository_model.dart';
import 'package:process_run/process_run.dart';

class GitUtils {
  final RepositoryModel repositoryModel;
  GitUtils({required this.repositoryModel});

  Future<String> version() async {
    return await _executeCommand('git --version');
  }

  Future<bool> checkConfig() async {
    final String name = await _executeCommand('git config --global user.name');
    final String email =
        await _executeCommand('git config --global user.email');
    return name.isNotEmpty && email.isNotEmpty;
  }

  Future<void> setConfig(String username, String email) async {
    await _executeCommand('git config --global user.name "$username"');
    await _executeCommand('git config --global user.email "$email"');
  }

  Future<String> clone(String url, String path) async {
    return await _executeCommand('git clone $url', path: path);
  }

  Future<String> init() async {
    return await _executeCommand('git init');
  }

  Future<String> resetHard() async {
    return await _executeCommand('git reset --hard');
  }

  Future<String> changeRemote(String url, {String name = 'origin'}) async {
    await removeRemote(name: name);
    final String result = await _executeCommand('git remote add $name $url');
    await fetch();
    return result;
  }

  Future<String> removeRemote({String name = 'origin'}) async {
    return await _executeCommand('git remote remove $name');
  }

  Future<String> checkout(String branch) async {
    final String result = await _executeCommand('git checkout -b $branch');
    if (result.startsWith('[ERROR]')) {
      return result;
    } else {
      await pull();
      return 'Branch alterada para: $branch';
    }
  }

  Future<String> fetch() async {
    final String result = await _executeCommand('git fetch');
    if (result.startsWith('[ERROR]')) {
      return result;
    } else {
      return 'Repositório sincronizado.';
    }
  }

  Future<String> pull() async {
    await fetch();
    final String result = await _executeCommand('git pull');
    if (result.startsWith('[ERROR]')) {
      return result;
    } else {
      return 'Arquivos atualizados com sucesso.';
    }
  }

  Future<void> add([List<String>? files]) async {
    if (files != null) {
      for (final String file in files) {
        await _executeCommand('git add $file');
      }
    } else {
      await _executeCommand('git add *');
    }
  }

  Future<String> commit([String? message]) async {
    final String commitMessage = (message == null || message.trim().isEmpty)
        ? '[GitF] Alterações sem descrição.'
        : message;
    return await _executeCommand('git commit -m "$commitMessage"');
  }

  Future<String> push() async {
    final String result = await _executeCommand('git push');
    if (result.startsWith('[ERROR]')) {
      return result;
    } else {
      return 'Alterações enviadas com sucesso.';
    }
  }

  Future<String> commitAndPush([String? message]) async {
    await push();
    final bool hasChanges = await repositoryHasChanges();
    if (hasChanges) {
      await add();
      await commit(message);
      return await push();
    } else {
      return "Não há alterações a serem enviadas.";
    }
  }

  Future<String> log() async {
    return await _executeCommand('git log');
  }

  Future<bool> repositoryHasChanges() async {
    final result = await _executeCommand('git diff');
    return result.isNotEmpty && !result.startsWith('[ERROR]');
  }

  Future<String> _executeCommand(
    String command, {
    String? path,
  }) async {
    try {
      final shell = Shell(workingDirectory: path ?? repositoryModel.path);
      final processResult = await shell.run(command);
      final String error = processResult.errText;
      final String result = processResult.outText;
      return (result.isEmpty && error.isNotEmpty) ? '[ERROR] $error' : result;
    } catch (_) {
      return 'Ocorreu um erro durante a execução. Tente novamente.';
    }
  }
}
