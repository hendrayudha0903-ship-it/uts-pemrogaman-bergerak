import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts_praktikum_starter/app/tugas_app.dart';
import 'package:uts_praktikum_starter/data/task_storage.dart';
import 'package:uts_praktikum_starter/models/task.dart';
import 'package:uts_praktikum_starter/widgets/task_card.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _addTask(WidgetTester tester, String title, String course) async {
  await tester.tap(find.byKey(const Key('add-task-button')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('task-title-field')), title);
  await tester.enterText(find.byKey(const Key('task-course-field')), course);
  await tester.tap(find.byKey(const Key('save-task-button')));
  await tester.pumpAndSettle();
}

void _seed(List<Task> tasks) {
  SharedPreferences.setMockInitialValues(<String, Object>{
    TaskStorage.storageKey: jsonEncode(
      tasks.map((Task t) => t.toJson()).toList(),
    ),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Task JSON', () {
    test('toJson lalu fromJson menghasilkan data yang sama', () {
      const Task task = Task(
        id: '1',
        title: 'Laporan',
        course: 'PPB',
        isDone: true,
      );
      final Task restored = Task.fromJson(task.toJson());
      expect(restored.id, '1');
      expect(restored.title, 'Laporan');
      expect(restored.course, 'PPB');
      expect(restored.isDone, isTrue);
    });

    test('key yang hilang memakai nilai aman', () {
      final Task restored = Task.fromJson(<String, dynamic>{'id': '2'});
      expect(restored.title, '');
      expect(restored.isDone, isFalse);
    });
  });

  group('TaskStorage', () {
    final TaskStorage storage = TaskStorage(loadDelay: Duration.zero);

    test('belum ada data menghasilkan daftar kosong', () async {
      expect(await storage.load(), isEmpty);
    });

    test('save lalu load mengembalikan daftar yang sama', () async {
      await storage.save(const <Task>[
        Task(id: '1', title: 'A', course: 'X'),
        Task(id: '2', title: 'B', course: 'Y', isDone: true),
      ]);
      final List<Task> loaded = await storage.load();
      expect(loaded.map((Task t) => t.title), <String>['A', 'B']);
      expect(loaded.last.isDone, isTrue);
    });

    test('JSON rusak menghasilkan FormatException', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{TaskStorage.storageKey: '{bukan json'},
      );
      expect(storage.load(), throwsFormatException);
    });

    test('JSON valid tetapi bentuknya salah menghasilkan FormatException',
        () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{TaskStorage.storageKey: '{"a": 1}'},
      );
      expect(storage.load(), throwsFormatException);
    });

    test('clear menghapus data', () async {
      await storage.save(const <Task>[Task(id: '1', title: 'A', course: 'X')]);
      await storage.clear();
      expect(await storage.load(), isEmpty);
    });
  });

  group('Form dan navigasi', () {
    testWidgets('judul dan mata kuliah kosong atau hanya spasi ditolak',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TugasApp());
      await _settle(tester);

      await tester.tap(find.byKey(const Key('add-task-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('task-title-field')), '   ');
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      expect(find.text('Judul tugas wajib diisi.'), findsOneWidget);
      expect(find.text('Mata kuliah wajib diisi.'), findsOneWidget);
      expect(find.text('Tambah Tugas'), findsOneWidget); // tetap di form
    });

    testWidgets('Batal kembali tanpa mengubah daftar',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TugasApp());
      await _settle(tester);

      await tester.tap(find.byKey(const Key('add-task-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada tugas'), findsOneWidget);
    });

    testWidgets('kartu dapat dibuka ke halaman detail',
        (WidgetTester tester) async {
      _seed(const <Task>[Task(id: '1', title: 'Laporan', course: 'PPB')]);
      await tester.pumpWidget(const TugasApp());
      await _settle(tester);

      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Tugas'), findsOneWidget);
    });
  });

  group('State, interaksi, dan persistensi', () {
    testWidgets('tambah, tandai selesai, lalu bertahan setelah aplikasi dibuka ulang',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TugasApp());
      await _settle(tester);

      await _addTask(tester, '  Laporan Modul 5  ', 'PPB');
      expect(find.text('Laporan Modul 5'), findsOneWidget); // spasi tepi dipangkas
      expect(find.text('1 tugas · 1 belum selesai · 0 selesai'), findsOneWidget);

      await tester.tap(find.byTooltip('Tandai selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('1 tugas · 0 belum selesai · 1 selesai'), findsOneWidget);

      // Simulasi menutup aplikasi lalu membukanya lagi.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const TugasApp());
      await _settle(tester);

      expect(find.text('Laporan Modul 5'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('1 tugas · 0 belum selesai · 1 selesai'), findsOneWidget);
    });

    testWidgets('data tersimpan rusak menampilkan pesan error dan tombol Coba lagi',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{TaskStorage.storageKey: '{bukan json'},
      );
      await tester.pumpWidget(const TugasApp());
      await _settle(tester);

      expect(find.byKey(const Key('retry-load-button')), findsOneWidget);
      expect(find.textContaining('rusak'), findsOneWidget);
    });
  });

  group('Layout responsif', () {
    final List<Task> tasks = List<Task>.generate(
      4,
      (int i) => Task(
        id: '$i',
        title: 'Judul tugas yang sangat panjang sekali nomor $i untuk menguji '
            'apakah teks terpotong dengan rapi tanpa overflow',
        course: 'Nama mata kuliah yang juga sangat panjang sekali nomor $i',
      ),
    );

    testWidgets('telepon 360 px: satu kolom dan tanpa overflow',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      _seed(tasks);

      await tester.pumpWidget(const TugasApp());
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('add-task-button')), findsOneWidget);
      final Offset first = tester.getTopLeft(find.byType(TaskCard).at(0));
      final Offset second = tester.getTopLeft(find.byType(TaskCard).at(1));
      expect(second.dx, first.dx); // tersusun vertikal
      expect(second.dy, greaterThan(first.dy));
    });

    testWidgets('tablet 700 px: dua kolom dan tanpa overflow',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(700, 900);
      addTearDown(tester.view.reset);
      _seed(tasks);

      await tester.pumpWidget(const TugasApp());
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('add-task-button')), findsOneWidget);
      final Offset first = tester.getTopLeft(find.byType(TaskCard).at(0));
      final Offset second = tester.getTopLeft(find.byType(TaskCard).at(1));
      expect(second.dy, first.dy); // satu baris
      expect(second.dx, greaterThan(first.dx)); // dua kolom
    });
  });
}
