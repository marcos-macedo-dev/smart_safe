import 'dart:developer' as developer;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sos_record.dart';

class LocalDatabase {
  static Database? _database;
  static const String _sosTableName = 'sos_records';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'smart_safe_database.db');

    // Para desenvolvimento: deleta banco antigo
    // Para desenvolvimento: deleta banco antigo
    // print('LocalDatabase: Deleting existing database for fresh start.');
    // await deleteDatabase(path);

    developer.log(
      'Opening database at $path with version 2.',
      name: 'LocalDatabase',
    );
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log(
      'onCreate triggered. Version: $version',
      name: 'LocalDatabase',
    );
    await db.execute('''
      CREATE TABLE $_sosTableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER,
        latitude REAL,
        longitude REAL,
        status TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        encerrado_em TEXT,
        caminho_audio TEXT,
        caminho_video TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log(
      'onUpgrade from $oldVersion to $newVersion',
      name: 'LocalDatabase',
    );
    if (oldVersion < 2) {
      developer.log(
        'Adding createdAt and updatedAt columns.',
        name: 'LocalDatabase',
      );
      await db.execute('ALTER TABLE $_sosTableName ADD COLUMN createdAt TEXT;');
      await db.execute('ALTER TABLE $_sosTableName ADD COLUMN updatedAt TEXT;');
    }
  }

  Future<int> insertSosRecord(SosRecord record) async {
    final db = await database;
    final data = record.toJson();
    if (data['id'] == 0 || data['id'] == null) data.remove('id');
    data['is_synced'] = 0;
    return await db.insert(
      _sosTableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SosRecord>> getUnsyncedSosRecords() async {
    final db = await database;
    final maps = await db.query(
      _sosTableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return maps.map((m) => SosRecord.fromJson(m)).toList();
  }

  Future<int> markSosRecordAsSynced(int id) async {
    final db = await database;
    return await db.update(
      _sosTableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSyncedSosRecords() async {
    final db = await database;
    return await db.delete(
      _sosTableName,
      where: 'is_synced = ?',
      whereArgs: [1],
    );
  }
}
