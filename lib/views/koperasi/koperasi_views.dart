import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/controllers/cart_controller.dart';
import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/order.dart';
import 'package:sekolahku/models/product.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/data_store.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/views/notif/bell_button.dart';
import 'package:sekolahku/widgets/widgets.dart';

class KoperasiTab extends StatefulWidget {
  const KoperasiTab({super.key});
  @override
  State<KoperasiTab> createState() => _KoperasiTabState();
}

class _KoperasiTabState extends State<KoperasiTab> {
  int cat = 0;
  static const cats = ['Semua', 'Makanan', 'Minuman', 'Alat tulis'];
  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<Product>>(
      stream: firebase_service.FirebaseService.i.productsStream(),
      builder: (context, snap) {
        final list = (snap.data ?? const <Product>[])
            .where((p) => cat == 0 || p.cat == cats[cat])
            .toList();
        return Page('Koperasi', back: false,
            action: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () => go(c, const CartScreen()),
                icon: const Text('🛒', style: TextStyle(fontSize: 18))),
            [
              GCard(
                  child: Row(children: [
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Saldo kamu', style: TextStyle(color: Colors.white70)),
                  StreamBuilder<int>(
                    stream: firebase_service.FirebaseService.i.mySaldoStream(),
                    builder: (context, sSnap) => Text(rp(sSnap.data ?? 0),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.white, foregroundColor: kPrimary),
                      onPressed: () => go(c, const SaldoScreen()).then((_) => setState(() {})),
                      child: const Text('+ Isi saldo')),
                ])),
                const Text('💳', style: TextStyle(fontSize: 54)),
              ])),
              Chips(cats, cat, (i) => setState(() => cat = i)),
              const H('Populer hari ini'),
              for (final p in list)
                Card2(
                    onTap: () => go(c, ProductDetail(p)),
                    child: Row(children: [
                      Emoji(p.emoji, bg: p.bg),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('Stok ${p.stock} · ${rp(p.price)}',
                            style: const TextStyle(color: kMuted, fontSize: 12)),
                      ])),
                      IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: kPrimary),
                          onPressed: () {
                            Cart.i.add(p, 1);
                            toast(c, '${p.name} masuk keranjang');
                          },
                          icon: const Icon(Icons.add, color: Colors.white)),
                    ])),
            ]);
      },
    );
  }
}

class ProductDetail extends StatefulWidget {
  final Product p;
  const ProductDetail(this.p, {super.key});
  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  int q = 1;
  @override
  Widget build(BuildContext c) {
    final p = widget.p;
    return Page('Detail produk',
        bottom: Btn('Tambah ke keranjang · ${rp(p.price * q)}', () {
      Cart.i.add(p, q);
      Navigator.pop(c);
      toast(c, 'Ditambahkan ke keranjang');
    }), [
      Container(
          height: 200,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(24)),
          child: Text(p.emoji, style: const TextStyle(fontSize: 96))),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        Text(rp(p.price),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kPrimary)),
      ]),
      Row(children: [
        Pill('Stok ${p.stock}', bg: kGreenBg, fg: kGreen),
        const SizedBox(width: 6),
        const Pill('Siap 09:00')
      ]),
      const SizedBox(height: 10),
      const Text('Dibuat segar setiap pagi oleh koperasi sekolah.',
          style: TextStyle(color: kMuted)),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        Row(children: [
          IconButton.filledTonal(
              onPressed: q > 1 ? () => setState(() => q--) : null,
              icon: const Icon(Icons.remove)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('$q',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: kPrimary),
              onPressed: q < p.stock ? () => setState(() => q++) : null,
              icon: const Icon(Icons.add)),
        ]),
      ]),
    ]);
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
      listenable: Cart.i,
      builder: (_, __) {
        final cart = Cart.i;
        return Page('Keranjang',
            bottom: Btn('Pilih waktu ambil',
                cart.items.isEmpty ? null : () => go(c, const PickupScreen())),
            [
              if (cart.items.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child: Text('Keranjang kosong 🛒', style: TextStyle(color: kMuted)))),
              for (final e in cart.items.entries)
                Card2(
                    child: Row(children: [
                  Emoji(e.key.emoji, bg: e.key.bg, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.key.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(rp(e.key.price), style: const TextStyle(color: kMuted, fontSize: 12)),
                  ])),
                  Text('× ${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: kMuted)),
                ])),
              if (cart.items.isNotEmpty)
                Card2(
                    child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Subtotal'),
                    Text(rp(cart.total))
                  ]),
                  const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('Biaya layanan'), Text('Rp 0')]),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(rp(cart.total),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: kPrimary, fontSize: 18)),
                  ]),
                ])),
            ]);
      });
}

