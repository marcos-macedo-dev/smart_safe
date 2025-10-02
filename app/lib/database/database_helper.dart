import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact_local.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smart_safe.db');
    return await openDatabase(
      path,
      version: 1, // Revert database version
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, email TEXT, parentesco TEXT, isSynced INTEGER)',
    );
  }

  // ContactLocal CRUD operations
  Future<int> insertContact(ContactLocal contact) async {
    Database db = await database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<ContactLocal>> getContacts() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('contacts');
    return List.generate(maps.length, (i) {
      return ContactLocal.fromMap(maps[i]);
    });
  }

  Future<int> updateContact(ContactLocal contact) async {
    Database db = await database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    Database db = await database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
