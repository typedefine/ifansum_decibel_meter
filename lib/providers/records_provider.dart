import 'package:flutter/material.dart';
import '../models/noise_record.dart';
import '../services/database_service.dart';

class RecordsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<NoiseRecord> _records = [];
  bool _isLoaded = false;

  List<NoiseRecord> get records => _records;
  bool get isLoaded => _isLoaded;

  Future<void> loadRecords() async {
    _records = await _db.getRecords();
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addRecord(NoiseRecord record) async {
    await _db.insertRecord(record);
    _records.insert(0, record);
    notifyListeners();
  }

  Future<void> updateRecord(NoiseRecord record) async {
    await _db.updateRecord(record);
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      notifyListeners();
    }
  }

  Future<void> deleteRecord(String id) async {
    await _db.deleteRecord(id);
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
