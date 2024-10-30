import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'event.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable(explicitToJson: true)
class Event extends ChangeNotifier {
  Event(title,
      {eventId,
      start,
      duration,
      room,
      slug,
      subtitle,
      track,
      type,
      language,
      abstract,
      description,
      persons,
      attachments,
      links,
      year});

  @JsonKey(name: 'event id')
  int? eventId;
  @JsonKey(name: 'start')
  String? start;
  @JsonKey(name: 'duration')
  String? duration;
  @JsonKey(name: 'room')
  String? room;
  @JsonKey(name: 'slug')
  String? slug;
  @JsonKey(name: 'title')
  String title = "";
  @JsonKey(name: 'subtitle')
  String? subtitle;
  @JsonKey(name: 'track')
  String? track;
  @JsonKey(name: 'type')
  String? type;
  @JsonKey(name: 'language')
  String? language;
  @JsonKey(name: 'abstract')
  String? abstract;
  @JsonKey(name: 'description')
  String? description;
  @JsonKey(name: 'persons')
  List<dynamic> persons = [];
  @JsonKey(name: 'attachments')
  List<dynamic> attachments = [];
  @JsonKey(name: 'links')
  List<dynamic> links = [];
  @JsonKey(name: 'year')
  int? year;
  @JsonKey(name: 'eventdate')
  String? eventdate;
  @JsonKey(name: 'favorite')
  int? favorite;
  int eventDateInMillis = 0;
  /// A necessary factory constructor for creating a new Event instance
  /// from a map. Pass the map to the generated `_$EventFromJson()` constructor.
  /// The constructor is named after the source class, in this case, Event.
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$EventToJson(this);

  // as the original XML data supplies (eg) int 1  as "1", we have to convert the int for storage in the Object and the database
  //static int _fromJson(String String) => int.parse(String);
  //static String _toJson(int anInt) => anInt.toString();

  Event.fromMapToObject(dynamic obj) {
    // mapping comes from the database: we fill year,
    // which is not contained in the info coming from the xml
    if (obj['year'] != null) {
      eventId = obj['eventid'];
      start = obj['start'];
      duration = obj["duration"];
      room = obj["room"];
      slug = obj["slug"];
      title = obj['title'];
      subtitle = obj["subtitle"];
      abstract = obj["abstract"];
      track = obj["track"];
      type = obj["type"];
      language = obj["language"];
      description = obj['description'];
      if (obj['persons'] != null) {
        persons = jsonDecode(obj['persons']);
      } else {
        persons = [];
      }
      if (obj['attachments'] != null) {
        attachments = jsonDecode(obj['attachments']);
      } else {
        attachments = [];
      }
      if (obj['links'] != null) {
        links = jsonDecode(obj['links']);
      } else {
        links = [];
      }
      year = obj['year'];
      eventdate = obj['eventdate'];
      DateFormat datetimeFormat = DateFormat('y-M-d H:m');
      eventDateInMillis = datetimeFormat.parse('$eventdate $start').millisecondsSinceEpoch;
      favorite = obj['favorite'];

      // information comes from xml transferred to json: somehow ints are not
      // understood as ints, so we do it manually.
      // also, this should not contain the column localavailable, which indicates localavailability
      // the groupcol is a database field, so we know that that comes out of the database
      // if an event has been downloaded;
    } else {
      //print("Runtimetype: ${obj['start'].runtimeType.toString()}");
      if (obj['start'].runtimeType.toString().contains('Map<String,')) {
        eventId = int.parse(obj["id"]);
        start = obj["start"]['\$t'];
        duration = obj["duration"]['\$t'];
        room = obj["room"]['\$t'];
        slug = obj["slug"]['\$t'];
        title = obj["title"]['\$t'];
        subtitle = obj["subtitle"]['\$t'];
        track = obj["track"]['\$t'];
        type = obj["type"]['\$t'];
        language = obj["language"]['\$t'];
        abstract = obj["abstract"]['\$t'];
        description = obj["description"]['\$t'];
      } else {
        eventId = int.parse(obj['id']);
        start = obj['start'];
        duration = obj["duration"];
        room = obj["room"];
        slug = obj["slug"];
        title = obj['title'];
        subtitle = obj["subtitle"];
        abstract = obj["abstact"];
        track = obj["track"];
        type = obj["type"];
        language = obj["language"];
        description = obj['description'];
      }
      links = obj["links"];
      persons = obj["persons"];
      attachments = obj["attachments"];
      eventdate = obj['eventdate'];
      DateFormat datetimeFormat = DateFormat('y-M-d H:m');
      eventDateInMillis = datetimeFormat.parse("$eventdate $start").millisecondsSinceEpoch;
      DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      DateTime time = dateFormat.parse(eventdate!);
      year = time.year;

      //     DateFormat datetimeFormat = DateFormat('yyyy-MM-dd hh:mm');
 //     eventDateInMillis = datetimeFormat.parse("${eventdate} ${start}").millisecondsSinceEpoch;
    }
    //audio = obj["Audio"];
  }

  // toMap is using to send info to the database.
  // if the data comes from xml, the localavailable is not filled
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    map['eventid'] = eventId;
    map['start'] = start;
    map['duration'] = duration;
    map['room'] = room;
    map['slug'] = slug;
    map['title'] = title;
    map['subtitle'] = subtitle;
    map['track'] = track;
    map['type'] = type;
    map['language'] = language;
    map['abstract'] = abstract;
    map['description'] = description;
    // as sqlite has group as a protected word, we use groupcol as columnname for group
    map['persons'] = jsonEncode(persons);
    map['attachments'] = jsonEncode(attachments);
    map['links'] = jsonEncode(links);
    map['year'] = year;
    map['eventdate'] = eventdate;
    map['favorite'] = favorite;

    return map;
  }
}
