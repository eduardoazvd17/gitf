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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _menuContent(),
                  ),
                ),
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
      _commandButton(title: 'Git Pull', command: git.pull),
    ];
    if (direction == Axis.vertical) {
      return Column(children: options);
    } else {
      return Row(children: options);
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
  }) {
    final Future<void> Function()? onTap = _isLoading
        ? null
        : () async {
            setState(() => _isLoading = true);
            final String result = await command.call();
            final String log = '$result${this.log}';
            setState(() {
              this.log = log;
              _isLoading = false;
            });
          };

    return TextButton(
      onPressed: onTap,
      child: Text(title),
    );
  }
}
