# Revisi SekolahKu — Role Wali Kelas, Daftar Koperasi & Wali Kelas

> Dikerjakan 20 Nov 2026 di salinan `sekolahku/` (repo asli milik teman, belum di-push ke sana).
> Flowchart: `flowchart-wali-kelas.mmd` (+ `flowchart-wali-kelas.png`). Uji rules: `sekolahku-rules-test.mjs`.
> **Cek dulu aturan pemakaian AI dari dosen Pemrograman Mobile.** Sebelum presentasi, pastikan kelompok paham alur di bagian 2 dan rules di bagian 4, karena dosen biasanya bertanya "kenapa begini".

---

## 1. Ringkasan permintaan dan statusnya

| # | Permintaan | Status |
|---|---|---|
| 1a | Guru menginput nilai, lalu wali kelas mengonfirmasi atau menolak (dengan alasan); guru dapat notifikasi; yang dihitung hanya nilai Terkonfirmasi | Selesai |
| 1b | Wali kelas CRUD jadwal kelas binaan | Selesai |
| 1c | Wali kelas mencatat absensi harian + rekap | Selesai |
| 1d | Ortu bisa melihat nilai terkonfirmasi, jadwal, dan absensi anak (siswa juga bisa melihat miliknya) | Selesai |
| 2 | Daftar: tambah pilihan Koperasi & Wali Kelas, tetap `active=false`; admin bisa mengaktifkan & mengatur kelas binaan; Koperasi memakai `KoperasiShell` yang sudah ada | Selesai |
| 3 | Data di Firestore (`students`, `nilai`, `jadwal`, `absensi`) + rules | Selesai, diuji di emulator (71/71) |
| 4 | Gaya kode, tema, widget bersama, setState/StreamBuilder, tanpa paket baru | Dipertahankan (pubspec tidak berubah) |
| 5 | Tombol Keluar memanggil signOut | Selesai (semua shell) |
| 6 | Test unit + widget | 26 test lulus (sebelumnya 9) |

## 2. Alur fitur baru

### a. Nilai: guru input, wali kelas konfirmasi, ortu melihat
1. **Guru** (Beranda/Layanan, menu **Input Nilai**) memilih siswa (filter per kelas), mengisi mapel, jenis (Tugas/UH/UTS/UAS), nilai 0–100, semester (otomatis), dan catatan opsional.
2. Dokumen baru di koleksi `nilai` dengan status **"Menunggu konfirmasi"**. Notifikasi dikirim ke role Wali Kelas.
3. **Wali kelas** (tab **Nilai**) melihat nilai siswa kelas binaannya, dipisah menjadi Menunggu / Terkonfirmasi / Ditolak.
   - **Konfirmasi**: status menjadi `Terkonfirmasi`, guru dapat notifikasi.
   - **Tolak**: alasan wajib diisi, status menjadi `Ditolak`, guru dapat notifikasi beserta alasannya.
4. Guru memantau status di bagian "Nilai yang saya input". Nilai yang belum terkonfirmasi bisa dibatalkan atau dihapus lalu diinput ulang.
5. **Perkembangan Siswa** (ortu, siswa, guru, wali kelas) hanya menghitung nilai `Terkonfirmasi` (rata-rata, tren, per mapel, riwayat).

### b. Jadwal kelas
Wali kelas (tab **Jadwal**): tombol + untuk menambah (hari Senin–Sabtu, jam mulai–selesai lewat time picker 24 jam, mapel, guru, ruang). Ketuk jadwal untuk mengubah atau menghapus. Validasi: format jam HH:MM, jam selesai harus setelah jam mulai, mapel wajib diisi. Ortu dan siswa melihat jadwal per hari (read-only).

