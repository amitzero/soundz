// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  test('simple sqflite example', () async {
    String inMemoryDatabasePath = 'temp/inmemorydb.db';
    var db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    expect(await db.getVersion(), 1);
    await db.close();
  });
}
