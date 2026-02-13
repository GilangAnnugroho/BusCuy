import 'dart:io';
import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/bus_model.dart';
import '../../models/user_model.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_format.dart';
import '../auth/login_screen.dart';
import '../detail/detail_bus_screen.dart'; 
import 'customer_history_screen.dart'; 

class CustomerHomeScreen extends StatefulWidget {
  final UserModel user;
  const CustomerHomeScreen({super.key, required this.user});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<BusModel> _listBus = [];
  bool _isLoading = true;
  
  // Filter Tanggal (Penting untuk Cek Ketersediaan)
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadBusData();
  }

  // --- LOGIC UTAMA: LOAD & FILTER BUS ---
  void _loadBusData() async {
    setState(() => _isLoading = true);

    // 1. Ambil Bus yang status fisiknya 'Tersedia' (Bukan Bengkel/Disewa Kontrak)
    // Bus yang sedang jalan (status 'Disewa' di tabel bus) tidak akan muncul.
    final data = await DatabaseHelper().getBusTersedia();
    List<BusModel> allBus = data.map((item) => BusModel.fromMap(item)).toList();
    List<BusModel> availableBus = [];

    // 2. LOGIC FILTER ANTI BENTROK (Sesuai Permintaan)
    // Jika User sudah pilih tanggal, sistem wajib mengecek jadwal di tabel transaksi
    if (_selectedDateRange != null) {
      String tglMulai = _selectedDateRange!.start.toIso8601String();
      String tglSelesai = _selectedDateRange!.end.toIso8601String();

      for (var bus in allBus) {
        // Cek ke tabel transaksi: Apakah bus ini kosong di tanggal tersebut?
        // Menggunakan logic irisan tanggal yang sudah kita perbaiki di db_helper
        bool isAvailable = await DatabaseHelper().checkAvailability(
          bus.idBus!, 
          tglMulai, 
          tglSelesai
        );

        if (isAvailable) {
          availableBus.add(bus);
        }
      }
    } else {
      // Jika belum pilih tanggal, tampilkan semua bus 'Tersedia' agar user bisa lihat katalog
      // Tapi saat mau booking nanti, tanggal tetap harus dipilih
      availableBus = allBus;
    }

    if (!mounted) return;
    setState(() {
      _listBus = availableBus;
      _isLoading = false;
    });
  }

  // Fungsi Pilih Tanggal
  void _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blueAccent,
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      }
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      // PENTING: Reload data untuk memfilter ulang bus yang bentrok di tanggal baru ini
      _loadBusData();
    }
  }

  // Fungsi Logout
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => const LoginScreen()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rental Bus Pariwisata"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          // Tombol Riwayat
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Riwayat Pesanan",
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerHistoryScreen(user: widget.user)));
            },
          ),
          // Tombol Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Keluar",
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- HEADER: WELCOME & FILTER TANGGAL ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, ${widget.user.username}!",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  "Mau pergi kemana hari ini?",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                
                // Card Pilih Tanggal
                InkWell(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedDateRange == null 
                              ? "Pilih Tanggal Sewa (Cek Ketersediaan)" 
                              : "${DateHelper.formatShort(_selectedDateRange!.start.toIso8601String())} - ${DateHelper.formatShort(_selectedDateRange!.end.toIso8601String())}",
                            style: TextStyle(
                              color: _selectedDateRange == null ? Colors.grey : Colors.black87,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                        if (_selectedDateRange != null)
                          const Icon(Icons.check_circle, color: Colors.green)
                      ],
                    ),
                  ),
                ),
                if (_selectedDateRange == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0, left: 4),
                    child: Text(
                      "*Pilih tanggal dulu untuk memfilter bus yang available",
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),

          // --- BODY: LIST BUS ---
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _listBus.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bus_alert, size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                          _selectedDateRange == null 
                            ? "Tidak ada armada yang aktif."
                            : "Yah, semua bus penuh di tanggal ini.\nCoba ganti tanggal lain.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _listBus.length,
                    itemBuilder: (context, index) {
                      final item = _listBus[index];
                      return _buildCustomerBusCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget Card Khusus Customer
  Widget _buildCustomerBusCard(BusModel bus) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigasi ke Detail (Bawa User dan Tanggal yang dipilih)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailBusScreen(
                bus: bus, 
                user: widget.user, // Kirim data user untuk mode Booking
                initialDateRange: _selectedDateRange, // Kirim tanggal yg sudah dipilih
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Foto Bus
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: bus.foto.isNotEmpty
                    ? Image.file(File(bus.foto), fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey))
                    : const Icon(Icons.directions_bus, size: 60, color: Colors.blueAccent),
              ),
            ),
            
            // 2. Info Bus
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bus.namaBus,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          "${bus.kapasitas} Seat",
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormat.convertToIdr(bus.hargaSewa, 0),
                    style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Expanded(child: Text(bus.fasilitas, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Aksi Booking (Sama dengan onTap Card)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailBusScreen(
                              bus: bus, 
                              user: widget.user,
                              initialDateRange: _selectedDateRange,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text("BOOKING SEKARANG", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
