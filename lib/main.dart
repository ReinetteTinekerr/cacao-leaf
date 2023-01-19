import 'package:cacao_leaf_detector/src/db/database.dart';
import 'package:cacao_leaf_detector/src/settings/model_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

List<CameraDescription> cameras = [];

late final ObjectBoxDatabase objectBox;

void main() async {
  // Set up the SettingsController, which will glue user settings to multiple
  WidgetsFlutterBinding.ensureInitialized();

  objectBox = await ObjectBoxDatabase.create();

  cameras = await availableCameras(); // Flutter Widgets.
  final settingsController =
      SettingsController(SettingsService(), ModelService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MyApp(settingsController: settingsController));
}
