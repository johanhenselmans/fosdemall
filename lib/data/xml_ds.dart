import 'dart:async';
import 'dart:convert';
import 'package:fosdem/utils/network_util.dart';
import 'package:fosdem/models/conference.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/utils/constants.dart';
import 'package:fosdem/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:xml2json/xml2json.dart';



class ConferenceAndEvent{
  Conference? conference;
  List<Event>? eventList;

  ConferenceAndEvent(this.conference, this.eventList);

}

class XMLDatasource {
  final NetworkUtil _netUtil = NetworkUtil();


  List<dynamic> fillEventList(dynamic eventsList, String currentDate){
//    Map mapEntry = {...aMap};
    //mapEntry = aMap;
    var tmpEventList = [];
//    if (mapEntry.key == "event") {
//      var eventsList = mapEntry.value;
      if (eventsList.runtimeType
          .toString()
          .contains("List<dynamic>")) {
        for (var eventsMap in eventsList) {
          //      var eventsMap = entry[0].value;
//                      for (var eventMap in eventsMap.entries){
          if (debug == DebugLevel.All ||
              debug == DebugLevel.XMLJSONParsing) {
            print("value event map: ${eventsMap.runtimeType.toString()}");
          }
          Map anEventMap = returnAProperEventMap(
              eventsMap, currentDate);
          tmpEventList.add(anEventMap);
        }
      } else {
        Map anEventMap = returnAProperEventMap(
            eventsList, currentDate);
        tmpEventList.add(anEventMap);
      }
      //                     }

    return tmpEventList;
  }

  ConferenceAndEvent transformConferenceAndEvent(Map response) {
    var tmpEventList = [];
    Conference? aConference;
    String currentDate = "";

    var tmpMapList = response['schedule'];


    for (var entry in tmpMapList.entries) {
      //This is the hlobal conference information, only one will be available per schedule
      if (entry.key == "conference") {
        aConference =
            Conference.fromMapToObject(
                response['schedule']['conference']);
        if (debug == DebugLevel.All ||
            debug == DebugLevel.XMLJSONParsing) {
          //print("RuntimeEventcatecory:"+conference.runtimeType.toString());
          print("Conference ${aConference.title}");
          print("Start: ${aConference.start}");
          print("End RuntimeType: ${aConference.end.runtimeType
              .toString()}");
          print(
              "days: ${aConference.days.toString()} Type: ${aConference
                  .days
                  .runtimeType.toString()}");
        }
      }
      if (entry.key == "day") {
        List dayList = entry.value;
        if (debug == DebugLevel.All ||
            debug == DebugLevel.XMLJSONParsing) {
          // if there is only one event, a hashmap is returned,
          // otherwise a list of hashmaps.
          // _InternalLinkedHashMap<String, dynamic>
          // List<dynamic>
          print("Type day list: ${dayList.runtimeType.toString()}");
        }
        if (dayList.runtimeType.toString().contains("List<dynamic>")) {
          for (var listEntry in dayList) {
            if (debug == DebugLevel.All ||
                debug == DebugLevel.XMLJSONParsing) {
              print(
                  "Type listEntry:${listEntry.runtimeType.toString()}");
            }
            for (var entry in listEntry.entries) {
              if (debug == DebugLevel.All ||
                  debug == DebugLevel.XMLJSONParsing) {
                print("Type entry: ${listEntry.runtimeType.toString()}");
              }
              if (entry.key == "date") {
                currentDate = entry.value;
              }
              // there are two separate json files, one orderer via room per day,
              //the other via event per day
              if (entry.key == "room") {
                var roomList = entry.value;
                for (var listEntry in roomList) {
                  for (var mapEntry in listEntry.entries) {
                    if (mapEntry.key == "name") {
                      if (debug == DebugLevel.All ||
                          debug == DebugLevel.XMLJSONParsing) {
                        print('room: ${mapEntry.value}');
                      }
                    }
                    if (mapEntry.key == "event") {
                      tmpEventList.addAll(fillEventList(mapEntry.value, currentDate));
                    }
                  }
                }
              } else if (entry.key == "event"){
                tmpEventList.addAll(fillEventList(entry.value, currentDate));
              }

            }
          }
        }
        if (debug == DebugLevel.All ||
            debug == DebugLevel.XMLJSONParsing) {
          print("End of day list: ");
        }
      }
      // there is only one map, not a list.
    }


    List<Event> eventList =
    tmpEventList.map((value) => Event.fromMapToObject(value)).toList();

    return ConferenceAndEvent(aConference, eventList);
  }


