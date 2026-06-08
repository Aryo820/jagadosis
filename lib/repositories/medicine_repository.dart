import 'package:aplikasi/database/db_helper.dart';
import 'package:aplikasi/models/medicine_model.dart';

/// Repository managing medicine data transactions.
/// Separates local database query/mapping logic from the UI layers.
class MedicineRepository {
  final DatabaseService _dbService;

  /// Constructor allowing dependency injection for easier testing.
  MedicineRepository({DatabaseService? dbService})
    : _dbService = dbService ?? DatabaseService();

  /// Adds a new medicine reminder entry to the local database.
  Future<void> addMedicine(MedicineModel medicine) async {
    await _dbService.insert(DatabaseService.tableMedicines, medicine.toMap());
  }

  /// Retrieves all registered medicine reminders from the database.
  Future<List<MedicineModel>> getAllMedicines() async {
    final List<Map<String, dynamic>> maps = await _dbService.query(
      DatabaseService.tableMedicines,
    );
    return maps.map((map) => MedicineModel.fromMap(map)).toList();
  }

  /// Updates the details of an existing medicine reminder.
  Future<void> updateMedicine(MedicineModel medicine) async {
    await _dbService.update(
      DatabaseService.tableMedicines,
      medicine.toMap(),
      where: '${DatabaseService.columnId} = ?',
      whereArgs: [medicine.id],
    );
  }

  /// Deletes a medicine reminder by its unique ID.
  Future<void> deleteMedicine(String id) async {
    await _dbService.delete(
      DatabaseService.tableMedicines,
      where: '${DatabaseService.columnId} = ?',
      whereArgs: [id],
    );
  }
}
