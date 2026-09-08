import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:fosdem/data/xml_ds.dart';
import 'package:fosdem/models/conference.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/utils/constants.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sprintf/sprintf.dart';

// inspired by https://github.com/udara94/flutterTodo
// and https://flutter.dev/docs/cookEvent/persistence/sqlite
// https://medium.com/swlh/flutter-get-data-from-a-rest-api-and-save-locally-in-a-sqlite-database-9a9de5867939
// https://github.com/fabiojansenbr/flutter_api_to_sqlite

class DatabaseHelper extends ChangeNotifier {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database> get db async => _db ??= await initDb();

  bool _isSyncingConferences = false;
  final Set<String> _syncingYears = {};

  DatabaseHelper.internal();

  void updateDatabaseHelper() {
    notifyListeners();
  }
  //SettingsController settingsController = SettingsController();

  Future<Database> initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "fosdem.db");
    var theDb = await openDatabase(path,
        version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return theDb;
  }

  // here the upgrades since the last version are added.
  _onUpgrade(Database db, int oldVersion, int newVersion) async {
    //await db.execute("ALTER TABLE Conference add column eventsdownloaded TEXT");
    //await db.execute("ALTER TABLE Event add column description TEXT");
    //await db.execute("ALTER TABLE Event add column eventdate TEXT");
    //await db.execute("ALTER TABLE Event add column favorite INTEGER");
    //await db.execute(
    //    "DELETE from Conference where year is '' or year is 0");
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute(
        "CREATE TABLE Conference(id INTEGER PRIMARY KEY AUTOINCREMENT, year INTEGER, title TEXT,  subtitle TEXT, venue TEXT, city TEXT, start TEXT, end TEXT, days INTEGER, daychange TEXT, timeslotduration TEXT, eventsdownloaded TEXT)");
    await db.execute(
        "CREATE TABLE Event(id INTEGER PRIMARY KEY AUTOINCREMENT, year INTEGER, eventid INTEGER, start TEXT, duration TEXT, room TEXT, slug TEXT, title TEXT, subtitle TEXT, track TEXT, type TEXT, language TEXT,  abstract TEXT, description TEXT, eventdate TEXT, links TEXT, persons TEXT, attachments TEXT, favorite INTEGER)");
    //await db.execute("CREATE UNIQUE INDEX Idx_Event on Event(eventid, year)");
    if (debug == DebugLevel.All || debug == DebugLevel.Database) {
      print("Created tables");
    }
  }

  Exception _handleError(dynamic e) {
    print(e); // for demo purposes only
    return Exception('Server error; cause: $e');
  }

  Future<void> putTheConfenceIntoTheDatabase(
      {Conference? conference, int? year}) async {
    //Find the same Conference in the database:
    //If it is not available, insert the Conference
    final dbClient = await db;
    if (conference != null && conference.year != null) {
      try {
        await dbClient.transaction((txn) async {
          var dbList = await txn.query('Conference',
              where: 'year = ?', whereArgs: [conference.year]);
          if (dbList.isNotEmpty) {
            Map map = dbList[0];
            Conference tmpConference = Conference.fromMapToObject(map);
            await txn.update(
              'Conference',
              tmpConference.toMap(),
              where: "year = ?",
              whereArgs: [tmpConference.year],
            );
          } else {
            await txn.insert("Conference", conference.toMap());
          }
        });
      } on Exception catch (exception) {
        // only executed if error is of type Exception
        print(exception);
      } catch (error) {
        print(error.toString());
      }
      notifyListeners();
    }
  }

  Future<int?> insertConference(Conference aConference) async {
    var dbClient = await db;
    int? res;
    try {
      res = await dbClient.insert("Conference", aConference.toMap());
    } on DatabaseException catch (e) {
      if (e.toString().contains('code 2067')) {
        print('Year unique constraint, carry on');
      }
    } catch (e) {
      print('error inserting Conference: $aConference');
      _handleError(e);
    }
    return res;
  }

  Future<void> updateConference(Conference aConference) async {
    // Get a reference to the database.
    final dbClient = await db;
    try {
      await dbClient.update(
        'Conference',
        aConference.toMap(),
        // Ensure that the Conference has a matching id.
        where: "year = ?",
        // Pass the Dog's id as a whereArg to prevent SQL injection.
        whereArgs: [aConference.year],
      );
    } catch (e) {
      print('error updating conference: $aConference');
      _handleError(e);
    }
  }

  Future<int> deleteConferences() async {
    var dbClient = await db;
    int res = await dbClient.delete("Conference");
    return res;
  }


  Future<Conference?> getConferenceFromDB(String year) async {
    // Get a reference to the database.
    final dbClient = await db;
    // Update the given Dog.
    List<Map> mapConference = await dbClient
        .query('Conference', where: "year = ?", whereArgs: [int.parse(year)]);
    if (mapConference.length == 1) {
      Conference aConference = Conference.fromMapToObject(mapConference[0]);
      if (debug == DebugLevel.All || debug == DebugLevel.Database) {
        print("in getConference downloaded: ${aConference.title}");
        print("Year: ${aConference.title}");
      }
      return aConference;
    } else {
      return null;
    }
  }


  //ToDo make sure one gets the conferences
  Future<List<Conference>>? getConferences(int year) {
    DatabaseHelper databaseHelper = DatabaseHelper();
    List<Conference> tmpConferenceList = [];
//    return databaseHelper.getCategoriesFromDb().then((value) {
    databaseHelper.getConferencesFromDb().then((value) {
      tmpConferenceList = value;
      if (tmpConferenceList.isEmpty) {
        XMLDatasource xmldatasrc = XMLDatasource();
        xmldatasrc.getEvents(year.toString());
      }
      return tmpConferenceList;
    });
    return null;
  }

  Future<List<Conference>> getConferencesFromDb() async {
    final dbClient = await db;
    List<Map> mapConference = await dbClient.query('Conference');
    List<Conference> listconf = [];
    //If only the curent Events are loaded, get all the older ones.
    if ((mapConference.isEmpty ||
            mapConference.length == 1 ||
            mapConference.length < getYearList().length) &&
        !_isSyncingConferences) {
      _isSyncingConferences = true;
      try {
        for (var year in getYearList()) {
          await updateEventsFromInternet(year: year.toString());
        }
      } finally {
        _isSyncingConferences = false;
      }
      mapConference = await dbClient.query('Conference');
    }
    for (var map in mapConference) {
      Conference conf = Conference.fromMapToObject(map);
      if (debug == DebugLevel.All || debug == DebugLevel.Database) {
        print('getConferenceFromDb: ${conf.title!}');
      }
      if (conf.year != null && conf.year != 0) {
        listconf.add(conf);
      }
    }
    listconf.sort((a, b) {
      return (b.year ?? 0).compareTo(a.year ?? 0);
    });
    return listconf;
  }

  Future<void> putTheEventListIntoTheDatabase(
      {required ConferenceAndEvent confandevents, int? year}) async {
    final dbClient = await db;
    await dbClient.transaction((txn) async {
      if (confandevents.eventList != null && confandevents.eventList!.isNotEmpty) {
        // Fetch existing event IDs and favorites in one query to avoid per-item query locks
        List<Map> existingRows = await txn.query(
          'Event',
          columns: ['eventid', 'favorite'],
        );
        Map<int, int> existingFavorites = {};
        Set<int> existingEventIds = {};
        for (var row in existingRows) {
          if (row['eventid'] != null) {
            int eid = row['eventid'] is int ? row['eventid'] as int : int.parse(row['eventid'].toString());
            existingEventIds.add(eid);
            if (row['favorite'] != null) {
              existingFavorites[eid] = row['favorite'] is int ? row['favorite'] as int : int.parse(row['favorite'].toString());
            }
          }
        }

        List<String?> eventIdvalues = [];
        Batch batch = txn.batch();
        for (Event anEvent in confandevents.eventList!) {
          try {
            var mapData = anEvent.toMap();
            int? eid = anEvent.eventId;
            if (eid != null) {
              if (existingFavorites.containsKey(eid)) {
                mapData['favorite'] = existingFavorites[eid];
              }
              if (existingEventIds.contains(eid)) {
                batch.update(
                  'Event',
                  mapData,
                  where: "eventid = ?",
                  whereArgs: [eid],
                );
              } else {
                batch.insert('Event', mapData);
              }
              eventIdvalues.add(eid.toString());
            }
          } catch (error) {
            print(error.toString());
          }
        }
        await batch.commit(noResult: true);
        
        if (year != null && eventIdvalues.isNotEmpty) {
          String eventIdSingleQuoteString = eventIdvalues.fold(
              '', (value, element) => '$value,\'${element!}\'');
          int res = await txn.delete(
            'Event',
            where:
            'eventid not in (${eventIdSingleQuoteString.substring(1)}) and year = ?',
            whereArgs: [year],
          );
          if (debug == DebugLevel.All || debug == DebugLevel.Database) {
            print('Events deleted: $res');
          }
        }
      }

      if (confandevents.conference != null && confandevents.conference!.year != null) {
        try {
          var dbList = await txn.query('Conference',
              where: 'year = ?', whereArgs: [confandevents.conference!.year]);
          if (dbList.isNotEmpty) {
            await txn.update(
              'Conference',
              confandevents.conference!.toMap(),
              where: "year = ?",
              whereArgs: [confandevents.conference!.year],
            );
          } else {
            await txn.insert('Conference', confandevents.conference!.toMap());
          }
        } catch (error) {
          print(error.toString());
        }
      }
    });
    notifyListeners();
  }


  Future<int?> insertEvent(Event anEvent) async {
    var dbClient = await db;
    int? res;
    try {
      res = await dbClient.insert("Event", anEvent.toMap());
    } on DatabaseException catch (e) {
      if (e.toString().contains('code 2067')) {
        print('Event unique constraint, carry on');
      }
    } catch (e) {
      print('error inserting Event: $anEvent');
      _handleError(e);
    }
    return res;
  }

  Future<int> deleteAllEvents() async {
    var dbClient = await db;
    int res = await dbClient.delete("Event");
    return res;
  }

  Future<List<Event>> getEventsPerYear(int year) async {
    // Get a reference to the database.
    final dbClient = await db;
    // Update the given Dog.
    List<Event> foundEvents = [];
    List<Map> mapEvent =
        await dbClient.query('Event', where: "year = ?", whereArgs: [year]);
    for (var aEventMap in mapEvent){
      Event aEvent = Event.fromMapToObject(aEventMap);
      if (debug == DebugLevel.All || debug == DebugLevel.Database) {
        print("in GetEvent downloaded: ${aEvent.eventId}");
        print("Event: ${aEvent.title}");
      }
      foundEvents.add(aEvent);
    }
    return foundEvents;
  }

  Future<Event?> getEvent(Event event) async {
    // Get a reference to the database.
    final dbClient = await db;
    // Update the given Event.
    List<Map> mapEvent = await dbClient
        .query('Event', where: "eventid = ?", whereArgs: [event.eventId]);
    if (mapEvent.length == 1) {
      Event anEvent = Event.fromMapToObject(mapEvent[0]);
      if (debug == DebugLevel.All || debug == DebugLevel.Database) {
        print("in GetEvent downloaded: ${anEvent.eventId}");
        print("Event: ${anEvent.title}");
      }
      return anEvent;
    } else {
      return null;
    }
  }

  Future<void> updateEvent(Event anEvent) async {
    // Get a reference to the database.
    final dbClient = await db;
    // Update the given Event.
    try {
      await dbClient.update('Event', anEvent.toMap(),
          // Ensure that the Event has a matching id.
          where: "eventid = ?",
          // Pass the Event's id as a whereArg to prevent SQL injection.
          whereArgs: [anEvent.eventId]);
    } on DatabaseException catch (e) {
      print('error updating Event: $anEvent');
      _handleError(e);
    } catch (e) {
      print('error updating Event: $anEvent');
      _handleError(e);
    }
    // make sure that after the events have been downloaded, there is a notification in the datbase
    // so that they will not be searched for again (apart from the event of the current year)
    // update the Conference to indicate a events are downloaded, only necessary if the Year does not already have this indication
    Conference? conference = await getConferenceFromDB(anEvent.year.toString());
    if (conference != null &&
        (conference.eventsdownloaded.isEmpty ||
            conference.eventsdownloaded == "")) {
      conference.eventsdownloaded = DateTime.now().toUtc().toIso8601String();
      await updateConference(conference);
    }
  }


  Future<void> updateEventsFromInternet({required String year}) async {
    if (_syncingYears.contains(year)) {
      return;
    }
    _syncingYears.add(year);
    try {
      Conference? aConference = await getConferenceFromDB(year);
      //DateTime currentTime = DateTime.now().toUtc();
      DateTime? downloaded;
      if (aConference == null || aConference.eventsdownloaded == "") {
        downloaded = DateTime(2000);
      } else {
        downloaded = DateTime.parse(aConference.eventsdownloaded);
      }
      DateTime sixhoursAgo =
          DateTime.now().toUtc().subtract(const Duration(hours: 6));
      if (downloaded.isAfter(sixhoursAgo)) {
        // do nothing, the stuff hase already been downloaded the last six hours
      } else {
        XMLDatasource xmldatasrc = XMLDatasource();
        //Get a list of Event, depending on the argument;
        ConferenceAndEvent confandevents = await xmldatasrc.getEvents(year);
        if (debug == DebugLevel.All || debug == DebugLevel.Database) {
          print("Got Events and Conferences from Internet and Local Storage");
        }
        await putTheEventListIntoTheDatabase(confandevents: confandevents, year: int.tryParse(year));
        notifyListeners();
  //      await putTheConfenceIntoTheDatabase(conference: confandevents.conference);
      }
    } finally {
      _syncingYears.remove(year);
    }
  }

  Future<List<Event>> getEventsFromDb(int year, bool selectedNow,{String? track, SettingsController? settingsController}) async {
    DateTime now = DateTime.now();
    String currentDate = sprintf("%04d-%02d-%02d",[now.year, now.month, now.day] );
    String currentStart = sprintf("%02d:%02d",[now.hour, now.minute]);

    final dbClient = await db;

    Future<List<Map>> queryEvents() async {
      if (track != null && track != "") {
        if (settingsController?.selectedTracksFromAllYears == true) {
          if (selectedNow == true) {
            return await dbClient.query('Event',
                where: 'track like ? and eventdate >= ? and start >= ?',
                whereArgs: [
                  track,
                  currentDate,
                  currentStart
                ]);
          } else {
            return await dbClient.query('Event', where: 'track like ?',
                whereArgs: [track]);
          }
        } else {
          if (selectedNow == true) {
            return await dbClient.query('Event',
                where: 'year = ? and track like ? and eventdate >= ? and start >= ?',
                whereArgs: [
                  year,
                  track,
                  currentDate,
                  currentStart
                ]);
          } else {
            return await dbClient.query('Event', where: 'year = ? and track like ?',
                whereArgs: [year, track]);
          }
        }
      } else {
        if (selectedNow == true) {
          return await dbClient.query('Event',
              where: 'year = ? and eventdate >= ? and start >= ?',
              whereArgs: [
                year,
                currentDate,
                currentStart
              ]);
        } else {
          return await dbClient.query('Event', where: 'year = ?', whereArgs: [year]);
        }
      }
    }

    List<Map> mapEvent = await queryEvents();

    // This should not happen. If it did, something went wrong gettings the events from
    // the schedulefiles or from the internet.
    if (mapEvent.isEmpty) {
      XMLDatasource xmldatasrc = XMLDatasource();
      ConferenceAndEvent confandevents = await xmldatasrc.getEvents(year.toString());
      if (confandevents.eventList != null && confandevents.eventList!.isNotEmpty){
        await putTheEventListIntoTheDatabase(confandevents: confandevents, year: year);
        mapEvent = await queryEvents();
      }
    }
    List<Event> listEvent = [];
    for (var map in mapEvent) {
      Event aEvent = Event.fromMapToObject(map);
      if (debug == DebugLevel.All || debug == DebugLevel.Database) {
        print("getEventsFromDb: ${aEvent.title}");
        print("Event title: ${aEvent.title}");
      }
      aEvent.year = year;
      listEvent.add(aEvent);
    }
    listEvent.sort((a, b) {
      return a.eventDateInMillis.compareTo(b.eventDateInMillis);
    });
    return listEvent;
  }


  Future<List<String>> getPersonsFromEvent(Event anEvent) async {
    final dbClient = await db;
    List<String> personNameList = [];
    List<Map<String, Object?>> persons = await dbClient
        .rawQuery('''select json_extract(person.value, '\$.\$t') 
  from (select value from json_each(Event.persons ), 
  Event where eventid = ?) person''', [anEvent.eventId]);
    for (var person in persons) {
      personNameList.add(person.values.toString());
    }
    return personNameList;
  }


  Future<List<Event>> getFavoritesFromDb(int year, SettingsController controller) async {
    final dbClient = await db;
    List<Map> mapEvent = [];
    if(controller.selectedFavoritesFromAllYears == true){
      mapEvent = await dbClient
          .query(
          'Event', where: 'favorite = 1', whereArgs: []);
    } else {
      mapEvent = await dbClient
          .query(
          'Event', where: 'year = ? and favorite = 1 ', whereArgs: [year]);
    }
    List<Event> listEvent = [];
    for (var map in mapEvent) {
      Event aEvent = Event.fromMapToObject(map);
      if (debug == DebugLevel.All || debug == DebugLevel.Database) {
        print("getEventsFromDb: ${aEvent.title}");
        print("Event title: ${aEvent.title}");
      }
      aEvent.year = year;
      listEvent.add(aEvent);
    }
    listEvent.sort((a, b) {
      return a.eventDateInMillis.compareTo(b.eventDateInMillis);
    });
    return listEvent;
  }

  Future<List<Event>> getEventList(int year, SettingsController controller) async {
    DatabaseHelper databaseHelper = DatabaseHelper();
    await databaseHelper.updateEventsFromInternet(year: year.toString());
    List<Event> tmpEventList = await databaseHelper.getEventsFromDb(year, controller.selectedNow, settingsController: controller);
    return tmpEventList;
  }

  Future<List<String>> getTrackListFromDb(int year, SettingsController controller) async {
    //final dbClient = await (db as FutureOr<Database>);
    final dbClient = await db;
    List<Map> mapTracks = [];
    if (controller.selectedTracksFromAllYears == true) {
      mapTracks = await dbClient.rawQuery(
          '''select track from Event group by track order by track ASC ''',
          []);
    } else {
      if (controller.selectedNow == true) {
        DateTime now = DateTime.now();
        mapTracks = await dbClient.rawQuery(
            '''select track from Event where year is ? and eventdate >= ? and start >= ? group by track order by track ASC ''',
            [
              year,
              sprintf("%04d-%02d-%02d",[now.year, now.month, now.day] ),
            sprintf("%02d:%02d",[now.hour, now.minute])
            ]);
      } else {
        mapTracks = await dbClient.rawQuery(
            '''select track from Event where year is ? group by track order by track ASC ''',
            [year]);
      }
    }
    List<String> listTracks = [];
    //If only the curent Events are loaded, get all the older ones.
    for (var map in mapTracks) {
      String track = map['track'];
      if (debug == DebugLevel.All || debug == DebugLevel.Database) {
        print('getConferenceFromDb: $track');
      }
      listTracks.add(track);
    }
    listTracks.sort((a, b) {
      return a.toString().compareTo(b.toString());
    });
    return listTracks;
  }


  //The yearlist is only suited for picking up some of the stuff.
  //2007 until 2011 were not delivered in xml format, and have been grazed and converted
  //by hand, sort of, to local assets
  // As Fosdem is always first week in februari, we can safely assume that in the beginning of the year there will be a conference list setup.

  List<int> getYearList() {
    int beginYear = 2007;
    DateTime now = DateTime.now();
    int currentYear = now.year;
    List<int> yearList = [];
    for (int i = beginYear; i <= currentYear; i++) {
      yearList.add(i);
    }
    return yearList;
  }


  Future resetData() async {
    // we do not remove the free Events from group FREEGROUP (10)
    // so we find which tasks do contain downloads from group FREEGROUP (10)
    // in the url of the task there is the Eventcode of the download.
    // so we do not delete these tasks
    DatabaseHelper dbhelper = DatabaseHelper();
    //await dbhelper.deleteAllEventsExceptGroup10();
    for (int year in getYearList()) {
      await dbhelper.updateEventsFromInternet(year: year.toString());
    }
    List<Conference> conferenceList = await dbhelper.getConferencesFromDb();
    for (var aConference in conferenceList)  {
      await dbhelper.updateEventsFromInternet(
          year: aConference.year.toString());
    }
  }
}
