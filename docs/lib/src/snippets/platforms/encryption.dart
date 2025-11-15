import 'dart:io';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

// #docregion check_cipher
bool _debugCheckHasCipher(Database database) {
  return database.select('PRAGMA cipher;').isNotEmpty;
}
// #enddocregion check_cipher

void databases() {
  final myDatabaseFile = File('/dev/null');

  // #docregion encrypted1
  NativeDatabase.createInBackground(
    myDatabaseFile,
    setup: (rawDb) {
      // Make SQLite3MultipleCiphers choose a format compatible with SQLCipher.
      // You can ignore this if you have not been using sqlcipher_flutter_libs
      // before. See also: https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md#encryption
      rawDb.execute("pragma cipher = 'sqlcipher'");
      rawDb.execute('pragma legacy = 4');

      rawDb.execute("PRAGMA key = 'passphrase';");
    },
  );
  // #enddocregion encrypted1

  // #docregion encrypted2
  NativeDatabase.createInBackground(
    myDatabaseFile,
    setup: (rawDb) {
      // To use a format compatible with SQLCipher - only relevant if you've
      // used sqlcipher_flutter_libs before.
      rawDb.execute("pragma cipher = 'sqlcipher'");
      rawDb.execute('pragma legacy = 4');

      assert(_debugCheckHasCipher(rawDb));

      rawDb.execute("PRAGMA key = 'passphrase';");
    },
  );
  // #enddocregion encrypted2

  // #docregion migration
  final existingDatabasePath = '/path/to/your/database.db';
  final encryptedDatabasePath = '/path/to/your/encrypted.db';
  const yourKey = 'passphrase';

  String escapeString(String source) {
    return source.replaceAll('\'', '\'\'');
  }

  // This database can be passed to the constructor of your database class
  // TODO: This is outdated, update
  NativeDatabase.createInBackground(
    File(encryptedDatabasePath),
    isolateSetup: () async {
      final existing = File(existingDatabasePath);
      final encrypted = File(encryptedDatabasePath);

      if (await existing.exists() && !await encrypted.exists()) {
        // We have an existing database to migrate.
        final plaintextDb = sqlite3.open(existingDatabasePath)
          ..execute(
            "ATTACH DATABASE '${escapeString(encryptedDatabasePath)}' "
            "AS encrypted KEY '${escapeString(yourKey)}';",
          )
          ..execute("SELECT sqlcipher_export('encrypted');");

        // sqlcipher_export doesn't apply the user_version pragma used by drift
        // to implement migrations. The version of the encrypted database must
        // match the previous state.
        final userVersion =
            plaintextDb.select('PRAGMA user_version;').first.columnAt(0) as int;
        plaintextDb
          ..execute('PRAGMA encrypted.user_version = $userVersion;')
          ..execute('DETACH DATABASE encrypted;')
          ..close();

        // This should have created the encrypted database.
        assert(await encrypted.exists());
        await existing.delete();
      }
    },
    setup: (rawDb) {
      assert(_debugCheckHasCipher(rawDb));
      rawDb.execute("PRAGMA key = '${escapeString(yourKey)}';");
    },
  );
  // #enddocregion migration
}
