import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:fadeu/models/word_model.dart';

// --- Table and Column Constants ---
const String _wordsTable = 'words';
const String _colId = 'id';
const String _colGerman = 'german';
const String _colPersian = 'persian';
const String _colEnglish = 'english';
const String _colLevel = 'level';

// --- DB Info Constants ---
const String _dbAssetName = "dictionary.db";
const String _dbFileName = "dictionary_app.db";

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dbPath = join(documentsDirectory.path, _dbFileName);
    bool dbExists = await databaseExists(dbPath);

    if (!dbExists) {
      print("Database does not exist. Copying from assets...");
      try {
        await Directory(dirname(dbPath)).create(recursive: true);
        ByteData data =
            await rootBundle.load(join('assets/database', _dbAssetName));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(dbPath).writeAsBytes(bytes, flush: true);
        print("Database copied successfully.");
      } catch (e) {
        print("Error copying database: $e");
        throw Exception("Failed to copy database from assets: $e");
      }
    }
    return await openDatabase(dbPath);
  }

  Future<List<Word>> _queryAndMap(String sql, [List<Object?>? arguments]) async {
    final database = await this.database;
    final List<Map<String, dynamic>> maps = await database.rawQuery(sql, arguments);
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getRandomWords({int limit = 25}) async {
    const sql = 'SELECT * FROM $_wordsTable ORDER BY RANDOM() LIMIT ?';
    return _queryAndMap(sql, [limit]);
  }

  Future<List<Word>> getWordsByLevel(String level, {int limit = 30}) async {
    String sql;
    List<Object?> arguments;

    if (level == 'All') {
      sql = 'SELECT * FROM $_wordsTable ORDER BY RANDOM() LIMIT ?';
      arguments = [limit];
    } else {
      sql = 'SELECT * FROM $_wordsTable WHERE $_colLevel = ? ORDER BY RANDOM() LIMIT ?';
      arguments = [level, limit];
    }
    return _queryAndMap(sql, arguments);
  }

  Future<List<Word>> getWordsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final sql = 'SELECT * FROM $_wordsTable WHERE $_colId IN ($placeholders)';
    return _queryAndMap(sql, ids);
  }
  
  // --- NEW METHOD ADDED ---
  /// Fetches a single word from the database by its unique ID.
  Future<Word?> getWordById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _wordsTable,
      where: '$_colId = ?',
      whereArgs: [id],
      limit: 1, // We only expect one result
    );

    if (maps.isNotEmpty) {
      return Word.fromMap(maps.first);
    }
    return null; // Return null if no word is found with that ID
  }

  Future<List<Word>> searchWords(String query) async {
    final String searchTerm = query.trim().toLowerCase();
    if (searchTerm.isEmpty) return [];

    const sql = '''
      SELECT *,
            CASE
                WHEN lower($_colGerman) = ? THEN 3
                WHEN lower($_colPersian) = ? THEN 3
                WHEN lower($_colEnglish) = ? THEN 3
                WHEN lower($_colGerman) LIKE ? THEN 2
                WHEN lower($_colPersian) LIKE ? THEN 2
                WHEN lower($_colEnglish) LIKE ? THEN 2
                WHEN lower($_colGerman) LIKE ? THEN 1
                WHEN lower($_colPersian) LIKE ? THEN 1
                WHEN lower($_colEnglish) LIKE ? THEN 1
                ELSE 0
            END AS score
      FROM $_wordsTable
      WHERE
          lower($_colGerman) LIKE ? OR
          lower($_colPersian) LIKE ? OR
          lower($_colEnglish) LIKE ?
      ORDER BY
          score DESC,
          length($_colGerman) ASC,
          $_colGerman ASC
      LIMIT 50;
    ''';

    final searchPattern = '%$searchTerm%';
    final List<Object?> arguments = [
      searchTerm, searchTerm, searchTerm,
      '$searchTerm%', '$searchTerm%', '$searchTerm%',
      searchPattern, searchPattern, searchPattern,
      searchPattern, searchPattern, searchPattern,
    ];

    return _queryAndMap(sql, arguments);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Toggles the save status of a word in the database.
  /// Returns the new save status (true if saved, false if unsaved).
  Future<bool> toggleSaveStatus(int wordId, bool isSaved) async {
    final db = await database;
    try {
      await db.update(
        _wordsTable,
        {'is_saved': isSaved ? 1 : 0},
        where: '$_colId = ?',
        whereArgs: [wordId],
      );
      return isSaved;
    } catch (e) {
      debugPrint('Error toggling save status: $e');
      rethrow;
    }
  }
}
