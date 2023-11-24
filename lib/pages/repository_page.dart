import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gitf/models/repository_model.dart';
import 'package:gitf/utils/git_utils.dart';

import '../models/file_model.dart';
import '../utils/repository_utils.dart';

class RepositoryPage extends StatefulWidget {
  final RepositoryModel repository;
  const RepositoryPage({super.key, required this.repository});

  @override
  State<RepositoryPage> createState() => _RepositoryPageState();
}

class _RepositoryPageState extends State<RepositoryPage> {
  final TextEditingController _commitMessageController =
      TextEditingController();
  bool _isLoading = false;
  String _log = '';
  late final GitUtils _git;
  late final List<FileModel> _files;

  @override
  void initState() {
    _git = GitUtils(repositoryPath: widget.repository.path);
    _files = RepositoryUtils.listFiles(widget.repository.path);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repository.name),
        actions: [
          IconButton(
            onPressed: () {
              RepositoryUtils.openDirectory(widget.repository.path);
            },
            icon: const Icon(
              Icons.folder,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 285),
              child: _menuContent,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Flexible(flex: 6, child: _filesContent),
                Flexible(flex: 4, child: _logContent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get _menuContent {
    const style = TextStyle(color: Colors.grey);

    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Antes de fazer alterações, atualize o repositório:',
            style: style,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _commandButton(
              title: 'Atualizar repositório',
              command: _git.pull,
            ),
          ),
          const Text(
            'Após fazer alterações, insira a mensagem de envio (opcional) e clique em enviar alterações:',
            style: style,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                TextField(
                  controller: _commitMessageController,
                  decoration: const InputDecoration(hintText: "Mensagem..."),
                ),
                _commandButton(
                  title: 'Enviar alterações',
                  command: () async {
                    final String message = _commitMessageController.text;
                    _commitMessageController.clear();
                    return await _git.commitAndPush(message);
                  },
                ),
              ],
            ),
          ),
          const Text(
            'Caso deseje abandonar as alterações recentes, clique no botão abaixo:',
            style: style,
          ),
          _commandButton(
            title: 'Abandonar alterações',
            command: _git.resetHard,
            showConfirmation: true,
          ),
          const Text(
            'Para visualizar o histórico de envios, clique no botão abaixo:',
            style: style,
          ),
          _commandButton(title: 'Histórico de envios', command: _git.log),
          const Text(
            'Para visualizar a versão instalada do Git, clique no botão abaixo:',
            style: style,
          ),
          _commandButton(title: 'Versão do Git', command: _git.version),
        ],
      ),
    );
  }

  Widget get _filesContent => Row(
        children: [
          const VerticalDivider(width: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Arquivos:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: () {
                          final files = RepositoryUtils.listFiles(
                            widget.repository.path,
                          );
                          setState(() {
                            _files.clear();
                            _files.addAll(files);
                          });
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  Expanded(
                    child: _files.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum arquivo encontrado',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView(
                            children: _files.map((e) {
                              return ListTile(
                                title: Text(e.name),
                                subtitle: Text(e.path),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget get _logContent => Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log de execução:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _log));
                        },
                        icon: const Icon(Icons.copy),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () => setState(() => _log = ''),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _log,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _commandButton({
    required String title,
    required Future<String> Function() command,
    bool showConfirmation = false,
  }) {
    final Future<void> Function()? onTap = _isLoading
        ? null
        : () async {
            executeCommand() async {
              setState(() => _isLoading = true);
              final dateNow = DateTime.now();
              final String dateString =
                  '${dateNow.day.toString().padLeft(2, '0')}/${dateNow.month.toString().padLeft(2, '0')}/${dateNow.year.toString()} - ${dateNow.hour.toString().padLeft(2, '0')}:${dateNow.minute.toString().padLeft(2, '0')}:${dateNow.second.toString().padLeft(2, '0')}';

              final String result = await command.call();
              final String log =
                  '[$dateString]\nComando: $title\nResultado: $result\n---------------------------------------------------------------------\n$_log';

              setState(() {
                _log = log;
                _isLoading = false;
              });
            }

            if (showConfirmation) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog.adaptive(
                  title: const Text('Atenção'),
                  content: Text(
                    'Deseja realmente executar o comando: "$title"?.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        executeCommand();
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
            } else {
              executeCommand();
            }
          };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton(
        onPressed: onTap,
        child: Text(title),
      ),
    );
  }
}
