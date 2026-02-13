import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/bus_model.dart';
import '../../models/pelanggan_model.dart';
import '../../models/user_model.dart'; // Import Model User
import '../../utils/currency_format.dart';
import '../../utils/date_format.dart';

class EntrySewaScreen extends StatefulWidget {
  // Menerima data Admin yang sedang login (Opsional, jika null pakai default ID 1)
  final UserModel? user; 

  const EntrySewaScreen({super.key, this.user});

  @override
  State<EntrySewaScreen> createState() => _EntrySewaScreenState();
}

class _EntrySewaScreenState extends State<EntrySewaScreen> {
  // Variabel Data
  List<BusModel> _listBus = []; 
  List<PelangganModel> _listPelanggan = [];

  // Variabel Pilihan User
  int? _selectedBusId;
  int? _selectedPelangganId;
  DateTimeRange? _selectedDateRange;

  // Variabel Hitungan
  int _totalHari = 0;
  int _hargaPerHari = 0;
  int _totalBiaya = 0;
  int _sisaBayar = 0;

  // Controller & Loading
  final TextEditingController _dpController = TextEditingController();
  bool _isLoading = true;
  bool _isChecking = false; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 1. Ambil Data Bus & Pelanggan
  void _loadData() async {
    final db = DatabaseHelper();
    
    final dataBus = await db.getBusTersedia(); 
    final dataPelanggan = await db.getPelanggan();

    if (!mounted) return;

    setState(() {
      _listBus = dataBus.map((e) => BusModel.fromMap(e)).toList();
      _listPelanggan = dataPelanggan.map((e) => PelangganModel.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  // 2. Fungsi Pilih Tanggal
  void _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blueAccent,
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _totalHari = picked.end.difference(picked.start).inDays + 1;
        _hitungTotal();
      });

      if (_selectedBusId != null) {
        _checkBusAvailability(_selectedBusId!);
      }
    }
  }

  // 3. Logic Cek Ketersediaan Bus
  Future<void> _checkBusAvailability(int busId) async {
    if (_selectedDateRange == null) return;

    setState(() => _isChecking = true);

    String start = _selectedDateRange!.start.toIso8601String();
    String end = _selectedDateRange!.end.toIso8601String();

    bool isAvailable = await DatabaseHelper().checkAvailability(busId, start, end);

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Bus SUDAH DIBOOKING pada tanggal ini! Silakan pilih bus lain atau ganti tanggal."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        )
      );

