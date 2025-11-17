---

title: Encryption
description: Use drift on encrypted databases

---

There are two ways to use drift on encrypted databases.
The `encrypted_drift` package is similar to `drift_sqflite` and uses a platform plugin written in
Java.
Alternatively, you can also enable encryption with drift and `drift_flutter` setups.
This setup is recommended for new apps.
An example of a Flutter app using the new encryption package is available
[here](https://github.com/simolus3/drift/tree/develop/examples/encryption).

## Encrypted version of a `NativeDatabase`

You can also use the new `drift/native` library with an encrypted executor.
This allows you to use an encrypted drift database on more platforms, which is particularly
interesting for Desktop applications.

### Setup

!!! Recent changes

    Previous versions of this page suggested using `sqlcipher_flutter_libs`. When using version
    3 of the `sqlite3` package, that is no longer applicable.
    See notes on [migrating](#migrating-from-sqlcipher) for additional details.

First, add a `hooks` section to your `pubspec.yaml` to make the `sqlite3` package load
[SQLite3MultipleCiphers](https://utelle.github.io/SQLite3MultipleCiphers/) instead of
the regular SQLite library:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

### Using

SQLCipher implements sqlite3's C api, which means that you can continue to use the `sqlite3` package and
`NativeDatabase` without changes.

To actually encrypt a database, you must set an encryption key before using it.
A good place to do that in drift is the `setup` parameter of `NativeDatabase`, which runs before drift
is using the database in any way:

<Snippet href="/lib/src/snippets/platforms/encryption.dart" name="encrypted1" />

### Encrypting existing databases

If you have an existing database which you now want to encrypt, there are a few steps to consider.
First, add a `hooks` section to your pubspec as shown in the [setup](#setup).

Note however that you can't just apply the `pragma key = ` statement on existing databases!
To migrate existing databases to encryption, SQLCipher recommends [these steps](https://discuss.zetetic.net/t/how-to-encrypt-a-plaintext-sqlite-database-to-use-sqlcipher-and-avoid-file-is-encrypted-or-is-not-a-database-errors/868):

1. Opening your existing database.
2. Attaching a new encrypted-variant.
3. Calling the `sqcipher_export` function to copy the unencrypted database into the encrypted file.
4. Closing and deleting the unencrypted database.

In drift, you can run these steps in the `isolateSetup` callback when opening a `NativeDatabase`:

<Snippet href="/lib/src/snippets/platforms/encryption.dart" name="migration" />

### Migrating from SQLCipher

## Using `encrypted_drift`

In addition to the `dart:ffi`-based encrypted executor based on `package:sqlite3`, we also provide
a version of drift that uses the [sqflite_sqlcipher](https://pub.dev/packages/sqflite_sqlcipher) library
by [@davidmartos96](https://github.com/davidmartos96).

To use it, you need to remove a dependency on `drift_sqflite` you might have in your `pubspec.yaml`
and replace it with this:

```yaml
dependencies:
  drift: ^{{ versions.drift }}
  encrypted_drift:
   git:
    url: https://github.com/simolus3/drift.git
    path: extras/encryption
```

Instead of importing `package:drift_sqflite/drift_sqflite.dart` (or `package:drift/native.dart`) in your apps, 
you would then import both `package:drift/drift.dart` and `package:encrypted_drift/encrypted_drift.dart`.

Finally, you can replace `SqfliteQueryExecutor` (or a `NativeDatabase`) with an `EncryptedExecutor`.

### Extra setup on Android and iOS

Some extra steps may have to be taken in your project so that SQLCipher works correctly. For example, the ProGuard configuration on Android for apps built for release.

[Read instructions](https://pub.dev/packages/sqflite_sqlcipher) (Usage and installation instructions of the package can be ignored, as that is handled internally by `encrypted_drift`)
