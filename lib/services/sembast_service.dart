// No direct dart:convert needed here
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:my_flutter_exercisetracker/models/exercise_record.dart';
import 'dart:io';

/// Simple Sembast-based service to store ExerciseRecord objects.
/// Uses a store named 'records' with string keys and JSON values.
class SembastService {
  static const String _dbName = 'exercise_tracker.db';
  static final _store = stringMapStoreFactory.store('records');
  static Database? _db;

  static Future<Database> _openDb() async {
    if (_db != null) return _db!;
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = '${docDir.path}/$_dbName';
    debugPrint('Opening Sembast DB at $dbPath');
    final dbDir = Directory(docDir.path);
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    _db = await databaseFactoryIo.openDatabase(dbPath);
    return _db!;
  }

  static String _keyForRecord(ExerciseRecord r) => r.startTime.toUtc().toIso8601String();

  static Map<String, dynamic> _toJson(ExerciseRecord r) => {
        'date': r.date.toIso8601String(),
        'startTime': r.startTime.toIso8601String(),
        'endTime': r.endTime?.toIso8601String(),
        'notes': r.notes,
        'taskType': r.taskType,
      };

  static ExerciseRecord _fromJson(Map<String, dynamic> j) {
    final start = DateTime.parse(j['startTime'] as String);
    final end = j['endTime'] != null ? DateTime.parse(j['endTime'] as String) : null;
    return ExerciseRecord(
      date: DateTime.parse(j['date'] as String),
      startTime: start,
      endTime: end,
      notes: j['notes'] as String? ?? '',
      taskType: j['taskType'] as String?,
    );
  }

  static Future<List<ExerciseRecord>> readAllRecords() async {
    final db = await _openDb();
    final recordsSnapshot = await _store.find(db);
    final list = recordsSnapshot.map((snap) => _fromJson(Map<String, dynamic>.from(snap.value))).toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  static Future<void> addRecord(ExerciseRecord record) async {
    final db = await _openDb();
    final key = _keyForRecord(record);
    await _store.record(key).put(db, _toJson(record));
  }

  static Future<void> replaceAllRecords(List<ExerciseRecord> records) async {
    final db = await _openDb();
    final batch = db.transaction((txn) async {
      await _store.delete(txn);
      for (final r in records) {
        await _store.record(_keyForRecord(r)).put(txn, _toJson(r));
      }
    });
    await batch;
  }
}