### c. Absensi
Wali kelas (tab **Absensi**):
- **Input harian**: pilih tanggal (default hari ini). Setiap siswa ditandai Hadir/Sakit/Izin/Alpa (default Hadir) dan bisa diberi keterangan. Tombol "Simpan absensi" menyimpan satu dokumen per siswa per hari (id `NIS_yyyy-MM-dd`), jadi kalau diisi ulang datanya ditimpa, bukan dobel.
- **Rekap**: rekap kelas + per siswa (H/S/I/A dan % hadir), bisa difilter Bulan ini / Semua.
Ortu dan siswa melihat rekap serta riwayat absensinya (read-only).

### d. Portal ortu
Di Beranda ortu: kartu anak (rata-rata & tren dari nilai terkonfirmasi), kartu **Jadwal Kelas** dan **Absensi Anak**, serta tab Nilai (Perkembangan Siswa). Data anak dicari lewat `parent_links` (parentUid = ortu) lalu `students/{nis}`.

### e. Daftar & aktivasi
- Form Daftar sekarang punya pilihan: Siswa, Orang Tua / Wali, Guru, **Wali Kelas**, **Koperasi**.
  - Siswa: Nama, NIS, **Kelas**, Email, Password.
  - Wali Kelas: Nama, NIP, **Kelas yang diwalikan**, Email, Password.
  - Koperasi: Nama, Email, Password (tanpa nomor induk).
- Semua akun tetap `active: false`. Admin (tab Pengguna) memakai filter baru "Wali Kelas", lalu:
  - menyalakan switch aktif. Untuk siswa yang punya NIS, data master `students/{nis}` ikut dibuat otomatis;
  - menekan **Atur** untuk mengubah data akademik: NIS & kelas (siswa), kelas yang diwalikan (wali kelas), NIS anak (ortu, sekaligus menulis `parent_links`).
- Role `koperasi` diarahkan RoleGate ke `KoperasiShell` yang sudah ada; `waliKelas` diarahkan ke `WaliKelasShell` yang baru.

## 3. Daftar perubahan per file