class PickupScreen extends StatefulWidget {
  const PickupScreen({super.key});
  @override
  State<PickupScreen> createState() => _PickupState();
}

class _PickupState extends State<PickupScreen> {
  int slot = 0, pay = 0;
  static const slots = [
    ('Istirahat 1', '09:30 – 09:45', 'Tersisa 12', true),
    ('Istirahat 2', '12:00 – 12:30', 'Tersisa 25', true),
    ('Pulang', '15:00 – 15:15', 'Penuh', false)
  ];
  static const pays = ['Saldo SekolahKu', 'Tunai saat ambil', 'QRIS'];
  @override
  Widget build(BuildContext c) {
    final total = Cart.i.total;
    return Page('Waktu ambil & bayar',
        bottom: Btn('Pesan sekarang · ${rp(total)}', () async {
          final saldo = await firebase_service.FirebaseService.i.mySaldoStream().first;
          if (!c.mounted) return;
          if (pay == 0 && total > saldo) {
            toast(c, 'Saldo tidak cukup, isi saldo dulu');
            return;
          }
          if (pay == 0) await firebase_service.FirebaseService.i.adjustSaldo(-total);
          final id = 'KP-${DataStore.i.orderSeq++}';
          await firebase_service.FirebaseService.i.addOrder(Order(
              id,
              Session.name,
              Cart.i.items.entries.map((e) => '${e.value} ${e.key.name}').join(', '),
              slots[slot].$1, total, 'Baru', Session.name));
          if (!c.mounted) return;
          NotifService.i.notify(
              '🍱', 'Pesanan koperasi baru', '#$id · ${Session.name} · ${slots[slot].$1}',
              bg: kYellowBg, roles: {Role.koperasi});
          Cart.i.clear();
          Navigator.pushReplacement(c,
              MaterialPageRoute(builder: (_) => OrderSuccess(id, slots[slot].$1, pays[pay], total)));
        }),
        [
          const H('Slot pengambilan'),
          for (final (i, s) in slots.indexed)
            Card2(
                border: slot == i ? kPrimary : null,
                color: s.$4 ? Colors.white : const Color(0xFFF1F0F7),
                onTap: s.$4 ? () => setState(() => slot = i) : null,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(s.$2, style: const TextStyle(color: kMuted, fontSize: 12)),
                  ]),
                  Text(s.$3, style: TextStyle(color: s.$4 ? kGreen : kRed, fontSize: 12)),
                ])),
          const H('Metode bayar'),
          for (final (i, p) in pays.indexed)
            Card2(
                onTap: () => setState(() => pay = i),
                child: Row(children: [
                  Icon(pay == i ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: kPrimary),
                  const SizedBox(width: 12),
                  Text(p, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (i == 0)
                    Text('  ${rp(DataStore.i.saldo)}',
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                ])),
        ]);
  }
}

class OrderSuccess extends StatelessWidget {
  final String id, slot, pay;
  final int total;
  const OrderSuccess(this.id, this.slot, this.pay, this.total, {super.key});
  @override
  Widget build(BuildContext c) => Page('', back: false,
          bottom: Column(children: [
            Btn('Lihat QR pesanan', () => go(c, QrScreen(id, slot))),
            TextButton(
                onPressed: () => Navigator.popUntil(c, (r) => r.isFirst),
                child: const Text('Kembali ke beranda')),
          ]),
          [
            const SizedBox(height: 30),
            const Center(child: Text('✅', style: TextStyle(fontSize: 80))),
            const Center(
                child: Text('Pesanan berhasil!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
            const Center(
                child: Text('Tunjukkan QR ke petugas koperasi saat pengambilan.',
                    style: TextStyle(color: kMuted), textAlign: TextAlign.center)),
            const SizedBox(height: 20),
            Card2(
                child: Column(children: [
              _row('No. pesanan', '#$id'),
              _row('Slot ambil', slot),
              _row('Pembayaran', pay),
              _row('Total', rp(total)),
            ])),
          ]);

  static Widget _row(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(a, style: const TextStyle(color: kMuted)),
        Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]));
}

