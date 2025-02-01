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

// inspired by https://github.com/udara94/flutterTodo
// and https://flutter.dev/docs/cookEvent/persistence/sqlite
// https://medium.com/swlh/flutter-get-data-from-a-rest-api-and-save-locally-in-a-sqlite-database-9a9de5867939
// https://github.com/fabiojansenbr/flutter_api_to_sqlite

class DatabaseHelper extends ChangeNotifier {
  static final DatabaseHelper _instance = DatabaseHelper.internal();



  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database> get db async => _db ??= await initDb();

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
        var dbList = await dbClient.query('Conference',
            where: 'year = ?', whereArgs: [conference.year]);
        if (dbList.isNotEmpty) {
          Map map = dbList[0];
          // only update Event when there is a new revision or if there is no revision of the current Event
          // or if the avalable status has been changed
          Conference tmpConference = Conference.fromMapToObject(map);
          // transfer data that can not be available in the downloaded Eventinfo;
          await updateConference(tmpConference);
        } else {
          await insertConference(conference);
        }
      } on Exception catch (exception) {
        // only executed if error is of type Exception
        print(exception);
      } catch (error) {
        print(error.toString());
      }
      //TODO: make sure the update of the database is recorded in the prefs, so we can update when the app has not updated for a day.
      notifyListeners();
    }
  }

  Future<int?> insertConference(Conference aConference) async {
    var dbClient = await db;
    int? res;
    await dbClient.transaction((txn) async {
      try {
        res = await txn.insert("Conference", aConference.toMap());
      } on DatabaseException catch (e) {
        if (e.toString().contains('code 2067')) {
          print('Year unique constraint, carry on');
        }
      } catch (e) {
        print('error inserting Conference: $aConference');
        _handleError(e);
      }
    });
    return res;
  }

  Future<void> updateConference(Conference aConference) async {
    // Get a reference to the database.
    final dbClient = await db;
    await dbClient.transaction((txn) async {
      try {
        txn.update(
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
    });
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
    //final dbClient = await (db as FutureOr<Database>);
    final dbClient = await db;
    List<Map> mapConference = await dbClient.query('Conference');
    List<Conference> listconf = [];
    //If only the curent Events are loaded, get all the older ones.
    if (mapConference.isEmpty ||
        mapConference.length == 1 ||
        mapConference.length < getYearList().length) {
      for (var year in getYearList()) {
        updateEventsFromInternet(year: year.toString());
      }
      mapConference = await dbClient.query('Conference');
    }
    for (var map in mapConference) {
      Conference conf = Conference.fromMapToObject(map);
      if (debug == DebugLevel.All || debug == DebugLevel.Database) {
        print('getConferenceFromDb: ${conf.title!}');
      }
      if (conf.year != '') {
        listconf.add(conf);
      }
    }
    listconf.sort((a, b) {
      return b.year.toString().compareTo(a.year.toString());
    });
    return listconf;
  }

  Future<void> putTheEventListIntoTheDatabase(
      {required ConferenceAndEvent confandevents, int? year}) async {
    //Find the same Event in the database:
    //If it is not available, insert the Event
    final dbClient = await db;
    if (confandevents.eventList != null && confandevents.eventList!.isNotEmpty) {
      List<String?> eventIdvalues = [];
      for (Event anEvent in confandevents.eventList!) {
        try {
          //first we check if a group variable is added: that means that this is a generic call to fetch Events
          //else we have the list of Events that are added for the logged in user.
          //If the Events are picked up while the user is logged in, the meaning of available == 0
          //means he is overEvented. Every value above means he is available.
          //If the user is not logged in, every value > 1 (1= available, 0=unavailable), means not available
          var dbList = await dbClient.query('Event',
              where: 'eventid = ?', whereArgs: [anEvent.eventId]);
          if (dbList.isNotEmpty) {
            Map map = dbList[0];
            // only update Event when there is a new revision or if there is no revision of the current Event
            // or if the avalable status has been changed
            Event tmpEvent = Event.fromMapToObject(map);
            // transfer data that can not be available in the downloaded Eventinfo;
            await updateEvent(tmpEvent);
          } else {
            await insertEvent(anEvent);
          }
          eventIdvalues.add(anEvent.eventId.toString());
        } on Exception catch (exception) {
          // only executed if error is of type Exception
          print(exception);
        } catch (error) {
          print(error.toString());
        }
      }
    //remove Events that are not in the internet database anymore, and the files belonging to it
    String eventIdSinqleQuoteString = eventIdvalues.fold(
        '', (value, element) => '$value,\'${element!}\'');
    //print('values: ${Eventcodevalues.toString()}, string: ${EventcodeSinqleQuoteString.substring(1)}');
    //TODO remove files belonging to Eventcodes that are not there any more
    // only do this if the if the group was mentioned, otherwise it means that the Events of a logged in user
    // are picked up. That is not the complete assortiment of Events.
    if (year != null) {
      // first select the Events that are not there any more
      // then delete their assets locally: thumbnail images and audio and image files
      // the delete  the Events from the database.
      int res = await dbClient.delete(
        'Event',
        where:
        'eventid not in (${eventIdSinqleQuoteString.substring(1)}) and year = ?',
        whereArgs: [year],
      );
//        int res = await dbClient.delete('Event', where: 'Eventcode not in (${Eventcodevalues.join(',')}) and groupcol = ?', whereArgs: [group],);
//        int res = await dbClient.delete('Event', where: 'Eventcode not in (?) and groupcol = ?', whereArgs: [EventcodeString.substring(1),group],);
      if (debug == DebugLevel.All || debug == DebugLevel.Database) {
        print('Events deleted: $res');
      }
    }
    //TODO: make sure the update of the database is recorded in the prefs, so we can update when the app has not updated for a day.
    //notifyListeners();
    }

    if (confandevents.conference != null && confandevents.conference!.year != null) {
        try {
          var dbList = await dbClient.query('Conference',
              where: 'year = ?', whereArgs: [confandevents.conference!.year]);
          if (dbList.isNotEmpty) {
            Map map = dbList[0];
            // only update Event when there is a new revision or if there is no revision of the current Event
            // or if the avalable status has been changed
            Conference tmpConference = Conference.fromMapToObject(map);
            // transfer data that can not be available in the downloaded Eventinfo;
            await updateConference(tmpConference);
          } else {
            await insertConference(confandevents.conference!);
          }
        } on Exception catch (exception) {
          // only executed if error is of type Exception
          print(exception);
        } catch (error) {
          print(error.toString());
        }
      }


  }

  Future<int?> insertEvent(Event anEvent) async {
    var dbClient = await db;
    int? res;
    await dbClient.transaction((txn) async {
      try {
        res = await txn.insert("Event", anEvent.toMap());
      } on DatabaseException catch (e) {
        if (e.toString().contains('code 2067')) {
          print('Event unique constraint, carry on');
        }
      } catch (e) {
        print('error inserting Event: $anEvent');
        _handleError(e);
      }
    });
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
    await dbClient.transaction((txn) async {
      try {
        await txn.update('Event', anEvent.toMap(),
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
    });
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
      await putTheEventListIntoTheDatabase(confandevents: confandevents);
//      await putTheConfenceIntoTheDatabase(conference: confandevents.conference);
    }
  }

  Future<List<Event>> getEventsFromDb(int year, {String? track}) async {
    final dbClient = await db;
    List<Map> mapEvent =[];
    if (track != ""){
      mapEvent =
      await dbClient.query('Event', where: 'year = ? and track like ?', whereArgs: [year, track]);
    } else {
     mapEvent =
      await dbClient.query('Event', where: 'year = ?', whereArgs: [year]);
    }
    // This should not happen. If it did, something went wrong gettings the events from
    // the schedulefiles or from the internet.
    if(mapEvent.isEmpty) {
      XMLDatasource xmldatasrc = XMLDatasource();
      ConferenceAndEvent confandevents = await xmldatasrc.getEvents(year.toString());
      if (confandevents.eventList!.isNotEmpty){
        await putTheEventListIntoTheDatabase(confandevents: confandevents);
        //await putTheConfenceIntoTheDatabase(conference: confandevents.conference);
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
          'Event', where: 'favorite = 1 order by eventdate', whereArgs: []);
    } else {
      mapEvent = await dbClient
          .query(
          'Event', where: 'year = ? and favorite = 1', whereArgs: [year]);
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

  Future<List<Event>> getEventList(int year) {
    DatabaseHelper databaseHelper = DatabaseHelper();
    databaseHelper.updateEventsFromInternet(year: year.toString());
    List<Event> tmpEventList = [];
    return databaseHelper.getEventsFromDb(year).then((value) {
      tmpEventList = value;
      return tmpEventList;
    });
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
      mapTracks = await dbClient.rawQuery(
          '''select track from Event where year is ?  group by track order by track ASC ''',
          [year]);

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
