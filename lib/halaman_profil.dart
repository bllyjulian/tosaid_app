import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Wajib buat upload foto
import 'package:image_picker/image_picker.dart'; // Wajib buat buka galeri
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

  String? _avatarUrl; // Nampung URL foto dari Firebase
  bool _isLoading = false;
  bool notifikasiAktif = true;

  @override
  void initState() {
    super.initState();
    _ambilDataProfil();
  }

  // --- 1. AMBIL DATA DARI FIREBASE ---
  Future<void> _ambilDataProfil() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _emailController.text = user.email ?? "";

        // Ambil data detail dari Firestore (karena Auth cuma simpan data dasar)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _namaController.text = data['nama'] ?? user.displayName ?? "User";
            _avatarUrl = data['avatar_url']; // Ambil link foto kalau ada
          });
        } else {
          // Kalau user login google tapi belum ada di firestore
          setState(() {
            _namaController.text = user.displayName ?? "User";
            _avatarUrl = user.photoURL;
          });
        }
      }
    } catch (e) {
      print("Error ambil profil: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 2. GANTI FOTO PROFIL (UPLOAD KE FIREBASE STORAGE) ---
  Future<void> _gantiFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      File file = File(image.path);

      // A. Siapkan tempat di Storage: folder 'profile_images', nama file = uid user
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}.jpg');

      // B. Upload File
      await ref.putFile(file);

      // C. Ambil Link Download (URL)
      String imageUrl = await ref.getDownloadURL();

      // D. Simpan URL ke Firestore (biar permanen)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'avatar_url': imageUrl},
          SetOptions(merge: true)); // merge: true biar data lain gak kehapus

      // E. Update Tampilan
      setState(() {
        _avatarUrl = imageUrl;
      });

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Foto berhasil diperbarui!")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal upload: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 3. SIMPAN PERUBAHAN NAMA ---
  Future<void> _simpanNama() async {
    if (_namaController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;

      // Update ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'nama': _namaController.text.trim()}, SetOptions(merge: true));

      // Update ke Auth Profile (Opsional, biar sinkron sama Google Auth)
      await user.updateDisplayName(_namaController.text.trim());

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Nama berhasil disimpan!"),
            backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 4. GANTI PASSWORD (VIA EMAIL) ---
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) return;

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Cek Email"),
            content: Text(
                "Link reset password telah dikirim ke ${_emailController.text}. Silakan cek inbox/spam."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text("Oke"))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  // --- 5. LOGOUT ---
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
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : const AssetImage('assets/images/profil.png')
                                    as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _gantiFoto, // Fungsi Ganti Foto Firebase
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
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
                    readOnly:
                        true, // Email di Firebase tidak bisa diganti sembarangan
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

                  // --- TOMBOL GANTI PASSWORD ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _resetPassword,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("GANTI PASSWORD (VIA EMAIL)",
                          style: TextStyle(
                              color: Colors.orange,
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
