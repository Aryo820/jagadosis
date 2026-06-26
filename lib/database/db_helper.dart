import 'dart:developer';

import 'package:aplikasi/models/user_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Service managing the local SQLite database via sqflite.
/// Implemented using the Singleton pattern to share a single database connection.
class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();

  // Private constructor
  DatabaseService._internal();

  // Factory constructor to return the singleton instance
  factory DatabaseService() => _instance;

  static Database? _database;

  // Database name and version constants
  static const String _dbName = 'jagadosis.db';
  static const int _dbVersion = 3;

  // Table names constants
  static const String tableMedicines = 'medicines';
  static const String tableHistories = 'histories';

  // Common column constants
  static const String columnId = 'id';
  static const String columnMedicineName = 'medicineName';
  static const String columnStatus = 'status';

  // Medicines table column constants
  static const String columnDose = 'dose';
  static const String columnScheduleTime = 'scheduleTime';
  static const String columnEnableNotification = 'enableNotification';

  // Histories table column constants
  static const String columnTakenAt = 'takenAt';

  /// Getter for the database instance. Initializes it if it has not been opened yet.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the SQLite database.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Callback to create the database schema tables when the database is first initialized.
  Future<void> _onCreate(Database db, int version) async {
    // Create medicines table
    await db.execute('''
      CREATE TABLE $tableMedicines (
        $columnId TEXT PRIMARY KEY,
        $columnMedicineName TEXT NOT NULL,
        $columnDose TEXT NOT NULL,
        $columnScheduleTime TEXT NOT NULL,
        $columnStatus TEXT NOT NULL,
        $columnEnableNotification INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create histories table
    await db.execute('''
      CREATE TABLE $tableHistories (
        $columnId TEXT PRIMARY KEY,
        $columnMedicineName TEXT NOT NULL,
        $columnTakenAt TEXT NOT NULL,
        $columnStatus TEXT NOT NULL
      )
    ''');

    await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');
  }

  /// Callback to upgrade the database schema when version is incremented.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          email TEXT UNIQUE,
          password TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add the enableNotification column for existing installs upgrading to v3.
      await db.execute(
        'ALTER TABLE $tableMedicines ADD COLUMN '
        '$columnEnableNotification INTEGER NOT NULL DEFAULT 1',
      );
    }
  }

  // Register

  Future<bool> registerUser(UserModel users) async {
    final db = await database;
    try {
      final map = users.toMap();
      map.remove(
        'id',
      ); // Remove id to let SQLite AUTOINCREMENT assign the integer ID automatically
      await db.insert('users', map);
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  // Log In

  Future<UserModel?> loginUser(String email, String password) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  // Fungsi untuk mengambil semua data user
  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('users');

    return results.map((map) => UserModel.fromMap(map)).toList();
  }

  // Fungsi untuk menghapus user berdasarkan ID
  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Fungsi untuk memperbarui data user
  Future<bool> updateUser(UserModel users) async {
    final db = await database;
    try {
      int count = await db.update(
        'users',
        users.toMap(),
        where: 'id = ?',
        whereArgs: [users.id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Raw CRUD: Inserts a map of data into the specified table.
  /// Uses [ConflictAlgorithm.replace] to resolve key conflicts automatically.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Raw CRUD: Queries records from the specified table.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  /// Raw CRUD: Updates records in the specified table matching the given condition.
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Raw CRUD: Deletes records from the specified table matching the given condition.
  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}
