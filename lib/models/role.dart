enum Role { siswa, guru, admin, koperasi, ortu }

String roleLabel(Role r) => switch (r) {
      Role.siswa => 'Siswa',
      Role.guru => 'Guru',
      Role.admin => 'Admin',
      Role.koperasi => 'Admin Koperasi',
      Role.ortu => 'Orang Tua / Wali',
    };

const ekskulList = ['Basket', 'Teater', 'Pramuka', 'PMR', 'Paduan Suara', 'Robotik'];

const bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

String fmtDate(DateTime d) => '${d.day} ${bulan[d.month - 1].substring(0, 3)} ${d.year}';