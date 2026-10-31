// On-device batch evaluation: runs the real YoloModelService (same model +
// pre/postprocessing code the app uses) against a handful of bundled sample
// images and prints results, so they can be diffed against the Python/
// Ultralytics reference for the same images and files.
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:groundnut_disease_app/services/yolo_model_service.dart';

const List<String> kEvalImages = [
  'Fungal_0_1043_jpg.rf.64329cc3cd51f41722e398f01e0d0960.jpg',
  '5454106-THUMB_jpg.rf.cd8b2c9d6953c78dd963881ca2caa430.jpg',
  'Fungal_0_1312_jpg.rf.53a79beb6f01ed51e2fd7347300f6e04.jpg',
  'Fungal_0_1211_jpg.rf.6416fd385bed870d30b6c1cb5f9b9f57.jpg',
  'Fungal_0_2018_jpg.rf.9c60d81c275331125c06f4b935048c46.jpg',
  'Fungal_0_1742_jpg.rf.b433d54f95e3a9fcebc788675427cf2e.jpg',
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('batch eval on sample images', (tester) async {
    for (final name in kEvalImages) {
      final bytes = (await rootBundle.load('assets/eval_images/$name')).buffer.asUint8List();
      final result = await YoloModelService.instance.runInference(bytes);
      // ignore: avoid_print
      print('RESULT $name => ${result.detections.map((d) => '${d.className}:${(d.confidence * 100).toStringAsFixed(1)}%').join(', ')}');
    }
  });
}
