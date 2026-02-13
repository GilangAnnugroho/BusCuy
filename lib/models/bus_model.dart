class BusModel {
  int? idBus;
  String namaBus;
  String platNomor;
  int kapasitas;
  int hargaSewa;
  String status; // 'Tersedia', 'Disewa', 'Bengkel'
  String deskripsi;
  String fasilitas;
  String foto;

  BusModel({
    this.idBus,
    required this.namaBus,
    required this.platNomor,
    required this.kapasitas,
    required this.hargaSewa,
    required this.status,
    required this.deskripsi,
    required this.fasilitas,
    required this.foto,
  });

  // Konversi dari Map (Database) ke Object Model
  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      idBus: map['id_bus'],
      namaBus: map['nama_bus'] ?? '',
      platNomor: map['plat_nomor'] ?? '',
      kapasitas: map['kapasitas'] ?? 0,
      hargaSewa: map['harga_sewa'] ?? 0,
      status: map['status'] ?? 'Tersedia',
      deskripsi: map['deskripsi'] ?? '',
      fasilitas: map['fasilitas'] ?? '',
      foto: map['foto'] ?? '',
    );
  }

  // Konversi dari Object Model ke Map (Untuk Simpan ke Database)
  Map<String, dynamic> toMap() {
    return {
      'id_bus': idBus,
      'nama_bus': namaBus,
      'plat_nomor': platNomor,
      'kapasitas': kapasitas,
      'harga_sewa': hargaSewa,
      'status': status,
      'deskripsi': deskripsi,
      'fasilitas': fasilitas,
      'foto': foto,
    };
  }
}

