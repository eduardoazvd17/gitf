import 'package:flutter/material.dart';
import 'package:gitf/models/file_model.dart';

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
      children: [
        AnimatedSize(
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  if (widget.fileModel.isFolder) {
                    setState(() {
                      _isOpen = !_isOpen;
                    });
                  }
                },
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
