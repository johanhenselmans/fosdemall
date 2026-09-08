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
  return FutureBuilder(
      initialData: aString,
      future: replaceUnknown(aString),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            String theString = snapshot.data;
            return Text(theString);
          } else if (snapshot.hasError) {
            return Text(aString);
          }
        }
        return Text(aString);
      });
}

Widget makeitUTF8Bold(String aString) {
  return FutureBuilder(
      initialData: aString,
      future: replaceUnknown(aString),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            String theString = snapshot.data;
            return Text(
              theString,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            );
          } else if (snapshot.hasError) {
            return Text(
              aString,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            );
          }
        }
        return Text(
          aString,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      });
}


//Not every string is encoded the same, as I noticed while looking at authors and conference venues and titles.
Future<String> replaceUnknown(dynamic data) async {
  if (data == null) return '';
  String str = data.toString();
  try {
    Uint8List bytesList = Uint8List.fromList(str.codeUnits);
    DecodingResult result = await CharsetDetector.autoDecode(bytesList);
    if (result.string.contains('\uFFFD') && !str.contains('\uFFFD')) {
      return replaceLatin1(str);
    }
    return result.string;
  } catch (e) {
    return replaceLatin1(str);
  }
}

String replaceLatin1(dynamic data) {
  if (data == null) return '';
  String str = data.toString();
  try {
    final itemUTF8 = latin1.encoder.convert(str);
    final itemString = utf8.decode(itemUTF8, allowMalformed: false);
    return itemString;
  } catch (_) {
    return str;
  }
}



String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