      setState(() {
        _selectedBusId = null;
        _hargaPerHari = 0;
        _hitungTotal();
      });
    }
  }

  // 4. Rumus Hitung Duit
  void _hitungTotal() {
    setState(() {
      _totalBiaya = _totalHari * _hargaPerHari;
      String cleanDp = _dpController.text.replaceAll(RegExp(r'[^0-9]'), '');
      int dp = int.tryParse(cleanDp) ?? 0;
      _sisaBayar = _totalBiaya - dp;
    });
  }

  // 5. PROSES SIMPAN TRANSAKSI
  void _prosesSewa() async {
    if (_selectedBusId == null || _selectedPelangganId == null || _selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi semua data!"), backgroundColor: Colors.red),
      );
      return;
    }

    String start = _selectedDateRange!.start.toIso8601String();
    String end = _selectedDateRange!.end.toIso8601String();
    bool isAvailable = await DatabaseHelper().checkAvailability(_selectedBusId!, start, end);
    
    // PERBAIKAN: Cek mounted setelah await
    if (!mounted) return;

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("GAGAL: Bus bentrok dengan jadwal lain!"), backgroundColor: Colors.red),
      );
      return;
    }

    int dp = int.tryParse(_dpController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    if (dp > _totalBiaya) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("DP tidak boleh lebih besar dari Total Biaya!"), backgroundColor: Colors.orange),
      );
      return;
    }

    String tglSewa = _selectedDateRange!.start.toIso8601String();
    String tglKembali = _selectedDateRange!.end.toIso8601String();

    try {
      await DatabaseHelper().insertTransaksi({
        'id_bus': _selectedBusId,
        'id_pelanggan': _selectedPelangganId,
        'id_user': widget.user?.idUser ?? 1,
        'tgl_sewa': tglSewa,
        'tgl_kembali': tglKembali,
        'total_hari': _totalHari,
        'total_biaya': _totalBiaya,
        'denda': 0,
        'dp_bayar': dp,
        'sisa_bayar': _sisaBayar,
        'status_pembayaran': _sisaBayar <= 0 ? 'Lunas' : 'Belum Lunas',
        'status_sewa': 'Booking',
        'created_at': DateTime.now().toIso8601String(),
      });

      // PERBAIKAN: Cek mounted setelah await
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Berhasil!"),
          content: const Text("Data sewa berhasil disimpan.\nJadwal bus telah diamankan."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      // PERBAIKAN: Cek mounted setelah await
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Sewa Baru (Manual)"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("1. Tanggal Sewa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _pickDateRange,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDateRange == null
                                        ? "Pilih Rentang Tanggal..."
                                        : "${DateHelper.formatShort(_selectedDateRange!.start.toString())} - ${DateHelper.formatShort(_selectedDateRange!.end.toString())}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Icon(Icons.calendar_month, color: Colors.blueAccent),
                                ],
                              ),
                            ),
                          ),
                          if (_totalHari > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text("Durasi: $_totalHari Hari", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("2. Data Penyewa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                            hint: const Text("Pilih Pelanggan"),
                            // PERBAIKAN: value diinisialisasi agar sinkron dengan state
                            initialValue: _selectedPelangganId,
                            items: _listPelanggan.map((pelanggan) {
                              return DropdownMenuItem(
                                value: pelanggan.idPelanggan,
                                child: Text(pelanggan.namaLengkap),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedPelangganId = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("3. Pilih Armada", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          if (_listBus.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              // PERBAIKAN: Menggunakan withValues (Standar baru Flutter)
                              color: Colors.orange.withValues(alpha: 0.1),
                              child: const Text("Tidak ada bus yang tersedia."),
                            )
                          else
                            _isChecking 
                              ? const LinearProgressIndicator()
                              : DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  hint: const Text("Pilih Bus..."),
                                  initialValue: _selectedBusId,
                                  isExpanded: true,
                                  items: _listBus.map((bus) {
                                    return DropdownMenuItem(
                                      value: bus.idBus,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(bus.namaBus, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(CurrencyFormat.convertToIdr(bus.hargaSewa, 0), style: const TextStyle(fontSize: 12, color: Colors.green)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (_selectedDateRange == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Harap Pilih Tanggal Dulu!"), backgroundColor: Colors.orange));
                                      return; 
                                    }
                                    setState(() {
                                      _selectedBusId = val;
                                      final selectedBus = _listBus.firstWhere((b) => b.idBus == val);
                                      _hargaPerHari = selectedBus.hargaSewa;
                                      _hitungTotal();
                                    });
                                    _checkBusAvailability(val!);
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      // PERBAIKAN: Menggunakan withValues
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text("Estimasi Total Biaya", style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(
                          CurrencyFormat.convertToIdr(_totalBiaya, 0),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        Text(
                          "($_totalHari Hari x ${CurrencyFormat.convertToIdr(_hargaPerHari, 0)})",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Divider(height: 30),
                        TextField(
                          controller: _dpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Input DP (Uang Muka)",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            prefixText: "Rp ",
                          ),
                          onChanged: (val) => _hitungTotal(),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              // PERBAIKAN: Menggunakan withValues
                              color: _sisaBayar > 0 ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Text(
                              _sisaBayar > 0 
                                ? "Sisa Pelunasan: ${CurrencyFormat.convertToIdr(_sisaBayar, 0)}"
                                : "STATUS: LUNAS",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _sisaBayar > 0 ? Colors.deepOrange : Colors.green.shade800
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _prosesSewa,
                    child: const Text(
                      "SIMPAN BOOKING",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
