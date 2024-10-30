import 'package:flutter/material.dart';
import 'package:fosdem/utils/style.dart';

// the years from 2007 until 2011 were manually converted and are not available
// on the internet. Starting from 2012 they are available
const int LOCALYEAR = 2007;
const int REMOTEYEAR = 2012;
const String PRODUCTIONURL = "https://fosdem.org/";
const String ARCHIVEURL="https://archive.fosdem.org/";
String MAINURL = PRODUCTIONURL;
const String GETEVENTURL="/schedule/xml";

const String NOT_AUTHORIZED="""Authenticatie mislukt, probeer a.u.b. opnieuw in te loggen
\nAls het probleem aanhoudt, neem dan contact op met Borre Educatief bv.""";
const String NO_NETWORK="""Er is geen verbinding met het netwerk
Controleer je verbinding en probeer het opnieuw.""";
const String OK="OK";
const  String CANCEL="Annuleren";
const int RUNDEBUGCODE = 0;
const double iconSize = 40.0;


enum Eventstatus{ EventStatusUnavailable, EventStatusAvailable, EventStatusLimitExceeded,EventStatusDownloaded, EventStatusDownloadedButUpdateAvailable }
enum VersionData{ Version1, Version2, Version3, Version4, Version5, CurrentVersion }
enum DebugLevel{ None, All, Database, XMLJSONParsing, ScreenLayout, LoginStatus, Sound}
enum ConnectivityStatus {
  WiFi,
  Cellular,
  Offline
}
const debug = DebugLevel.None;
const debugDownload = false;
const Color fosdemColor1 = fosdemBlue;
//const Color fosdemColor1 = Color(0xFFC3E0E4);
const Color fosdemColor2 = fosdemLightBlue;
//const Color fosdemColor2 = Color(0xFF5DB3BE);
const Color fosdemColor1ligther = Color(0x90C3E0E4);
const Color fosdemColor3 = Color(0xFF91CBD4);
const Color fosdemColorButtonBackground = Color(0xFF8FCDD5);
//const Color fosdemColorButtonTekst = Color(0xFF4C949A);
const Color fosdemColorButtonTekst = Colors.white;


final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
  elevation: 10.0,
  //onPrimary: Colors.black87,
  //primary: fosdemColor2,
  textStyle: const TextStyle(color: fosdemColor1),
  backgroundColor: fosdemColor1,
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);

final ButtonStyle fosdemButtonStyle = ElevatedButton.styleFrom(
  elevation: 10.0,
  //onPrimary: Colors.black87,
  //primary: fosdemColor2,
  textStyle: const TextStyle(color: fosdemColorButtonTekst),
  backgroundColor: fosdemColor1,
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);