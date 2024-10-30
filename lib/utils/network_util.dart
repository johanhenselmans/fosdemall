import 'dart:async';
//import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fosdem/utils/constants.dart';

class NetworkUtil {
  // next three lines makes this class a Singleton
  static final NetworkUtil _instance =  NetworkUtil.internal();
  NetworkUtil.internal();
  factory NetworkUtil() => _instance;
//  String _connectionStatus = 'Unknown';
//  final Connectivity _connectivity = Connectivity();

  final JsonDecoder _decoder =  const JsonDecoder();
  final xmlTransformer = Xml2Json();

  Future<dynamic> getXML(String url) async {
    if (debug == DebugLevel.All || debug == DebugLevel.XMLJSONParsing) {
      print("in getXML url: $url");
    }
    int statusCode = 0;
    String res ="";
    try {
      final response = await http.get(Uri.parse(url));
      res = response.body;
      statusCode = response.statusCode;
      xmlTransformer.parse(res);
      var json = xmlTransformer.toParker();
      return json;
    } on SocketException {
      if (debug == DebugLevel.All) {
        print("No Internet Connection");
      }
      return null;
    } on HttpException {
      if (statusCode < 200 || statusCode > 400 ) {
        throw  Exception("Error while fetching data");
      }
      return null;
    } on FormatException {
      if (debug == DebugLevel.All || debug == DebugLevel.XMLJSONParsing) {
        print("Could not convert messages");
      }
      return null;
    }
    /*
    return http.get(Uri.parse(url)).then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || res == null) {
        throw  Exception("Error while fetching data");
      }
      //print(res);
      _xmlDocument = xml.XmlDocument.parse(res);
      //print("xml document:");
      //print(_xmlDocument);
      xmlTransformer.parse(res);
      //var json = xmlTransformer.toBadgerfish();
      //print('Badgerfish');
      //print(json);
      //var json = xmlTransformer.toGData();
      //print('toGData');
      //print(json);
       var json = xmlTransformer.toParker();
      //print('toParker');
      //print(json);
      return json;
    });
    */
  }


  Future<dynamic> getXMLHeavy(String url) async {
    if (debug == DebugLevel.All || debug == DebugLevel.XMLJSONParsing) {
      print(url);
    }
    int statusCode = 0;
    String res ="";
    try {
      final response = await http.get(Uri.parse(url));
      res = response.body;
      statusCode = response.statusCode;
      xmlTransformer.parse(res);
      var json = xmlTransformer.toGData();
      return json;
    } on SocketException {
      if (debug == DebugLevel.All ) {
        print("No Internet Connection");
      }
      return null;
    } on HttpException {
      if (statusCode < 200 || statusCode > 400) {
        throw  Exception("Error while fetching data");
      }
      return null;
    } on FormatException {
      if (debug == DebugLevel.All || debug == DebugLevel.XMLJSONParsing) {
        print("Could not convert messages");
      }
      return null;
    }
    /*
    return http.get(Uri.parse(url)).then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 || res == null) {
        throw  Exception("Error while fetching data");
      }
      //print(res);
      _xmlDocument = xml.XmlDocument.parse(res);
      //print("xml document:");
      //print(_xmlDocument);
      xmlTransformer.parse(res);
      //var json = xmlTransformer.toBadgerfish();
      //print('Badgerfish');
      //print(json);
      var json = xmlTransformer.toGData();
      //print('toGData');
      //print(json);
      //var json = xmlTransformer.toParker();
      //print('toParker');
      //print(json);
      return json;
    });

     */
  }

  Future<dynamic> get(String url) {
    return http.get(Uri.parse(url)).then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400) {
        throw  Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }

  Future<dynamic> post(String url, {Map? headers, body, encoding}) {
    return http
        .post(Uri.parse(url), body: body, headers: headers as Map<String, String>?, encoding: encoding)
        .then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 400 ) {
        throw  Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }



}


// https://www.filledstacks.com/post/make-your-flutter-app-network-aware-using-provider-and-connectivity-status/
// and https://stackoverflow.com/questions/58013611/fixed-error-how-to-solve-the-return-type-streamcontrollerconnectivitystatus
// for the fix of the StreamProvider arguments.
class ConnectivityService {
  // Create our public controller
  StreamController<ConnectivityStatus> connectionStatusController = StreamController<ConnectivityStatus>();

  ConnectivityService() {
    // Subscribe to the connectivity Chanaged Steam
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      // Use Connectivity() here to gather more info if you need t

      connectionStatusController.add(_getStatusFromResult(result));
    });
  }

  // Convert from the third part enum to our own enum
  ConnectivityStatus _getStatusFromResult(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.mobile)) {
      return ConnectivityStatus.Cellular;
    } else if (result.contains(ConnectivityResult.wifi)) {
      return ConnectivityStatus.WiFi;
    } else if (result.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.Offline;
    } else {
      return ConnectivityStatus.Offline;
    }
  }
}