| File | Perubahan |
|---|---|
| `lib/models/role.dart` | `Role.waliKelas` (label "Wali Kelas"), `roleFromName()`, `registrableRoles` (tanpa admin) |
| `lib/models/user.dart` | Field opsional `nis`, `kelas`, `waliKelas`, `nisAnak` |
| `lib/models/session.dart` | `Session.waliKelas`, `Session.clear()` (dipakai saat Keluar) |
| `lib/models/akademik.dart` | Model baru `NilaiEntry`, `JadwalItem`, `AbsensiRecord`, konstanta status/jenis/hari, logika murni yang bisa dites: `validateNilai`, `waliBolehKonfirmasi`, `nilaiTerkonfirmasi`, `NilaiStats` (rata-rata/per mapel/tren), `validateJadwal`, `urutkanJadwal`, `rekapAbsensi`, `persenHadir`, `normKelas`, `semesterOf`, `tglKey` |
| `lib/services/firebase_service.dart` | `ready`; `register()` menyimpan nis/kelas/waliKelas/nisAnak/nip; `login()` & `_userFromDoc()` membaca field baru; `logout()` aman tanpa Firebase; `setUserActive(user:)` menyinkronkan `students`; `setUserAkademik()`; bagian **AKADEMIK v2** (students, nilai, jadwal, absensi: stream + tulis). Fungsi lama `grades` diberi label legacy |
| `lib/services/akademik_service.dart` (baru) | Penghubung: Firebase aktif membaca Firestore, tanpa Firebase (test) memakai data demo `RelationsService` |
| `lib/services/relations_service.dart` | Statistik memakai `NilaiStats`; kasus `Role.waliKelas` (demo) |
| `lib/services/auth_service.dart` | Label "Wali Kelas"/"Koperasi" dipetakan ke enum; parameter `kelas` |
| `lib/views/wali_kelas/wali_kelas_shell.dart` (baru) | `WaliKelasShell`: Beranda, Nilai (konfirmasi/tolak), Jadwal (CRUD + `JadwalForm`), Absensi (input harian + rekap), Profil (Keluar) |
| `lib/views/akademik/akademik_views.dart` (baru) | `InputNilaiScreen` (guru), `JadwalKelasScreen` & `AbsensiSiswaScreen` (read-only ortu/siswa), widget bersama `NilaiTile`, `JadwalList`, `RekapAbsensiCard`, `SiswaSayaBuilder` |
| `lib/views/akademik/perkembangan_screen.dart` | Membaca Firestore (nilai Terkonfirmasi) saat online; wali kelas/admin juga bisa memilih siswa; perbaikan kecil: filter mapel di-reset saat ganti siswa (sebelumnya bisa membuat Dropdown error) |
| `lib/views/home/role_gate.dart` | `Role.waliKelas => WaliKelasShell()` |
| `lib/views/home/ortu_shell.dart` | Kartu anak dari Firestore + kartu Jadwal Kelas & Absensi Anak; profil memakai data anak asli; Keluar = signOut |
| `lib/views/home/shell.dart` | Guru: menu/pintasan Input Nilai. Siswa: Jadwal kelas & Absensi saya. Profil siswa memakai kelas/NIS asli bila ada. Keluar = signOut |
| `lib/views/admin/admin_shell.dart` | Filter "Wali Kelas", emoji role, tombol **Atur** data akademik, aktivasi menyinkronkan `students`. Keluar = signOut |
| `lib/views/koperasi/koperasi_views.dart` | Keluar = signOut |
| `lib/views/auth/auth_screen.dart` | Pilihan Wali Kelas & Koperasi, field Kelas (siswa) / Kelas yang diwalikan (wali), Koperasi tanpa NIS/NIP |
| `lib/widgets/widgets.dart` | `keluarAkun()` (signOut + bersihkan Session + ke /auth); warna `Pill.status` untuk Terkonfirmasi/Hadir/Alpa |
| `firestore.rules` | Helper akademik + aturan `students`, `nilai`, `jadwal`, `absensi`; daftar boleh role koperasi/waliKelas (tetap nonaktif), saldo awal 0, tidak boleh set `ketuaOf` sendiri |
| `test/relations_and_role_test.dart` | +13 unit test (role, alur nilai, rules relasi, jadwal, absensi) |
| `test/widgets_view_test.dart` | Form daftar menampilkan Koperasi & Wali Kelas; field per role; RoleGate wali kelas; WaliKelasShell; InputNilaiScreen; portal ortu menampilkan Jadwal & Absensi |
| `SUMBER.md` | Catatan revisi |

## 4. Struktur koleksi Firestore & ringkasan rules

| Koleksi | Id dokumen | Field utama |
|---|---|---|
| `users/{uid}` (tambahan) | uid | `nis`, `kelas` (siswa) · `waliKelas`, `nip` (wali kelas) · `nisAnak` (ortu) · `nip` (guru) |
| `students/{nis}` | NIS | `nis`, `name`, `kelas`, `uid` (ditulis admin/otomatis saat aktivasi) |
| `parent_links/{nis}` | NIS anak | `parentUid`, `parentName`, `studentId` (sudah ada sebelumnya) |
| `nilai/{auto}` | otomatis | `nis`, `studentName`, `kelas`, `mapel`, `jenis`, `semester`, `nilai` (number), `catatan`, `guruUid`, `guruName`, `status`, `alasanTolak`, `confirmedBy`, `createdAt`, `confirmedAt` |
| `jadwal/{auto}` | otomatis | `kelas`, `hari`, `jamMulai`, `jamSelesai` ("HH:MM"), `mapel`, `guru`, `ruang`, `updatedBy`, `updatedAt` |
| `absensi/{nis}_{yyyy-MM-dd}` | deterministik | `nis`, `studentName`, `kelas`, `tanggal`, `status`, `keterangan`, `dicatatOleh`, `updatedAt` |

Kelas selalu dinormalisasi (`normKelas`: huruf besar, spasi rapi), jadi "xi ipa 3" dan "XI IPA 3" dianggap sama. Semua query hanya memakai filter `==` tanpa `orderBy`, sehingga **tidak perlu membuat composite index**.

