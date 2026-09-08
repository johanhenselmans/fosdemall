import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

/// This allows the `Category` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'conference.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable(explicitToJson: true)
class Conference {
  Conference(
    this.title,
    this.subtitle,
    this.start, {
    this.end,
    this.venue,
    this.city,
  });

  @JsonKey(name: 'title')
  String? title;
  @JsonKey(name: 'subtitle')
  String? subtitle;
  @JsonKey(name: 'venue')
  String? venue;
  @JsonKey(name: 'city')
  String? city;
  @JsonKey(name: 'start')
  String? start;
  @JsonKey(name: 'end')
  String? end;
  @JsonKey(name: 'days')
  int? days;
  @JsonKey(name: 'day_change')
  String? day_change;
  @JsonKey(name: 'timeslot_duration')
  String? timeslot_duration;
  @JsonKey(name: 'year')
  int? year;
  @JsonKey(name: 'eventsdownloaded')
  String eventsdownloaded = "";

  /// A necessary factory constructor for creating a new Category instance
  /// from a map. Pass the map to the generated `$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory Conference.fromJson(Map<String, dynamic> json) =>
      _$ConferenceFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `$UserToJson`.
  Map<String, dynamic> toJson() => _$ConferenceToJson(this);

  // as the original XML data supplies (eg) int 1  as "1", we have to convert the int for storage in the Object and the database
  //static int fromJson(String String) => int.parse(String);
  //static String toJson(int anInt) => anInt.toString();

//these maps may come from the XML datasource or from the database.
//if the data comes from xml, than it is all strings, so we have to parse it to integers etc
// year is only available in the database, not in the internet XML source, so we can determine
// if it comes from the database by asking for the year value
  static String? _extractString(dynamic val) {
    if (val == null) return null;
    if (val is Map) {
      if (val.containsKey('\$t')) {
        return val['\$t']?.toString();
      }
      return val.values.isNotEmpty ? val.values.first?.toString() : null;
    }
    return val.toString();
  }

  static int? _extractInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    final s = _extractString(val);
    return s != null ? int.tryParse(s) : null;
  }

  Conference.fromMapToObject(dynamic obj) {
    if (obj['year'] == null) {
 //     print("Runtimetype conference title: ${obj['title'].runtimeType.toString()}");
      title = _extractString(obj['title']);
      subtitle = _extractString(obj['subtitle']);
      venue = _extractString(obj['venue']);
      city = _extractString(obj['city']);
      start = _extractString(obj['start']);
      end = _extractString(obj['end']);
      days = _extractInt(obj['days']) ?? 1;
      day_change = _extractString(obj['day_change']);
      timeslot_duration = _extractString(obj['timeslot_duration']);

      DateFormat timeFormat = DateFormat('yyyy-MM-dd');
      DateTime time = timeFormat.parse(start ?? DateTime.now().toIso8601String());
      year = time.year;
      eventsdownloaded = DateTime.now().toUtc().toIso8601String();
    } else {
      year = obj['year'];
      title = _extractString(obj['title']);
      subtitle = _extractString(obj['subtitle']);
      venue = _extractString(obj['venue']);
      city = _extractString(obj['city']);
      start = _extractString(obj['start']);
      end = _extractString(obj['end']);
      days = _extractInt(obj['days']);
      day_change = _extractString(obj['day_change']);
      timeslot_duration = _extractString(obj['timeslot_duration']);
      if (obj['eventsdownloaded'] != null) {
        eventsdownloaded = obj['eventsdownloaded'].toString();
      }
    }
  }

  //this is a mapping to the database
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    map['title'] = title;
    map['subtitle'] = subtitle;
    map['venue'] = venue;
    map['city'] = city;
    map['days'] = days;
    map['start'] = start;
    map['end'] = end;
    map['timeslotduration'] = timeslot_duration;
    map['daychange'] = day_change;
    map['year'] = year;
    map['eventsdownloaded'] = eventsdownloaded;
    return map;
  }
}
