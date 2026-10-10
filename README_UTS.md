# UTS Praktikum Pemrograman Perangkat Bergerak 2026/2027

**Nama:** Hendra Yudha Pratama
**NIM:** 362558302101
**Aplikasi:** Pencatat Tugas Praktikum (Flutter)
**Berkas ZIP:** `UTS_362558302101_Hendra_Yudha_Pratama.zip`

---

## 1. Cara menjalankan aplikasi

```sh
flutter pub get      # mengunduh dependency
flutter run          # pilih emulator/perangkat Android
flutter analyze      # pemeriksaan kualitas kode
flutter test         # menjalankan seluruh tes otomatis (jika ada)
```

Tidak ada package baru yang ditambahkan. `shared_preferences` sudah tersedia
pada starter app, dan seluruh implementasi hanya memakai materi Modul 05.

### Langkah uji manual

1. Jalankan aplikasi pada emulator ukuran telepon (lebar 360 px), lalu pastikan
   tidak ada overflow dan semua tombol terbaca.
2. Jalankan pada emulator tablet (lebar ≥ 700 px), lalu pastikan kartu tampil
   dua kolom.
3. Tekan **Tambah tugas**, kosongkan judul/mata kuliah (atau isi spasi saja),
   lalu tekan Simpan. Pesan validasi harus muncul.
4. Isi data yang valid lalu Simpan. Tugas baru harus langsung muncul di daftar
   dan jumlah pada ringkasan bertambah.
5. Tandai tugas selesai/belum selesai. Kartu dan ringkasan harus langsung berubah.
6. Buka detail tugas, lalu tekan Batal. Daftar tidak boleh berubah.
7. Gunakan kontrol simulasi pada starter untuk memicu kondisi loading, empty,
   dan error. Pada kondisi error, tekan **Coba Lagi**.
8. Tutup aplikasi sepenuhnya lalu buka kembali. Daftar dan status setiap tugas
   harus masih ada.

---

## 2. Jawaban teori

**Soal 1 – Daftar tugas dan UI responsif (KAD-1).**
Halaman daftar menampilkan judul tugas, mata kuliah, status selesai/belum
selesai, dan ringkasan jumlah tugas. Bila belum ada data, ditampilkan empty
state. Untuk responsivitas saya memakai `LayoutBuilder` yang membaca lebar
yang tersedia: di bawah 700 px kartu disusun satu kolom, dan pada 700 px atau
lebih disusun dua kolom dengan `GridView`. Teks yang panjang dibatasi dengan
`maxLines` dan `TextOverflow.ellipsis` supaya tidak menyebabkan overflow pada
layar 360 px. Angka ringkasan dihitung dari daftar yang sama dengan yang
ditampilkan, jadi keduanya selalu konsisten.

**Soal 2 – Form, validasi, dan navigasi (KAD-2).**
Form dibungkus `Form` dengan `GlobalKey<FormState>`. Saat tombol Simpan
ditekan, `validate()` menjalankan `validator` setiap field. Nilai judul dan
mata kuliah di-`trim()` terlebih dahulu, sehingga isian yang hanya berisi spasi
tetap dianggap kosong dan ditolak dengan pesan validasi. Halaman form/detail
dibuka dengan `Navigator.push`. Tombol Simpan memanggil
`Navigator.pop(context, task)` untuk mengirim `Task` kembali ke halaman daftar,
sedangkan Batal memanggil `Navigator.pop(context)` tanpa data, sehingga daftar
tidak berubah.

**Soal 3 – State dan interaksi daftar (KAD-3).**
State daftar disimpan pada variabel `_tasks` di `State` halaman daftar dan
diubah melalui `setState`. Karena kartu dan ringkasan jumlah sama-sama dibangun
dari `_tasks`, tugas baru dan perubahan status (selesai/belum selesai) langsung
terlihat di kartu maupun ringkasan tanpa perlu memuat ulang halaman.

**Soal 4 – Operasi asynchronous dan state UI (KAD-4).**
Pemuatan daftar dilakukan oleh fungsi `Future` (`load()`). Selama proses
berjalan UI menampilkan indikator loading. Setelah selesai, UI menampilkan
salah satu dari: daftar data, atau empty state "Belum ada tugas". Jika
pembacaan gagal, `try/catch` menangkap kesalahan dan UI menampilkan pesan error
yang mudah dipahami beserta tombol **Coba Lagi** yang menjalankan ulang
pemuatan. Kondisi error diuji memakai kontrol simulasi bawaan starter. Setelah
setiap `await`, saya memeriksa `mounted` sebelum memanggil `setState` agar tidak
terjadi pembaruan pada widget yang sudah dibuang.

