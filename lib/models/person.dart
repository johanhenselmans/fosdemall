import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/utils/utils.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'person.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable(explicitToJson: true)
class Person extends ChangeNotifier {
  Person(
    this.id,
    this.name, {
    this.asciiName,
    this.description,
    this.picture,
    this.pictureUrl,
    this.descriptionYear,
    this.pictureYear,
    this.events,
  });

  @JsonKey(name: 'id')
  int? id;
  @JsonKey(name: r'$t')
  String? name;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? asciiName;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? description;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Uint8List? picture;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? pictureUrl;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? descriptionYear;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? pictureYear;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Event>? events;

  /// A necessary factory constructor for creating a new Event instance
  /// from a map. Pass the map to the generated `_$EventFromJson()` constructor.
  /// The constructor is named after the source class, in this case, Event.
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$PersonToJson(this);

  factory Person.fromDbMap(Map<dynamic, dynamic> map) {
    Uint8List? picBytes;
    if (map['person_picture'] != null) {
      if (map['person_picture'] is Uint8List) {
        picBytes = map['person_picture'] as Uint8List;
      } else if (map['person_picture'] is List<int>) {
        picBytes = Uint8List.fromList(map['person_picture'] as List<int>);
      }
    }
    final rawName = map['person_name'] ?? map['name'] ?? map[r'$t'];
    final rawDesc = map['person_description'];
    return Person(
      map['id'] is int
          ? map['id']
          : (map['person_id'] is int
              ? map['person_id']
              : int.tryParse(map['id']?.toString() ?? '')),
      rawName != null ? cleanPersonName(rawName) : null,
      asciiName: map['person_ascii_name'],
      description: rawDesc != null ? cleanMojibake(rawDesc) : null,
      picture: picBytes,
      pictureUrl: map['person_picture_url'],
      descriptionYear: map['description_year'] is int
          ? map['description_year']
          : int.tryParse(map['description_year']?.toString() ?? ''),
      pictureYear: map['picture_year'] is int
          ? map['picture_year']
          : int.tryParse(map['picture_year']?.toString() ?? ''),
    );
  }

  Person.fromMapToObject(dynamic obj) {
    if (obj['person_name'] != null) {
      id = obj['id'] is int
          ? obj['id']
          : (obj['person_id'] is int
              ? obj['person_id']
              : int.tryParse(obj['id']?.toString() ?? ''));
      name = cleanPersonName(obj['person_name']);
      asciiName = obj['person_ascii_name'];
      description = obj['person_description'] != null
          ? cleanMojibake(obj['person_description'])
          : null;
      if (obj['person_picture'] != null) {
        if (obj['person_picture'] is Uint8List) {
          picture = obj['person_picture'];
        } else if (obj['person_picture'] is List<int>) {
          picture = Uint8List.fromList(obj['person_picture']);
        }
      }
      pictureUrl = obj['person_picture_url'];
      descriptionYear = obj['description_year'] is int
          ? obj['description_year']
          : int.tryParse(obj['description_year']?.toString() ?? '');
      pictureYear = obj['picture_year'] is int
          ? obj['picture_year']
          : int.tryParse(obj['picture_year']?.toString() ?? '');
    } else if (obj['id'] != null && obj['id'].runtimeType.toString().contains('String')) {
      id = int.tryParse(obj["id"]);
      final rawName = obj[r"$t"];
      name = rawName != null ? cleanPersonName(rawName) : null;
    } else {
      id = obj['id'];
      final rawName = obj["name"] ?? obj[r"$t"];
      name = rawName != null ? cleanPersonName(rawName) : null;
    }
  }
}