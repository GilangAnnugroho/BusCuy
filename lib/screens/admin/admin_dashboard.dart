import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_drawer.dart';

// --- IMPORT MENU ADMIN (Satu Folder) ---
import 'manage_bus_screen.dart';
import 'manage_pelanggan_screen.dart';
import 'entry_sewa_screen.dart';

// --- IMPORT LAPORAN (Beda Folder, harus keluar satu level) ---
import '../laporan/laporan_screen.dart'; 

class AdminDashboard extends StatefulWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      drawer: AdminDrawer(user: widget.user),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Sapaan
            Text(
              "Halo, ${widget.user.username}!", 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const Text(
              "Selamat bekerja, semoga hari ini lancar.", 
              style: TextStyle(color: Colors.grey)
            ),
            
            const SizedBox(height: 30),
            
            // Menu Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildCardMenu(
                  Icons.directions_bus, 
                  "Data Bus", 
                  Colors.orange, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBusScreen()))
                ),
                _buildCardMenu(
                  Icons.people, 
                  "Pelanggan", 
                  Colors.blue, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePelangganScreen()))
                ),
                _buildCardMenu(
                  Icons.add_circle, 
                  "Sewa Baru", 
                  Colors.green, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EntrySewaScreen()))
                ),
                _buildCardMenu(
                  Icons.receipt, 
                  "Laporan", 
                  Colors.purple, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanScreen()))
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardMenu(IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
