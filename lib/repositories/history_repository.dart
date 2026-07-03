import 'package:aplikasi/database/db_helper.dart';
import 'package:aplikasi/models/history_model.dart';
import 'package:intl/intl.dart';

/// Repository managing consumption history data transactions.
/// Separates local database query/mapping logic from the UI layers.
class HistoryRepository {
  final DatabaseService _dbService;

  /// Constructor allowing dependency injection for easier testing.
  HistoryRepository({DatabaseService? dbService})
    : _dbService = dbService ?? DatabaseService();

  /// Adds a new medication consumption history entry to the local database.
  Future<void> addHistory(HistoryModel history) async {
    await _dbService.insert(DatabaseService.tableHistories, history.toMap());
  }

  /// Retrieves all consumption history entries from the database, ordered by the consumption date.
  Future<List<HistoryModel>> getAllHistories() async {
    final List<Map<String, dynamic>> maps = await _dbService.query(
      DatabaseService.tableHistories,
      orderBy: '${DatabaseService.columnTakenAt} DESC',
    );
    return maps.map((map) => HistoryModel.fromMap(map)).toList();
  }

  /// Retrieves history entries filtered by a specific date.
  /// Converts the [date] to 'yyyy-MM-dd' pattern and queries for matching records.
  Future<List<HistoryModel>> getHistoriesByDate(DateTime date) async {
    final String dateString = DateFormat('yyyy-MM-dd').format(date);
    final List<Map<String, dynamic>> maps = await _dbService.query(
      DatabaseService.tableHistories,
      where: '${DatabaseService.columnTakenAt} LIKE ?',
      whereArgs: ['$dateString%'],
      orderBy: '${DatabaseService.columnTakenAt} DESC',
    );
    return maps.map((map) => HistoryModel.fromMap(map)).toList();
  }

  /// Retrieves history entries filtered by a specific month.
  Future<List<HistoryModel>> getHistoriesByMonth(int year, int month) async {
    // Ambil tanggal 1 di bulan berikutnya sebagai batas atas (eksklusif)
    final String startDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(year, month, 1));
    final String endDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(year, month + 1, 1));

    final List<Map<String, dynamic>> maps = await _dbService.query(
      DatabaseService.tableHistories,
      // Gunakan >= dan < agar jam 23:59 di hari terakhir masuk
      where:
          '${DatabaseService.columnTakenAt} >= ? AND ${DatabaseService.columnTakenAt} < ?',
      whereArgs: [startDate, endDate],
      orderBy: '${DatabaseService.columnTakenAt} DESC',
    );
    return maps.map((map) => HistoryModel.fromMap(map)).toList();
  }

  /// Retrieves history entries filtered by a specific year.
  Future<List<HistoryModel>> getHistoriesByYear(int year) async {
    final String startDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(year, 1, 1));
    final String endDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(year + 1, 1, 1));

    final List<Map<String, dynamic>> maps = await _dbService.query(
      DatabaseService.tableHistories,
      where:
          '${DatabaseService.columnTakenAt} >= ? AND ${DatabaseService.columnTakenAt} < ?',
      whereArgs: [startDate, endDate],
      orderBy: '${DatabaseService.columnTakenAt} DESC',
    );
    return maps.map((map) => HistoryModel.fromMap(map)).toList();
  }
}
