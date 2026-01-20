import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:google_sign_in/google_sign_in.dart';
import 'halaman_login.dart';

class HalamanProfilPage extends StatefulWidget {
  const HalamanProfilPage({super.key});

  @override
  State<HalamanProfilPage> createState() => _HalamanProfilPageState();
}

class _HalamanProfilPageState extends State<HalamanProfilPage> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();

  String? _avatarPath; // Menyimpan path asset atau URL
  bool _isLoading = false;

  // --- DAFTAR 10 AVATAR (ASSET LOKAL) ---
  final List<String> _listAvatar = [
    'assets/ava/ava1.png',
    'assets/ava/ava2.png',
    'assets/ava/ava3.png',
    'assets/ava/ava4.png',
    'assets/ava/ava5.png',
    'assets/ava/ava6.png',
    'assets/ava/ava7.png',
    'assets/ava/ava8.png',
    'assets/ava/ava9.png',
    'assets/ava/ava10.png',
  ];

  @override
  void initState() {
    super.initState();
    _ambilDataProfil();
  }

  // --- 1. AMBIL DATA PROFIL (SUMBER UTAMA: FIREBASE) ---
  Future<void> _ambilDataProfil() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _emailController.text = user.email ?? "";

        // Ambil data detail dari Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _namaController.text = data['nama'] ?? user.displayName ?? "User";
            _avatarPath = data['avatar_url']; // Bisa URL http atau path asset
          });
        } else {
          // Jika user baru login pertama kali
          setState(() {
            _namaController.text = user.displayName ?? "User";
            _avatarPath = 'assets/ava/ava1.png'; // Default
          });
        }
      }
    } catch (e) {
      print("Error ambil profil: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIKA GANTI AVATAR (UPDATE FIREBASE & SUPABASE) ---
  Future<void> _simpanAvatarKeFirebase(String assetPath) async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // A. UPDATE KE FIREBASE (Untuk Halaman Ini & Home)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'avatar_url': assetPath}, SetOptions(merge: true));

      // B. UPDATE KE SUPABASE (Untuk Sinkronisasi Leaderboard)
      // Kita mencari user di Supabase yang ID-nya SAMA DENGAN UID Firebase
      try {
        await Supabase.instance.client
            .from(
                'profil_siswa') // GANTI dengan nama tabelmu: 'users' atau 'profil_siswa'
            .update({
          'avatar_url': assetPath,
          // 'nama': _namaController.text // Opsional: kalau mau update nama juga
        }).eq('id', user.uid); // Asumsi kolom ID di Supabase bernama 'id'
      } catch (e) {
        print("Gagal sync ke Supabase (Mungkin user belum tes): $e");
        // Kita biarkan error ini silent, karena prioritas profil Firebase sukses
      }

      // C. UPDATE TAMPILAN
      setState(() {
        _avatarPath = assetPath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Avatar berhasil diperbarui!")));
      }
    } catch (e) {
      print("Gagal ganti avatar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 3. LOGIKA TAMPILAN GAMBAR (PINTAR) ---
  ImageProvider _getAvatarImage() {
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      // Jika link internet (dari Google login lama)
      if (_avatarPath!.startsWith('http')) {
        return NetworkImage(_avatarPath!);
      }
      // Jika path asset lokal (Avatar pilihan)
      else {
        return AssetImage(_avatarPath!);
      }
    }
    // Default
    return const AssetImage('assets/ava/ava1.png');
  }

  // --- 4. TAMPILKAN MODAL PILIHAN ---
  void _tampilkanPilihanAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 380,
          child: Column(
            children: [
              const Text("Pilih Karakter Kamu",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, // 5 gambar per baris
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _listAvatar.length,
                  itemBuilder: (context, index) {
                    bool isSelected = _avatarPath == _listAvatar[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Tutup dulu
                        _simpanAvatarKeFirebase(
                            _listAvatar[index]); // Lalu simpan
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 3)),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(_listAvatar[index]),
                          backgroundColor: Colors.grey[100],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 5. SIMPAN NAMA (SYNC JUGA KE SUPABASE BIAR RAPI) ---
  Future<void> _simpanNama() async {
    if (_namaController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String namaBaru = _namaController.text.trim();

      // 1. Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'nama': namaBaru}, SetOptions(merge: true));

      // 2. Supabase (Sync)
      try {
        await Supabase.instance.client
            .from('profil_siswa')
            .update({'nama': namaBaru}).eq('id', user.uid);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Nama berhasil disimpan!"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 6. LOGOUT ---
  void _logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Edit Profil",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- FOTO PROFIL ---
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                _getAvatarImage(), // Panggil fungsi pintar
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _tampilkanPilihanAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- FORM NAMA ---
                  TextField(
                    controller: _namaController,
                    decoration: InputDecoration(
                        labelText: "Nama Lengkap",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // --- EMAIL (READ ONLY) ---
                  TextField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[200]),
                  ),
                  const SizedBox(height: 30),

                  // --- TOMBOL SIMPAN NAMA ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _simpanNama,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("SIMPAN NAMA",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- TOMBOL LOGOUT ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("KELUAR / LOGOUT",
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
