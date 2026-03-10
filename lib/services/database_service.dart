import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/noise_record.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'decibel_meter.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE noise_records (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            durationSeconds INTEGER NOT NULL,
            deviceInfo TEXT,
            location TEXT,
            notes TEXT,
            frequencyWeighting TEXT,
            responseTimeMs INTEGER,
            calibration REAL,
            maxDecibel REAL NOT NULL,
            minDecibel REAL NOT NULL,
            avgDecibel REAL NOT NULL,
            peakValue REAL NOT NULL,
            waveformData TEXT NOT NULL,
            audioFilePath TEXT
          )
        ''');
      },
    );
  }

  Future<List<NoiseRecord>> getRecords() async {
    final db = await database;
    final maps = await db.query('noise_records', orderBy: 'createdAt DESC');
    return maps.map((map) => NoiseRecord.fromMap(map)).toList();
  }

  Future<void> insertRecord(NoiseRecord record) async {
    final db = await database;
    await db.insert('noise_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateRecord(NoiseRecord record) async {
    final db = await database;
    await db.update(
      'noise_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.delete('noise_records', where: 'id = ?', whereArgs: [id]);
  }
}
