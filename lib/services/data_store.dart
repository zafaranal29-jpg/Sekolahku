import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/aduan.dart';
import 'package:sekolahku/models/agenda.dart';
import 'package:sekolahku/models/booking.dart';
import 'package:sekolahku/models/complaint.dart';
import 'package:sekolahku/models/lost_found.dart';
import 'package:sekolahku/models/mading.dart';
import 'package:sekolahku/models/notif.dart';
import 'package:sekolahku/models/order.dart';
import 'package:sekolahku/models/report.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/user.dart';

/// In-memory state bersama (simulasi backend database).
class DataStore {
  static final DataStore i = DataStore._();
  DataStore._();

  int saldo = 48500;
  int complaintSeq = 88;
  int aduanSeq = 13;
  int orderSeq = 234;
  int lfSeq = 6;
  int claimSeq = 44;

  final List<AppNotif> notifs = <AppNotif>[
    AppNotif('🍱', 'Pesananmu sedang disiapkan', 'Pesanan #KP-0231 · 5 menit lalu', kYellowBg,
        toName: 'Alex Johnson'),
    AppNotif('🛠️', 'Status pengaduan berubah', 'AC kelas XI-3 → Diproses', kRedBg,
        toName: 'Alex Johnson', time: '1 jam lalu'),
    AppNotif('📌', 'Pengumuman baru', 'Jadwal UAS Semester Ganjil', kSoft,
        toRoles: {Role.siswa, Role.guru, Role.ortu}, time: '2 jam lalu', readBy: {'Alex Johnson'}),
    AppNotif('🏟️', 'Booking disetujui', 'Aula Utama · 30 Okt 10:00', kBlueBg,
        toName: 'Alex Johnson', time: 'Kemarin', readBy: {'Alex Johnson'}),
  ];

  final List<Mading> madingData = <Mading>[
    Mading(
      emoji: '📌',
      cat: 'Akademik',
      title: 'Jadwal UAS Semester Ganjil',
      target: 'Kelas XI',
      time: '2 jam lalu',
      bg: kRedBg,
      by: 'Bu Rina Wulandari',
      owner: 'Bu Rina Wulandari',
      pinned: true,
      push: true,
      body:
          'UAS dilaksanakan 7–18 Desember 2026. Siswa wajib hadir 15 menit sebelum ujian dimulai dan membawa kartu ujian.',
    ),
    Mading(
      emoji: '🏆',
      cat: 'Prestasi',
      title: 'Tim Basket Juara 1 Antarsekolah',
      target: 'Semua',
      time: 'Kemarin',
      bg: kYellowBg,
      kind: 'Mading',
      by: 'Alex Johnson',
      owner: 'Alex Johnson',
      body: 'Selamat kepada tim basket putra yang meraih juara 1 turnamen antarsekolah.',
    ),
    Mading(
      emoji: '🎭',
      cat: 'Kegiatan',
      title: 'Pendaftaran Pentas Seni 2026',
      target: 'Ekskul Teater',
      time: '2 hari lalu',
      bg: kGreenBg,
      by: 'Bella Anindya · Ketua Teater',
      owner: 'Bella Anindya',
      body: 'Pendaftaran pentas seni dibuka sampai 15 November di ruang OSIS.',
    ),
    Mading(
      emoji: '📢',
      cat: 'Info',
      title: 'Perubahan Jam Masuk Hari Jumat',
      target: 'Semua',
      time: '3 hari lalu',
      bg: kBlueBg,
      body: 'Mulai pekan depan jam masuk hari Jumat menjadi 06.45.',
    ),
    Mading(
      emoji: '🎨',
      cat: 'Karya',
      title: 'Pameran Karya Seni Rupa Kelas X',
      target: 'Semua',
      time: '1 jam lalu',
      bg: kSoft,
      kind: 'Mading',
      by: 'Bella Anindya',
      owner: 'Bella Anindya',
      status: 'Menunggu',
      body: 'Karya lukis dan patung siswa kelas X dipamerkan di lorong gedung A minggu ini.',
    ),
  ];

  late final List<AgendaEvent> agendas = <AgendaEvent>[
    AgendaEvent(_day(3), 'Rapat guru', 'Evaluasi pembelajaran semester ganjil · Ruang guru 13:00', '📝'),
    AgendaEvent(_day(5), 'Turnamen basket antarkelas', 'Lapangan basket · 08:00', '🏆'),
    AgendaEvent(_day(9), 'Mulai UAS Semester Ganjil', 'Hadir 15 menit sebelum ujian dimulai', '📅'),
    AgendaEvent(_day(14), 'Pentas Seni 2026', 'Aula Utama · 09:00', '🎭'),
    AgendaEvent(_day(20), 'Libur nasional', 'Tidak ada kegiatan belajar mengajar', '🏖️'),
  ];

