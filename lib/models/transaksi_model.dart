class TransaksiModel {
  int? idTransaksi;
  int idBus;
  int idPelanggan;
  int idUser; // ID Admin atau User yang melakukan booking
  String tglSewa;
  String tglKembali;
  int totalHari;
  int totalBiaya;
  int denda;
  
  // --- KOLOM BARU SESUAI REVISI DB ---
  int dpBayar;          // Uang Muka
  int sisaBayar;        // Yang belum dibayar
  String statusPembayaran; // 'Lunas', 'Belum Lunas'
  String statusSewa;    // 'Booking', 'Berjalan', 'Selesai', 'Batal'
  String createdAt;     // Tanggal pembuatan transaksi

  TransaksiModel({
    this.idTransaksi,
    required this.idBus,
    required this.idPelanggan,
    required this.idUser,
    required this.tglSewa,
    required this.tglKembali,
    required this.totalHari,
    required this.totalBiaya,
    this.denda = 0,
    required this.dpBayar,
    required this.sisaBayar,
    required this.statusPembayaran,
    required this.statusSewa,
    required this.createdAt,
  });

  // Konversi dari Map (Database) ke Object Model
  factory TransaksiModel.fromMap(Map<String, dynamic> map) {
    return TransaksiModel(
      idTransaksi: map['id_transaksi'],
      idBus: map['id_bus'] ?? 0,
      idPelanggan: map['id_pelanggan'] ?? 0,
      idUser: map['id_user'] ?? 0,
      tglSewa: map['tgl_sewa'] ?? '',
      tglKembali: map['tgl_kembali'] ?? '',
      totalHari: map['total_hari'] ?? 0,
      totalBiaya: map['total_biaya'] ?? 0,
      denda: map['denda'] ?? 0,
      
      // Mapping Kolom Baru
      dpBayar: map['dp_bayar'] ?? 0,
      sisaBayar: map['sisa_bayar'] ?? 0,
      statusPembayaran: map['status_pembayaran'] ?? 'Belum Lunas',
      statusSewa: map['status_sewa'] ?? 'Booking',
      createdAt: map['created_at'] ?? '',
    );
  }

  // Konversi dari Object Model ke Map (Untuk Simpan ke Database)
  Map<String, dynamic> toMap() {
    return {
      'id_transaksi': idTransaksi,
      'id_bus': idBus,
      'id_pelanggan': idPelanggan,
      'id_user': idUser,
      'tgl_sewa': tglSewa,
      'tgl_kembali': tglKembali,
      'total_hari': totalHari,
      'total_biaya': totalBiaya,
      'denda': denda,
      'dp_bayar': dpBayar,
      'sisa_bayar': sisaBayar,
      'status_pembayaran': statusPembayaran,
      'status_sewa': statusSewa,
      'created_at': createdAt,
    };
  }
}
