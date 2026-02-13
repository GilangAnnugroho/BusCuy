import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/pelanggan_model.dart';

class ManagePelangganScreen extends StatefulWidget {
  const ManagePelangganScreen({super.key});

  @override
  State<ManagePelangganScreen> createState() => _ManagePelangganScreenState();
}

class _ManagePelangganScreenState extends State<ManagePelangganScreen> {
  List<PelangganModel> _listPelanggan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // 1. AMBIL DATA DARI DB
  void _refreshData() async {
    final data = await DatabaseHelper().getPelanggan();
    if (!mounted) return;
    setState(() {
      _listPelanggan = data.map((item) => PelangganModel.fromMap(item)).toList();
      _isLoading = false;
    });
  }

  // 2. FUNGSI SEEDER PELANGGAN (Data Dummy Manual)
  void _seedPelanggan() async {
    final List<Map<String, dynamic>> dummyData = [
      {'nama_lengkap': 'Budi Santoso', 'nik_ktp': '3201123456780001', 'no_hp': '081234567890', 'alamat': 'Jl. Merdeka No. 45, Jakarta Pusat'},
      {'nama_lengkap': 'Siti Aminah', 'nik_ktp': '3202987654320002', 'no_hp': '085712345678', 'alamat': 'Jl. Kebon Jeruk 10 No. 12, Jakarta Barat'},
      {'nama_lengkap': 'Andi Pratama', 'nik_ktp': '3275123400010003', 'no_hp': '081398765432', 'alamat': 'Perumahan Griya Asri Blok B1 No. 5, Bekasi'},
      {'nama_lengkap': 'Dewi Sartika', 'nik_ktp': '3301123456780004', 'no_hp': '087811223344', 'alamat': 'Jl. Diponegoro No. 8, Bandung'},
      {'nama_lengkap': 'Rizky Hidayat', 'nik_ktp': '3501123456780005', 'no_hp': '089655667788', 'alamat': 'Jl. Jenderal Sudirman No. 99, Surabaya'},
    ];

    for (var data in dummyData) {
      try {
        await DatabaseHelper().insertPelanggan(data);
      } catch (e) {
        // Abaikan jika NIK duplikat
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("5 Data Pelanggan Berhasil Ditambahkan!")));
    _refreshData();
  }

  // 3. HAPUS DATA
  void _deletePelanggan(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('pelanggan', where: 'id_pelanggan = ?', whereArgs: [id]);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data pelanggan dihapus")));
    _refreshData();
  }

  // 4. FORM TAMBAH / EDIT
  void _showForm({PelangganModel? pelanggan}) {
    final namaController = TextEditingController(text: pelanggan?.namaLengkap ?? '');
    final nikController = TextEditingController(text: pelanggan?.nikKtp ?? '');
    final hpController = TextEditingController(text: pelanggan?.noHp ?? '');
    final alamatController = TextEditingController(text: pelanggan?.alamat ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pelanggan == null ? "Tambah Pelanggan" : "Edit Data", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            TextField(controller: namaController, decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: nikController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "NIK KTP (Wajib)", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: hpController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "No HP / WA", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: alamatController, maxLines: 2, decoration: const InputDecoration(labelText: "Alamat Lengkap", border: OutlineInputBorder())),
            
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blueAccent),
              onPressed: () async {
                if (namaController.text.isEmpty || nikController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama & NIK Wajib diisi!")));
                  return;
                }

                // PENTING: Saat update, pastikan id_user tidak hilang jika pelanggan tersebut adalah user app
                final data = {
                  'id_user': pelanggan?.idUser, // Preservasi ID User
                  'nama_lengkap': namaController.text,
                  'nik_ktp': nikController.text,
                  'no_hp': hpController.text,
                  'alamat': alamatController.text,
                };

                final db = await DatabaseHelper().database;
                if (pelanggan == null) {
                  // Insert Baru (Manual oleh Admin -> id_user NULL)
                  await DatabaseHelper().insertPelanggan(data);
                } else {
                  // Update
                  await db.update('pelanggan', data, where: 'id_pelanggan = ?', whereArgs: [pelanggan.idPelanggan]);
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                _refreshData();
              },
              child: const Text("SIMPAN DATA", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 5. POPUP DETAIL
  void _showDetailDialog(PelangganModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(item.namaLengkap, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.idUser != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)),
                child: const Text("User Aplikasi Terdaftar", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            Text("NIK: ${item.nikKtp}"),
            const SizedBox(height: 8),
            Text("HP: ${item.noHp}"),
            const Divider(),
            const Text("Alamat:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(item.alamat.isEmpty ? "-" : item.alamat),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Pelanggan"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          // TOMBOL MAGIC UNTUK ISI DATA CEPAT
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: "Isi Data Dummy",
            onPressed: _seedPelanggan,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listPelanggan.isEmpty
              ? const Center(child: Text("Belum ada data pelanggan."))
              : ListView.separated(
                  itemCount: _listPelanggan.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _listPelanggan[index];
                    
                    // Logic Warna Avatar: Hijau jika User App, Biru jika Manual
                    bool isAppUser = item.idUser != null;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAppUser ? Colors.green : Colors.blueAccent,
                        foregroundColor: Colors.white,
                        child: Text(item.namaLengkap.isNotEmpty ? item.namaLengkap[0].toUpperCase() : "?"),
                      ),
                      title: Row(
                        children: [
                          Text(item.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (isAppUser) 
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.verified, size: 16, color: Colors.green),
                            )
                        ],
                      ),
                      subtitle: Text("HP: ${item.noHp}"),
                      onTap: () => _showDetailDialog(item),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showForm(pelanggan: item)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePelanggan(item.idPelanggan!)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
