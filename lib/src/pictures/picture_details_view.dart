import 'dart:io';

import 'package:cacao_leaf_detector/main.dart';
import 'package:cacao_leaf_detector/src/db/picture_model.dart';
import 'package:flutter/material.dart';

/// Displays detailed information about a SampleItem.
class PictureDetailsView extends StatelessWidget {
  const PictureDetailsView({super.key, required this.picture});
  final Picture picture;

  static const routeName = '/picture-details';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Picture;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
              onPressed: () {
                objectBox.deletePicture(args.id);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: Column(
        children: [
          Text(args.id.toString()),
          Text(args.title),
          Image.file(File(args.picture))
        ],
      ),
    );
  }
}
