import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:fosdem/utils/utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('test replaceUnknown on Adam Růžička', () async {
    String name = "Adam Růžička";
    print('INPUT: $name');
    String result = await replaceUnknown(name);
    print('RESULT: $result');
    print('RESULT CODEUNITS: ${result.codeUnits}');
  });
}
