import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem/utils/utils.dart';

void main() {
  group('cleanPersonName tests', () {
    test('Collapses multiple spaces between name tokens into a single space', () {
      expect(cleanPersonName('Abhishek  Lekshmanan'), 'Abhishek Lekshmanan');
      expect(cleanPersonName('Alexis   Jacomy '), 'Alexis Jacomy');
      expect(cleanPersonName('  David    Navarro  '), 'David Navarro');
      expect(cleanPersonName('Luis Ramirez  Vargas'), 'Luis Ramirez Vargas');
    });

    test('Handles tabs, newlines, and non-breaking spaces correctly', () {
      expect(cleanPersonName('Abhishek\t\tLekshmanan'), 'Abhishek Lekshmanan');
      expect(cleanPersonName('First\u00A0\u00A0Last'), 'First Last');
      expect(cleanPersonName('John\nDoe'), 'John Doe');
    });

    test('Cleans mojibake while normalizing whitespace', () {
      expect(cleanPersonName('Jens  MÃ¶nig'), 'Jens Mönig');
      expect(cleanPersonName('AleÅ¡   MatÄ›j'), 'Aleš Matěj');
      expect(cleanPersonName('Martin  DÄ›ckÃ½'), 'Martin Děcký');
    });

    test('Preserves already clean single-spaced names idempotently', () {
      expect(cleanPersonName('Abhishek Lekshmanan'), 'Abhishek Lekshmanan');
      expect(cleanPersonName('Stéphane'), 'Stéphane');
      expect(cleanPersonName('Aleš Matěj'), 'Aleš Matěj');
      expect(cleanPersonName('Jens Mönig'), 'Jens Mönig');
    });

    test('Handles null and empty inputs safely', () {
      expect(cleanPersonName(null), '');
      expect(cleanPersonName(''), '');
      expect(cleanPersonName('     '), '');
    });

    test('replaceUnknown preserves Jordi Subirà', () async {
      final res = await replaceUnknown('Jordi Subirà');
      print('replaceUnknown("Jordi Subirà") -> "$res"');
      expect(res, 'Jordi Subirà');
    });
  });
}
