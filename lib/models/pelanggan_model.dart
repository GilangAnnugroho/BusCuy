class PelangganModel {
  int? idPelanggan;
  int? idUser; // Foreign Key ke tabel Users
  String namaLengkap;
  String nikKtp;
  String noHp;
  String alamat;

  PelangganModel({
    this.idPelanggan,
    this.idUser, // Bisa null jika pelanggan diinput manual oleh admin
    required this.namaLengkap,
    required this.nikKtp,
    required this.noHp,
    required this.alamat,
  });

  // Konversi dari Map (Database) ke Object Model
  factory PelangganModel.fromMap(Map<String, dynamic> map) {
    return PelangganModel(
      idPelanggan: map['id_pelanggan'],
      idUser: map['id_user'], 
      namaLengkap: map['nama_lengkap'] ?? '', // Safety check agar tidak crash jika null
      nikKtp: map['nik_ktp'] ?? '',
      noHp: map['no_hp'] ?? '',
      alamat: map['alamat'] ?? '',
    );
  }

  // Konversi dari Object Model ke Map (Untuk Simpan ke Database)
  Map<String, dynamic> toMap() {
    return {
      'id_pelanggan': idPelanggan,
      'id_user': idUser,
      'nama_lengkap': namaLengkap,
      'nik_ktp': nikKtp,
      'no_hp': noHp,
      'alamat': alamat,
    };
  }
}
