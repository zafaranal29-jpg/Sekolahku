import 'package:flutter/material.dart' show Color;

import 'package:sekolahku/core/theme.dart';

class Product {
  final String? id; // id dokumen Firestore products/{id}
  final String name, emoji;
  final int price, stock;
  final Color bg;
  final String cat;
  const Product(this.name, this.emoji, this.price, this.stock, this.bg, this.cat, {this.id});
}

const products = [
  Product('Roti Isi Keju', '🥪', 6000, 20, kYellowBg, 'Makanan'),
  Product('Jus Jeruk', '🧃', 5000, 17, kRedBg, 'Minuman'),
  Product('Nasi Kepal', '🍙', 7000, 14, kGreenBg, 'Makanan'),
  Product('Buku Tulis', '📓', 4500, 11, kBlueBg, 'Alat tulis'),
  Product('Pensil 2B', '✏️', 2500, 8, kSoft, 'Alat tulis'),
];