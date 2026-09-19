import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fosdem/data/xml_ds.dart';
import 'package:fosdem/models/conference.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/models/person.dart';
import 'package:fosdem/utils/constants.dart';
import 'package:fosdem/utils/preferences.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/utils.dart';
import 'package:http/http.dart' as http;
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
  final Set<String> _scrapingPersonYears = {};
  bool _isScrapingAllPersons = false;
  String _currentScrapeStatus = '';
  double _currentScrapeProgress = 0.0;

  bool get isScrapingAllPersons => _isScrapingAllPersons;
  bool get isScrapingPersons => _scrapingPersonYears.isNotEmpty || _isScrapingAllPersons;
  String get currentScrapeStatus => _currentScrapeStatus;
  double get currentScrapeProgress => _currentScrapeProgress;

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
    await theDb.execute('''
      CREATE TABLE IF NOT EXISTS person(
        id INTEGER PRIMARY KEY,
        person_id INTEGER,
        person_name TEXT,
        person_ascii_name TEXT,
        person_description TEXT,
        person_picture BLOB,
        person_picture_url TEXT,
        description_year INTEGER DEFAULT 0,
        picture_year INTEGER DEFAULT 0
      )
    ''');
    await cleanPersonMojibakeInDb(theDb);
    return theDb;
  }

  Future<void> cleanPersonMojibakeInDb(Database theDb) async {
    try {
      final rows = await theDb.rawQuery(
        '''SELECT id, person_id, person_name, person_ascii_name, person_description, person_picture_url, description_year, picture_year,
                  CASE WHEN person_picture IS NOT NULL AND LENGTH(person_picture) > 0 THEN 1 ELSE 0 END as has_picture
           FROM person'''
      );
      if (rows.isEmpty) return;

      Map<String, List<Map<String, dynamic>>> byName = {};
      for (var r in rows) {
        final rawName = r['person_name']?.toString() ?? '';
        final cleanName = cleanPersonName(rawName);
        if (cleanName.isNotEmpty) {
          byName.putIfAbsent(cleanName, () => []).add(Map<String, dynamic>.from(r));
        }
      }

      await theDb.transaction((txn) async {
        for (var entry in byName.entries) {
          final cleanName = entry.key;
          final group = entry.value;

          if (group.length == 1) {
            final r = group.first;
            final id = r['id'];
            final rawName = r['person_name']?.toString();
            final desc = r['person_description']?.toString();
            final fixedDesc = cleanMojibake(desc);
            if (cleanName != rawName || fixedDesc != desc) {
              await txn.update(
                'person',
                {
                  if (cleanName != rawName) 'person_name': cleanName,
                  if (fixedDesc != desc) 'person_description': fixedDesc,
                },
                where: 'id = ?',
                whereArgs: [id],
              );
            }
          } else {
            // Multiple rows map to the same clean name (e.g. Abhishek Lekshmanan, Alexis Jacomy)
            // Sort to choose the best primary record: prefer one with description, then picture, then lowest id
            group.sort((a, b) {
              final aDescLen = (a['person_description']?.toString() ?? '').length;
              final bDescLen = (b['person_description']?.toString() ?? '').length;
              if (aDescLen != bDescLen) return bDescLen.compareTo(aDescLen);
              final aHasPic = (a['has_picture'] as num?)?.toInt() == 1 ? 1 : 0;
              final bHasPic = (b['has_picture'] as num?)?.toInt() == 1 ? 1 : 0;
              if (aHasPic != bHasPic) return bHasPic.compareTo(aHasPic);
              return (a['id'] as int).compareTo(b['id'] as int);
            });

            final primary = group.first;
            final primaryId = primary['id'];

            String mergedDesc = cleanMojibake(primary['person_description']?.toString() ?? '').trim();
            int mergedDescYear = primary['description_year'] is int
                ? primary['description_year'] as int
                : (int.tryParse(primary['description_year']?.toString() ?? '') ?? 0);
            int bestPicId = primaryId as int;
            bool hasBestPic = (primary['has_picture'] as num?)?.toInt() == 1;
            String? mergedPicUrl = primary['person_picture_url']?.toString();
            int mergedPicYear = primary['picture_year'] is int
                ? primary['picture_year'] as int
                : (int.tryParse(primary['picture_year']?.toString() ?? '') ?? 0);
            int mergedPid = primary['person_id'] is int
                ? primary['person_id'] as int
                : (int.tryParse(primary['person_id']?.toString() ?? '') ?? 0);
            String mergedAscii = primary['person_ascii_name']?.toString() ?? '';

            for (int i = 1; i < group.length; i++) {
              final other = group[i];
              final otherId = other['id'] as int;
              final otherDesc = cleanMojibake(other['person_description']?.toString() ?? '').trim();
              final otherDescYear = other['description_year'] is int
                  ? other['description_year'] as int
                  : (int.tryParse(other['description_year']?.toString() ?? '') ?? 0);
              if (otherDesc.isNotEmpty) {
                if (mergedDesc.isEmpty) {
                  mergedDesc = otherDesc;
                  mergedDescYear = otherDescYear;
                } else if (otherDesc != mergedDesc && !mergedDesc.contains(otherDesc)) {
                  mergedDesc = _mergeDescriptions(
                    existingDesc: mergedDesc,
                    existingDescYear: mergedDescYear,
                    newDesc: otherDesc,
                    newYear: otherDescYear,
                  );
                }
              }

              final otherHasPic = (other['has_picture'] as num?)?.toInt() == 1;
              final otherPicYear = other['picture_year'] is int
                  ? other['picture_year'] as int
                  : (int.tryParse(other['picture_year']?.toString() ?? '') ?? 0);
              if (otherHasPic && (!hasBestPic || otherPicYear >= mergedPicYear)) {
                bestPicId = otherId;
                hasBestPic = true;
                mergedPicUrl = other['person_picture_url']?.toString();
                mergedPicYear = otherPicYear;
              }

              final otherPid = other['person_id'] is int
                  ? other['person_id'] as int
                  : (int.tryParse(other['person_id']?.toString() ?? '') ?? 0);
              if (mergedPid == 0 && otherPid > 0) {
                mergedPid = otherPid;
              }
              final otherAscii = other['person_ascii_name']?.toString() ?? '';
              if (mergedAscii.isEmpty && otherAscii.isNotEmpty) {
                mergedAscii = otherAscii;
              }
            }

            // If a non-primary row has the best picture, copy it inside SQLite without pulling blob into memory
            if (bestPicId != primaryId) {
              await txn.rawUpdate(
                'UPDATE person SET person_picture = (SELECT person_picture FROM person WHERE id = ?) WHERE id = ?',
                [bestPicId, primaryId],
              );
            }

            for (int i = 1; i < group.length; i++) {
              await txn.delete('person', where: 'id = ?', whereArgs: [group[i]['id']]);
            }

            await txn.update(
              'person',
              {
                'person_name': cleanName,
                'person_ascii_name': mergedAscii,
                if (mergedPid > 0) 'person_id': mergedPid,
                'person_description': mergedDesc,
                'person_picture_url': mergedPicUrl,
                'description_year': mergedDescYear,
                'picture_year': mergedPicYear,
              },
              where: 'id = ?',
              whereArgs: [primaryId],
            );
          }
        }

        // Clean up double spaces in Event.persons JSON
        final eventRows = await txn.rawQuery("SELECT id, persons FROM Event WHERE persons LIKE '%  %' OR persons LIKE '%Ã%' OR persons LIKE '%Å%' OR persons LIKE '%Ä%'");
        for (var er in eventRows) {
          final eid = er['id'];
          final rawPersonsStr = er['persons']?.toString();
          if (rawPersonsStr == null || rawPersonsStr.isEmpty) continue;
          try {
            final decoded = jsonDecode(rawPersonsStr);
            if (decoded is List) {
              bool changed = false;
              for (var p in decoded) {
                if (p is Map && p[r'$t'] != null) {
                  final orig = p[r'$t'].toString();
                  final cleaned = cleanPersonName(orig);
                  if (cleaned != orig) {
                    p[r'$t'] = cleaned;
                    changed = true;
                  }
                }
              }
              if (changed) {
                await txn.update(
                  'Event',
                  {'persons': jsonEncode(decoded)},
                  where: 'id = ?',
                  whereArgs: [eid],
                );
              }
            }
          } catch (_) {}
        }
      });
    } catch (e) {
      print('cleanPersonMojibakeInDb note: $e');
    }
  }

  // here the upgrades since the last version are added.
  _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS person(
        id INTEGER PRIMARY KEY,
        person_id INTEGER,
        person_name TEXT,
        person_ascii_name TEXT,
        person_description TEXT,
        person_picture BLOB,
        person_picture_url TEXT,
        description_year INTEGER DEFAULT 0,
        picture_year INTEGER DEFAULT 0
      )
    ''');
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute(
        "CREATE TABLE Conference(id INTEGER PRIMARY KEY AUTOINCREMENT, year INTEGER, title TEXT,  subtitle TEXT, venue TEXT, city TEXT, start TEXT, end TEXT, days INTEGER, daychange TEXT, timeslotduration TEXT, eventsdownloaded TEXT)");
    await db.execute(
        "CREATE TABLE Event(id INTEGER PRIMARY KEY AUTOINCREMENT, year INTEGER, eventid INTEGER, start TEXT, duration TEXT, room TEXT, slug TEXT, title TEXT, subtitle TEXT, track TEXT, type TEXT, language TEXT,  abstract TEXT, description TEXT, eventdate TEXT, links TEXT, persons TEXT, attachments TEXT, favorite INTEGER)");
    await db.execute('''
      CREATE TABLE IF NOT EXISTS person(
        id INTEGER PRIMARY KEY,
        person_id INTEGER,
        person_name TEXT,
        person_ascii_name TEXT,
        person_description TEXT,
        person_picture BLOB,
        person_picture_url TEXT,
        description_year INTEGER DEFAULT 0,
        picture_year INTEGER DEFAULT 0
      )
    ''');
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


  Future<void> updateEventsFromInternet({required String year, bool force = false}) async {
    if (_syncingYears.contains(year)) {
      return;
    }
    final int currentYear = DateTime.now().year;
    final int? reqYear = int.tryParse(year);

    // After initial download, historical years (prior to current year) are static archives
    // and should not be re-downloaded from the internet unless force is requested.
    if (reqYear != null && reqYear != currentYear && !force) {
      final dbClient = await db;
      final existingCount = Sqflite.firstIntValue(
        await dbClient.rawQuery('SELECT count(*) FROM Event WHERE year = ?', [reqYear]),
      ) ?? 0;
      if (existingCount > 0) {
        return;
      }
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
      if (!force && downloaded.isAfter(sixhoursAgo)) {
        // do nothing, the stuff has already been downloaded the last six hours
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

  Future<void> refreshCurrentYearEvents({void Function(String message)? onProgress}) async {
    final currentYear = DateTime.now().year.toString();
    onProgress?.call('Refreshing events for $currentYear...');
    await updateEventsFromInternet(year: currentYear, force: true);
    onProgress?.call('Events for $currentYear successfully refreshed!');
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
        if (settingsController?.selectedEventsFromAllYears == true) {
          if (selectedNow == true) {
            return await dbClient.query('Event',
                where: 'eventdate >= ? and start >= ?',
                whereArgs: [
                  currentDate,
                  currentStart
                ]);
          } else {
            return await dbClient.query('Event');
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
    }

    List<Map> mapEvent = await queryEvents();

    // This should not happen. If it did, something went wrong gettings the events from
    // the schedulefiles or from the internet.
    if (mapEvent.isEmpty && settingsController?.selectedEventsFromAllYears != true) {
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
      if (map['year'] != null) {
        aEvent.year = map['year'] is int ? map['year'] as int : int.tryParse(map['year'].toString());
      } else {
        aEvent.year = year;
      }
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
      if (map['year'] != null) {
        aEvent.year = map['year'] is int ? map['year'] as int : int.tryParse(map['year'].toString());
      } else {
        aEvent.year = year;
      }
      listEvent.add(aEvent);
    }
    listEvent.sort((a, b) {
      return a.eventDateInMillis.compareTo(b.eventDateInMillis);
    });
    return listEvent;
  }

  Future<List<Event>> getEventList(int year, SettingsController controller) async {
    DatabaseHelper databaseHelper = DatabaseHelper();
    final int currentYear = DateTime.now().year;
    if (year == currentYear) {
      await databaseHelper.updateEventsFromInternet(year: year.toString());
    }
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

  Future<List<Person>> getPersonsFromDb(int year, SettingsController controller) async {
    final dbClient = await db;
    List<Map<String, Object?>> rows;

    if (controller.selectedPersonsFromAllYears == true) {
      rows = await dbClient.rawQuery('''
        SELECT p.id, p.person_id, p.person_name, p.person_ascii_name, p.person_picture_url, p.description_year, p.picture_year,
               CASE WHEN p.person_picture IS NOT NULL AND LENGTH(p.person_picture) > 0 THEN 1 ELSE 0 END as has_picture
        FROM person p
        WHERE p.person_name IS NOT NULL AND p.person_name != ''
        ORDER BY p.person_name COLLATE NOCASE ASC
      ''');
    } else {
      final epRows = await dbClient.rawQuery('''
        SELECT DISTINCT json_extract(value, '\$.\$t') as pname
        FROM Event, json_each(Event.persons)
        WHERE Event.year = ? AND json_extract(value, '\$.\$t') IS NOT NULL
      ''', [year]);

      final names = epRows
          .map((r) => r['pname']?.toString().trim())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet();

      if (names.isNotEmpty) {
        final placeholders = List.filled(names.length, '?').join(',');
        rows = await dbClient.rawQuery('''
          SELECT DISTINCT p.id, p.person_id, p.person_name, p.person_ascii_name, p.person_picture_url, p.description_year, p.picture_year,
                 CASE WHEN p.person_picture IS NOT NULL AND LENGTH(p.person_picture) > 0 THEN 1 ELSE 0 END as has_picture
          FROM person p
          WHERE p.person_name IN ($placeholders) OR p.person_ascii_name IN ($placeholders)
          ORDER BY p.person_name COLLATE NOCASE ASC
        ''', [...names, ...names]);
      } else {
        rows = [];
      }
    }

    if (rows.isEmpty) {
      final query = controller.selectedPersonsFromAllYears == true
          ? '''
            SELECT DISTINCT json_extract(value, '\$.id') as id, json_extract(value, '\$.\u0024t') as name
            FROM Event, json_each(Event.persons)
            ORDER BY name COLLATE NOCASE ASC
          '''
          : '''
            SELECT DISTINCT json_extract(value, '\$.id') as id, json_extract(value, '\$.\u0024t') as name
            FROM Event, json_each(Event.persons)
            WHERE Event.year = ?
            ORDER BY name COLLATE NOCASE ASC
          ''';
      final fallbackRows = controller.selectedPersonsFromAllYears == true
          ? await dbClient.rawQuery(query)
          : await dbClient.rawQuery(query, [year]);

      List<Person> list = [];
      for (var r in fallbackRows) {
        if (r['id'] != null && r['name'] != null) {
          list.add(Person(
            r['id'] is int ? (r['id'] as int) : int.tryParse(r['id'].toString()),
            r['name'].toString(),
          ));
        }
      }
      return list;
    }

    List<Person> personList = [];
    for (var map in rows) {
      personList.add(Person.fromDbMap(map));
    }
    return personList;
  }

  Future<List<Event>> getEventsForPerson(int personId, {String? personName, int? year, bool allYears = false}) async {
    final dbClient = await db;
    String pidStr = personId.toString();
    List<Map> rows;
    final cleanName = personName != null ? cleanPersonName(personName) : '';

    if (cleanName.isNotEmpty) {
      if (allYears || year == null) {
        rows = await dbClient.rawQuery('''
          SELECT DISTINCT e.* FROM Event e, json_each(e.persons)
          WHERE json_extract(value, '\$.\u0024t') = ?
          ORDER BY e.year DESC, e.eventdate ASC, e.start ASC
        ''', [cleanName]);
      } else {
        rows = await dbClient.rawQuery('''
          SELECT DISTINCT e.* FROM Event e, json_each(e.persons)
          WHERE json_extract(value, '\$.\u0024t') = ?
            AND e.year = ?
          ORDER BY e.eventdate ASC, e.start ASC
        ''', [cleanName, year]);
      }
    } else {
      if (allYears || year == null) {
        rows = await dbClient.rawQuery('''
          SELECT DISTINCT e.* FROM Event e, json_each(e.persons)
          WHERE json_extract(value, '\$.id') = ? OR CAST(json_extract(value, '\$.id') AS INTEGER) = ?
          ORDER BY e.year DESC, e.eventdate ASC, e.start ASC
        ''', [pidStr, personId]);
      } else {
        rows = await dbClient.rawQuery('''
          SELECT DISTINCT e.* FROM Event e, json_each(e.persons)
          WHERE (json_extract(value, '\$.id') = ? OR CAST(json_extract(value, '\$.id') AS INTEGER) = ?)
            AND e.year = ?
          ORDER BY e.eventdate ASC, e.start ASC
        ''', [pidStr, personId, year]);
      }
    }

    List<Event> events = [];
    for (var map in rows) {
      events.add(Event.fromMapToObject(map));
    }
    return events;
  }

  Future<Person?> getPersonById(int personId, {String? personName}) async {
    final dbClient = await db;
    List<Map> rows = [];
    final cleanName = personName != null ? cleanPersonName(personName) : '';
    if (cleanName.isNotEmpty) {
      rows = await dbClient.query('person',
        where: 'person_name = ?',
        whereArgs: [cleanName],
        limit: 1,
      );
    }
    if (rows.isEmpty) {
      rows = await dbClient.query('person',
        where: 'id = ? OR person_id = ?',
        whereArgs: [personId, personId],
        limit: 1,
      );
    }
    if (rows.isNotEmpty) {
      Person p = Person.fromDbMap(rows.first);
      p.events = await getEventsForPerson(p.id ?? personId, personName: p.name, allYears: true);
      return p;
    }
    List<Map> eventRows = await dbClient.rawQuery('''
      SELECT DISTINCT json_extract(value, '\$.\u0024t') as name
      FROM Event, json_each(Event.persons)
      WHERE json_extract(value, '\$.id') = ? OR CAST(json_extract(value, '\$.id') AS INTEGER) = ?
      LIMIT 1
    ''', [personId.toString(), personId]);
    if (eventRows.isNotEmpty) {
      final name = eventRows.first['name']?.toString() ?? 'Speaker';
      Person p = Person(personId, name);
      p.events = await getEventsForPerson(personId, personName: name, allYears: true);
      return p;
    }
    return null;
  }

  String _unescapeHtml(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  String _slugify(String name) {
    var s = cleanPersonName(_unescapeHtml(name)).toLowerCase();
    const map = {
      'ø': 'o', 'ß': 'ss', 'ł': 'l', 'ı': 'i', 'ð': 'd', 'æ': 'ae', 'þ': 'th', 'đ': 'd',
      'ö': 'o', 'ü': 'u', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'å': 'a', 'í': 'i', 'ì': 'i', 'î': 'i',
      'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ù': 'u', 'û': 'u',
      'ñ': 'n', 'ç': 'c', 'ů': 'u', 'ž': 'z', 'č': 'c', 'š': 's', 'ř': 'r', 'ý': 'y',
      'ť': 't', 'ď': 'd', 'ň': 'n', 'ė': 'e', 'ę': 'e', 'ą': 'a', 'ć': 'c', 'ń': 'n',
      'ź': 'z', 'ż': 'z', 'ğ': 'g', 'ş': 's', 'ő': 'o', 'ű': 'u',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAll(RegExp(r'''['"`’“”]'''), '');
    s = s.replaceAll(RegExp(r'[\s.@/\\:]+'), '_');
    s = s.replaceAll(RegExp(r'[^a-z0-9\-_]'), '');
    s = s.replaceAll(RegExp(r'_+'), '_');
    return s.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _normalizeDesc(String s) {
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Deduplicates historical sections within a description string.
  /// If a person has the same description in multiple years (e.g. 2013 and 2014),
  /// only one will be displayed.
  String _deduplicateDescription(String fullDesc) {
    if (fullDesc.trim().isEmpty) return '';
    if (!fullDesc.contains('\n\nOriginal description: ')) {
      return fullDesc.trim();
    }

    final regex = RegExp(r'\n\nOriginal description: (\d+)\n');
    final matches = regex.allMatches(fullDesc).toList();
    if (matches.isEmpty) return fullDesc.trim();

    String topDesc = fullDesc.substring(0, matches.first.start).trim();
    List<Map<String, String>> history = [];

    for (int i = 0; i < matches.length; i++) {
      String year = matches[i].group(1)!;
      int contentStart = matches[i].end;
      int contentEnd = (i + 1 < matches.length) ? matches[i + 1].start : fullDesc.length;
      String content = fullDesc.substring(contentStart, contentEnd).trim();
      history.add({'year': year, 'content': content});
    }

    Set<String> seenNormalized = {_normalizeDesc(topDesc)};
    List<Map<String, String>> uniqueHistory = [];

    for (var item in history) {
      String norm = _normalizeDesc(item['content']!);
      if (norm.isNotEmpty && !seenNormalized.contains(norm)) {
        seenNormalized.add(norm);
        uniqueHistory.add(item);
      }
    }

    if (uniqueHistory.isEmpty) {
      return topDesc;
    }

    StringBuffer sb = StringBuffer(topDesc);
    for (var item in uniqueHistory) {
      sb.write('\n\nOriginal description: ${item['year']}\n${item['content']}');
    }
    return sb.toString();
  }

  /// Merges a newly scraped description with an existing description.
  /// Ensures that no duplicate description is added if the person has the same
  /// description in multiple years (e.g. 2013 and 2014).
  String _mergeDescriptions({
    required String existingDesc,
    required int existingDescYear,
    required String newDesc,
    required int newYear,
  }) {
    final cleanNew = newDesc.trim();
    if (cleanNew.isEmpty) {
      return _deduplicateDescription(existingDesc);
    }
    final cleanExisting = _deduplicateDescription(existingDesc);
    if (cleanExisting.isEmpty) {
      return cleanNew;
    }

    String topDesc = cleanExisting;
    if (cleanExisting.contains('\n\nOriginal description: ')) {
      topDesc = cleanExisting.split('\n\nOriginal description: ')[0].trim();
    }

    final normNew = _normalizeDesc(cleanNew);
    final normTop = _normalizeDesc(topDesc);

    // If identical to top description, do NOT duplicate
    if (normNew == normTop) {
      return cleanExisting;
    }

    // Check if newDesc matches any historical description in cleanExisting
    final histRegex = RegExp(r'\n\nOriginal description: \d+\n?');
    final allParts = cleanExisting.split(histRegex);
    if (allParts.any((part) => _normalizeDesc(part) == normNew)) {
      return cleanExisting;
    }

    // New description is different from existing ones: prepend with history marker
    if (newYear > existingDescYear) {
      int origYear = existingDescYear > 0 ? existingDescYear : newYear - 1;
      return '$cleanNew\n\nOriginal description: $origYear\n$cleanExisting';
    } else {
      return '$cleanExisting\n\nOriginal description: $newYear\n$cleanNew';
    }
  }

  bool _byteEquals(Uint8List a, Uint8List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<http.Response?> _fetchWithRetry(http.Client client, String url, {int maxRetries = 3}) async {
    int backoffMs = 800;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final resp = await client.get(
          Uri.parse(url),
          headers: {'User-Agent': 'Fosdem4All/1.0 (+https://www.netsense.nl; contact: fosdem@netsense.nl)'},
        ).timeout(const Duration(seconds: 20));

        if (resp.statusCode == 200 || resp.statusCode == 404) {
          return resp;
        }
      } catch (e) {
        if (attempt == maxRetries) {
          return null;
        }
      }
      await Future.delayed(Duration(milliseconds: backoffMs));
      backoffMs *= 2;
    }
    return null;
  }

  String _decodeUtf8(http.Response resp) {
    try {
      return utf8.decode(resp.bodyBytes);
    } catch (_) {
      return resp.body;
    }
  }

  Future<({String desc, Uint8List? picBytes, String? picUrl})> _scrapeSpeakerPage({
    required http.Client client,
    required int year,
    required String slug,
  }) async {
    final pageUrl = 'https://archive.fosdem.org/$year/schedule/speaker/$slug/';
    final resp = await _fetchWithRetry(client, pageUrl);
    if (resp == null || resp.statusCode != 200) {
      return (desc: '', picBytes: null, picUrl: null);
    }

    final htmlContent = _decodeUtf8(resp);

    String mainChunk = htmlContent;
    if (htmlContent.contains('id="main"')) {
      mainChunk = htmlContent.split('id="main"')[1];
    } else if (htmlContent.contains('id="content"')) {
      mainChunk = htmlContent.split('id="content"')[1];
    }

    for (var stopMarker in [
      '<h3>Events</h3>',
      '<h3>Sessions</h3>',
      '<h3>Links</h3>',
      '<table class="table',
      '<div id="footer">',
      '<footer'
    ]) {
      if (mainChunk.contains(stopMarker)) {
        mainChunk = mainChunk.split(stopMarker)[0];
      }
    }

    Uint8List? picBytes;
    String? picUrl;
    final photoMatch = RegExp(
      r'<img[^>]*class=["\x27][^"\x27]*(?:speaker-photo|speaker_photo|speaker-image)[^"\x27]*["\x27][^>]*>',
      caseSensitive: false,
    ).firstMatch(mainChunk) ??
    RegExp(
      r'<img[^>]*class=["\x27][^"\x27]*(?:speaker-photo|speaker_photo|speaker-image)[^"\x27]*["\x27][^>]*>',
      caseSensitive: false,
    ).firstMatch(htmlContent);

    if (photoMatch != null) {
      final srcMatch = RegExp(r'src=["\x27]([^"\x27]+)["\x27]', caseSensitive: false).firstMatch(photoMatch.group(0)!);
      if (srcMatch != null) {
        final rawSrc = _unescapeHtml(srcMatch.group(1)!.trim());
        if (rawSrc.startsWith('http://') || rawSrc.startsWith('https://')) {
          picUrl = rawSrc;
        } else if (rawSrc.startsWith('//')) {
          picUrl = 'https:$rawSrc';
        } else if (rawSrc.startsWith('/')) {
          picUrl = 'https://archive.fosdem.org$rawSrc';
        } else {
          picUrl = 'https://archive.fosdem.org/$year/schedule/speaker/$slug/$rawSrc';
        }

        final picResp = await _fetchWithRetry(client, picUrl);
        if (picResp != null && picResp.statusCode == 200 && picResp.bodyBytes.isNotEmpty) {
          picBytes = picResp.bodyBytes;
        }
      }
    }

    List<String> bios = [];
    final pMatches = RegExp(r'<p(?:\s+class=["\x27]([^"\x27]*)["\x27])?[^>]*>(.*?)</p>', dotAll: true)
        .allMatches(mainChunk);
    for (var pm in pMatches) {
      final cls = pm.group(1) ?? '';
      final body = pm.group(2) ?? '';
      if (cls.contains('label-info') || body.contains('potentially outdated')) {
        continue;
      }
      final clean = _unescapeHtml(body.replaceAll(RegExp(r'<[^>]+>'), '')).trim();
      if (clean.isNotEmpty) {
        bios.add(clean);
      }
    }

    final newDesc = bios.join('\n\n').trim();
    return (desc: newDesc, picBytes: picBytes, picUrl: picUrl);
  }

  Future<void>? _dbWriteLock;
  Future<T> _withDbLock<T>(Future<T> Function() action) async {
    final prev = _dbWriteLock;
    final completer = Completer<void>();
    _dbWriteLock = completer.future;
    try {
      if (prev != null) await prev;
      return await action();
    } finally {
      completer.complete();
    }
  }

  Future<void> _saveOrUpdatePersonInDb({
    required Database dbClient,
    required int year,
    required int pid,
    required String rawName,
    required String slug,
    required String newDesc,
    required Uint8List? picBytes,
    required String? picUrl,
  }) async {
    final cleanName = cleanPersonName(rawName);
    final cleanDescription = cleanMojibake(newDesc);
    return _withDbLock(() async {
      List<Map> existing = [];
      if (slug.isNotEmpty) {
        existing = await dbClient.query('person',
          where: 'person_ascii_name = ?',
          whereArgs: [slug],
          limit: 1,
        );
      }
      if (existing.isEmpty && cleanName.isNotEmpty) {
        existing = await dbClient.query('person',
          where: 'person_name = ?',
          whereArgs: [cleanName],
          limit: 1,
        );
      }
      if (existing.isEmpty && rawName.isNotEmpty && rawName != cleanName) {
        existing = await dbClient.query('person',
          where: 'person_name = ?',
          whereArgs: [rawName],
          limit: 1,
        );
      }

      if (existing.isEmpty) {
        final desc = cleanDescription.trim();
        final descYear = desc.isNotEmpty ? year : 0;
        final picYear = (picBytes != null && picBytes.isNotEmpty) ? year : 0;
        await dbClient.insert('person', {
          // Do NOT specify 'id' so SQLite auto-assigns a unique primary key rowid!
          'person_id': pid,
          'person_name': cleanName,
          'person_ascii_name': slug,
          'person_description': desc,
          'person_picture': picBytes,
          'person_picture_url': picUrl,
          'description_year': descYear,
          'picture_year': picYear,
        });
        return;
      }

      final exRow = existing.first;
      final int exId = (exRow['id'] as num).toInt();
      final String exDesc = (exRow['person_description']?.toString() ?? '').trim();
      final int exDescYear = exRow['description_year'] is int
          ? exRow['description_year'] as int
          : (int.tryParse(exRow['description_year']?.toString() ?? '') ?? 0);
      final int exPicYear = exRow['picture_year'] is int
          ? exRow['picture_year'] as int
          : (int.tryParse(exRow['picture_year']?.toString() ?? '') ?? 0);
      final dynamic exPic = exRow['person_picture'];
      final Uint8List? exPicBytes = exPic is Uint8List
          ? exPic
          : (exPic is List<int> ? Uint8List.fromList(exPic) : null);

      Map<String, dynamic> updates = {};

      // Description logic: deduplicate across years
      if (cleanDescription.trim().isNotEmpty) {
        if (exDesc.isEmpty) {
          updates['person_description'] = cleanDescription.trim();
          updates['description_year'] = year;
        } else {
          final merged = _mergeDescriptions(
            existingDesc: exDesc,
            existingDescYear: exDescYear,
            newDesc: cleanDescription,
            newYear: year,
          );
          if (merged != exDesc) {
            updates['person_description'] = merged;
            updates['description_year'] = year;
          }
        }
      } else if (exDesc.isNotEmpty) {
        final deduped = _deduplicateDescription(exDesc);
        if (deduped != exDesc) {
          updates['person_description'] = deduped;
        }
      }

      // Picture logic: newer picture replaces older picture (matching Go db.go)
      if (picBytes != null && picBytes.isNotEmpty) {
        if (exPicBytes == null || exPicBytes.isEmpty) {
          updates['person_picture'] = picBytes;
          updates['person_picture_url'] = picUrl;
          updates['picture_year'] = year;
        } else if (year >= exPicYear) {
          if (!_byteEquals(exPicBytes, picBytes)) {
            updates['person_picture'] = picBytes;
            updates['person_picture_url'] = picUrl;
            updates['picture_year'] = year;
          }
        }
      }

      // Update name if better/non-empty
      final exName = exRow['person_name']?.toString() ?? '';
      if (cleanName.isNotEmpty && (exName.isEmpty || exName == 'Speaker' || exName != cleanPersonName(exName))) {
        updates['person_name'] = cleanName;
      }
      if (pid > 0 && (exRow['person_id'] == null || exRow['person_id'] == 0)) {
        updates['person_id'] = pid;
      }
      if (slug.isNotEmpty && (exRow['person_ascii_name'] == null || exRow['person_ascii_name'].toString().isEmpty)) {
        updates['person_ascii_name'] = slug;
      }

      if (updates.isNotEmpty) {
        await dbClient.update('person', updates, where: 'id = ?', whereArgs: [exId]);
      }
    });
  }

  Future<void> _scrapeSingleYear({
    required Database dbClient,
    required http.Client client,
    required int year,
    void Function(String message, double progress)? onProgress,
  }) async {
    // 1. Fetch XML schedule and extract persons (ID -> Name)
    Map<int, String> xmlPersons = {};
    try {
      final xmlResp = await _fetchWithRetry(client, 'https://archive.fosdem.org/$year/schedule/xml');
      if (xmlResp != null && xmlResp.statusCode == 200) {
        final matches = RegExp(r'<person\s+id=["\x27]?(\d+)["\x27]?[^>]*>([^<]+)</person>', caseSensitive: false)
            .allMatches(_decodeUtf8(xmlResp));
        for (var m in matches) {
          final id = int.tryParse(m.group(1)!);
          final name = cleanPersonName(_unescapeHtml(m.group(2)!));
          if (id != null && name.isNotEmpty) {
            xmlPersons[id] = name;
          }
        }
      }
    } catch (e) {
      print('[$year] XML fetch note: $e');
    }

    // Supplement from Event table in DB if populated
    try {
      final dbRows = await dbClient.rawQuery('''
        SELECT DISTINCT json_extract(value, '\$.id') as id, json_extract(value, '\$.\u0024t') as name
        FROM Event, json_each(Event.persons)
        WHERE Event.year = ?
      ''', [year]);
      for (var r in dbRows) {
        final id = r['id'] is int ? r['id'] as int : int.tryParse(r['id']?.toString() ?? '');
        final name = cleanPersonName(r['name']?.toString() ?? '');
        if (id != null && name.isNotEmpty && !xmlPersons.containsKey(id)) {
          xmlPersons[id] = name;
        }
      }
    } catch (_) {}

    // 2. Fetch speakers index for authoritative slug mapping
    Map<String, String> speakerMap = {};
    try {
      final spkResp = await _fetchWithRetry(client, 'https://archive.fosdem.org/$year/schedule/speakers/');
      if (spkResp != null && spkResp.statusCode == 200) {
        final matches = RegExp(r'<a\s+href="[^"]*/schedule/speaker/([^/]+)/"[^>]*>([^<]+)</a>')
            .allMatches(_decodeUtf8(spkResp));
        for (var m in matches) {
          final slug = m.group(1)!;
          final rawName = cleanPersonName(_unescapeHtml(m.group(2)!));
          speakerMap[rawName] = slug;
          speakerMap[rawName.toLowerCase()] = slug;
        }
      }
    } catch (e) {
      print('[$year] Speakers index note: $e');
    }

    // 3. Prepare task list
    List<({int id, String name, String slug})> tasks = [];
    Set<String> seenSlugs = {};

    for (var entry in xmlPersons.entries) {
      final id = entry.key;
      final name = entry.value;
      final slug = speakerMap[name] ?? speakerMap[name.toLowerCase()] ?? _slugify(name);
      if (!seenSlugs.contains(slug)) {
        seenSlugs.add(slug);
        tasks.add((id: id, name: name, slug: slug));
      }
    }

    int fallbackId = 900000;
    for (var entry in speakerMap.entries) {
      final name = entry.key;
      final slug = entry.value;
      if (!seenSlugs.contains(slug)) {
        seenSlugs.add(slug);
        tasks.add((id: ++fallbackId, name: name, slug: slug));
      }
    }

    if (tasks.isEmpty) {
      onProgress?.call('[$year] No speakers found', 1.0);
      return;
    }

    int total = tasks.length;
    int processed = 0;
    const int concurrency = 12;

    int taskIndex = 0;
    Future<void> worker() async {
      while (true) {
        int i;
        if (taskIndex >= tasks.length) return;
        i = taskIndex++;

        final task = tasks[i];
        try {
          var result = await _scrapeSpeakerPage(
            client: client,
            year: year,
            slug: task.slug,
          );

          if (result.desc.isEmpty && result.picBytes == null) {
            final altSlug = _slugify(task.name);
            if (altSlug != task.slug) {
              final altResult = await _scrapeSpeakerPage(
                client: client,
                year: year,
                slug: altSlug,
              );
              if (altResult.desc.isNotEmpty || altResult.picBytes != null) {
                result = altResult;
              }
            }
          }

          await _saveOrUpdatePersonInDb(
            dbClient: dbClient,
            year: year,
            pid: task.id,
            rawName: task.name,
            slug: task.slug,
            newDesc: result.desc,
            picBytes: result.picBytes,
            picUrl: result.picUrl,
          );
        } catch (e) {
          print('[$year] Note for person ${task.id} (${task.name}, slug: ${task.slug}): $e');
        }

        processed++;
        if (processed % 50 == 0 || processed == total) {
          final progress = processed / total;
          onProgress?.call('[$year] Scraping speakers: $processed/$total', progress);
        }
      }
    }

    final workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);
  }

  /// Cleans and deduplicates any preexisting duplicate descriptions in SQLite `person` table.
  /// If a person has the same description in multiple years (e.g. 2013 and 2014),
  /// only one will be displayed.
  Future<int> deduplicateExistingPersonDescriptions() async {
    final dbClient = await db;
    final rows = await dbClient.query('person',
      columns: ['id', 'person_description'],
      where: "person_description LIKE '%Original description:%'",
    );
    int cleanedCount = 0;
    for (var r in rows) {
      final int id = r['id'] as int;
      final String desc = r['person_description']?.toString() ?? '';
      final deduped = _deduplicateDescription(desc);
      if (deduped != desc) {
        await dbClient.update(
          'person',
          {'person_description': deduped},
          where: 'id = ?',
          whereArgs: [id],
        );
        cleanedCount++;
      }
    }
    return cleanedCount;
  }

  /// Scrapes all persons across all FOSDEM conferences since [startYear] (default: 2013)
  /// up to [endYear] (default: current year), matching the behavior of the Go scraper.
  /// Ensures no duplicate descriptions are created for identical bios across years.
  /// Returns whether the initial multi-year scraping of persons has been completed.
  Future<bool> isInitialPersonsScraped() async {
    final prefs = Preferences();
    if (prefs.getInitialPersonsScraped()) return true;

    // Also check if person table already has records from previous scraping
    final dbClient = await db;
    final res = await dbClient.rawQuery('SELECT count(*) as cnt FROM person');
    final count = Sqflite.firstIntValue(res) ?? 0;
    if (count > 2000) {
      prefs.setInitialPersonsScraped(true);
      return true;
    }
    return false;
  }

  /// Scrapes all persons across all FOSDEM conferences since [startYear] (default: 2013)
  /// up to [endYear] (default: current year), matching the behavior of the Go scraper.
  /// After initial scraping, this method restricts re-scraping to the current year
  /// unless [force] is true.
  Future<void> scrapePersonsSince2013({
    int startYear = 2013,
    int? endYear,
    bool force = false,
    void Function(String message, double progress)? onProgress,
  }) async {
    final int finalEndYear = endYear ?? DateTime.now().year;
    final bool initialDone = await isInitialPersonsScraped();

    // After initial scraping of persons, only allow refreshing current year!
    if (initialDone && !force) {
      onProgress?.call('Initial scraping already completed. Refreshing current year ($finalEndYear)...', 0.0);
      await scrapePersonsForYear(finalEndYear.toString(), force: true, onProgress: onProgress);
      return;
    }

    if (_isScrapingAllPersons) return;
    _isScrapingAllPersons = true;
    _currentScrapeStatus = 'Starting scraper from $startYear...';
    _currentScrapeProgress = 0.0;
    notifyListeners();

    final client = http.Client();
    try {
      final dbClient = await db;

      List<int> years = [];
      for (int y = startYear; y <= finalEndYear; y++) {
        years.add(y);
      }
      years.sort(); // Chronological order: 2013, 2014, ..., currentYear

      await deduplicateExistingPersonDescriptions();

      int totalYears = years.length;
      for (int i = 0; i < totalYears; i++) {
        final year = years[i];
        final yearProgressBase = i / totalYears;
        final statusMsg = 'FOSDEM $year ($year of $finalEndYear)';
        _currentScrapeStatus = statusMsg;
        _currentScrapeProgress = yearProgressBase;
        notifyListeners();
        onProgress?.call(statusMsg, yearProgressBase);

        await _scrapeSingleYear(
          dbClient: dbClient,
          client: client,
          year: year,
          onProgress: (msg, prog) {
            final overallProg = yearProgressBase + (prog / totalYears);
            _currentScrapeStatus = msg;
            _currentScrapeProgress = overallProg;
            notifyListeners();
            onProgress?.call(msg, overallProg);
          },
        );
      }

      await deduplicateExistingPersonDescriptions();
      Preferences().setInitialPersonsScraped(true);
      final doneMsg = 'Completed scraping all speakers ($startYear–$finalEndYear)';
      _currentScrapeStatus = doneMsg;
      _currentScrapeProgress = 1.0;
      notifyListeners();
      onProgress?.call(doneMsg, 1.0);
    } finally {
      client.close();
      _isScrapingAllPersons = false;
      notifyListeners();
    }
  }

  /// Scrapes speakers for a specific year.
  /// After initial scraping has completed, only allows refreshing the current year.
  Future<void> scrapePersonsForYear(
    String year, {
    bool force = false,
    void Function(String message, double progress)? onProgress,
  }) async {
    final currentYear = DateTime.now().year.toString();
    final bool initialDone = await isInitialPersonsScraped();

    // After initial scraping of persons, only make it possible to refresh the current year!
    if (initialDone && year != currentYear && year.toLowerCase() != 'all' && !force) {
      final msg = 'Only the current year ($currentYear) can be refreshed after initial scraping.';
      _currentScrapeStatus = msg;
      _currentScrapeProgress = 1.0;
      notifyListeners();
      onProgress?.call(msg, 1.0);
      return;
    }

    if (year.toLowerCase() == 'all') {
      await scrapePersonsSince2013(force: force, onProgress: onProgress);
      return;
    }

    if (_scrapingPersonYears.contains(year)) return;
    _scrapingPersonYears.add(year);
    _currentScrapeStatus = 'Scraping speakers for $year...';
    _currentScrapeProgress = 0.0;
    notifyListeners();

    final client = http.Client();
    try {
      final dbClient = await db;
      final intYear = int.tryParse(year) ?? DateTime.now().year;

      await _scrapeSingleYear(
        dbClient: dbClient,
        client: client,
        year: intYear,
        onProgress: (msg, prog) {
          _currentScrapeStatus = msg;
          _currentScrapeProgress = prog;
          notifyListeners();
          onProgress?.call(msg, prog);
        },
      );

      await deduplicateExistingPersonDescriptions();
      _currentScrapeStatus = 'Completed scraping speakers for $year';
      _currentScrapeProgress = 1.0;
      notifyListeners();
      onProgress?.call('Completed scraping speakers for $year', 1.0);
    } finally {
      client.close();
      _scrapingPersonYears.remove(year);
      notifyListeners();
    }
  }

  /// Refreshes persons for the current year.
  Future<void> refreshCurrentYearPersons({void Function(String message, double progress)? onProgress}) async {
    final currentYear = DateTime.now().year.toString();
    await scrapePersonsForYear(currentYear, force: true, onProgress: onProgress);
  }

  @visibleForTesting
  Future<({String desc, Uint8List? picBytes, String? picUrl})> scrapeSpeakerPageForTest({
    required http.Client client,
    required int year,
    required String slug,
  }) => _scrapeSpeakerPage(client: client, year: year, slug: slug);

  @visibleForTesting
  Future<void> saveOrUpdatePersonInDbForTest({
    required Database dbClient,
    required int year,
    required int pid,
    required String rawName,
    required String slug,
    required String newDesc,
    required Uint8List? picBytes,
    required String? picUrl,
  }) => _saveOrUpdatePersonInDb(
    dbClient: dbClient,
    year: year,
    pid: pid,
    rawName: rawName,
    slug: slug,
    newDesc: newDesc,
    picBytes: picBytes,
    picUrl: picUrl,
  );
}
