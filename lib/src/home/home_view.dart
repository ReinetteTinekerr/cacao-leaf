import 'package:cacao_leaf_detector/main.dart';
import 'package:cacao_leaf_detector/src/db/picture_model.dart';
import 'package:cacao_leaf_detector/src/object_detector/object_detector_view.dart';
import 'package:cacao_leaf_detector/src/pictures/pictures_grid_view.dart';
import 'package:flutter/material.dart';

import '../settings/settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  static const routeName = '/';

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Stream<List<Picture>> streamPictures;
  @override
  void initState() {
    super.initState();
    streamPictures = objectBox.getAllPictures();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cacao Leaf Classifier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to the settings page. If the user leaves and returns
              // to the app after it has been killed while running in the
              // background, the navigation stack is restored.
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.restorablePushNamed(context, ObjectDetectorView.routeName);
        },
        icon: const Icon(
          Icons.camera,
        ),
        label: const Text('Camera'),
      ),
      body: StreamBuilder<List<Picture>>(
          stream: streamPictures,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final pictures = snapshot.data!;
            return PicturesGridView(pictures: pictures);
          }),
    );
  }
}
