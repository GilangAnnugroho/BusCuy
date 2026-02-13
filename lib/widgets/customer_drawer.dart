import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/customer/customer_home_screen.dart';
import '../screens/customer/customer_history_screen.dart';

class CustomerDrawer extends StatelessWidget {
  final UserModel user;

  const CustomerDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // --- HEADER PROFIL PELANGGAN ---
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              image: DecorationImage(
                image: AssetImage('assets/images/bus1.jpg'), // Optional: Background header
                fit: BoxFit.cover,
                opacity: 0.2, // Agar teks tetap terbaca
              ),
            ),
            accountName: Text(
              user.username.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Row(
              children: [
                Icon(Icons.verified_user, size: 14, color: Colors.lightGreenAccent),
                SizedBox(width: 4),
                Text("Member Verified", style: TextStyle(color: Colors.white70)),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : "U",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
          ),

          // --- MENU ITEMS ---
          
          // 1. Beranda (Katalog Bus)
          _buildMenuItem(
            context,
            icon: Icons.directions_bus_filled,
            title: "Cari Bus",
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              // Gunakan pushReplacement agar tidak menumpuk halaman Home
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => CustomerHomeScreen(user: user))
              );
            },
          ),

          // 2. Riwayat Pesanan
          _buildMenuItem(
            context,
            icon: Icons.history,
            title: "Riwayat Pesanan Saya",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => CustomerHistoryScreen(user: user))
              );
            },
          ),

          // 3. Bantuan (Dummy / Static)
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: "Pusat Bantuan",
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Hubungi Admin: 0812-3456-7890 (WhatsApp)"))
              );
            },
          ),

          const Spacer(),
          const Divider(),

          // --- LOGOUT ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Keluar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              // Hapus sesi dan kembali ke Login
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen()), 
                (route) => false
              );
            },
          ),
          
          const SizedBox(height: 10),
          const Text(
            "Versi Aplikasi 1.0.0",
            style: TextStyle(color: Colors.grey, fontSize: 10),
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
