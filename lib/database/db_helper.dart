import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'rental_bus_app_final.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // ===========================================================================
  // 1. PEMBUATAN TABEL & SEED DATA
  // ===========================================================================
  Future<void> _onCreate(Database db, int version) async {
    // A. Tabel Users
    await db.execute('''
      CREATE TABLE users(
        id_user INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT
      )
    ''');

    // B. Tabel Bus
    await db.execute('''
      CREATE TABLE bus(
        id_bus INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_bus TEXT,
        plat_nomor TEXT UNIQUE,
        kapasitas INTEGER,
        harga_sewa INTEGER,
        status TEXT, 
        deskripsi TEXT,
        fasilitas TEXT,
        foto TEXT
      )
    ''');

    // C. Tabel Pelanggan
    await db.execute('''
      CREATE TABLE pelanggan(
        id_pelanggan INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user INTEGER,
        nama_lengkap TEXT,
        nik_ktp TEXT UNIQUE,
        no_hp TEXT,
        alamat TEXT,
        FOREIGN KEY (id_user) REFERENCES users (id_user)
      )
    ''');

    // D. Tabel Transaksi
    await db.execute('''
      CREATE TABLE transaksi(
        id_transaksi INTEGER PRIMARY KEY AUTOINCREMENT,
        id_bus INTEGER,
        id_pelanggan INTEGER,
        id_user INTEGER,
        tgl_sewa TEXT,
        tgl_kembali TEXT,
        total_hari INTEGER,
        total_biaya INTEGER,
        denda INTEGER,
        dp_bayar INTEGER,
        sisa_bayar INTEGER,
        status_pembayaran TEXT,
        status_sewa TEXT,
        created_at TEXT,
        FOREIGN KEY (id_bus) REFERENCES bus (id_bus),
        FOREIGN KEY (id_pelanggan) REFERENCES pelanggan (id_pelanggan),
        FOREIGN KEY (id_user) REFERENCES users (id_user)
      )
    ''');

    // Seed Admin Default
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
    });

    // Seed Data Bus Awal (Opsional)
    await db.insert('bus', {
      'nama_bus': 'Jetbus 3+ Voyager',
      'plat_nomor': 'B 7777 EEE',
      'kapasitas': 50,
      'harga_sewa': 3500000,
      'status': 'Tersedia',
      'deskripsi': 'Bus Luxury',
      'fasilitas': 'AC, Wifi, Toilet',
      'foto': '',
    });
  }

  // ===========================================================================
  // 2. BAGIAN AUTHENTICATION (LOGIN & REGISTER)
  // ===========================================================================
  
  // Login Cek User & Pass
  Future<Map<String, dynamic>?> loginUser(String user, String pass) async {
    final db = await database;
    final res = await db.query('users', where: "username = ? AND password = ?", whereArgs: [user, pass]);
    return res.isNotEmpty ? res.first : null;
  }

  // Register Pelanggan (Transaction: User + Profil)
  Future<bool> registerPelanggan({
    required String username, 
    required String password, 
    required String nama, 
    required String nik, 
    required String hp, 
    required String alamat
  }) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        int idUser = await txn.insert('users', {'username': username, 'password': password, 'role': 'pelanggan'});
        await txn.insert('pelanggan', {'id_user': idUser, 'nama_lengkap': nama, 'nik_ktp': nik, 'no_hp': hp, 'alamat': alamat});
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 3. BAGIAN KELOLA BUS (CRUD)
  // ===========================================================================

  // [FITUR BARU] Cek Transaksi Aktif (Untuk Guard Edit/Hapus di Admin)
  Future<bool> checkActiveTransaction(int busId) async {
    final db = await database;
    // Cek apakah bus ini ada di transaksi yang statusnya MASIH JALAN (Bukan Selesai/Batal)
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM transaksi WHERE id_bus = ? AND status_sewa NOT IN ('Selesai', 'Batal')",
      [busId]
    );
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0; // True jika bus sedang dipesan/disewa
  }

  Future<int> insertBus(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('bus', row);
  }

  // Get Semua Bus (Untuk Admin)
  Future<List<Map<String, dynamic>>> getBus() async {
    final db = await database;
    return await db.query('bus', orderBy: 'id_bus DESC');
  }

  // Get Bus Tersedia (Untuk User - Filter Status Fisik)
  Future<List<Map<String, dynamic>>> getBusTersedia() async {
    final db = await database;
    return await db.query('bus', where: "status = 'Tersedia'");
  }

  Future<int> updateBus(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('bus', row, where: "id_bus = ?", whereArgs: [id]);
  }

  Future<int> deleteBus(int id) async {
    final db = await database;
    return await db.delete('bus', where: "id_bus = ?", whereArgs: [id]);
  }

  Future<void> updateStatusBus(int id, String status) async {
    final db = await database;
    await db.update('bus', {'status': status}, where: "id_bus = ?", whereArgs: [id]);
  }

  // ===========================================================================
  // 4. BAGIAN KELOLA PELANGGAN
  // ===========================================================================
  
  Future<int> insertPelanggan(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('pelanggan', row);
  }

  Future<List<Map<String, dynamic>>> getPelanggan() async {
    final db = await database;
    return await db.query('pelanggan', orderBy: 'nama_lengkap ASC');
  }

  // Get Profil by ID User (Penting untuk Home User)
  Future<Map<String, dynamic>?> getProfilPelanggan(int idUser) async {
    final db = await database;
    final res = await db.query('pelanggan', where: "id_user = ?", whereArgs: [idUser]);
    return res.isNotEmpty ? res.first : null;
  }
  
  Future<int> deletePelanggan(int id) async {
    final db = await database;
    return await db.delete('pelanggan', where: "id_pelanggan = ?", whereArgs: [id]);
  }

  // ===========================================================================
  // 5. BAGIAN TRANSAKSI & LOGIC BOOKING
  // ===========================================================================

  Future<int> insertTransaksi(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('transaksi', row);
  }

  // [FITUR MODIFIKASI] Cek Ketersediaan (Anti Bentrok Tanggal)
  // Memastikan bus tidak bisa dipesan ganda di tanggal yang sama
  Future<bool> checkAvailability(int idBus, String tglMulaiBaru, String tglSelesaiBaru) async {
    final db = await database;
    
    // Logic Query: Cari irisan tanggal
    // Transaksi dianggap bentrok jika:
    // (Start_Existing <= End_New) DAN (End_Existing >= Start_New)
    // Dan Status Sewa transaksi tersebut BELUM 'Selesai' atau 'Batal'
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM transaksi 
      WHERE id_bus = ? 
      AND status_sewa NOT IN ('Batal', 'Selesai')
      AND (tgl_sewa <= ? AND tgl_kembali >= ?)
    ''', [idBus, tglSelesaiBaru, tglMulaiBaru]);

    int count = Sqflite.firstIntValue(result) ?? 0;
    
    // Jika count == 0, berarti TIDAK ADA bentrok -> Available (True)
    return count == 0; 
  }

  // Get Riwayat Lengkap (Untuk Laporan Admin)
  // [DIUPDATE] Menambahkan kolom: no_hp, alamat, dan kapasitas bus
  Future<List<Map<String, dynamic>>> getRiwayatLengkap() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, b.nama_bus, b.plat_nomor, b.kapasitas, 
             p.nama_lengkap, p.no_hp, p.alamat 
      FROM transaksi t
      JOIN bus b ON t.id_bus = b.id_bus
      JOIN pelanggan p ON t.id_pelanggan = p.id_pelanggan
      ORDER BY t.id_transaksi DESC
    ''');
  }

  // Get Riwayat User Tertentu
  Future<List<Map<String, dynamic>>> getRiwayatPelanggan(int idPelanggan) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, b.nama_bus, b.plat_nomor, b.foto
      FROM transaksi t
      JOIN bus b ON t.id_bus = b.id_bus
      WHERE t.id_pelanggan = ?
      ORDER BY t.id_transaksi DESC
    ''', [idPelanggan]);
  }

  // Update Status Transaksi (Pelunasan / Selesai / Batal)
  Future<int> updateStatusTransaksi({
    required int idTransaksi, 
    String? statusSewa, 
    String? statusBayar, 
    int? sisaBayar
  }) async {
    final db = await database;
    
    // Map dinamis, hanya update field yang dikirim saja
    Map<String, dynamic> data = {};
    if (statusSewa != null) data['status_sewa'] = statusSewa;
    if (statusBayar != null) data['status_pembayaran'] = statusBayar;
    if (sisaBayar != null) data['sisa_bayar'] = sisaBayar;
    
    return await db.update('transaksi', data, where: "id_transaksi = ?", whereArgs: [idTransaksi]);
  }
}
