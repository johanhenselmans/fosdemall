import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as htmlparser;
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:url_launcher/url_launcher.dart';

void displayAlert(String aTitle, String aText, BuildContext context) {
  var alert = AlertDialog(
    title: Text(aTitle),
    content: Text(aText),
    actions: <Widget>[
      TextButton(
        child: const Text('OK'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ],
  );
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      });
}



class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class ServerAddress {
  String? serverName;
  String? serverIP;
  //ServerAddress()

  ServerAddress({required this.serverName, required this.serverIP});

  String? ServerName() {
    return serverName;
  }

  String? ServerIP() {
    return serverIP;
  }
}


Widget checkHTMLContent(String? content) {
  if (content != null) {
    var cleancontent = content.replaceAll('\\\\n', '');
    dom.Document document = htmlparser.parse(cleancontent);
    return html.Html(
        data: cleancontent,
        onLinkTap: (String? url, Map<String, String> attributes, dom.Element? element) {
          launchUrl(Uri.parse(url!));
        }
        );

  } else {
    return Container();
  }
}

Widget makeitUTF8(String aString) {
  return Text(cleanPersonName(aString));
}

Widget makeitUTF8Bold(String aString) {
  return Text(
    cleanPersonName(aString),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
  );
}

// Cleans mojibake and normalizes character encoding.
Future<String> replaceUnknown(dynamic data) async {
  if (data == null) return '';
  return cleanMojibake(data.toString());
}

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

String cleanMojibake(dynamic data) {
  if (data == null) return '';
  final text = data.toString();
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
    return decoded.replaceAll('\uFFFD', '');
  } catch (_) {
    return text;
  }
}

/// Cleans mojibake and ensures there is only one space between tokens of a name,
/// with leading and trailing whitespace trimmed.
String cleanPersonName(dynamic data) {
  if (data == null) return '';
  final cleaned = cleanMojibake(data).trim();
  return cleaned.replaceAll(RegExp(r'[\s\u00A0]+'), ' ');
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

String replaceLatin1(dynamic data) {
  if (data == null) return '';
  String str = data.toString();
  try {
    return cleanMojibake(str);
  } catch (_) {
    return str;
  }
}



String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
