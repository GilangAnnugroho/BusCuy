import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../database/db_helper.dart';
import '../../models/bus_model.dart';
import '../../widgets/bus_card.dart';
import '../detail/detail_bus_screen.dart'; 

class ManageBusScreen extends StatefulWidget {
  const ManageBusScreen({super.key});

  @override
  State<ManageBusScreen> createState() => _ManageBusScreenState();
}

class _ManageBusScreenState extends State<ManageBusScreen> {
  List<BusModel> _listBus = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final data = await DatabaseHelper().getBus();
    if (mounted) {
      setState(() {
        _listBus = data.map((item) => BusModel.fromMap(item)).toList();
        _isLoading = false;
      });
    }
  }

  // --- LOGIC BARU: CEK SEBELUM EDIT ---
  void _handleEditCheck(BusModel bus) async {
    // Jika statusnya 'Disewa', kita cek validitasnya ke tabel transaksi
    if (bus.status == 'Disewa') {
      bool isReallyRented = await DatabaseHelper().checkActiveTransaction(bus.idBus!);
      
      if (isReallyRented) {
        // SKENARIO 1: Ada Transaksi Asli -> TOLAK EDIT
        if (!mounted) return;
        _showLockedAlert(isTransactionActive: true);
      } else {
        // SKENARIO 2: Tidak ada Transaksi (Status Stuck/Error) -> IZINKAN EDIT
        if (!mounted) return;
        _showForm(bus: bus); 
      }
    } else {
      // Jika status 'Tersedia' atau 'Bengkel' -> Langsung Buka Form
      _showForm(bus: bus);
    }
  }

  void _deleteBus(int id) async {
    // Tambahan pengaman delete juga
    bool isReallyRented = await DatabaseHelper().checkActiveTransaction(id);
    if (isReallyRented) {
      if (!mounted) return;
      _showLockedAlert(isTransactionActive: true);
      return;
    }

    await DatabaseHelper().deleteBus(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bus berhasil dihapus")));
    _refreshData();
  }

  void _showForm({BusModel? bus}) {
    final nameController = TextEditingController(text: bus?.namaBus ?? '');
    final platController = TextEditingController(text: bus?.platNomor ?? '');
    final seatController = TextEditingController(text: bus?.kapasitas.toString() ?? '');
    final priceController = TextEditingController(text: bus?.hargaSewa.toString() ?? '');
    final descController = TextEditingController(text: bus?.deskripsi ?? '');
    final facilityController = TextEditingController(text: bus?.fasilitas ?? '');
    
    // Auto-Reset: Jika masuk sini dan status 'Disewa', berarti itu stuck data. Reset ke 'Tersedia'.
    String status = (bus?.status == 'Disewa') ? 'Tersedia' : (bus?.status ?? 'Tersedia');
    
    String? imagePath = bus?.foto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 16
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(bus == null ? "Tambah Bus Baru" : "Edit Bus", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    GestureDetector(
                      onTap: () async {
                        final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
                        if (photo != null) {
                          setStateModal(() => imagePath = photo.path);
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: imagePath != null && imagePath!.isNotEmpty
                          ? (imagePath!.contains('assets/') 
                              ? Image.asset(imagePath!, fit: BoxFit.cover) // Handle Asset
                              : Image.file(File(imagePath!), fit: BoxFit.cover)) // Handle File Kamera/Galeri
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.add_a_photo, size: 40), Text("Tap untuk Upload Foto")],
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Bus (Cth: Jetbus 3)")),
                    TextField(controller: platController, decoration: const InputDecoration(labelText: "Plat Nomor")),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: seatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Kapasitas (Seat)"))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Harga Sewa (Rp)"))),
                      ],
                    ),
                    TextField(controller: facilityController, decoration: const InputDecoration(labelText: "Fasilitas (AC, Wifi, dll)")),
                    TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: "Deskripsi Singkat")),
                    
                    const SizedBox(height: 10),
                    
                    InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Status Armada (Manual)",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: status,
                              isExpanded: true,
                              items: ['Tersedia', 'Bengkel'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (val) {
                                setStateModal(() => status = val!);
                              },
                            ),
                          ),
                        ),
                    
                    if (bus?.status == 'Disewa')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        color: Colors.orange.shade100,
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.orange),
                            SizedBox(width: 5),
                            Expanded(child: Text("Status 'Disewa' terdeteksi error (tanpa transaksi). Silakan simpan untuk reset ke 'Tersedia'.", style: TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
                      onPressed: () async {
                        if (nameController.text.isEmpty || priceController.text.isEmpty) return;

                        final data = {
                          'nama_bus': nameController.text,
                          'plat_nomor': platController.text,
                          'kapasitas': int.tryParse(seatController.text) ?? 0,
                          'harga_sewa': int.tryParse(priceController.text) ?? 0,
                          'status': status,
                          'deskripsi': descController.text,
                          'fasilitas': facilityController.text,
                          'foto': imagePath ?? ''
                        };

                        if (bus == null) {
                          await DatabaseHelper().insertBus(data);
                        } else {
                          await DatabaseHelper().updateBus(bus.idBus!, data);
                        }

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _refreshData();
                      },
                      child: Text(bus == null ? "SIMPAN BUS" : "UPDATE BUS", style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // --- BAGIAN SEED 10 DATA DUMMY ---
  void _seedData() async {
    final List<Map<String, dynamic>> dummyData = [
      {
        'nama_bus': 'Jetbus 3+ Voyager (Luxury)',
        'plat_nomor': 'B 7001 TAA',
        'kapasitas': 50,
        'harga_sewa': 3500000,
        'status': 'Tersedia',
        'deskripsi': 'Bus Pariwisata Luxury dengan suspensi udara yang nyaman untuk perjalanan jauh.',
        'fasilitas': 'AC, Toilet, Wifi, Karaoke, Selimut, Bantal',
        'foto': 'assets/images/bus1.jpg'
      },
      {
        'nama_bus': 'Legacy SR2 HDD Prime',
        'plat_nomor': 'D 7200 XA',
        'kapasitas': 47,
        'harga_sewa': 3200000,
        'status': 'Tersedia',
        'deskripsi': 'Bus High Deck dengan pandangan luas dan bagasi lapang.',
        'fasilitas': 'AC, TV LED 32 Inch, Audio System, Reclining Seat',
        'foto': 'assets/images/bus2.jpg'
      },
      {
        'nama_bus': 'Avante H9 Priority',
        'plat_nomor': 'AB 8888 XY',
        'kapasitas': 40,
        'harga_sewa': 4500000,
        'status': 'Tersedia',
        'deskripsi': 'Bus Super Executive dengan Legrest di setiap kursi.',
        'fasilitas': 'Toilet, Legrest, Snack, Coolbox, USB Charger',
        'foto': 'assets/images/bus3.jpg'
      },
      {
        'nama_bus': 'Jetbus 3+ SDD (Double Decker)',
        'plat_nomor': 'K 9999 ZZ',
        'kapasitas': 30,
        'harga_sewa': 6000000,
        'status': 'Tersedia',
        'deskripsi': 'Bus Tingkat Premium untuk pengalaman wisata tak terlupakan.',
        'fasilitas': 'Sleeper Seat, Mini Bar, Toilet Premium, VOD',
        'foto': 'assets/images/bus4.jpg'
      },
      {
        'nama_bus': 'Tourista Medium Bus',
        'plat_nomor': 'F 3030 BB',
        'kapasitas': 31,
        'harga_sewa': 1800000,
        'status': 'Tersedia',
        'deskripsi': 'Bus medium lincah cocok untuk rombongan keluarga atau kantor kecil.',
        'fasilitas': 'AC, Karaoke, Reclining Seat',
        'foto': 'assets/images/bus5.jpg'
      },
      {
        'nama_bus': 'Toyota HiAce Commuter',
        'plat_nomor': 'D 5678 EF',
        'kapasitas': 15,
        'harga_sewa': 1100000,
        'status': 'Tersedia',
        'deskripsi': 'Minibus nyaman untuk travel atau wisata kota.',
        'fasilitas': 'AC Dingin, Audio, Charger',
        'foto': 'assets/images/bus6.jpg'
      },
      {
        'nama_bus': 'Isuzu Elf Long Giga',
        'plat_nomor': 'B 1234 CD',
        'kapasitas': 19,
        'harga_sewa': 1300000,
        'status': 'Tersedia',
        'deskripsi': 'Microbus long chassis dengan kapasitas muat banyak.',
        'fasilitas': 'AC Ducting, TV, Audio',
        'foto': 'assets/images/bus7.jpg'
      },
      {
        'nama_bus': 'Mercedes-Benz OH 1626',
        'plat_nomor': 'AD 4545 JK',
        'kapasitas': 59,
        'harga_sewa': 2800000,
        'status': 'Tersedia',
        'deskripsi': 'Big Bus konfigurasi 2-3 untuk kapasitas maksimal (Ekonomi/Pelajar).',
        'fasilitas': 'AC, TV, Mic Karaoke',
        'foto': 'assets/images/bus8.jpg'
      },
      {
        'nama_bus': 'Hino RK8 R260',
        'plat_nomor': 'B 4321 GH',
        'kapasitas': 50,
        'harga_sewa': 2500000,
        'status': 'Tersedia',
        'deskripsi': 'Bus tangguh mesin Hino, handal di segala medan wisata.',
        'fasilitas': 'AC, Bagasi Luas, Standard Tourism',
        'foto': 'assets/images/bus9.jpg'
      },
      {
        'nama_bus': 'Scania K410IB Opticruise',
        'plat_nomor': 'H 1111 LL',
        'kapasitas': 24,
        'harga_sewa': 5500000,
        'status': 'Tersedia',
        'deskripsi': 'Bus Super Luxury konfigurasi 1-1-1 (Social Distancing).',
        'fasilitas': 'Electric Seat, Massage Chair, Private TV, Meal Service',
        'foto': 'assets/images/bus10.jpg'
      },
    ];

    for (var bus in dummyData) {
      try {
        await DatabaseHelper().insertBus(bus);
      } catch (e) {
        // Abaikan jika duplikat
      }
    }
    
    _refreshData();
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("10 Data Bus Berhasil Ditambahkan!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Armada Bus"), 
        backgroundColor: Colors.blueAccent, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: "Isi Data Dummy (Reset)",
            onPressed: _seedData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listBus.isEmpty
              ? const Center(child: Text("Belum ada data bus. Klik ikon awan di pojok kanan atas."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _listBus.length,
                  itemBuilder: (context, index) {
                    final item = _listBus[index];
                    
                    return BusCard(
                      bus: item,
                      // PANGGIL LOGIC VALIDASI SEBELUM BUKA FORM
                      onEdit: () => _handleEditCheck(item),
                      
                      // HAPUS JUGA CEK DATABASE DULU
                      onDelete: () => _deleteBus(item.idBus!),
                      
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailBusScreen(bus: item)));
                      },
                    );
                  },
                ),
    );
  }

  void _showLockedAlert({required bool isTransactionActive}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(isTransactionActive
                ? "GAGAL: Bus sedang ada transaksi aktif (Disewa/Booking). Selesaikan dulu di menu Laporan."
                : "Akses Ditolak."
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
