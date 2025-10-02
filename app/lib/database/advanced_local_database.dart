import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sos_record.dart';
import '../models/user.dart';
import '../models/delegacia.dart';
import '../models/emergency_contact.dart';

class AdvancedLocalDatabase {
  static Database? _database;
  static const String _sosTableName = 'sos_records';
  static const String _usersTableName = 'users';
  static const String _delegaciasTableName = 'delegacias';
  static const String _contactsTableName = 'emergency_contacts';
  static const String _syncQueueTableName = 'sync_queue';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'smart_safe_advanced.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela para registros SOS
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

    // Tabela para usuários
    await db.execute('''
      CREATE TABLE $_usersTableName(
        id INTEGER PRIMARY KEY,
        nome_completo TEXT,
        email TEXT,
        telefone TEXT,
        cpf TEXT,
        data_nascimento TEXT,
        genero TEXT,
        cor TEXT,
        cidade TEXT,
        estado TEXT,
        endereco TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    // Tabela para delegacias
    await db.execute('''
      CREATE TABLE $_delegaciasTableName(
        id INTEGER PRIMARY KEY,
        nome TEXT,
        endereco TEXT,
        latitude REAL,
        longitude REAL,
        telefone TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    // Tabela para contatos de emergência
    await db.execute('''
      CREATE TABLE $_contactsTableName(
        id INTEGER PRIMARY KEY,
        usuario_id INTEGER,
        nome TEXT,
        telefone TEXT,
        email TEXT,
        parentesco TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabela para fila de sincronização
    await db.execute('''
      CREATE TABLE $_syncQueueTableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT,
        entity_id INTEGER,
        operation TEXT,
        data TEXT,
        timestamp TEXT,
        retry_count INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Métodos CRUD para SOS
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

  Future<List<SosRecord>> getAllSosRecords() async {
    final db = await database;
    final maps = await db.query(_sosTableName);
    return maps.map((m) => SosRecord.fromJson(m)).toList();
  }

  Future<int> updateSosRecord(SosRecord record) async {
    final db = await database;
    final data = record.toJson();
    return await db.update(
      _sosTableName,
      data,
      where: 'id = ?',
      whereArgs: [record.id],
    );
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

  // Métodos CRUD para usuários
  Future<int> insertUser(User user) async {
    final db = await database;
    final data = user.toJson();
    data['is_synced'] = 1; // Usuários geralmente vêm do servidor
    return await db.insert(
      _usersTableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final maps = await db.query(
      _usersTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final data = user.toJson();
    return await db.update(
      _usersTableName,
      data,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Métodos CRUD para delegacias
  Future<int> insertDelegacia(Delegacia delegacia) async {
    final db = await database;
    final data = delegacia.toJson();
    data['is_synced'] = 1; // Delegacias geralmente vêm do servidor
    return await db.insert(
      _delegaciasTableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Delegacia>> getAllDelegacias() async {
    final db = await database;
    final maps = await db.query(_delegaciasTableName);
    return maps.map((m) => Delegacia.fromJson(m)).toList();
  }

  Future<int> updateDelegacia(Delegacia delegacia) async {
    final db = await database;
    final data = delegacia.toJson();
    return await db.update(
      _delegaciasTableName,
      data,
      where: 'id = ?',
      whereArgs: [delegacia.id],
    );
  }

  // Métodos CRUD para contatos de emergência
  Future<int> insertEmergencyContact(EmergencyContact contact) async {
    final db = await database;
    final data = contact.toJson();
    data['is_synced'] = 0; // Contatos criados localmente
    return await db.insert(
      _contactsTableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EmergencyContact>> getAllEmergencyContacts() async {
    final db = await database;
    final maps = await db.query(_contactsTableName);
    return maps.map((m) => EmergencyContact.fromJson(m)).toList();
  }

  Future<int> updateEmergencyContact(EmergencyContact contact) async {
    final db = await database;
    final data = contact.toJson();
    data['is_synced'] = 0; // Marcar como não sincronizado
    return await db.update(
      _contactsTableName,
      data,
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteEmergencyContact(int id) async {
    final db = await database;
    return await db.delete(
      _contactsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markEmergencyContactAsSynced(int id) async {
    final db = await database;
    return await db.update(
      _contactsTableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para fila de sincronização
  Future<int> addToSyncQueue({
    required String entityType,
    required int entityId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    return await db.insert(
      _syncQueueTableName,
      {
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'data': jsonEncode(data),
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'is_synced': 0,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedItems() async {
    final db = await database;
    return await db.query(
      _syncQueueTableName,
      where: 'is_synced = 0',
      orderBy: 'timestamp ASC',
    );
  }

  Future<int> markItemAsSynced(int id) async {
    final db = await database;
    return await db.update(
      _syncQueueTableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $_syncQueueTableName SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
    final result = await db.query(
      _syncQueueTableName,
      columns: ['retry_count'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.first['retry_count'] as int;
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