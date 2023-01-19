import 'package:cacao_leaf_detector/objectbox.g.dart';
import 'package:cacao_leaf_detector/src/db/picture_model.dart';

const kpath = 'pictures_db';

class ObjectBoxDatabase {
  late final Store store;
  late final Box<Picture> _pictureBox;

  ObjectBoxDatabase._create(this.store) {
    _pictureBox = store.box<Picture>();
  }

  static Future<ObjectBoxDatabase> create() async {
    final store = await openStore();
    return ObjectBoxDatabase._create(store);
  }

  Picture? getPicture(int id) => _pictureBox.get(id);
  int savePicture(Picture picture) => _pictureBox.put(picture);
  bool deletePicture(int id) => _pictureBox.remove(id);
  Stream<List<Picture>> getAllPictures() => _pictureBox
      .query()
      .watch(triggerImmediately: true)
      .map((query) => query.find());
}
