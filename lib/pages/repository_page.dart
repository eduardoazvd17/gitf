import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gitf/models/repository_model.dart';
import 'package:gitf/utils/git_utils.dart';

import '../utils/repository_utils.dart';

class RepositoryPage extends StatefulWidget {
  final RepositoryModel repository;
  const RepositoryPage({super.key, required this.repository});

  @override
  State<RepositoryPage> createState() => _RepositoryPageState();
}

class _RepositoryPageState extends State<RepositoryPage> {
  final ScrollController logScrollController = ScrollController();
  bool _isLoading = false;
  String log = '';
  late final GitUtils git;

  @override
  void initState() {
    git = GitUtils(repositoryModel: widget.repository);
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 768) {
            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: _menuContent(),
                  ),
                ),
                Expanded(child: _logContent),
              ],
            );
          } else {
            return Column(
              children: [
                _menuContent(direction: Axis.horizontal),
                Expanded(child: _logContent),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _menuContent({Axis direction = Axis.vertical}) {
    List<Widget> options = [
      _commandButton(title: 'Pegar alterações', command: git.pull),
      _commandButton(title: 'Enviar alterações', command: git.commitAndPush),
      _commandButton(title: 'Histórico de envios', command: git.log),
      _commandButton(
        title: 'Abandonar alterações',
        command: git.resetHard,
        showConfirmation: true,
      ),
      _commandButton(title: 'Versão do Git', command: git.version),
    ];
    if (direction == Axis.vertical) {
      return Column(children: options);
    } else {
      return Wrap(children: options);
    }
  }

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
                          Clipboard.setData(ClipboardData(text: log));
                        },
                        icon: const Icon(Icons.copy),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () => setState(() => log = ''),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: logScrollController,
                  child: SelectableText(
                    log,
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
              final String result = await command.call();
              final String log = '$result${this.log}';
              setState(() {
                this.log = log;
                _isLoading = false;
              });
            }

            if (showConfirmation) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
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
      padding: const EdgeInsets.all(5.0),
      child: TextButton(
        onPressed: onTap,
        child: Text(title),
      ),
    );
  }
}
