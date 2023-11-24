import 'package:flutter/material.dart';
import 'package:gitf/models/git_user_model.dart';
import 'package:gitf/models/repository_model.dart';
import 'package:gitf/pages/repository_page.dart';
import 'package:gitf/utils/git_utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../utils/repository_utils.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  GitUserModel? _gitUserModel;
  bool _isLoading = true;
  late final List<String> _recents;

  bool get _buttonIsEnabled => _gitUserModel != null && !_isLoading;

  @override
  void initState() {
    GitUtils().checkConfig().then((gitUserModel) {
      setState(() => _gitUserModel = gitUserModel);
      if (_gitUserModel == null) _changeGitUser();
      RepositoryUtils.loadRecents().then((recents) {
        setState(() {
          _recents = recents;
          _isLoading = false;
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 768) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _menuContent,
                  const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: VerticalDivider(),
                  ),
                  Expanded(child: _recentsContent()),
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            drawer: Drawer(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Column(
                      children: [
                        Text(
                          'GitF',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        const Text('Gerenciamento de Repositórios'),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: _menuContent,
                  ),
                ],
              ),
            ),
            appBar: AppBar(
              title: const Text('Recentes'),
              actions: [
                IconButton(
                  onPressed:
                      (_isLoading || _recents.isEmpty) ? null : _clearRecents,
                  color: Colors.red,
                  icon: const Icon(Icons.delete_forever),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _recentsContent(showHeader: false),
            ),
          );
        }
      },
    );
  }

  Widget _recentsContent({bool showHeader = true}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recentes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed:
                        (_isLoading || _recents.isEmpty) ? null : _clearRecents,
                    color: Colors.red,
                    icon: const Icon(Icons.delete_forever),
                  ),
                ],
              ),
            ),
          if (_isLoading)
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: CircularProgressIndicator()),
                ],
              ),
            )
          else if (_recents.isEmpty)
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      'Nenhum repositório acessado recentemente',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView(
                children: _recents.reversed.map((e) {
                  final repository = RepositoryModel.fromPath(e);
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ListTile(
                      enabled: _buttonIsEnabled,
                      onTap: () => _open(repository),
                      title: Text(repository.name),
                      subtitle: Text(
                        repository.path,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => RepositoryUtils.openDirectory(e),
                            icon: const Icon(
                              Icons.folder,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () {
                              setState(() => _recents.remove(e));
                              RepositoryUtils.saveRecents(_recents);
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red[200],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );

  Widget get _menuContent => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          children: [
            ListTile(
              enabled: false,
              onTap: _newRepository,
              leading: const Icon(Icons.add),
              title: const Text('Criar um novo repositório'),
            ),
            const SizedBox(height: 16),
            ListTile(
              enabled: false,
              onTap: _newRepository,
              leading: const Icon(Icons.cloud),
              title: const Text('Clonar repositório'),
            ),
            const SizedBox(height: 16),
            ListTile(
              enabled: _buttonIsEnabled,
              onTap: _openRepository,
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Abrir um repositório existente'),
            ),
            const SizedBox(height: 32),
            ListTile(
              onTap: _aboutApp,
              leading: const Icon(Icons.info_outline),
              title: const Text('Sobre este app'),
            ),
            if (_gitUserModel != null) ...[
              const SizedBox(height: 32),
              ListTile(
                onTap: _changeGitUser,
                leading: const Icon(Icons.change_circle_outlined),
                title: Text(_gitUserModel!.name),
                subtitle: Text(_gitUserModel!.email),
              ),
            ]
          ],
        ),
      );

  Future<void> _newRepository() async {}

  Future<void> _openRepository() async {
    final String? path = await RepositoryUtils.select();
    if (path != null) {
      if (await RepositoryUtils.validate(path)) {
        setState(() {
          _recents.remove(path);
          _recents.add(path);
        });
        RepositoryUtils.saveRecents(_recents);
        _open(RepositoryModel.fromPath(path));
      } else {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (_) => AlertDialog.adaptive(
            title: const Text('Diretório inválido'),
            content: const Text(
              'O diretório selecionado não é um repositório do Git.',
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _open(RepositoryModel repository) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepositoryPage(repository: repository),
      ),
    );
  }

  void _clearRecents() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        title: const Text('Limpar recentes'),
        content: const Text(
            'Deseja realmente limpar a lista de repositórios acessados recentemente?'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _recents.clear());
              RepositoryUtils.saveRecents(_recents);
              Navigator.of(context).pop();
            },
            child: const Text('Sim'),
          ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Não'),
          ),
        ],
      ),
    );
  }

  void _aboutApp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GitF',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            const Text('Gerenciamento de Repositórios'),
            const SizedBox(height: 20),
            const Text('Desenvolvido por: Eduardo Azevedo'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    launchUrlString(
                      'https://www.linkedin.com/in/eduardoazvd17/',
                    );
                  },
                  child: const Text('LinkedIn'),
                ),
                TextButton(
                  onPressed: () {
                    launchUrlString('https://github.com/eduardoazvd17/');
                  },
                  child: const Text('GitHub'),
                ),
                TextButton(
                  onPressed: () {
                    launchUrlString('https://eduardoazevedo.com/');
                  },
                  child: const Text('Site'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  void _changeGitUser() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '${_gitUserModel == null ? 'Inserir' : 'Alterar'} identificação no Git',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Insira seu nome de usuário e seu e-mail nos campos abaixo\nambos serão usados apenas para identificação.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  label: Text("Nome:"),
                ),
              ),
            ),
            SizedBox(
              width: 250,
              child: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  label: Text("E-mail:"),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final git = GitUtils();
                      await git.setConfig(name, email);
                      final gitUserModel = await git.checkConfig();
                      setState(() => _gitUserModel = gitUserModel);
                      if (_gitUserModel != null) {
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text("Salvar"),
                  ),
                  if (_gitUserModel != null)
                    TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: const Text("Cancelar"),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
      barrierDismissible: _gitUserModel != null,
    );
  }
}
