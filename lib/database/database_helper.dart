import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'agrovision.db');

    // increment version if you change schema and implement onUpgrade
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
  // Load SQL file from assets
  String script;
  try {
    script = await rootBundle.loadString('assets/sql/agrovision_database.sql');
  } catch (e) {
    throw Exception('Could not load SQL asset: assets/sql/agrovision_database.sql. Error: $e');
  }

  // Remove single-line comments (-- ...) and block comments (/* ... */)
  script = script.replaceAll(RegExp(r'--.*(\r?\n|$)'), '\n');
  script = script.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '\n');

  // Normalize newlines
  script = script.replaceAll('\r\n', '\n');

  // Remove MySQL-specific statements and tokens that SQLite doesn't support
  // Note: DON'T use inline flags like (?im) — instead set RegExp flags below.
  script = script.replaceAll(
    RegExp(r'^\s*(DROP|CREATE)\s+DATABASE.*$', multiLine: true, caseSensitive: false),
    '',
  );
  script = script.replaceAll(
    RegExp(r'^\s*USE\s+\w+.*$', multiLine: true, caseSensitive: false),
    '',
  );
  script = script.replaceAll(
    RegExp(r'^\s*SHOW\s+.*$', multiLine: true, caseSensitive: false),
    '',
  );
  script = script.replaceAll(
    RegExp(r'^\s*SET\s+.*$', multiLine: true, caseSensitive: false),
    '',
  );
  script = script.replaceAll(
    RegExp(r'^\s*LOCK\s+.*$', multiLine: true, caseSensitive: false),
    '',
  );

  // Remove MySQL-versioned comment blocks like /*!50001 ... */
  script = script.replaceAll(RegExp(r'/\*!\d+[\s\S]*?\*/'), '');

  // Remove ENGINE/CHARSET/ROW_FORMAT table options after ')'
  script = script.replaceAll(RegExp(r'\)\s*ENGINE\s*=\s*\w+[^;]*;?', caseSensitive: false), ');');
  script = script.replaceAll(RegExp(r'DEFAULT\s+CHARSET\s*=\s*\w+;?', caseSensitive: false), ';');

  // Token replacements
  script = script.replaceAll('`', '');
  script = script.replaceAll(RegExp(r'\bUNSIGNED\b', caseSensitive: false), '');
  script = script.replaceAll(RegExp(r'\bAFTER\b\s+\w+', caseSensitive: false), '');

  // Convert AUTO_INCREMENT primary keys
  script = script.replaceAll(
    RegExp(r'INT\s+AUTO_INCREMENT\s+PRIMARY\s+KEY', caseSensitive: false),
    'INTEGER PRIMARY KEY AUTOINCREMENT',
  );
  script = script.replaceAll(
    RegExp(r'(BIGINT|SMALLINT|TINYINT|MEDIUMINT)\s+AUTO_INCREMENT\s+PRIMARY\s+KEY', caseSensitive: false),
    'INTEGER PRIMARY KEY AUTOINCREMENT',
  );

  // Remove residual ENGINE tokens with trailing semicolons
  script = script.replaceAll(RegExp(r'ENGINE\s*=\s*\w+\s*;?', caseSensitive: false), ';');

  // Split and execute statements
  final rawStatements = script.split(';');
  final batch = db.batch();

for (final raw in rawStatements) {
  final stmt = raw.trim();
  if (stmt.isEmpty) continue;

  final upper = stmt.toUpperCase();

  // Skip unsupported statements for SQLite or queries that shouldn't be run via batch
  if (upper.startsWith('SELECT') ||
      upper.startsWith('SHOW ') ||
      upper.startsWith('DESCRIBE ') ||
      upper.startsWith('EXPLAIN ') ||
      upper.startsWith('SET ') ||
      upper.startsWith('USE ') ||
      upper.startsWith('LOCK ')) {
    print('Skipping non-DDL/non-DML SQL statement from asset: ${stmt.split('\n').first}');
    continue;
  }

  try {
    batch.execute(stmt);
  } catch (e) {
    print('Failed to add statement to batch (skipped). Statement preview: ${stmt.substring(0, stmt.length > 120 ? 120 : stmt.length)}');
    print('Error: $e');
  }
}

try {
  await batch.commit(noResult: true);
  print('Database created from SQL asset successfully.');
} catch (e, st) {
  print('Error while executing SQL batch during DB creation: $e\n$st');
  rethrow;
}
}

  // Example helper (unchanged)
  Future<Map<String, dynamic>?> getFarmerByPhone(String phone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Farmers',
      where: 'phone = ?',
      whereArgs: [phone],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}
