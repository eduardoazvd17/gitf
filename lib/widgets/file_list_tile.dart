import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gitf/models/file_model.dart';
import 'package:gitf/utils/repository_utils.dart';

class FileListTile extends StatefulWidget {
  final FileModel fileModel;
  const FileListTile({super.key, required this.fileModel});

  @override
  State<FileListTile> createState() => _FileListTileState();
}

class _FileListTileState extends State<FileListTile> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.fileModel.isFolder
                    ? () => setState(() => _isOpen = !_isOpen)
                    : null,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Icon(
                        widget.fileModel.isFolder
                            ? (_isOpen ? Icons.folder_open : Icons.folder)
                            : Icons.file_open_outlined,
                      ),
                    ),
                    Expanded(child: Text(widget.fileModel.name)),
                    if (widget.fileModel.isFile)
                      Row(
                        children: [
                          TextButton(
                            onPressed: () =>
                                RepositoryUtils.openFile(widget.fileModel.path),
                            child: const Text('Abrir'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (Platform.isWindows) {
                                RepositoryUtils.openDirectory(
                                  widget.fileModel.path.replaceFirst(
                                    widget.fileModel.name,
                                    '',
                                  ),
                                );
                              } else {
                                RepositoryUtils.openDirectory(
                                  widget.fileModel.path,
                                );
                              }
                            },
                            child: const Text('Mostrar na pasta'),
                          ),
                        ],
                      )
                  ],
                ),
              ),
              if (_isOpen && widget.fileModel.children != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 30, bottom: 0),
                  child: widget.fileModel.children!.isNotEmpty
                      ? Column(
                          children: widget.fileModel.children!
                              .map((e) => FileListTile(fileModel: e))
                              .toList(),
                        )
                      : const Text(
                          'Esta pasta está vazia',
                          style: TextStyle(color: Colors.grey),
                        ),
                ),
            ],
          ),
        ),
        const Divider()
      ],
    );
  }
}
