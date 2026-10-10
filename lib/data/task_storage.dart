import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

/// Kegagalan menulis data ke penyimpanan lokal.
class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Titik akses data tugas.
///
/// Seluruh daftar disimpan sebagai satu String JSON di SharedPreferences.
/// Widget tidak boleh mengakses SharedPreferences secara langsung.
class TaskStorage {
  TaskStorage({this.loadDelay = const Duration(milliseconds: 450)});

  static const String storageKey = 'tasks_json_v1';

  final Duration loadDelay;

  Future<List<Task>> load({bool simulateError = false}) async {
    await Future<void>.delayed(loadDelay);
    if (simulateError) {
      throw const FormatException('Simulasi data tersimpan yang rusak.');
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(storageKey);

    // Belum ada data tersimpan: daftar kosong, bukan error.
    if (raw == null || raw.trim().isEmpty) return <Task>[];

    const FormatException corrupted = FormatException(
      'Data tugas tersimpan rusak dan tidak dapat dibaca. '
      'Coba lagi, atau hapus data lewat menu titik tiga.',
    );

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) throw corrupted;

      return decoded.map<Task>((Object? item) {
        if (item is! Map<String, dynamic>) throw corrupted;
        return Task.fromJson(item);
      }).toList();
    } on FormatException {
      throw corrupted;
    } on TypeError {
      // Tipe field tidak sesuai (misalnya title berupa angka).
      throw corrupted;
    }
  }

  Future<void> save(List<Task> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      tasks.map((Task task) => task.toJson()).toList(),
    );
    final bool saved = await prefs.setString(storageKey, encoded);
    if (!saved) {
      throw const StorageException('Data tugas gagal disimpan.');
    }
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool removed = await prefs.remove(storageKey);
    if (!removed) {
      throw const StorageException('Data tugas gagal dihapus.');
    }
  }

  /// Hanya untuk mengisolasi pengujian lokal: mengosongkan penyimpanan tiruan.
  static void resetMemoryForTest() {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(<String, Object>{});
  }
}
