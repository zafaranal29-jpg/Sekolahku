class Order {
  final String id, customer, items, slot, owner;
  final int total;
  final String? fsId; // id dokumen Firestore orders/{id}
  String status; // Baru | Disiapkan | Siap | Selesai
  Order(this.id, this.customer, this.items, this.slot, this.total, this.status, this.owner,
      {this.fsId});
}