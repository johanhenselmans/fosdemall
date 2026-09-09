import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  io.HttpOverrides.global = null;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '/Users/localadmin/Documents';
  });

  test('test scrape picture for Jens Monig', () async {
    final helper = DatabaseHelper();
    final db = await helper.db;

    // Test scrape Jens Monig
    print('Testing scrape and save for Jens Monig...');
    final client = http.Client();
    final result = await helper.scrapeSpeakerPageForTest(
      client: client,
      year: 2025,
      slug: 'jens_monig',
    );
    client.close();

    print('Scraped description length: ${result.desc.length}');
    print('Scraped picture bytes length: ${result.picBytes?.length}');
    print('Scraped picture url: ${result.picUrl}');
    expect(result.picBytes, isNotNull);
    expect(result.picBytes!.length, greaterThan(100));

    await helper.saveOrUpdatePersonInDbForTest(
      dbClient: db,
      year: 2025,
      pid: 18694,
      rawName: 'Jens Mönig',
      slug: 'jens_monig',
      newDesc: result.desc,
      picBytes: result.picBytes,
      picUrl: result.picUrl,
    );

    final row = await db.query('person', where: 'person_ascii_name = ?', whereArgs: ['jens_monig']);
    print('Jens Monig row in DB: $row');
    expect(row, isNotEmpty);
    expect(row.first['person_picture'], isNotNull);
    final picData = row.first['person_picture'];
    print('Stored picture runtimeType: ${picData.runtimeType}, length: ${(picData as List).length}');
    expect((picData).length, equals(result.picBytes!.length));

    // Test getPersonById returns picture
    final person = await helper.getPersonById(row.first['id'] as int);
    expect(person, isNotNull);
    expect(person!.picture, isNotNull);
    expect(person.picture!.length, equals(result.picBytes!.length));
    print('Successfully verified picture in person model!');
  });
}
