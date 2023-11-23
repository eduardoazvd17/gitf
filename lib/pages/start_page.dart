import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gitf/models/repository_model.dart';
import 'package:gitf/pages/repository_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool _isLoading = true;
  late final List<String> _recents;

  @override
  void initState() {
    _loadRecents();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 768) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('GitF'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _menuContent,
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: VerticalDivider(),
                ),
                Expanded(child: _recentsContent),
              ],
            ),
          ),
        );
      } else {
        return Scaffold(
          drawer: Drawer(
              child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: Icon(Icons.menu),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _menuContent,
              ),
            ],
          )),
          appBar: AppBar(
            title: const Text('GitF'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _recentsContent,
          ),
        );
      }
    });
  }

  Widget get _recentsContent => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recentes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: _recents.isEmpty ? null : _clearRecents,
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
                      onTap: () => _open(repository),
                      title: Text(repository.name),
                      subtitle: Text(
                        repository.path,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() => _recents.remove(e));
                          _saveRecents();
                        },
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red[200],
                        ),
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
              onTap: _openRepository,
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Abrir um repositório existente'),
            ),
          ],
        ),
      );

  Future<void> _saveRecents() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('Recents', _recents);
  }

  Future<void> _loadRecents() async {
    if (!_isLoading) setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recents = prefs.getStringList('Recents') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _newRepository() async {}

  Future<void> _openRepository() async {
    final String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      setState(() {
        _recents.remove(path);
        _recents.add(path);
      });
      await _saveRecents();
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
      builder: (_) => AlertDialog(
        title: const Text('Limpar recentes'),
        content: const Text(
            'Deseja realmente limpar a lista de repositórios acessados recentemente?'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _recents.clear());
              _saveRecents();
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
}
