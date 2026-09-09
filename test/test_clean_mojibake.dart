import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _hasMojibake(String text) {
  if (text.isEmpty) return false;
  final last = text.codeUnitAt(text.length - 1);
  if (last >= 0xC2 && last <= 0xDF) {
    return true;
  }
  for (int i = 0; i < text.length - 1; i++) {
    final c1 = text.codeUnitAt(i);
    final c2 = text.codeUnitAt(i + 1);
    if (c1 >= 0xC2 && c1 <= 0xEF) {
      if ((c2 >= 0x80 && c2 <= 0xBF) || _windows1252ToByte(c2) != null) {
        return true;
      }
    }
  }
  return false;
}

String cleanMojibake(String text) {
  if (!_hasMojibake(text)) {
    return text;
  }
  try {
    var s = text;
    if (s.endsWith('Ã') || s.endsWith('Å') || s.endsWith('Ä')) {
      s = '$s\u00A0';
    }
    final bytes = <int>[];
    for (int i = 0; i < s.length; i++) {
      final code = s.codeUnitAt(i);
      if (code <= 255) {
        bytes.add(code);
      } else {
        final cp = _windows1252ToByte(code);
        if (cp != null) {
          bytes.add(cp);
        } else {
          bytes.addAll(utf8.encode(s[i]));
        }
      }
    }
    final decoded = utf8.decode(bytes, allowMalformed: true);
    final cleaned = decoded.replaceAll('\uFFFD', '');
    return cleaned.isNotEmpty ? cleaned : text;
  } catch (_) {
    return text;
  }
}

int? _windows1252ToByte(int code) {
  switch (code) {
    case 0x20AC: return 0x80;
    case 0x201A: return 0x82;
    case 0x0192: return 0x83;
    case 0x201E: return 0x84;
    case 0x2026: return 0x85;
    case 0x2020: return 0x86;
    case 0x2021: return 0x87;
    case 0x02C6: return 0x88;
    case 0x2030: return 0x89;
    case 0x0160: return 0x8A;
    case 0x2039: return 0x8B;
    case 0x0152: return 0x8C;
    case 0x017D: return 0x8E;
    case 0x2018: return 0x91;
    case 0x2019: return 0x92;
    case 0x201C: return 0x93;
    case 0x201D: return 0x94;
    case 0x2022: return 0x95;
    case 0x2013: return 0x96;
    case 0x2014: return 0x97;
    case 0x02DC: return 0x98;
    case 0x2122: return 0x99;
    case 0x0161: return 0x9A;
    case 0x203A: return 0x9B;
    case 0x0153: return 0x9C;
    case 0x017E: return 0x9E;
    case 0x0178: return 0x9F;
    default: return null;
  }
}

void main() {
  final testCases = {
    'Jens MÃ¶nig': 'Jens Mönig',
    'MichaÃ«l Peeters': 'Michaël Peeters',
    'Jan-Simon MÃ¶ller': 'Jan-Simon Möller',
    'BjÃ¶rn Stenberg': 'Björn Stenberg',
    'Petteri RÃ¤ty': 'Petteri Räty',
    'Tim-Philipp MÃ¼ller': 'Tim-Philipp Müller',
    'Michael HÃ¼ttermann': 'Michael Hüttermann',
    'IstvÃ¡n Koren': 'István Koren',
    'Juan JuliÃ¡n Merelo': 'Juan Julián Merelo',
    'SaÃºl Ibarra CorretgÃ©': 'Saúl Ibarra Corretgé',
    'Martin DÄ›ckÃ½': 'Martin Děcký',
    'Eugenio PetullÃ': 'Eugenio Petullà',
    'Teodoro VadalÃ': 'Teodoro Vadalà',
    'Jordi SubirÃ': 'Jordi Subirà',
    'AleÅ¡ is a software engineer': 'Aleš is a software engineer',
    'Å½eljko Filipin': 'Željko Filipin',
    'MikoÅ\x82aj Izdebski': 'Mikołaj Izdebski',
    // Idempotency: already clean strings should not be changed or mangled
    'Aleš Matěj': 'Aleš Matěj',
    'Jens Mönig': 'Jens Mönig',
    'Martin Děcký': 'Martin Děcký',
    'Stéphane': 'Stéphane',
    'John Doe': 'John Doe',
  };

  int passed = 0;
  testCases.forEach((input, expected) {
    final result = cleanMojibake(input);
    if (result == expected) {
      print('PASS: $input -> $result');
      passed++;
    } else {
      print('FAIL: $input -> got "$result", expected "$expected"');
    }
  });

  print('$passed / ${testCases.length} tests passed.');
}
