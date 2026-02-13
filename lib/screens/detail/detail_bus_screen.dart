import 'dart:io';
import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/bus_model.dart';
import '../../models/user_model.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_format.dart';

class DetailBusScreen extends StatefulWidget {
  final BusModel bus;
  
  // Parameter Opsional (Hanya diisi jika akses dari Customer Home)
  final UserModel? user; 
  final DateTimeRange? initialDateRange;

  const DetailBusScreen({
    super.key, 
    required this.bus,
    this.user,
    this.initialDateRange,
  });

  @override
  State<DetailBusScreen> createState() => _DetailBusScreenState();
}

class _DetailBusScreenState extends State<DetailBusScreen> {
  // State untuk Tanggal & Biaya
  DateTimeRange? _selectedDateRange;
  int _totalHari = 0;
  int _totalBiaya = 0;
  int _dpWajib = 0; // Misal DP minimal 30%

  final TextEditingController _dpController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Jika ada tanggal dari Home, langsung pasang
    if (widget.initialDateRange != null) {
      _selectedDateRange = widget.initialDateRange;
      _hitungBiaya();
    }
  }

  // 1. Hitung Durasi & Biaya
  void _hitungBiaya() {
    if (_selectedDateRange != null) {
      setState(() {
        // +1 agar sewa hari yang sama dihitung 1 hari
        _totalHari = _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
        _totalBiaya = _totalHari * widget.bus.hargaSewa;
        _dpWajib = (_totalBiaya * 0.3).ceil(); // DP Min 30% (Contoh logic bisnis)
      });
    }
  }

  // 2. Pilih Tanggal (Jika user ingin ubah tanggal di halaman detail)
  void _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _hitungBiaya();
      });
    }
  }

  // 3. LOGIC UTAMA: PROSES BOOKING
  void _prosesBooking() async {
    // A. Validasi Input Dasar
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap pilih tanggal sewa!"), backgroundColor: Colors.red));
      return;
    }

    if (_dpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap masukkan nominal DP!"), backgroundColor: Colors.red));
      return;
    }

    int dpInput = int.tryParse(_dpController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    
    // Validasi Nominal DP (Opsional: Minimal 30% atau terserah)
    if (dpInput > _totalBiaya) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DP tidak boleh melebihi Total Biaya!"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isProcessing = true);

    // B. FORMAT TANGGAL SQL
    String tglMulai = _selectedDateRange!.start.toIso8601String();
    String tglSelesai = _selectedDateRange!.end.toIso8601String();

    // C. FINAL CHECK AVAILABILITY (PENTING!)
    // Mencegah "Race Condition": User A lihat kosong, tapi saat mau bayar, User B sudah duluan booking.
    bool isStillAvailable = await DatabaseHelper().checkAvailability(
      widget.bus.idBus!, 
      tglMulai, 
      tglSelesai
    );

    if (!isStillAvailable) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Gagal Booking"),
          content: const Text("Maaf, bus ini baru saja dibooking oleh orang lain untuk tanggal tersebut. Silakan pilih tanggal atau bus lain."),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
        )
      );
      return;
    }

    // D. AMBIL ID PELANGGAN
    // Kita butuh ID Pelanggan dari tabel 'pelanggan', bukan ID User dari tabel 'users'
    // Asumsi: widget.user tidak null karena tombol booking hanya muncul jika user ada
    final profil = await DatabaseHelper().getProfilPelanggan(widget.user!.idUser!);
    if (profil == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Profil pelanggan tidak ditemukan.")));
      setState(() => _isProcessing = false);
      return;
    }
    int idPelanggan = profil['id_pelanggan'];

    // E. SIMPAN TRANSAKSI
    int sisa = _totalBiaya - dpInput;
    
    Map<String, dynamic> transaksiBaru = {
      'id_bus': widget.bus.idBus,
      'id_pelanggan': idPelanggan,
      'id_user': widget.user!.idUser, // User yang melakukan input
      'tgl_sewa': tglMulai,
      'tgl_kembali': tglSelesai,
      'total_hari': _totalHari,
      'total_biaya': _totalBiaya,
      'denda': 0,
      'dp_bayar': dpInput,
      'sisa_bayar': sisa,
      'status_pembayaran': sisa <= 0 ? 'Lunas' : 'Belum Lunas',
      'status_sewa': 'Booking', // Status awal
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await DatabaseHelper().insertTransaksi(transaksiBaru);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // F. SUKSES & NAVIGASI
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Booking Berhasil!"),
          content: const Text("Pesanan Anda telah tercatat. Silakan cek menu Riwayat."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Tutup Dialog
                Navigator.pop(context); // Tutup Detail Screen
                // User kembali ke Home Screen
              }, 
              child: const Text("OK")
            ),
          ],
        )
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal Simpan: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // LOGIKA GAMBAR DEFAULT
    final List<String> defaultImages = [
      'assets/images/bus1.jpg',
      'assets/images/bus2.jpg',
      'assets/images/bus3.jpg',
      'assets/images/bus4.jpg',
      'assets/images/bus5.jpg',
      'assets/images/bus6.jpg',
      'assets/images/bus7.jpg',
      'assets/images/bus8.jpg',
      'assets/images/bus9.jpg',
      'assets/images/bus10.jpg',
    ];

    int imageIndex = (widget.bus.idBus ?? 0) % defaultImages.length;
    String assetImage = defaultImages[imageIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bus.namaBus),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. KONTEN SCROLLABLE (Gambar & Info)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER GAMBAR
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: widget.bus.foto.isNotEmpty && File(widget.bus.foto).existsSync()
                      ? Image.file(File(widget.bus.foto), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(assetImage, fit: BoxFit.cover))
                      : Image.asset(assetImage, fit: BoxFit.cover),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HARGA & STATUS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              CurrencyFormat.convertToIdr(widget.bus.hargaSewa, 0),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(widget.bus.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _getStatusColor(widget.bus.status)),
                              ),
                              child: Text(
                                widget.bus.status.toUpperCase(),
                                style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(widget.bus.status)),
                              ),
                            )
                          ],
                        ),
                        const Text("/hari", style: TextStyle(color: Colors.grey)),
                        
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        // INFO GRID
                        Row(
                          children: [
                            _buildInfoItem(Icons.confirmation_number, "Plat Nomor", widget.bus.platNomor),
                            _buildInfoItem(Icons.event_seat, "Kapasitas", "${widget.bus.kapasitas} Seat"),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        const Text("Fasilitas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(widget.bus.fasilitas.isEmpty ? "-" : widget.bus.fasilitas, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                        ),

                        const SizedBox(height: 20),
                        const Text("Deskripsi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          widget.bus.deskripsi.isEmpty ? "Tidak ada deskripsi tambahan." : widget.bus.deskripsi,
                          style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                        ),
                        
                        const Divider(height: 40),

                        // --- BAGIAN FORM BOOKING (KHUSUS PELANGGAN) ---
                        if (widget.user != null && widget.user!.role == 'pelanggan') ...[
                          const Text("Rencana Sewa:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 10),
                          
                          // Pilih Tanggal
                          InkWell(
                            onTap: _pickDateRange,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDateRange == null 
                                      ? "Pilih Tanggal Sewa..." 
                                      : "${DateHelper.formatShort(_selectedDateRange!.start.toString())} - ${DateHelper.formatShort(_selectedDateRange!.end.toString())}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Icon(Icons.calendar_month, color: Colors.blueAccent),
                                ],
                              ),
                            ),
                          ),

                          if (_totalHari > 0) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                children: [
                                  _rowInfo("Total Hari", "$_totalHari Hari"),
                                  const SizedBox(height: 8),
                                  _rowInfo("Total Biaya", CurrencyFormat.convertToIdr(_totalBiaya, 0), isBold: true),
                                  const Divider(),
                                  TextField(
                                    controller: _dpController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Masukkan DP (Wajib)",
                                      prefixText: "Rp ",
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("Min. DP 30% disarankan: ${CurrencyFormat.convertToIdr(_dpWajib, 0)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. TOMBOL AKSI BAWAH (Sticky)
          if (widget.user != null && widget.user!.role == 'pelanggan')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _prosesBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("KONFIRMASI BOOKING", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value, 
          style: TextStyle(
            fontSize: isBold ? 18 : 14, 
            fontWeight: FontWeight.bold, 
            color: isBold ? Colors.blueAccent : Colors.black
          )
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tersedia': return Colors.blue;
      case 'Disewa': return Colors.orange;
      case 'Bengkel': return Colors.red;
      default: return Colors.grey;
    }
  }
}
