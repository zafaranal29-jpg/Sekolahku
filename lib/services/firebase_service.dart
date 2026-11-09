import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/aduan.dart';
import 'package:sekolahku/models/agenda.dart';
import 'package:sekolahku/models/akademik.dart';
import 'package:sekolahku/models/booking.dart';
import 'package:sekolahku/models/complaint.dart';
import 'package:sekolahku/models/lost_found.dart';
import 'package:sekolahku/models/mading.dart';
import 'package:sekolahku/models/notif.dart';
import 'package:sekolahku/models/order.dart';
import 'package:sekolahku/models/product.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/models/user.dart';

/// Service Firebase riil untuk autentikasi dan database Firestore.
class FirebaseService {
  static final FirebaseService i = FirebaseService._();
  FirebaseService._();

  bool get _fbReady => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get db => _db;

  // ===================== AUTENTIKASI =====================

  /// Daftar akun baru: buat akun di Firebase Auth + simpan dokumen di Firestore `users`.
  /// Akun berstatus `isActive: false` (menunggu persetujuan admin).
  Future<AppUser> register({
    required String email,
    required String password,
    required String name,
    required Role role,
    String? studentNis, // khusus Ortu (NIS anak) atau Siswa (NIS sendiri)
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    final info = switch (role) {
      Role.guru => 'Guru · Menunggu aktivasi',
      Role.ortu => 'Orang Tua / Wali · Menunggu aktivasi',
      Role.admin => 'Admin · Menunggu aktivasi',
      Role.koperasi => 'Petugas Koperasi · Menunggu aktivasi',
      _ => 'Siswa · Menunggu aktivasi',
    };

    final userDoc = {
      'uid': uid,
      'email': email.trim(),
      'name': name.trim(),
      'role': role.name,
      'info': info,
      'active': false, // semua akun baru nonaktif, menunggu ACC admin
      'saldo': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(uid).set(userDoc);

    // Jika ortu mendaftar dan menyertakan NIS anak.
    // Doc id = NIS anak (studentId) supaya Security Rules `iAmOrtuOf`
    // bisa memverifikasi relasi lewat get() deterministik.
    if (role == Role.ortu && studentNis != null && studentNis.isNotEmpty) {
      await _db.collection('parent_links').doc(studentNis.trim()).set({
        'parentUid': uid,
        'parentName': name.trim(),
        'studentId': studentNis.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Akun baru berstatus nonaktif: keluar dari sesi Auth agar tidak "seakan login".
    await _auth.signOut();

    return AppUser(name.trim(), info, role, false);
  }

  /// Login riil: periksa kredensial ke Firebase Auth + ambil role & status dari Firestore.
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('Data pengguna tidak ditemukan di database.');
    }

    final data = doc.data()!;
    final bool active = data['active'] ?? false;
    if (!active) {
      await _auth.signOut();
      throw Exception(
          'Akun Anda belum diaktifkan oleh pihak sekolah. Silakan hubungi admin TU.');
    }

    final roleStr = data['role'] as String? ?? 'siswa';
    final role = Role.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => Role.siswa,
    );
    final name = data['name'] as String? ?? 'Pengguna';
    final info = data['info'] as String? ?? roleLabel(role);

    final appUser = AppUser(name, info, role, active);

    // Set sesi saat ini
    Session.role = role;
    Session.name = name;
    Session.user = appUser;

    return appUser;
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Bootstrap (dev): buat akun ADMIN pertama bila belum ada admin aktif.
  /// Hanya jalan saat Firestore rules masih terbuka (test mode). Dengan rules
  /// produksi (terkunci), akun admin dibuat manual via Firebase Console (satu
  /// kali). Aman diulang (idempoten).
  Future<bool> bootstrapAdmin({
    String email = 'admin@sekolahku.id',
    String password = 'AdminSekolahku2026',
  }) async {
    // 1. Sudah ada admin aktif? Kalau ya, tidak usah buat lagi.
    final admins = await _db
        .collection('users')
        .where('role', isEqualTo: Role.admin.name)
        .limit(1)
        .get();
    if (admins.docs.any((d) => d.data()['active'] == true)) {
      return false;
    }

    // 2. Buat akun Auth (atau pakai yang sudah ada bila email terdaftar).
    String uid;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      uid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      uid = cred.user!.uid;
    }

    // 3. Tulis dokumen admin yang SUDAH AKTIF (role admin).
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': 'Admin Sekolah',
      'role': Role.admin.name,
      'info': 'Admin Sekolah',
      'active': true,
      'saldo': 0,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Jangan biarkan sesi admin tertinggal dari proses bootstrap.
    await _auth.signOut();
    return true;
  }

  // ============ MANAJEMEN PENGGUNA (ADMIN) ============

  /// Stream daftar pengguna riil dari Firestore (`users`), terurut nama.
  /// Tanpa `orderBy` Firestore supaya setiap dokumen selalu tampil (agar tidak
  /// ada dokumen yang diam-diam hilang saat field pengurutnya belum lengkap).
  Stream<List<AppUser>> usersStream() {
    return _db.collection('users').snapshots().map((snap) {
      final list = snap.docs.map(_userFromDoc).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  AppUser _userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final roleStr = d['role'] as String? ?? 'siswa';
    final role = Role.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => Role.siswa,
    );
    return AppUser(
      d['name'] as String? ?? 'Pengguna',
      d['info'] as String? ?? roleLabel(role),
      role,
      d['active'] == true,
      ketuaOf: d['ketuaOf'] as String?,
      uid: doc.id,
    );
  }

  /// Admin mengaktifkan / menonaktifkan akun.
  Future<void> setUserActive({required String uid, required bool active}) {
    return _db.collection('users').doc(uid).update({'active': active});
  }

  /// Admin menetapkan / mencabut peran ketua ekskul seorang siswa.
  Future<void> setUserKetua({required String uid, String? ekskul}) {
    return _db
        .collection('users')
        .doc(uid)
        .update({'ketuaOf': ekskul ?? FieldValue.delete()});
  }

  // ===================== MADING =====================

  /// Stream seluruh mading dari Firestore. Filter status/role dilakukan di UI.
  Stream<List<Mading>> madingsStream() {
    if (!_fbReady) return const Stream.empty();
    return _db.collection('madings').snapshots().map((snap) {
      final list = snap.docs.map(_madingFromDoc).toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      return list;
    });
  }

  Mading _madingFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Mading(
      id: doc.id,
      emoji: d['emoji'] as String? ?? '📌',
      cat: d['cat'] as String? ?? 'Info',
      title: d['title'] as String? ?? '',
      target: d['target'] as String? ?? 'Semua',
      body: d['body'] as String? ?? '',
      by: d['by'] as String? ?? 'Admin Sekolah',
      owner: d['owner'] as String? ?? '',
      kind: d['kind'] as String? ?? 'Pengumuman',
      status: d['status'] as String? ?? 'Disetujui',
      time: d['time'] as String? ?? 'Baru saja',
      bg: Color(d['bgColor'] as int? ?? kSoft.toARGB32()),
      pinned: d['pinned'] == true,
      push: d['push'] == true,
      reqPin: d['reqPin'] == true,
      reqPush: d['reqPush'] == true,
    );
  }

  Map<String, dynamic> _madingToMap(Mading m) => {
        'emoji': m.emoji,
        'cat': m.cat,
        'title': m.title,
        'target': m.target,
        'body': m.body,
        'by': m.by,
        'owner': m.owner,
        'kind': m.kind,
        'status': m.status,
        'time': m.time,
        'bgColor': m.bg.toARGB32(),
        'pinned': m.pinned,
        'push': m.push,
        'reqPin': m.reqPin,
        'reqPush': m.reqPush,
      };

  Future<void> addMading(Mading m) {
    return _db.collection('madings').add(
        {..._madingToMap(m), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateMading(Mading m) {
    return _db.collection('madings').doc(m.id!).set(
        {..._madingToMap(m), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteMading(Mading m) {
    return _db.collection('madings').doc(m.id!).delete();
  }

  // ===================== AGENDA =====================

  Stream<List<AgendaEvent>> agendasStream() {
    if (!_fbReady) return const Stream.empty();
    return _db.collection('agendas').snapshots().map((snap) {
      final list = snap.docs.map(_agendaFromDoc).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  AgendaEvent _agendaFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final ts = d['date'] as Timestamp?;
    return AgendaEvent(
      ts?.toDate() ?? DateTime.now(),
      d['title'] as String? ?? '',
      d['desc'] as String? ?? '',
      d['emoji'] as String? ?? '📅',
      id: doc.id,
    );
  }

  Future<void> addAgenda(AgendaEvent e) {
    return _db.collection('agendas').add({
      'date': Timestamp.fromDate(e.date),
      'title': e.title,
      'desc': e.desc,
      'emoji': e.emoji,
    });
  }

  Future<void> updateAgenda(AgendaEvent e) {
    return _db.collection('agendas').doc(e.id!).update({
      'date': Timestamp.fromDate(e.date),
      'title': e.title,
      'desc': e.desc,
      'emoji': e.emoji,
    });
  }

  Future<void> deleteAgenda(AgendaEvent e) {
    return _db.collection('agendas').doc(e.id!).delete();
  }

  // ===================== NOTIFIKASI =====================

  /// Stream seluruh notifikasi; dipilah per-user di lapisan NotifService/UI.
  Stream<List<AppNotif>> notifsStream() {
    if (!_fbReady) return const Stream.empty();
    return _db.collection('notifications').snapshots().map((snap) {
      final items = snap.docs.map((d) {
        final data = d.data();
        final ts = data['createdAt'] as Timestamp?;
        return (
          notif: _notifFromDoc(d),
          ts: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      }).toList();
      items.sort((a, b) => b.ts.compareTo(a.ts));
      return items.map((e) => e.notif).toList();
    });
  }

  AppNotif _notifFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final roles = (d['toRoles'] as List?)
        ?.map((e) => Role.values
            .firstWhere((r) => r.name == (e as String), orElse: () => Role.siswa))
        .toSet();
    return AppNotif(
      d['emoji'] as String? ?? '🔔',
      d['title'] as String? ?? '',
      d['sub'] as String? ?? '',
      Color(d['bgColor'] as int? ?? kSoft.toARGB32()),
      id: doc.id,
      toName: d['toName'] as String?,
      toRoles: roles,
      time: d['time'] as String? ?? 'Baru saja',
      readBy: (d['readBy'] as List?)?.map((e) => e as String).toSet() ?? <String>{},
    );
  }

  Future<void> addNotification({
    required String emoji,
    required String title,
    required String sub,
    Color bg = kSoft,
    String? toName,
    List<String>? toRoles,
    String time = 'Baru saja',
  }) {
    return _db.collection('notifications').add({
      'emoji': emoji,
      'title': title,
      'sub': sub,
      'bgColor': bg.toARGB32(),
      if (toName != null) 'toName': toName,
      if (toRoles != null) 'toRoles': toRoles,
      'time': time,
      'readBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tandai satu notifikasi sudah dibaca oleh pengguna sekarang.
  Future<void> markNotificationRead(String id) {
    return _db
        .collection('notifications')
        .doc(id)
        .update({'readBy': FieldValue.arrayUnion([Session.name])});
  }

  // ===================== KOPERASI: PRODUK & PESANAN =====================

  Stream<List<Product>> productsStream() {
    if (!_fbReady) return const Stream.empty();
    return _db.collection('products').snapshots().map((snap) {
      final list = snap.docs.map(_productFromDoc).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Product _productFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Product(
      d['name'] as String? ?? '',
      d['emoji'] as String? ?? '📦',
      (d['price'] as num?)?.toInt() ?? 0,
      (d['stock'] as num?)?.toInt() ?? 0,
      Color(d['bgColor'] as int? ?? kSoft.toARGB32()),
      d['cat'] as String? ?? 'Lainnya',
      id: doc.id,
    );
  }

  Future<void> updateProductStock(Product p, int stock) {
    return _db.collection('products').doc(p.id!).update({'stock': stock});
  }

  Stream<List<Order>> ordersStream() {
    if (!_fbReady) return const Stream.empty();
    return _db.collection('orders').snapshots().map((snap) {
      final list = snap.docs.map(_orderFromDoc).toList();
      list.sort((a, b) => b.id.compareTo(a.id));
      return list;
    });
  }

  Order _orderFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Order(
      d['id'] as String? ?? doc.id,
      d['customer'] as String? ?? '',
      d['items'] as String? ?? '',
      d['slot'] as String? ?? '',
      (d['total'] as num?)?.toInt() ?? 0,
      d['status'] as String? ?? 'Baru',
      d['owner'] as String? ?? '',
      fsId: doc.id,
    );
  }

  Future<void> addOrder(Order o) {
    return _db.collection('orders').add({
      'id': o.id,
      'customer': o.customer,
      'items': o.items,
      'slot': o.slot,
      'total': o.total,
      'status': o.status,
      'owner': o.owner,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrderStatus(Order o, String status) {
    return _db.collection('orders').doc(o.fsId!).update({'status': status});
  }

  // ===================== PENGADUAN =====================

  Stream<List<Complaint>> complaintsStream() {
    if (!_fbReady) return const Stream.empty();
    return _db.collection('complaints').snapshots().map((snap) {
      final list = snap.docs.map(_complaintFromDoc).toList();
      list.sort((a, b) => b.id.compareTo(a.id));
      return list;
    });
  }

  Complaint _complaintFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Complaint(
      d['id'] as String? ?? doc.id,
      d['title'] as String? ?? '',
      d['loc'] as String? ?? '',
      d['by'] as String? ?? '',
      d['status'] as String? ?? 'Baru',
      d['pic'] as String? ?? 'Belum ditentukan',
      d['reply'] as String? ?? '',
      d['owner'] as String? ?? '',
      fsId: doc.id,
    );
  }

  Future<void> addComplaint(Complaint c) {
    return _db.collection('complaints').add({
      'id': c.id,
      'title': c.title,
      'loc': c.loc,
      'by': c.by,
      'status': c.status,
      'pic': c.pic,
      'reply': c.reply,
      'owner': c.owner,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateComplaint(Complaint c) {
    return _db.collection('complaints').doc(c.fsId!).update({
      'status': c.status,
      'pic': c.pic,
      'reply': c.reply,
    });
  }

  // ===================== LOST & FOUND =====================

  Stream<List<LfItem>> lfItemsStream() {
    if (!_fbReady) return const Stream.empty();
    return _db.collection('lf_items').snapshots().map(
        (snap) => snap.docs.map(_lfItemFromDoc).toList());
  }

  LfItem _lfItemFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return LfItem(
      d['id'] as String? ?? doc.id,
      d['emoji'] as String? ?? '🎒',
      d['name'] as String? ?? '',
      d['where'] as String? ?? '',
      d['kind'] as String? ?? 'Ditemukan',
      d['hidden'] as String? ?? '',
      d['by'] as String? ?? '',
      d['owner'] as String? ?? '',
      Color(d['bgColor'] as int? ?? kSoft.toARGB32()),
      d['status'] as String? ?? 'Menunggu validasi',
      fsId: doc.id,
    );
  }

  Future<void> addLfItem(LfItem it) {
    return _db.collection('lf_items').add({
      'id': it.id,
      'emoji': it.emoji,
      'name': it.name,
      'where': it.where,
      'kind': it.kind,
      'hidden': it.hidden,
      'by': it.by,
      'owner': it.owner,
      'bgColor': it.bg.toARGB32(),
      'status': it.status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLfItem(LfItem it) {
    return _db.collection('lf_items').doc(it.fsId!).update({'status': it.status});
  }

  Stream<List<LfClaim>> lfClaimsStream() {
    if (!_fbReady) return const Stream.empty();
    return _db.collection('lf_claims').snapshots().map(
        (snap) => snap.docs.map(_lfClaimFromDoc).toList());
  }

  LfClaim _lfClaimFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final item = LfItem(
      d['itemId'] as String? ?? '',
      d['itemEmoji'] as String? ?? '🎒',
      d['itemName'] as String? ?? '',
      d['itemWhere'] as String? ?? '',
      'Ditemukan',
      d['itemHidden'] as String? ?? '',
      '',
      '',
      Color(d['itemBg'] as int? ?? kSoft.toARGB32()),
      'Aktif',
      fsId: d['itemFsId'] as String?,
    );
    return LfClaim(
      d['id'] as String? ?? doc.id,
      item,
      d['owner'] as String? ?? '',
      d['desc'] as String? ?? '',
      d['status'] as String? ?? 'Menunggu',
      fsId: doc.id,
    );
  }

  Future<void> addLfClaim(LfClaim k) {
    return _db.collection('lf_claims').add({
      'id': k.id,
      'itemId': k.item.id,
      'itemFsId': k.item.fsId,
      'itemEmoji': k.item.emoji,
      'itemName': k.item.name,
      'itemWhere': k.item.where,
      'itemHidden': k.item.hidden,
      'itemBg': k.item.bg.toARGB32(),
      'owner': k.owner,
      'desc': k.desc,
      'status': k.status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLfClaim(LfClaim k) {
    return _db.collection('lf_claims').doc(k.fsId!).update({'status': k.status});
  }

  // ===================== BOOKING & ADUAN =====================

  Stream<List<BookingReq>> bookingsStream() {
    if (!_fbReady) return const Stream.empty();
    return _db
        .collection('bookings')
        .snapshots()
        .map((snap) => snap.docs.map(_bookingFromDoc).toList());
  }

  BookingReq _bookingFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return BookingReq(
      d['emoji'] as String? ?? '🏟️',
      d['facility'] as String? ?? '',
      d['when'] as String? ?? '',
      d['who'] as String? ?? '',
      d['status'] as String? ?? 'Menunggu',
      d['owner'] as String? ?? '',
      doc.id,
    );
  }

  Future<void> addBooking(BookingReq b) {
    return _db.collection('bookings').add({
      'emoji': b.emoji,
      'facility': b.facility,
      'when': b.when,
      'who': b.who,
      'status': b.status,
      'owner': b.owner,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBooking(BookingReq b) {
    return _db.collection('bookings').doc(b.fsId!).update({'status': b.status});
  }

  Stream<List<Aduan>> aduansStream() {
    if (!_fbReady) return const Stream.empty();
    return _db
        .collection('aduans')
        .snapshots()
        .map((snap) => snap.docs.map(_aduanFromDoc).toList());
  }

  Aduan _aduanFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Aduan(
      d['id'] as String? ?? doc.id,
      d['kind'] as String? ?? 'Lainnya',
      d['body'] as String? ?? '',
      d['owner'] as String? ?? '',
      d['anon'] == true,
      d['status'] as String? ?? 'Baru',
      d['reply'] as String? ?? '',
      fsId: doc.id,
    );
  }

  Future<void> addAduan(Aduan a) {
    return _db.collection('aduans').add({
      'id': a.id,
      'kind': a.kind,
      'body': a.body,
      'owner': a.owner,
      'anon': a.anon,
      'status': a.status,
      'reply': a.reply,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAduan(Aduan a) {
    return _db
        .collection('aduans')
        .doc(a.fsId!)
        .update({'status': a.status, 'reply': a.reply});
  }

  // ===================== SALDO (per-user wallet) =====================

  Stream<int> mySaldoStream() {
    if (!_fbReady) return const Stream.empty();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((s) => (s.data()?['saldo'] as num?)?.toInt() ?? 0);
  }

  Future<void> adjustSaldo(int delta) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Future.value();
    return _db
        .collection('users')
        .doc(uid)
        .update({'saldo': FieldValue.increment(delta)});
  }

  // ===================== DATA AKADEMIK =====================

  /// Ambil data anak dari Ortu yang sedang login (berdasarkan UID-nya).
  /// Query `parent_links` oleh `parentUid` — bukan nama — supaya cocok
  /// dengan Security Rules (`resource.data.parentUid == myUid()`).
  Future<Student?> getStudentForOrtu() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final linkSnap = await _db
          .collection('parent_links')
          .where('parentUid', isEqualTo: uid)
          .limit(1)
          .get();

      if (linkSnap.docs.isEmpty) return null;
      final studentId = linkSnap.docs.first.data()['studentId'] as String;

      final studentDoc = await _db.collection('students').doc(studentId).get();
      if (!studentDoc.exists) return null;

      final sData = studentDoc.data()!;
      final grades = await getGrades(studentId);

      return Student(studentId, sData['name'] ?? '', sData['kelas'] ?? '', grades);
    } catch (e) {
      debugPrint('Error getStudentForOrtu: $e');
      return null;
    }
  }

  /// Ambil seluruh nilai seorang siswa
  Future<List<GradeRecord>> getGrades(String studentId) async {
    try {
      final snap = await _db
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .orderBy('tanggal', descending: true)
          .get();

      return snap.docs.map((d) {
        final m = d.data();
        final ts = m['tanggal'] as Timestamp?;
        final t = ts != null ? ts.toDate() : DateTime.now();
        return GradeRecord(
          m['mapel'] ?? '',
          m['jenis'] ?? '',
          m['semester'] ?? '',
          (m['nilai'] as num?)?.toDouble() ?? 0.0,
          t,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getGrades: $e');
      return [];
    }
  }

  /// Guru menginput nilai baru untuk siswa
  Future<void> addGrade({
    required String studentId,
    required String mapel,
    required String jenis,
    required String semester,
    required double nilai,
    required String guruName,
  }) async {
    await _db.collection('grades').add({
      'studentId': studentId,
      'mapel': mapel,
      'jenis': jenis,
      'semester': semester,
      'nilai': nilai,
      'guruName': guruName,
      'tanggal': FieldValue.serverTimestamp(),
    });
  }

  // ===================== SEEDER DATABASE PERDANA =====================
  /// Membantu mengisi database Firestore pertama kali jika masih kosong.
  Future<void> seedInitialDataIfEmpty() async {
    try {
      final check = await _db.collection('students').limit(1).get();
      if (check.docs.isNotEmpty) return; // sudah ada data

      debugPrint('Seeding initial Firestore data...');

      // 1. Students
      final students = [
        {'id': '2024-0153', 'name': 'Alex Johnson', 'kelas': 'XI IPA 3'},
        {'id': '2024-0120', 'name': 'Bella Anindya', 'kelas': 'XI IPA 2'},
        {'id': '2024-0144', 'name': 'Dimas Pratama', 'kelas': 'XI IPA 2'},
        {'id': '2024-0111', 'name': 'Siti Rahma', 'kelas': 'XI IPA 3'},
      ];
      for (final s in students) {
        await _db.collection('students').doc(s['id']).set(s);
      }

      // 2. Parent Link
      await _db.collection('parent_links').add({
        'parentName': 'Pak Hendra Johnson',
        'studentId': '2024-0153',
      });

      // 3. Grades Starter
      final grades = [
        {'studentId': '2024-0153', 'mapel': 'Matematika', 'jenis': 'UH 1', 'semester': 'Ganjil 2026/2027', 'nilai': 85.0, 'tanggal': Timestamp.fromDate(DateTime(2026, 8, 15))},
        {'studentId': '2024-0153', 'mapel': 'Matematika', 'jenis': 'UTS', 'semester': 'Ganjil 2026/2027', 'nilai': 88.0, 'tanggal': Timestamp.fromDate(DateTime(2026, 9, 20))},
        {'studentId': '2024-0153', 'mapel': 'Fisika', 'jenis': 'UH 1', 'semester': 'Ganjil 2026/2027', 'nilai': 80.0, 'tanggal': Timestamp.fromDate(DateTime(2026, 8, 18))},
        {'studentId': '2024-0153', 'mapel': 'Kimia', 'jenis': 'UH 1', 'semester': 'Ganjil 2026/2027', 'nilai': 92.0, 'tanggal': Timestamp.fromDate(DateTime(2026, 8, 20))},
        {'studentId': '2024-0153', 'mapel': 'Bahasa Indonesia', 'jenis': 'UH 1', 'semester': 'Ganjil 2026/2027', 'nilai': 88.0, 'tanggal': Timestamp.fromDate(DateTime(2026, 8, 12))},
      ];
      for (final g in grades) {
        await _db.collection('grades').add(g);
      }

      // 4. Products Koperasi
      final prods = [
        {'name': 'Roti Isi Keju', 'emoji': '🥪', 'price': 6000, 'stock': 20, 'cat': 'Makanan'},
        {'name': 'Jus Jeruk', 'emoji': '🧃', 'price': 5000, 'stock': 17, 'cat': 'Minuman'},
        {'name': 'Nasi Kepal', 'emoji': '🍙', 'price': 7000, 'stock': 14, 'cat': 'Makanan'},
        {'name': 'Buku Tulis', 'emoji': '📓', 'price': 4500, 'stock': 11, 'cat': 'Alat tulis'},
        {'name': 'Pensil 2B', 'emoji': '✏️', 'price': 2500, 'stock': 8, 'cat': 'Alat tulis'},
      ];
      for (final p in prods) {
        await _db.collection('products').add(p);
      }

      debugPrint('Firestore seeded successfully.');
    } catch (e) {
      debugPrint('Error seeding data: $e');
    }
  }
}