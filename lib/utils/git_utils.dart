import 'package:git/git.dart';
import 'package:gitf/models/git_user_model.dart';
import 'package:process_run/process_run.dart';

class GitUtils {
  final String? repositoryPath;
  GitUtils({this.repositoryPath});

  Future<String> version() async {
    return await _executeCommand('git --version');
  }

  Future<GitUserModel?> checkConfig() async {
    final String name = await _executeCommand(
      'git config --global user.name',
    );
    final String email = await _executeCommand(
      'git config --global user.email',
    );

    if (name.isNotEmpty &&
        email.isNotEmpty &&
        !name.startsWith('[ERROR]') &&
        !email.startsWith('[ERROR]')) {
      return GitUserModel(name: name, email: email);
    } else {
      return null;
    }
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
    final String result = await _executeCommand('git reset --hard');
    if (result.startsWith('[ERROR]')) {
      return result;
    } else {
      return 'Alterações abandonadas com sucesso ($result)';
    }
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
    await _executeCommand('git checkout -b $branch');
    final String result = await _executeCommand('git switch $branch');
    if (result.startsWith('[ERROR]') &&
        !result.contains('Switched to branch') &&
        !result.contains('Already on')) {
      return '[ERROR] Não é possível alterar de branch, verifique se possui alterações a serem enviadas e tente alterar após enviá-las';
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
        ? '[GitF] Alteracoes sem descricao.'
        : message;
    return await _executeCommand('git commit -m "$commitMessage"');
  }

  Future<String> push() async {
    final String result = await _executeCommand('git push');
    return result.replaceAll('[ERROR]', '').trim();
  }

  Future<String> commitAndPush([String? message]) async {
    await push();
    final bool hasChanges = await repositoryHasChanges();
    if (hasChanges) {
      await add();
      await commit(message);
      await push();
      return "Alterações enviadas com sucesso.";
    } else {
      return "Não há alterações a serem enviadas.";
    }
  }

  Future<String> log() async {
    return await _executeCommand('git log --shortstat');
  }

  Future<bool> repositoryHasChanges() async {
    final result = await _executeCommand('git diff');
    return result.isNotEmpty && !result.startsWith('[ERROR]');
  }

  Future<String> currentBranch() async {
    try {
      final git = await GitDir.fromExisting(repositoryPath!);
      final branch = await git.currentBranch();
      return branch.branchName;
    } catch (_) {
      return '';
    }
  }

  Future<List<String>> listBranches() async {
    try {
      final git = await GitDir.fromExisting(repositoryPath!);
      final branches = await git.branches();
      return branches.map((e) => e.branchName).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> _executeCommand(
    String command, {
    String? path,
  }) async {
    try {
      final shell = Shell(workingDirectory: path ?? repositoryPath);
      final processResult = await shell.run(command);
      final String error = processResult.errText;
      final String result = processResult.outText;
      return (result.isEmpty && error.isNotEmpty)
          ? '[ERROR] $error'.trim()
          : result.trim();
    } catch (_) {
      return '[ERROR] Ocorreu um erro durante a execução. Tente novamente.';
    }
  }
}
