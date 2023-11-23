import 'package:flutter/material.dart';
import 'package:gitf/models/repository_model.dart';

class RepositoryPage extends StatefulWidget {
  final RepositoryModel repository;
  const RepositoryPage({super.key, required this.repository});

  @override
  State<RepositoryPage> createState() => _RepositoryPageState();
}

class _RepositoryPageState extends State<RepositoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.repository.name)),
      body: Center(child: Text(widget.repository.path)),
    );
  }
}
