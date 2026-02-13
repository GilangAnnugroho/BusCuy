import 'dart:io';
import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../utils/currency_format.dart';

class BusCard extends StatelessWidget {
  final BusModel bus;
  // Callback dibuat nullable (?) agar fleksibel
  final VoidCallback? onEdit; 
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  const BusCard({
    super.key,
    required this.bus,
    this.onEdit,
    this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. DAFTAR 10 GAMBAR DARI ASSETS (Fallback Images)
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

    // 2. PILIH GAMBAR BERDASARKAN ID BUS
    int imageIndex = (bus.idBus ?? 0) % defaultImages.length;
    String assetImage = defaultImages[imageIndex];

    // 3. LOGIKA WARNA & STATE
    bool isLocked = bus.status == 'Disewa'; // Cek apakah sedang disewa

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FOTO BUS ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: bus.foto.isNotEmpty && File(bus.foto).existsSync()
                    ? Image.file(
                        File(bus.foto),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(assetImage, fit: BoxFit.cover),
                      )
                    : Image.asset(
                        assetImage,
                        fit: BoxFit.cover,
                      ),
              ),
            ),

            // --- INFO BUS ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bus.namaBus,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Badge Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(bus.status),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          bus.status.toUpperCase(), 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Plat: ${bus.platNomor} • ${bus.kapasitas} Seat", style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(
                    "${CurrencyFormat.convertToIdr(bus.hargaSewa, 0)} /hari",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  
                  const Divider(),
                  
                  // --- TOMBOL AKSI (Edit & Hapus) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indikator visual jika terkunci
                      if (isLocked)
                        const Row(
                          children: [
                            Icon(Icons.lock, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text("Sedang Jalan", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        )
                      else 
                        const SizedBox(), // Spacer kosong

                      Row(
                        children: [
                          TextButton.icon(
                            icon: Icon(Icons.edit, size: 18, color: isLocked ? Colors.grey : Colors.blueAccent),
                            label: Text("Edit", style: TextStyle(color: isLocked ? Colors.grey : Colors.blueAccent)),
                            onPressed: onEdit, // Fungsi tetap dipanggil (untuk show snackbar)
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.delete, size: 18, color: isLocked ? Colors.grey : Colors.red),
                            label: Text("Hapus", style: TextStyle(color: isLocked ? Colors.grey : Colors.red)),
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Warna Status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tersedia': return Colors.green;
      case 'Disewa': return Colors.blueAccent; // Biru untuk menandakan sedang aktif
      case 'Bengkel': return Colors.red;
      default: return Colors.grey;
    }
  }
}
