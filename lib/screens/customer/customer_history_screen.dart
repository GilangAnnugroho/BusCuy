import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/user_model.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_format.dart';
import '../../utils/struk_helper.dart';

class CustomerHistoryScreen extends StatefulWidget {
  final UserModel user;
  const CustomerHistoryScreen({super.key, required this.user});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  List<Map<String, dynamic>> _listRiwayat = [];
  bool _isLoading = true;
  String _namaPelanggan = ""; // Untuk keperluan struk

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);

    // 1. Cari ID Pelanggan berdasarkan ID User yang login
    final profile = await DatabaseHelper().getProfilPelanggan(widget.user.idUser!);
    
    if (profile != null) {
      int idPelanggan = profile['id_pelanggan'];
      _namaPelanggan = profile['nama_lengkap'];

      // 2. Ambil Riwayat Transaksi milik Pelanggan ini
      final data = await DatabaseHelper().getRiwayatPelanggan(idPelanggan);
      
      if (mounted) {
        setState(() {
          _listRiwayat = data;
          _isLoading = false;
        });
      }
    } else {
      // Jika profil belum ada (kasus jarang terjadi jika alur register benar)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // LOGIC: Batalkan Pesanan (Hanya jika masih Booking)
  void _batalkanPesanan(int idTransaksi, int idBus) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Batalkan Pesanan?"),
        content: const Text("Apakah Anda yakin ingin membatalkan booking ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tidak")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog
              
              // 1. Update Status Transaksi jadi 'Batal'
              await DatabaseHelper().updateStatusTransaksi(
                idTransaksi: idTransaksi,
                statusSewa: 'Batal'
              );

              // 2. Update Status Bus kembali jadi 'Tersedia'
              await DatabaseHelper().updateStatusBus(idBus, 'Tersedia');

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pesanan berhasil dibatalkan."))
              );
              
              _loadData(); // Refresh list
            },
            child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Booking': return Colors.orange;
      case 'Disewa': return Colors.blue; // Atau 'Berjalan'
      case 'Selesai': return Colors.green;
      case 'Batal': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pesanan Saya"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listRiwayat.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 80, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text("Belum ada riwayat pesanan.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cari Bus Sekarang"),
                    )
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _listRiwayat.length,
                itemBuilder: (context, index) {
                  final item = _listRiwayat[index];
                  return _buildHistoryCard(item);
                },
              ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    String statusSewa = item['status_sewa'] ?? '-';
    // Fix: Menggunakan variabel statusBayar agar tidak warning 'unused'
    String statusBayar = item['status_pembayaran'] ?? 'Belum Lunas'; 
    int sisa = item['sisa_bayar'] ?? 0;

    // Persiapkan data lengkap untuk cetak struk (inject nama pelanggan)
    Map<String, dynamic> dataStruk = Map.from(item);
    dataStruk['nama_lengkap'] = _namaPelanggan;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: TANGGAL & STATUS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateHelper.formatDate(item['tgl_sewa']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(statusSewa).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(statusSewa)),
                  ),
                  child: Text(
                    statusSewa.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(statusSewa),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),

            // --- BODY: INFO BUS ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.directions_bus, color: Colors.blueAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nama_bus'] ?? 'Bus',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        item['plat_nomor'] ?? '-',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- INFO KEUANGAN ---
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Tagihan:"),
                      Text(
                        CurrencyFormat.convertToIdr(item['total_biaya'], 0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Status Pembayaran:"),
                       Text(
                        statusBayar.toUpperCase(), // Menampilkan status bayar
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusBayar == 'Lunas' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Sisa Kekurangan:"),
                      Text(
                        CurrencyFormat.convertToIdr(sisa, 0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sisa > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- FOOTER: ACTION BUTTONS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol Cetak Struk
                OutlinedButton.icon(
                  onPressed: () => StrukHelper.cetakStruk(dataStruk),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text("Bukti"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey.shade400)
                  ),
                ),
                
                const SizedBox(width: 8),

                // Tombol Batalkan (Hanya jika status Booking)
                if (statusSewa == 'Booking')
                  ElevatedButton(
                    onPressed: () => _batalkanPesanan(item['id_transaksi'], item['id_bus']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Batalkan"),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