**Soal 5 – Penyimpanan lokal dan verifikasi (KAD-5).**
Seluruh daftar tugas diubah menjadi satu String JSON dengan `jsonEncode`
(setiap item lewat `toJson`), lalu disimpan dengan
`SharedPreferences.setString` pada key `tasks_json_v1`, termasuk status setiap
tugas. Saat aplikasi dimulai, String dibaca, di-decode dengan `jsonDecode`, dan
tiap item dikonversi lewat `Task.fromJson`. Jika belum ada data tersimpan,
hasilnya daftar kosong (empty state); jika JSON rusak, muncul `FormatException`
yang ditampilkan sebagai state error. Verifikasi dilakukan dengan menambah
tugas, mengubah status, menutup lalu membuka ulang aplikasi, serta menjalankan
aplikasi pada ukuran telepon dan tablet, lalu menjalankan `flutter analyze`.

---

## 3. Acceptance criteria

| Kriteria | Status | Keterangan |
|---|---|---|
| A. Telepon 360 px: tidak ada overflow horizontal, kontrol penting terbaca | Berhasil | Teks dipotong dengan ellipsis |
| B. Tablet ≥ 700 px: kartu dua kolom dan tetap terbaca | Berhasil | `GridView` 2 kolom |
| C. Form: judul/mata kuliah kosong ditolak; spasi tepi tidak dianggap terisi | Berhasil | Memakai `trim()`; pesan validasi tampil |
| D. Navigasi: detail menerima Task; Simpan mengembalikan data; Batal tidak mengubah daftar | Berhasil | `Navigator.push` / `pop(context, task)` / `pop(context)` |
| E. State: penambahan dan perubahan status langsung memperbarui daftar dan ringkasan | Berhasil | Satu sumber data `_tasks` + `setState` |
| F. Async: loading, empty, data, error sesuai kondisi; Coba Lagi memuat ulang | Berhasil | Diuji dengan kontrol simulasi starter |
| G. Persistensi: daftar dan status tetap ada setelah aplikasi ditutup dan dibuka kembali | Berhasil | JSON di SharedPreferences |
| H. Verifikasi: aplikasi berjalan; hasil `flutter analyze` dan langkah uji dicatat | Berhasil | `flutter analyze` tanpa isu; langkah uji ada di bagian 1 |
---

## 4. Ringkasan satu alur kode

Pengguna menekan **Tambah tugas** → `TaskListScreen._addTask` membuka
`TaskFormScreen` dengan `Navigator.push` → validasi lolos →
`Navigator.pop(context, task)` → `_tasks` diperbarui lewat `setState` →
`_persist` memanggil `TaskStorage.save` → daftar di-encode menjadi JSON dan
ditulis ke SharedPreferences → saat aplikasi dibuka lagi `initState` memanggil
`_loadTasks` → `TaskStorage.load` membaca dan men-decode JSON → state loading
berganti menjadi data (atau empty/error) dan daftar tampil kembali.

---

## 5. Bukti flutter analyze dan error tersisa

**Keluaran `flutter analyze`** (dijalankan 10/10/2026):

```text
C:\UTS_NIM_Nama>flutter analyze
Analyzing UTS_NIM_Nama...
No issues found! (ran in 3.5s)
```

**Error/warning yang tersisa:** Tidak ada.

---

## 6. Screenshot

Dua screenshot dari aplikasi yang benar-benar dijalankan:

- `screenshot/hp.png` (lebar 360 px, satu kolom)
- `screenshot/tablet.png` (lebar ≥ 700 px, dua kolom)

---

## 7. Daftar berkas pengumpulan

- [ ] `UTS_362558302101_Hendra_Yudha_Pratama.zip` berisi project Flutter lengkap
      (source code dan `pubspec.yaml`)
- [ ] `README_UTS.md` (berkas ini)
- [ ] Dua screenshot: telepon dan tablet
- [ ] Bukti keluaran `flutter analyze`
- [ ] ZIP sudah dicoba dibuka dan dikumpulkan sebelum batas waktu
