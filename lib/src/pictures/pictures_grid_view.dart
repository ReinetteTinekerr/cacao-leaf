import 'dart:io';

import 'package:cacao_leaf_detector/src/db/picture_model.dart';
import 'package:cacao_leaf_detector/src/pictures/picture_arguments.dart';
import 'package:cacao_leaf_detector/src/pictures/picture_details_view.dart';
import 'package:flutter/material.dart';

class PicturesGridView extends StatelessWidget {
  const PicturesGridView({
    Key? key,
    required this.pictures,
  }) : super(key: key);

  final List<Picture> pictures;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      restorationId: 'sampleItemListView',
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: pictures.length,
      itemBuilder: (BuildContext context, int index) {
        final picture = pictures[index];
        return InkWell(
          onTap: () => Navigator.pushNamed(
              context, PictureDetailsView.routeName,
              arguments: Picture(
                  id: picture.id,
                  title: picture.title,
                  date: picture.date,
                  picture: picture.picture)),
          child: Card(
            child: Container(
              height: 290,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.all(5),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Image.file(
                          File(picture.picture),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        picture.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
