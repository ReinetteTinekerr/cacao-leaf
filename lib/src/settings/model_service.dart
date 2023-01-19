import 'package:cacao_leaf_detector/src/values/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<String> model() async {
    final SharedPreferences prefs = await _prefs;
    final model = prefs.getString(AppStrings.model);
    if (model == null) {
      prefs.setString(AppStrings.model, AppStrings.efficientnetlite0);
      return AppStrings.efficientnetlite0;
    }
    return model;
  }

  Future<void> updateModel(String model) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
    final SharedPreferences prefs = await _prefs;
    prefs.setString(AppStrings.model, model);
  }
}