class QrScreen extends StatelessWidget {
  final String id, slot;
  const QrScreen(this.id, this.slot, {super.key});
  @override
  Widget build(BuildContext c) => Page('QR pesanan', [
        GCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text('Tunjukkan kode ini ke petugas', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration:
                      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: QrBox(id.hashCode)),
              const SizedBox(height: 14),
              Text(id,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4)),
              Text(slot, style: const TextStyle(color: Colors.white70)),
            ])),
        const Card2(
            child: Row(children: [
          Emoji('⏳', bg: kYellowBg, size: 44),
          SizedBox(width: 12),
          Expanded(
              child: Text('Berlaku sampai 09:45', style: TextStyle(fontWeight: FontWeight.w700))),
          Pill('Sekali pakai', bg: kRedBg, fg: kRed),
        ])),
        const Center(
            child: Text('QR hanya bisa dipindai satu kali.\nJangan bagikan ke orang lain.',
                textAlign: TextAlign.center, style: TextStyle(color: kMuted))),
      ]);
}

class SaldoScreen extends StatefulWidget {
  const SaldoScreen({super.key});
  @override
  State<SaldoScreen> createState() => _SaldoState();
}

class _SaldoState extends State<SaldoScreen> {
  int pick = 1;
  static const amounts = [10000, 25000, 50000];
  @override
  Widget build(BuildContext c) => Page('Saldo', [
        GCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Saldo aktif', style: TextStyle(color: Colors.white70)),
          StreamBuilder<int>(
            stream: firebase_service.FirebaseService.i.mySaldoStream(),
            builder: (context, sSnap) => Text(rp(sSnap.data ?? 0),
                style: const TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
          ),
          const Text('Limit harian jajan: Rp 30.000',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        const H('Isi saldo'),
        Row(children: [
          for (final (i, a) in amounts.indexed)
            Expanded(
                child: GestureDetector(
                    onTap: () => setState(() => pick = i),
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: pick == i ? kSoft : Colors.white,
                            border: Border.all(
                                color: pick == i ? kPrimary : Colors.transparent, width: 2),
                            borderRadius: BorderRadius.circular(18)),
                        child: Text(rp(a),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12))))),
        ]),
        const SizedBox(height: 10),
        Btn('Isi ${rp(amounts[pick])}', () {
          firebase_service.FirebaseService.i.adjustSaldo(amounts[pick]);
          toast(c, 'Saldo bertambah');
        }),
        const Card2(
            child: Row(children: [
          Emoji('👨‍👩‍👧', size: 44),
          SizedBox(width: 12),
          Text('Minta orang tua isi\nKirim tautan ke WhatsApp ortu')
        ])),
        const Card2(
            child: Row(children: [
          Emoji('🏪', bg: kYellowBg, size: 44),
          SizedBox(width: 12),
          Text('Setor tunai di koperasi\nTunjukkan QR top-up')
        ])),
      ]);
}

