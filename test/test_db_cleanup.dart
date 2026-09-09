import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fosdem/data/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Run cleanPersonMojibakeInDb on fosdem.db and verify Abhishek Lekshmanan', () async {
    sqfliteFfiInit();
    final theDb = await databaseFactoryFfi.openDatabase('/Users/localadmin/Documents/fosdem.db');
    final helper = DatabaseHelper();
    print('Running cleanPersonMojibakeInDb...');
    await helper.cleanPersonMojibakeInDb(theDb);
    print('Done cleaning!');

    final rows = await theDb.query('person',
      where: 'person_name LIKE ?',
      whereArgs: ['%Lekshmanan%'],
    );
    print('Lekshmanan rows in person table: ${rows.length}');
    for (var r in rows) {
      print('ID: ${r['id']}, PID: ${r['person_id']}, Name: "${r['person_name']}", DescLen: ${(r['person_description']?.toString() ?? '').length}');
    }
    expect(rows.length, 1);
    expect(rows.first['person_name'], 'Abhishek Lekshmanan');
    expect((rows.first['person_description'] as String).isNotEmpty, isTrue);

    final jacomyRows = await theDb.query('person',
      where: 'person_name LIKE ?',
      whereArgs: ['%Alexis%Jacomy%'],
    );
    print('Alexis Jacomy rows in person table: ${jacomyRows.length}');
    for (var r in jacomyRows) {
      print('ID: ${r['id']}, PID: ${r['person_id']}, Name: "${r['person_name']}", DescLen: ${(r['person_description']?.toString() ?? '').length}');
    }
    expect(jacomyRows.length, 1);
    expect(jacomyRows.first['person_name'], 'Alexis Jacomy');

    // Verify events for Abhishek Lekshmanan
    final eventRows = await theDb.rawQuery('''
      SELECT DISTINCT e.id, e.title, e.year FROM Event e, json_each(e.persons)
      WHERE json_extract(value, '\$.\u0024t') = ?
    ''', ['Abhishek Lekshmanan']);
    print('Events for Abhishek Lekshmanan: ${eventRows.length}');
    for (var er in eventRows) {
      print('  Event: ${er['id']}, Year: ${er['year']}, Title: ${er['title']}');
    }
    expect(eventRows.length, 3);

    await theDb.close();
  });
}
