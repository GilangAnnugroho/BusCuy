import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_format.dart';
import '../../utils/struk_helper.dart'; 

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  List<Map<String, dynamic>> _allTransaksi = [];
  List<Map<String, dynamic>> _filteredTransaksi = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. LOAD DATA DARI DB
  Future<void> _loadData() async {
    final data = await DatabaseHelper().getRiwayatLengkap();
    if (!mounted) return;
    setState(() {
      _allTransaksi = data;
      _filteredTransaksi = data; // Awalnya tampilkan semua
      _isLoading = false;
    });
  }

  // 2. FILTER PENCARIAN
  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTransaksi = _allTransaksi.where((item) {
        final namaPelanggan = (item['nama_lengkap'] ?? '').toLowerCase();
        final namaBus = (item['nama_bus'] ?? '').toLowerCase();
        final status = (item['status_sewa'] ?? '').toLowerCase();
        
        return namaPelanggan.contains(query) || 
               namaBus.contains(query) || 
               status.contains(query);
      }).toList();
    });
  }

  // LOGIC 1: MENANGANI TOMBOL SELESAI
  void _handleSelesai(Map<String, dynamic> item) {
    int sisa = item['sisa_bayar'] ?? 0;
    
    // Jika masih ada sisa, wajib pelunasan dulu
    if (sisa > 0) {
      _showDialogPelunasan(item);
    } else {
      // Jika sudah lunas, konfirmasi penyelesaian
      _showDialogKonfirmasiSelesai(item);
    }
  }

  // LOGIC 2: DIALOG PELUNASAN (FITUR POWERFULL)
  void _showDialogPelunasan(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pelunasan Pembayaran"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Penyewa belum melunasi tagihan."),
              const SizedBox(height: 10),
              const Text("Sisa Tagihan:", style: TextStyle(fontSize: 14, color: Colors.grey)),
              Text(
                CurrencyFormat.convertToIdr(item['sisa_bayar'], 0),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 10),
              const Text("Apakah penyewa sudah membayar sisa tagihan ini sekarang?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context); // Tutup Dialog
                // Update sisa jadi 0, status Lunas, Sewa Selesai
                _prosesSewaSelesai(item['id_transaksi'], item['id_bus'], 0);
              },
              child: const Text("YA, LUNASI & SELESAI", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDialogKonfirmasiSelesai(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Selesaikan Sewa?"),
        content: const Text("Pastikan bus sudah kembali dan dicek kondisinya. Status bus akan kembali menjadi 'Tersedia'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _prosesSewaSelesai(item['id_transaksi'], item['id_bus'], 0);
            },
            child: const Text("Selesai"),
          )
        ],
      )
    );
  }

  // LOGIC 3: UPDATE DATABASE (SELESAI)
  void _prosesSewaSelesai(int idTransaksi, int idBus, int sisaBayar) async {
    // 1. Update Transaksi (Status Sewa: Selesai, Status Bayar: Lunas, Sisa: 0)
    await DatabaseHelper().updateStatusTransaksi(
      idTransaksi: idTransaksi, 
      statusSewa: 'Selesai',
      statusBayar: 'Lunas',
      sisaBayar: 0 // Pastikan sisa jadi 0
    );

    // 2. Kembalikan Bus jadi Tersedia 
    await DatabaseHelper().updateStatusBus(idBus, 'Tersedia');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Transaksi Lunas & Sewa Selesai!")),
    );
    _loadData();
  }

  // LOGIC 4: BATALKAN SEWA
  void _batalkanSewa(int idTransaksi, int idBus) async {
    // Konfirmasi dulu biar gak kepencet
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Batal"),
        content: const Text("Yakin ingin membatalkan booking ini? Status Bus akan kembali Tersedia."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tidak")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper().updateStatusTransaksi(idTransaksi: idTransaksi, statusSewa: 'Batal');
              await DatabaseHelper().updateStatusBus(idBus, 'Tersedia');
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi Dibatalkan.")));
              _loadData();
            },
            child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.red)),
          )
        ],
      )
    );
  }

  // Helper Warna Status Sewa
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Booking': return Colors.orange;
      case 'Berjalan': return Colors.blue;
      case 'Selesai': return Colors.green;
      case 'Batal': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Riwayat Sewa"),
        backgroundColor: Colors.blueAccent, 
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari Pelanggan / Bus / Status...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey.shade50
              ),
            ),
          ),

          // --- LIST DATA ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransaksi.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(
                            _searchController.text.isEmpty 
                              ? "Belum ada riwayat transaksi."
                              : "Data tidak ditemukan.",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _filteredTransaksi.length,
                        itemBuilder: (context, index) {
                          final item = _filteredTransaksi[index];
                          String statusSewa = item['status_sewa'] ?? '-';
                          String statusBayar = item['status_pembayaran'] ?? 'Belum Lunas';
                          int sisa = item['sisa_bayar'] ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- HEADER: Tanggal & ID ---
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${DateHelper.formatShort(item['tgl_sewa'])} - ${DateHelper.formatShort(item['tgl_kembali'])}",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text("ID: #${item['id_transaksi']}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        ],
                                      ),
                                      // Tombol Print
                                      IconButton(
                                        onPressed: () => StrukHelper.cetakStruk(item),
                                        icon: const Icon(Icons.print, color: Colors.blueGrey),
                                        tooltip: "Cetak Struk",
                                      )
                                    ],
                                  ),
                                  const Divider(),

                                  // --- BODY: Info Bus & Pelanggan ---
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.directions_bus, color: Colors.blueAccent, size: 30),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['nama_bus'] ?? 'Bus Dihapus',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text("Penyewa: ${item['nama_lengkap']}", style: const TextStyle(fontSize: 14)),
                                            Text("Plat: ${item['plat_nomor']}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // --- INFO KEUANGAN ---
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200)
                                    ),
                                    child: Column(
                                      children: [
                                        _buildMoneyRow("Total Biaya", item['total_biaya'], isBold: true),
                                        _buildMoneyRow("DP (Uang Muka)", item['dp_bayar']),
                                        const Divider(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text("Sisa Pembayaran", style: TextStyle(fontSize: 13)),
                                            Text(
                                              CurrencyFormat.convertToIdr(sisa, 0),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                color: sisa > 0 ? Colors.red : Colors.green
                                              ),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // --- FOOTER: Status Badges & Actions ---
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Status Badges
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildBadge(statusSewa, _getStatusColor(statusSewa)),
                                          const SizedBox(height: 4),
                                          _buildBadge(
                                            statusBayar, 
                                            statusBayar == 'Lunas' ? Colors.green : Colors.orange
                                          ),
                                        ],
                                      ),

                                      // Action Buttons (Hanya muncul jika belum selesai/batal)
                                      if (statusSewa == 'Booking' || statusSewa == 'Berjalan')
                                        Row(
                                          children: [
                                            // Tombol Batal
                                            InkWell(
                                              onTap: () => _batalkanSewa(item['id_transaksi'], item['id_bus']),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                                child: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            
                                            // Tombol Selesai / Lunasi
                                            ElevatedButton(
                                              onPressed: () => _handleSelesai(item),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: sisa > 0 ? Colors.orange : Colors.green,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                sisa > 0 ? "Lunasi & Selesai" : "Selesai",
                                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyRow(String label, int value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            CurrencyFormat.convertToIdr(value, 0),
            style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5)
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
