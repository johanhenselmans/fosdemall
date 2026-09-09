import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('query persons from db', () async {
    final db = await openDatabase('/Users/localadmin/Documents/fosdem.db');

    // 1. Check person with ascii adam_ruzicka
    final pRow = await db.rawQuery("SELECT * FROM person WHERE person_ascii_name = 'adam_ruzicka'");
    print('pRow: $pRow');

    // 2. Check Event persons matching 6736 or ruzicka
    final evRows = await db.rawQuery("SELECT id, year, persons FROM Event WHERE persons LIKE '%6736%'");
    for (var r in evRows) {
      print('Event ${r['id']} (year ${r['year']}): ${r['persons']}');
    }

    // 3. Run getPersonsFromDb query for 2020
    final q2020 = await db.rawQuery('''
      SELECT DISTINCT p.* FROM person p
      JOIN (
        SELECT json_extract(value, '\$.id') as pid 
        FROM Event, json_each(Event.persons)
        WHERE Event.year = ?
      ) ep ON p.id = ep.pid OR p.person_id = ep.pid OR CAST(p.id AS TEXT) = ep.pid
      ORDER BY p.person_name COLLATE NOCASE ASC
    ''', [2020]);
    final match2020 = q2020.where((r) => r['person_name'].toString().contains('Adam') || r['person_ascii_name'].toString().contains('ruzicka'));
    print('2020 matches: $match2020');

    // 4. Run getPersonsFromDb query for 2026
    final q2026 = await db.rawQuery('''
      SELECT DISTINCT p.* FROM person p
      JOIN (
        SELECT json_extract(value, '\$.id') as pid 
        FROM Event, json_each(Event.persons)
        WHERE Event.year = ?
      ) ep ON p.id = ep.pid OR p.person_id = ep.pid OR CAST(p.id AS TEXT) = ep.pid
      ORDER BY p.person_name COLLATE NOCASE ASC
    ''', [2026]);
    final match2026 = q2026.where((r) => r['person_name'].toString().contains('Adam') || r['person_ascii_name'].toString().contains('ruzicka'));
    print('2026 matches: $match2026');

    // 5. Look for any person whose person_name contains 'adam_ruzicka' or is snake_case or has encoding issues
    final slugAsName = await db.rawQuery("SELECT id, person_name, person_ascii_name FROM person WHERE person_name LIKE '%\\_%' ESCAPE '\\'");
    print('slugAsName count: ${slugAsName.length}, first 5: ${slugAsName.take(5).toList()}');
  });
}