**Rules (ringkas):**
- **users**: daftar sendiri hanya untuk role siswa/guru/ortu/koperasi/waliKelas dengan `active == false`, saldo 0, dan tanpa `ketuaOf`. Pemilik hanya boleh mengubah `name`/`info`, jadi role, kelas, kelas binaan, dan NIS tidak bisa diubah sendiri. Admin bebas.
- **students**: dibaca guru/wali kelas/admin, siswa itu sendiri, dan ortunya. Ditulis hanya admin.
- **nilai**:
  - *create*: hanya guru aktif atas nama sendiri (`guruUid == uid`), status wajib "Menunggu konfirmasi", nilai berupa number 0–100, field dibatasi, dan `kelas` harus sama dengan `students/{nis}.kelas`.
  - *update*: hanya wali kelas dari kelas tersebut dan hanya selama statusnya menunggu (admin boleh kapan saja). Field yang boleh berubah hanya `status`/`alasanTolak`/`confirmedBy`/`confirmedAt`, dan status hanya boleh menjadi Terkonfirmasi/Ditolak. Angka nilai tidak bisa diubah wali kelas.
  - *read*: admin; guru (nilai miliknya + semua yang Terkonfirmasi); wali kelas (semua nilai di kelasnya + Terkonfirmasi); siswa/ortu hanya yang Terkonfirmasi milik diri/anak.
  - *delete*: admin, atau guru pemilik selama belum Terkonfirmasi.
- **jadwal**: ditulis wali kelas kelas tersebut/admin (hari Senin–Sabtu, tidak bisa dipindah ke kelas lain). Dibaca staf, siswa kelas itu, dan ortu yang anaknya di kelas itu.
- **absensi**: ditulis wali kelas kelas tersebut/admin. Id harus `nis_tanggal`, status salah satu dari 4, dan kelas harus cocok dengan `students/{nis}`. Dibaca admin, wali kelasnya, siswa itu, dan ortunya.

**Hasil uji rules (Firestore Emulator v1.19.8, `@firebase/rules-unit-testing`): 71 lulus, 0 gagal.** Termasuk kasus: daftar sebagai admin ditolak, siswa menaikkan role ditolak, guru langsung set "Terkonfirmasi" ditolak, nilai 120 ditolak, kelas palsu ditolak, wali kelas lain mengonfirmasi ditolak, ortu membaca nilai/jadwal/absensi anak orang lain ditolak, dan query yang dipakai aplikasi diizinkan.

## 5. Verifikasi

| Cek | Hasil |
|---|---|
| `flutter pub get` (Flutter 3.50.1 stable, Dart 3.14.0) | OK, tanpa paket baru |
| `flutter analyze` | 0 error, 0 warning. 28 info semuanya "package:flutter/material.dart is deprecated" (sudah ada 26 di kode asli karena SDK terbaru; +2 dari 2 file view baru yang mengikuti gaya yang sama) |
| `flutter test` | **26/26 lulus** (asli 9) |
| Rules emulator | 71/71 lulus |
| Render Mermaid (mermaid-cli v10) | Valid, 29 node |

Belum diuji: menjalankan aplikasi di HP/Chrome terhubung ke project Firebase asli (tidak ada akses ke project kelompok). Lakukan langkah demo di bawah setelah rules di-deploy.

## 6. Cara uji / demo (akun per role)

Persiapan sekali:
1. Deploy rules: `firebase deploy --only firestore:rules` (atau salin isi `firestore.rules` ke Firebase Console → Firestore → Rules → Publish).
2. Akun **admin** sudah ada dan aktif (lewat Console seperti sebelumnya).

Akun demo yang disarankan (daftar lewat aplikasi, lalu aktifkan dari admin):