  Future<ConferenceAndEvent> getEvents(String year) async {
//  Future<List<Event>> getEvents(String year) {
    DateTime now = DateTime.now();
    int currentYear = now.year;
    String mainURL = MAINURL;
    if (int.parse(year) < currentYear && int.parse(year) >= LOCALYEAR) {
      mainURL = ARCHIVEURL;
    }
    //Some of the conferences can not be read from the archive online. These have been stored locally in assets/schedule/fosdem_schedule$year.xml
    if (int.parse(year) < REMOTEYEAR){
      final xmlTransformer = Xml2Json();
      String scheduleasset = "assets/schedule/fosdem_schedule$year.xml"; //path to asset
      String scheduleString = await rootBundle.loadString(scheduleasset); //load schedyles from assets
      xmlTransformer.parse(scheduleString);
      var json = xmlTransformer.toGData();
      Map<String, dynamic> response = jsonDecode(json);
      if (debug == DebugLevel.All || debug == DebugLevel.XMLJSONParsing) {
        print("getEvents xmlres:");
        print(json.toString());
        print("jsonresponse:");
        print(response.toString());
      }
      return transformConferenceAndEvent(response);
    } else {
      return _netUtil
          .getXMLHeavy(mainURL + year + GETEVENTURL)
          .then((dynamic res) {
        if (res != null) {
          Map<String, dynamic> response = jsonDecode(res);
          if (debug == DebugLevel.All || debug == DebugLevel.XMLJSONParsing) {
            print("getEvents xmlres:");
            print(res.toString());
            print("jsonresponse:");
            print(response.toString());
          }
          return transformConferenceAndEvent(response);
        } else {
          List<Event> eventList =[];
          return ConferenceAndEvent(Conference("","",""), eventList);
        }
      });
    }
  }

  Map returnAProperEventMap(Map eventmap, String currentDate) {
    // we create an links list so that they can be stored as a json object in
    // the database: we find if there are any pages, if not, it will be ant empty list.
    // object stuff.
    List<dynamic> linkList = [];
    List<dynamic> personList = [];
    List<dynamic> attachmentList = [];
    if (eventmap['links']['link'] != null) {
      if (debug == DebugLevel.All || debug == DebugLevel.XMLJSONParsing) {
        //print("We have links");
        print('''links:
            ${eventmap['links'].toString()} 
            runtimetype: links
            ${eventmap['links'].runtimeType.toString()} 
            runtimetype: links 
            ${eventmap['links']['link'].runtimeType.toString()}''');
      }
      //Map<String, dynamic> thelinks = eventmap['links'];
      if (eventmap['links']['link']
          .runtimeType
          .toString()
          .contains("List<dynamic>")) {
        List<dynamic> data = eventmap['links']['link'];
        for (var mapValue in data) {
          linkList.add(mapValue);
          //linkList.add(mapvalue['\$t']);
        }
      } else {
        //There is only one value, which results in a map instead of a list.
        Map mapvalue = eventmap['links']['link'];
        linkList.add(mapvalue);
        //linkList.add(mapvalue['\$t']);
      }
    }
    if (eventmap['persons']['person'] != null) {
      if (debug == DebugLevel.All || debug == DebugLevel.XMLJSONParsing) {
        //print("We have links");
        print('''persons: 
            ${eventmap['persons'].toString()}
            runtimetype: persons
            ${eventmap['persons'].runtimeType.toString()} 
             runtimetype: person 
            ${eventmap['persons']['person'].runtimeType.toString()}''');
      }
      //Map<String, dynamic> thelinks = eventmap['links'];
      if (eventmap['persons']['person']
          .runtimeType
          .toString()
          .contains("List<dynamic>")) {
        List<dynamic> data = eventmap['persons']['person'];
        for (var mapvalue in data) {
          if (mapvalue is Map && mapvalue[r'$t'] != null) {
            mapvalue = Map<String, dynamic>.from(mapvalue);
            mapvalue[r'$t'] = cleanPersonName(mapvalue[r'$t']);
          }
          personList.add(mapvalue);
        }
      } else {
        //There is only one value, which results in a map instead of a list.
        dynamic mapvalue = eventmap['persons']['person'];
        if (mapvalue is Map && mapvalue[r'$t'] != null) {
          mapvalue = Map<String, dynamic>.from(mapvalue);
          mapvalue[r'$t'] = cleanPersonName(mapvalue[r'$t']);
        }
        personList.add(mapvalue);
      }
    }
    if (eventmap['attachments'] != null && eventmap['attachments']['attachment'] != null) {
      if (debug == DebugLevel.All || debug == DebugLevel.XMLJSONParsing) {
        //print("We have links");
        print('''attachements:
            ${eventmap['attachments'].toString()} 
            runtimetype: attachments
            ${eventmap['attachments'].runtimeType.toString()}
            runtimetype: attachment
            ${eventmap['attachments']['attachment'].runtimeType.toString()}''');
      }
      //Map<String, dynamic> thelinks = eventmap['links'];
      if (eventmap['attachments']['attachment']
          .runtimeType
          .toString()
          .contains("List<dynamic>")) {
        List<dynamic> data = eventmap['attachments']['attachment'];
        for (var mapvalue in data) {
          attachmentList.add(mapvalue);
        }
      } else {
        //There is only one value, which results in a map instead of a list.
        Map mapvalue = eventmap['attachments']['attachment'];
        attachmentList.add(mapvalue);
      }
    }
    eventmap['eventdate'] = currentDate;
    eventmap['links'] = linkList;
    eventmap['persons'] = personList;
    eventmap['attachments'] = attachmentList;
    return eventmap;
  }
}