  static DateTime _day(int plus) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).add(Duration(days: plus));
  }

  List<AgendaEvent> upcomingAgenda() {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return agendas.where((e) => !e.date.isBefore(today)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  final List<BookingReq> bookingRequests = <BookingReq>[
    BookingReq('🔬', 'Lab Kimia', 'Sen 9 Nov · 08:00–10:00', 'Bu Maya (Guru)', 'Menunggu', 'Bu Maya'),
    BookingReq('🎭', 'Aula Utama', 'Rab 11 Nov · 09:00–12:00', 'Dimas Pratama (Siswa)', 'Menunggu', 'Dimas Pratama'),
    BookingReq('🏀', 'Lapangan Basket', '6 Nov · 13:00', 'Alex Johnson (Siswa)', 'Menunggu', 'Alex Johnson'),
    BookingReq('🎭', 'Aula Utama', '30 Okt · 10:00', 'Alex Johnson (Siswa)', 'Disetujui', 'Alex Johnson'),
    BookingReq('💻', 'Lab Komputer', '15 Okt · 13:00', 'Alex Johnson (Siswa)', 'Ditolak', 'Alex Johnson'),
  ];

  final List<Complaint> complaints = <Complaint>[
    Complaint('PF-0087', 'AC kelas XI-3 rusak', 'Gedung B', 'Alex Johnson', 'Diproses',
        'Pak Joko (Sarpras)', 'Teknisi datang Senin pagi.', 'Alex Johnson'),
    Complaint('PF-0086', 'Keran toilet bocor', 'Toilet lt. 2', 'Bella Anindya', 'Baru',
        'Belum ditentukan', '', 'Bella Anindya'),
  ];

  final List<Aduan> aduans = <Aduan>[
    Aduan(
        'AD-0012',
        'Perundungan',
        'Waktu/lokasi: istirahat, belakang kantin\nSeorang teman sekelas sering diejek dan dikucilkan.',
        'Dimas Pratama',
        true,
        'Baru',
        ''),
    Aduan(
        'AD-0011',
        'Aspirasi / saran',
        'Mohon antrean kantin ditambah kasirnya di jam istirahat.',
        'Alex Johnson',
        false,
        'Selesai',
        'Terima kasih, kasir tambahan mulai minggu depan.'),
  ];

  final List<Order> orders = <Order>[
    Order('KP-0231', 'Alex Johnson', '1 Roti Isi Keju', 'Istirahat 1', 6000, 'Disiapkan', 'Alex Johnson'),
    Order('KP-0232', 'Bella Anindya', '1 Nasi Kepal', 'Istirahat 1', 7000, 'Baru', 'Bella Anindya'),
    Order('KP-0233', 'Dimas Pratama', '3 Air mineral', 'Istirahat 2', 9000, 'Baru', 'Dimas Pratama'),
  ];

  final List<LfItem> lfItems = <LfItem>[
    LfItem('LB-001', '🧴', 'Botol minum biru', 'Kantin · Hari ini', 'Ditemukan',
        'Ada stiker bintang di tutup', 'Siswa XI IPA 1', 'Bella Anindya', kBlueBg, 'Diklaim'),
    LfItem('LB-002', '🎒', 'Tas ransel hitam', 'Lab · Kemarin', 'Ditemukan',
        'Gantungan kunci kucing, ada buku bersampul hijau', 'Siswa XI IPS 1', 'Dimas Pratama', kRedBg, 'Aktif'),
    LfItem('LB-003', '🎧', 'Earphone putih', 'Aula · 2 hari', 'Ditemukan',
        'Casing retak di sisi kiri', 'Guru', 'Bu Maya', kSoft, 'Aktif'),
    LfItem('LB-004', '📘', 'Buku catatan Fisika', 'R. 12 · 3 hari', 'Ditemukan',
        'Nama di halaman pertama', 'Siswa XI IPA 3', 'Alex Johnson', kYellowBg, 'Aktif'),
    LfItem('LB-005', '👓', 'Kacamata bulat', 'Terakhir: Perpustakaan', 'Hilang',
        'Bingkai hitam, lensa minus', 'Siswa XI IPA 2', 'Dimas Pratama', kYellowBg, 'Aktif'),
    LfItem('LB-006', '📦', 'Kotak pensil merah', 'Kelas X-2 · Hari ini', 'Ditemukan',
        'Ada 3 pulpen biru', 'Siswa X-2', 'Bella Anindya', kSoft, 'Menunggu validasi'),
  ];

  late final List<LfClaim> lfClaims = <LfClaim>[
    LfClaim('LF-0042', lfItems[0], 'Alex Johnson', 'Ada stiker bintang di tutupnya.', 'Disetujui'),
    LfClaim('LF-0043', lfItems[1], 'Dimas Pratama', 'Gantungan kunci kucing dan buku hijau.', 'Menunggu'),
  ];

  final List<AppUser> users = <AppUser>[
    AppUser('Alex Johnson', 'Siswa · XI IPA 3 (NIS: 2024-0153)', Role.siswa, true, ketuaOf: 'Basket'),
    AppUser('Bella Anindya', 'Siswa · XI IPA 2 (NIS: 2024-0120)', Role.siswa, true, ketuaOf: 'Teater'),
    AppUser('Dimas Pratama', 'Siswa · XI IPA 2 (NIS: 2024-0144)', Role.siswa, false),
    AppUser('Bu Rina Wulandari', 'Guru · Wali kelas XI IPA 3 & Guru Matematika', Role.guru, true),
    AppUser('Bu Maya', 'Guru · Kimia', Role.guru, true),
    AppUser('Pak Budi', 'Admin Koperasi', Role.koperasi, true),
    AppUser('Pak Hendra Johnson', 'Orang Tua / Wali dari Alex Johnson (2024-0153)', Role.ortu, true),
  ];

  final List<Report> reports = <Report>[
    Report('🎒', 'Posting Lost & Found', 'Oleh siswa XI IPS 1', 'Foto tidak sesuai dengan barang...', 2),
    Report('📌', 'Kiriman mading', 'Kategori Kegiatan', 'Isi mengandung kata kasar...', 1),
  ];
}