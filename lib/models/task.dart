/// Data satu tugas praktikum.
///
/// Lengkapi serialisasi JSON pada TODO 1 agar model dapat disimpan dan dibaca
/// kembali menggunakan SharedPreferences.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.course,
    this.isDone = false,
  });

  final String id;
  final String title;
  final String course;
  final bool isDone;

  Task copyWith({bool? isDone}) => Task(
        id: id,
        title: title,
        course: course,
        isDone: isDone ?? this.isDone,
      );

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'course': course,
      'isDone': isDone,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Nilai aman dipakai bila data lama tidak memiliki sebuah key.
    return Task(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      course: json['course'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}
