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
  Conference.fromMapToObject(dynamic obj) {
    if (obj['year'] == null) {
      //next we have to find out if it is from a local file, somehow these are better formet as
      //the ones we get from the internet.
      print("Runtimetype conference title: ${obj['title'].runtimeType.toString()}");
      if (obj['title'].runtimeType.toString().contains('Map<String,') ) {
        title = obj['title']['\$t'];
        subtitle = obj['subtitle']['\$t'];
        venue = obj['venue']['\$t'];
        city = obj['city']['\$t'];
        start = obj['start']['\$t'];
        end = obj['end']['\$t'];
        days = int.parse(obj['days']['\$t']);
        day_change = obj['day_change']['\$t'];
        timeslot_duration = obj['timeslot_duration']['\$t'];
      } else {
        title = obj['title'];
        subtitle = obj['subtitle'];
        venue = obj['venue'];
        city = obj['city'];
        start = obj['start'];
        end = obj['end'];
        days =  int.parse(obj['days']);
        day_change = obj['day_change'];
        timeslot_duration = obj['timeslot_duration'];
      }
      // Add the year to the mapping
      DateFormat timeFormat = DateFormat('yyyy-MM-dd');
      DateTime time = timeFormat.parse(start!);
      year = time.year;
      //When a mapping takes place from the internet, we store the date when
      //this occured.
      eventsdownloaded = DateTime.now().toUtc().toIso8601String();
    } else {
      year = obj['year'];
      title = obj['title'];
      subtitle = obj['subtitle'];
      venue = obj['venue'];
      city = obj['city'];
      start = obj['start'];
      end = obj['end'];
      days = obj['days'];
      day_change = obj['day_change'];
      timeslot_duration = obj['timeslot_duration'];
      if (obj['eventsdownloaded'] != null) {
        eventsdownloaded = obj['eventsdownloaded'];
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
