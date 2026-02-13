import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/manage_bus_screen.dart';
import '../screens/admin/manage_pelanggan_screen.dart';
import '../screens/admin/entry_sewa_screen.dart';
import '../screens/laporan/laporan_screen.dart'; 

class AdminDrawer extends StatelessWidget {
  final UserModel user;

  const AdminDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // --- HEADER PROFIL ADMIN ---
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueAccent),
            accountName: Text(
              user.username.toUpperCase(), 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            accountEmail: Text(
              "Role: ${user.role.toUpperCase()}",
              style: const TextStyle(color: Colors.white70)
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.username[0].toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
          ),
          
          // --- MENU ITEMS ---
          _buildMenuItem(
            context, 
            icon: Icons.dashboard, 
            title: "Dashboard", 
            onTap: () => Navigator.pop(context) // Tutup drawer aja
          ),
          
          _buildMenuItem(
            context, 
            icon: Icons.directions_bus, 
            title: "Kelola Bus", 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBusScreen()));
            }
          ),

          _buildMenuItem(
            context, 
            icon: Icons.people, 
            title: "Kelola Pelanggan", 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePelangganScreen()));
            }
          ),

          const Divider(),

          _buildMenuItem(
            context, 
            icon: Icons.add_circle_outline, 
            title: "Input Sewa Baru", 
            onTap: () {
              Navigator.pop(context);
              // PENTING: Kirim data admin (user) ke layar entry sewa
              Navigator.push(context, MaterialPageRoute(builder: (_) => EntrySewaScreen(user: user)));
            }
          ),

          _buildMenuItem(
            context, 
            icon: Icons.receipt_long, 
            title: "Laporan & Riwayat", 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanScreen()));
            }
          ),

          const Spacer(), 
          const Divider(),

          // --- LOGOUT ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Keluar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              // Hapus semua stack navigasi dan kembali ke Login
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen()), 
                (route) => false
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