| Akun | Role saat daftar | Isian penting | Tindakan admin |
|---|---|---|---|
| siswa1@demo.id | Siswa | NIS `2024-0153`, Kelas `XI IPA 3` | Aktifkan (otomatis membuat `students/2024-0153`) |
| siswa2@demo.id | Siswa | NIS `2024-0111`, Kelas `XI IPA 3` | Aktifkan |
| guru1@demo.id | Guru | NIP opsional | Aktifkan |
| wali1@demo.id | Wali Kelas | Kelas yang diwalikan `XI IPA 3` | Aktifkan (cek/ubah lewat **Atur**) |
| ortu1@demo.id | Ortu | NIS anak `2024-0153` | Aktifkan |
| kop1@demo.id | Koperasi | – | Aktifkan, lalu login masuk ke Dashboard koperasi |

Skenario demo (±3 menit):
1. **guru1** → Input Nilai → pilih Alex (XI IPA 3), Matematika, UH, 88 → Kirim. Status "Menunggu konfirmasi".
2. **ortu1** → tab Nilai: nilai 88 **belum** muncul (karena belum dikonfirmasi).
3. **wali1** → Beranda menampilkan "1 nilai menunggu" → tab Nilai → **Konfirmasi**. Coba juga input nilai kedua dari guru lalu **Tolak** dengan alasan; guru melihat alasan di notifikasi dan di daftarnya.
4. **ortu1** → nilai 88 sekarang muncul dan dihitung di rata-rata.
5. **wali1** → Jadwal → + Senin 07:00–08:30 Matematika, guru, ruang → **ortu1/siswa1** melihat di Jadwal Kelas.
6. **wali1** → Absensi → tandai Alex "Sakit" + keterangan → Simpan → Rekap. **ortu1** → Absensi Anak menampilkan rekapnya.
7. Tekan **Keluar** di akun mana pun, lalu tekan tombol back: tidak bisa kembali ke dalam karena sesi Auth sudah di-signOut.

## 7. Perlu dikonfirmasi ke kelompok

1. **Wali kelas sebagai akun terpisah dari guru.** Sesuai permintaan, Wali Kelas adalah role sendiri. Di dunia nyata wali kelas biasanya juga guru mapel; dengan desain ini ia butuh 2 akun bila juga harus menginput nilai. Alternatif (belum dibuat): izinkan `waliKelas` juga menginput nilai.
2. **Notifikasi "nilai menunggu" dikirim ke semua akun Wali Kelas** (role-based, karena guru tidak boleh membaca data user lain). Isi notifikasi menyebut kelasnya. Kalau mau tepat sasaran, perlu koleksi `kelas/{kelas}` berisi uid wali.
3. **Guru bisa melihat semua siswa** (koleksi `students`) untuk menginput nilai. Kalau ingin dibatasi per mapel/kelas yang diampu, perlu data penugasan guru (belum ada).
4. **Satu anak = satu akun ortu** (karena `parent_links/{nis}` hanya satu dokumen per NIS, warisan desain lama). Ortu juga bisa "mengklaim" NIS saat daftar, jadi admin wajib mengecek sebelum ACC.
5. **Nama kelas harus konsisten** (mis. "XI IPA 3"). Sudah dinormalisasi huruf besar/spasi, tetapi "XI-IPA-3" tetap dianggap beda kelas.
6. **Wali kelas perlu login ulang** setelah admin mengubah kelas binaannya (data sesi dibaca saat login).
7. Jalankan **langkah demo** di project Firebase asli setelah deploy rules. Rules sudah lulus emulator, tetapi belum dicoba di project kelompok.

## 8. Kekurangan lama yang belum disentuh (di luar permintaan)

- `adjustSaldo()` tetap bentrok dengan rules (pemilik hanya boleh mengubah `name`/`info`). Perbaikan yang benar butuh logika server (Cloud Functions) atau saldo hanya diubah admin/koperasi, jadi perlu keputusan kelompok.
- `AuthService.register()` mengirim notifikasi ke admin **setelah** sesi di-signOut, sehingga ditolak rules (notifikasi pendaftaran tidak sampai). Bawaan kode lama.
- Tab Aktivitas, statistik Profil, sebagian dashboard admin, dan Status Terbaca masih memakai `DataStore` demo.
- `bootstrapAdmin()` masih berisi email/password admin hardcode, sebaiknya dihapus sebelum repo publik diperbarui.
