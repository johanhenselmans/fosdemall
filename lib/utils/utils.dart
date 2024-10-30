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
      initialData: '',
      future: replaceUnknown(aString),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            String theString = snapshot.data;
            return Text(theString);
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
        }
        return const Text('Wating...',);
      });
}

Widget makeitUTF8Bold(String aString) {
  return FutureBuilder(
      initialData: '',
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
            return Text(snapshot.error.toString());
          }
        }
        return const Text('Wating...',);
      });
}


//Not every string is encoded the same, as I noticed while looking at authors and conference venues and titles.
Future<String> replaceUnknown(data) async {
  //three ways:
  //one:
  //Iterable <int>bytes = data.runes;
  //Uint8List bytesList = bytes as Uint8List.toList();
  //two:
//  Uint8List bytes = await Uint8List.fromList(utf8.encode(data)); // bytes with unknown encoding
// we have a winner!
  Uint8List bytesList = Uint8List.fromList(data.codeUnits); // bytes with unknown encoding
  DecodingResult result = await CharsetDetector.autoDecode(bytesList);
//  print(result.charset); // => e.g. 'SHIFT_JIS'
//  print(result.string); // => e.g. '日本語'
  return result.string;


}

String replaceLatin1(data){
 //Uint8List bytes = Uint8List.fromList(utf8.encode(data));; // bytes with unknown encoding
 // DecodingResult result = CharsetDetector.autoDecode(bytes);
//  print(result.charset); // => e.g. 'SHIFT_JIS'
//  print(result.string); // => e.g. '日本語'
//  return result.string;
  final itemUTF8 = latin1.encoder.convert(data);
  final itemString = utf8.decode(itemUTF8, allowMalformed: true);
  return itemString;
}



String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
