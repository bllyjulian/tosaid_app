import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Import Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // 2. Import Database
import 'package:google_sign_in/google_sign_in.dart'; // 3. Import Google Sign In
import 'halaman_login.dart';

class HalamanProfilPage extends StatefulWidget {
  const HalamanProfilPage({super.key});

  @override
  State<HalamanProfilPage> createState() => _HalamanProfilPageState();
}

class _HalamanProfilPageState extends State<HalamanProfilPage> {
  bool notifikasiAktif = true;

  // Variabel untuk menampung data user
  String _namaLengkap = "Memuat...";
  String _emailUser = "Memuat...";

  @override
  void initState() {
    super.initState();
    _ambilDataProfil(); // Ambil data saat halaman dibuka
  }

  // --- FUNGSI AMBIL DATA USER DARI FIREBASE ---
  void _ambilDataProfil() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 1. Set Email langsung dari Auth
      setState(() {
        _emailUser = user.email ?? "-";
      });

      try {
        // 2. Ambil Nama dari Firestore (karena nama di Auth kadang kosong kalau daftar via Email biasa)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _namaLengkap = userDoc.get('nama');
          });
        } else {
          // Fallback kalau data di database belum ada, ambil dari Display Name Auth
          setState(() {
            _namaLengkap = user.displayName ?? "User TOSA";
          });
        }
      } catch (e) {
        setState(() => _namaLengkap = "User");
      }
    }
  }

  // --- FUNGSI LOGOUT (GOOGLE + FIREBASE) ---
  void _tampilDialogLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah kamu yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Batal
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog dulu

              // 1. Logout dari Google (PENTING: Supaya pas login lagi dia nanya akun)
              await GoogleSignIn().signOut();

              // 2. Logout dari Firebase
              await FirebaseAuth.instance.signOut();

              // 3. Kembali ke Halaman Login & Hapus semua history
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Profil Saya",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings, color: Colors.black))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. HEADER PROFIL (FOTO & NAMA DINAMIS)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.blue.shade100, width: 4),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage(
                              'assets/images/profil.png'), // Pastikan gambar ada
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- NAMA USER (DINAMIS) ---
                  Text(_namaLengkap,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 4),

                  // --- EMAIL USER (DINAMIS) ---
                  Text(_emailUser, style: const TextStyle(color: Colors.grey)),

                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Level 2 - Mubtadi",
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. MENU PENGATURAN (AKUN)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Akun",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey)),
              ),
            ),

            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuTile(
                      icon: Icons.person_outline,
                      title: "Edit Profil",
                      onTap: () {}),
                  _buildDivider(),
                  _buildMenuTile(
                      icon: Icons.lock_outline,
                      title: "Ganti Password",
                      onTap: () {}),
                  _buildDivider(),
                  _buildMenuTile(
                      icon: Icons.language,
                      title: "Bahasa Aplikasi",
                      trailingText: "Indonesia",
                      onTap: () {}),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. MENU PENGATURAN (LAINNYA)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Lainnya",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey)),
              ),
            ),

            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Switch Notifikasi
                  SwitchListTile(
                    value: notifikasiAktif,
                    onChanged: (val) {
                      setState(() {
                        notifikasiAktif = val;
                      });
                    },
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.notifications_none,
                          color: Colors.orange),
                    ),
                    title: const Text("Notifikasi",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    activeColor: Colors.blue,
                  ),
                  _buildDivider(),
                  _buildMenuTile(
                      icon: Icons.help_outline,
                      title: "Pusat Bantuan",
                      onTap: () {}),
                  _buildDivider(),
                  _buildMenuTile(
                      icon: Icons.info_outline,
                      title: "Tentang Aplikasi",
                      onTap: () {}),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. TOMBOL LOGOUT (PANGGIL FUNGSI LOGOUT YANG BARU)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _tampilDialogLogout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Keluar Akun",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // WIDGET HELPER: ITEM MENU
  Widget _buildMenuTile(
      {required IconData icon,
      required String title,
      VoidCallback? onTap,
      String? trailingText}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trailingText != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(trailingText,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey),
              ],
            )
          : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  // WIDGET HELPER: GARIS PEMISAH
  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 70);
  }
}