// ======================= ADMIN KOPERASI =======================
class KoperasiShell extends StatelessWidget {
  const KoperasiShell({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: KoperasiAdminTab());
}

Future<void> _setOrder(Order o, String status) async {
  await firebase_service.FirebaseService.i.updateOrderStatus(o, status);
  o.status = status;
  switch (status) {
    case 'Disiapkan':
      NotifService.i.notify('🍱', 'Pesananmu sedang disiapkan', '#${o.id} · ${o.slot}',
          bg: kYellowBg, to: o.owner);
    case 'Siap':
      NotifService.i.notify('✅', 'Pesananmu siap diambil', '#${o.id} · tunjukkan QR ke petugas',
          bg: kGreenBg, to: o.owner);
    case 'Selesai':
      NotifService.i.notify('🎉', 'Pesanan selesai', '#${o.id} sudah diserahkan',
          bg: kSoft, to: o.owner);
  }
}

class KoperasiAdminTab extends StatefulWidget {
  const KoperasiAdminTab({super.key});
  @override
  State<KoperasiAdminTab> createState() => _KoperasiAdminState();
}

class _KoperasiAdminState extends State<KoperasiAdminTab> {
  int tab = 0;
  final code = TextEditingController();
  Order? found;
  String? scanMsg;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> validate() async {
    final id = code.text.trim().toUpperCase().replaceAll('#', '');
    final orders = await firebase_service.FirebaseService.i.ordersStream().first;
    final o = orders.where((x) => x.id == id).firstOrNull;
    if (!mounted) return;
    setState(() {
      found = null;
      if (o == null) {
        scanMsg = '❌ Kode tidak ditemukan';
      } else if (o.status == 'Selesai') {
        scanMsg = '⚠️ QR sudah dipakai';
      } else if (o.status != 'Siap') {
        scanMsg = '⏳ Pesanan belum siap diambil (status: ${o.status})';
      } else {
        found = o;
        scanMsg = '✅ QR valid. Pesanan belum pernah diambil';
      }
    });
  }

  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<Order>>(
      stream: firebase_service.FirebaseService.i.ordersStream(),
      builder: (context, oSnap) {
        final orders = oSnap.data ?? const <Order>[];
        return StreamBuilder<List<Product>>(
          stream: firebase_service.FirebaseService.i.productsStream(),
          builder: (context, pSnap) {
            final prods = pSnap.data ?? const <Product>[];
            final low = prods.where((p) => p.stock <= 5).map((p) => '${p.name} (${p.stock})').join(' · ');
            return Page('Dashboard koperasi', back: false,
                action: Row(mainAxisSize: MainAxisSize.min, children: [
                  const BellButton(),
                  IconButton(
                      tooltip: 'Keluar',
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(c, '/auth', (_) => false),
                      icon: const Icon(Icons.logout)),
                ]),
                [
                  const GCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Penjualan hari ini', style: TextStyle(color: Colors.white70)),
                    Text('Rp 1.245.000',
                        style: TextStyle(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                    Text('▲ 12% dari kemarin · 86 pesanan',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                  if (low.isNotEmpty) Card2(color: kRedBg, child: Text('⚠️ Stok menipis: $low')),
                  SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Pesanan')),
                        ButtonSegment(value: 1, label: Text('Scan QR')),
                        ButtonSegment(value: 2, label: Text('Stok'))
                      ],
                      selected: {tab},
                      onSelectionChanged: (v) => setState(() => tab = v.first)),
                  const SizedBox(height: 12),
                  if (tab == 0) ...[
                    for (final o in orders.where((o) => o.status != 'Selesai'))
                      Card2(
                          child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('#${o.id} · ${o.customer}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(o.slot,
                              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                        ]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(
                              child: Text(o.items,
                                  style: const TextStyle(color: kMuted, fontSize: 12))),
                          Text(rp(o.total), style: const TextStyle(color: kMuted)),
                        ]),
                        const SizedBox(height: 8),
                        if (o.status == 'Baru')
                          Btn('Mulai siapkan', () => _setOrder(o, 'Disiapkan')),
                        if (o.status == 'Disiapkan')
                          Btn('Tandai siap diambil', () => _setOrder(o, 'Siap')),
                        if (o.status == 'Siap')
                          const Pill('Siap diambil · tunggu scan QR', bg: kGreenBg, fg: kGreen),
                      ])),
                    if (orders.every((o) => o.status == 'Selesai'))
                      const Center(
                          child: Text('Semua pesanan selesai 🎉', style: TextStyle(color: kMuted))),
                  ],
                  if (tab == 1) ...[
                    Card2(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          const Text(
                              'Di perangkat ini kamera QR belum dipasang. Masukkan kode dari ponsel pembeli (contoh: KP-0234).',
                              style: TextStyle(color: kMuted, fontSize: 12)),
                          const SizedBox(height: 10),
                          Field('Kode pesanan', controller: code),
                          Btn('Validasi', validate),
                        ])),
                    if (scanMsg != null)
                      Card2(
                          color: found != null ? kGreenBg : kYellowBg,
                          child: Text(scanMsg!, style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (found != null)
                      Card2(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('#${found!.id} · ${found!.customer}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(found!.items, style: const TextStyle(color: kMuted)),
                        Text('Total ${rp(found!.total)} · Lunas',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Btn('Serahkan pesanan', () {
                          _setOrder(found!, 'Selesai');
                          setState(() {
                            found = null;
                            scanMsg = '✅ Pesanan diserahkan';
                            code.clear();
                          });
                        }),
                      ])),
                  ],
                  if (tab == 2)
                    for (final p in prods)
                      infoRow(p.emoji, p.bg, p.name, rp(p.price),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                                onPressed: () => firebase_service.FirebaseService.i
                                    .updateProductStock(p, (p.stock - 1).clamp(0, 999)),
                                icon: const Icon(Icons.remove_circle_outline)),
                            Text('${p.stock}',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            IconButton(
                                onPressed: () => firebase_service.FirebaseService.i
                                    .updateProductStock(p, p.stock + 1),
                                icon: const Icon(Icons.add_circle_outline, color: kPrimary)),
                          ])),
                ]);
          },
        );
      },
    );
  }
}