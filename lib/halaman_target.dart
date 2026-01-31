import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HalamanTargetPage extends StatefulWidget {
  const HalamanTargetPage({super.key});

  @override
  State<HalamanTargetPage> createState() => _HalamanTargetPageState();
}

class _HalamanTargetPageState extends State<HalamanTargetPage> {
  int _totalXp = 0;
  int _streakHari = 0;
  bool _isLoading = true;
  List<bool> _mingguanAktif = List.filled(7, false);

  // Struktur Misi: {id, judul, xp, status, tipe, target_skor, target_kategori}
  // Status: 0 (Belum), 1 (Bisa Klaim), 2 (Selesai/Diklaim)
  List<Map<String, dynamic>> _misiHarian = [];

  @override
  void initState() {
    super.initState();
    _inisialisasiHalaman();
  }

  Future<void> _inisialisasiHalaman() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Ambil Profil (XP)
      final supabase = Supabase.instance.client;
      final profil = await supabase
          .from('profil_siswa')
          .select('total_xp')
          .eq('id', user.uid)
          .maybeSingle();

      setState(() {
        _totalXp = profil != null ? (profil['total_xp'] ?? 0) : 0;
      });

      // 2. Cek & Generate Misi Hari Ini
      await _cekDanGenerateMisi(user.uid);

      // 3. Validasi Misi dengan Riwayat Skor Hari Ini
      await _validasiMisi(user.uid);

      // 4. Hitung Streak & Mingguan
      await _hitungStatistik(user.uid);
    } catch (e) {
      print("Error init: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _generateMisiRandom() {
    // BANK MISI SPESIFIK
    List<Map<String, dynamic>> templateMisi = [
      // --- MISI LOGIN (Tetap) ---
      {
        'judul': 'Login Aplikasi',
        'xp': 10,
        'tipe': 'login',
        'kunci_pencarian': '',
        'status': 1
      },

      // --- MISI SIMULASI (Tetap) ---
      {
        'judul': 'Selesaikan Simulasi TOSA',
        'xp': 50,
        'tipe': 'simulasi',
        'kunci_pencarian': 'simulasi',
        'status': 0
      },

      // --- MISI LATIHAN SPESIFIK (BARU) ---
      // ISTIMA'
      {
        'judul': "Latihan Istima' Pola 1",
        'xp': 30,
        'tipe': 'latihan_spesifik',
        'kunci_pencarian':
            "Latihan Istima' Pola 1", // Harus SAMA PERSIS dengan format simpan tadi
        'status': 0
      },
      {
        'judul': "Latihan Istima' Pola 2",
        'xp': 30,
        'tipe': 'latihan_spesifik',
        'kunci_pencarian': "Latihan Istima' Pola 2",
        'status': 0
      },

      // TARAKIB
      {
        'judul': "Latihan Tarakib Pola 1",
        'xp': 35,
        'tipe': 'latihan_spesifik',
        'kunci_pencarian': "Latihan Tarakib Pola 1",
        'status': 0
      },
      {
        'judul': "Latihan Tarakib Pola 3",
        'xp': 35,
        'tipe': 'latihan_spesifik',
        'kunci_pencarian': "Latihan Tarakib Pola 3",
        'status': 0
      },

      // QIRA'AH
      {
        'judul': "Latihan Qira'ah Pola 1",
        'xp': 25,
        'tipe': 'latihan_spesifik',
        'kunci_pencarian': "Latihan Qira'ah Pola 1",
        'status': 0
      },
    ];

    // Acak dan ambil 3 Misi
    templateMisi.shuffle();
    // Pastikan Login selalu ada (opsional) atau ambil acak murni
    return templateMisi.sublist(0, 3);
  }

// --- LOGIKA 1: GENERATE MISI (VERSI PERBAIKAN) ---
  Future<void> _cekDanGenerateMisi(String uid) async {
    final supabase = Supabase.instance.client;
    String hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // 1. Cek apakah sudah ada misi untuk tanggal ini di database?
      final cekMisi = await supabase
          .from('misi_harian')
          .select()
          .eq('user_id', uid)
          .eq('tanggal', hariIni) // Pastikan kolom di DB tipe DATE atau TEXT
          .maybeSingle();

      if (cekMisi != null) {
        // KASUS A: SUDAH ADA DI DB -> LOAD DATA LAMA
        print("Misi hari ini ditemukan di DB.");
        List<dynamic> rawList = cekMisi['daftar_misi'];

        if (mounted) {
          setState(() {
            _misiHarian = List<Map<String, dynamic>>.from(rawList);
          });
        }
      } else {
        // KASUS B: BELUM ADA -> BUAT BARU
        print("Misi hari ini belum ada. Membuat baru...");

        // Buat misi acak
        List<Map<String, dynamic>> misiBaru = _generateMisiRandom();

        // [PENTING] Update UI DULUAN biar user gak nunggu loading database
        if (mounted) {
          setState(() {
            _misiHarian = misiBaru;
          });
        }

        // Baru simpan ke Database (Proses di latar belakang)
        await supabase.from('misi_harian').insert(
            {'user_id': uid, 'tanggal': hariIni, 'daftar_misi': misiBaru});
        print("Misi baru berhasil disimpan ke DB.");
      }
    } catch (e) {
      print("Error di _cekDanGenerateMisi: $e");

      // Fallback Darurat: Kalau database error/mati, TETAP TAMPILKAN MISI (Lokal)
      // Supaya halaman target gak kosong melompong
      if (_misiHarian.isEmpty && mounted) {
        setState(() {
          _misiHarian = _generateMisiRandom();
        });
      }
    }
  }

// --- LOGIKA 2: VALIDASI MISI (VERSI FIX TIMEZONE & STRING MATCH) ---
  Future<void> _validasiMisi(String uid) async {
    final supabase = Supabase.instance.client;

    // 1. Dapatkan Rentang Waktu Hari Ini (Lokal -> UTC)
    final now = DateTime.now();
    // Awal hari ini (00:00:00)
    final startOfDay = DateTime(now.year, now.month, now.day);
    // Akhir hari ini (23:59:59)
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Konversi ke format ISO string agar Supabase paham
    final startIso = startOfDay.toIso8601String();
    final endIso = endOfDay.toIso8601String();

    try {
      // 2. Ambil Data (Query lebih aman dengan gte/lte ISO String)
      final response = await supabase
          .from('riwayat_skor')
          .select()
          .eq('user_id', uid)
          .gte('created_at', startIso)
          .lte('created_at', endIso);

      List<dynamic> riwayatHariIni = response as List<dynamic>;
      bool adaPerubahan = false;

      // String tanggal untuk update misi_harian (Format YYYY-MM-DD)
      String hariIniStr = DateFormat('yyyy-MM-dd').format(now);

      print("LOG DEBUG: Ditemukan ${riwayatHariIni.length} riwayat hari ini.");

      for (var misi in _misiHarian) {
        if (misi['status'] == 0) {
          // Cek hanya yang belum selesai
          bool completed = false;

          // --- TIPE 1: LOGIN ---
          if (misi['tipe'] == 'login') {
            completed = true;
          }

          // --- TIPE 2: SIMULASI ---
          else if (misi['tipe'] == 'simulasi') {
            completed = riwayatHariIni
                .any((r) => r['jenis'] == 'simulasi' || r['jenis'] == null);
          }

          // --- TIPE 3: LATIHAN SPESIFIK (Pencarian String Longgar) ---
          else if (misi['tipe'] == 'latihan_spesifik') {
            String kunci =
                (misi['kunci_pencarian'] ?? "").toString().toLowerCase().trim();

            // Cek apakah ada riwayat yang judulnya MENGANDUNG kunci
            // Kita pakai 'contains' dan 'toLowerCase' biar aman dari typo kecil
            completed = riwayatHariIni.any((r) {
              String judulDiDb =
                  (r['judul_materi'] ?? "").toString().toLowerCase().trim();

              // Debugging: Print perbandingan
              // print("Cek Misi: '$kunci' vs DB: '$judulDiDb'");

              return judulDiDb.contains(kunci);
            });
          }

          if (completed) {
            print("✅ Misi Selesai: ${misi['judul']}");
            misi['status'] = 1; // Update jadi 'Bisa Klaim'
            adaPerubahan = true;
          }
        }
      }

      // 3. Simpan perubahan ke database
      if (adaPerubahan) {
        await supabase
            .from('misi_harian')
            .update({'daftar_misi': _misiHarian})
            .eq('user_id', uid)
            .eq('tanggal', hariIniStr);

        if (mounted) setState(() {});
      }
    } catch (e) {
      print("Error Validasi Misi: $e");
    }
  }

  // --- LOGIKA 3: KLAIM XP ---
  Future<void> _klaimMisi(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    String hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());

    int xpDidapat = _misiHarian[index]['xp'];

    try {
      // 1. Update List Misi Lokal
      _misiHarian[index]['status'] = 2; // Tandai Selesai (Diklaim)

      // 2. Update Misi di Database
      await supabase
          .from('misi_harian')
          .update({'daftar_misi': _misiHarian})
          .eq('user_id', user.uid)
          .eq('tanggal', hariIni);

      // 3. Tambah Total XP User di Profil
      // Ambil XP lama dulu biar aman
      final resProfil = await supabase
          .from('profil_siswa')
          .select('total_xp')
          .eq('id', user.uid)
          .single();
      int currentTotalXp = resProfil['total_xp'] ?? 0;
      int newTotal = currentTotalXp + xpDidapat;

      await supabase
          .from('profil_siswa')
          .update({'total_xp': newTotal}).eq('id', user.uid);

      // 4. Update UI
      setState(() {
        _totalXp = newTotal;
        _isLoading = false;
      });

      // 5. Munculkan Efek/Snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Selamat! Kamu dapat +$xpDidapat XP 🎉"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      print("Gagal klaim: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA 4: HITUNG STREAK (Sama seperti sebelumnya) ---
  Future<void> _hitungStatistik(String uid) async {
    final supabase = Supabase.instance.client;
    final riwayat = await supabase
        .from('riwayat_skor')
        .select('created_at')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    Set<String> tanggalBelajar = {};
    for (var item in riwayat) {
      DateTime tgl = DateTime.parse(item['created_at']).toLocal();
      tanggalBelajar.add(DateFormat('yyyy-MM-dd').format(tgl));
    }

    // Hitung Streak
    int streak = 0;
    DateTime cek = DateTime.now();
    // Cek hari ini, jika ada hitung, jika tidak cek kemarin
    if (tanggalBelajar.contains(DateFormat('yyyy-MM-dd').format(cek))) {
      streak++;
    }
    while (true) {
      cek = cek.subtract(const Duration(days: 1));
      if (tanggalBelajar.contains(DateFormat('yyyy-MM-dd').format(cek))) {
        streak++;
      } else {
        break;
      }
    }

    // Hitung Mingguan
    List<bool> mingguan = List.filled(7, false);
    DateTime now = DateTime.now();
    DateTime senin = now.subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < 7; i++) {
      DateTime h = senin.add(Duration(days: i));
      if (tanggalBelajar.contains(DateFormat('yyyy-MM-dd').format(h))) {
        mingguan[i] = true;
      }
    }

    if (mounted)
      setState(() {
        _streakHari = streak;
        _mingguanAktif = mingguan;
      });
  }

  @override
  Widget build(BuildContext context) {
    int misiSelesai = _misiHarian.where((e) => e['status'] == 2).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        // ... (AppBar sama) ...
        title: const Text("Target Belajar",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      // --- BUNGKUS BODY DENGAN REFRESH INDICATOR ---
      body: RefreshIndicator(
        onRefresh:
            _inisialisasiHalaman, // Panggil ulang fungsi init saat ditarik
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Wajib biar bisa discroll walau konten dikit
                padding: const EdgeInsets.all(20),
                child: Column(
                  // ... (Isi Column SAMA PERSIS dengan sebelumnya) ...
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderStatistik(misiSelesai),
                    const SizedBox(height: 24),
                    const Text("Aktivitas Minggu Ini",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildKalenderMingguan(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Misi Harian",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("Reset tiap 00:00",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._misiHarian.asMap().entries.map((entry) {
                      return _buildKartuMisi(entry.value, entry.key);
                    }).toList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildKartuMisi(Map<String, dynamic> misi, int index) {
    int status = misi['status']; // 0: Belum, 1: Klaim, 2: Selesai

    Color warnaBorder = Colors.grey.shade200;
    Color warnaBg = Colors.white;
    IconData iconStatus = Icons.lock_clock;
    Color warnaIcon = Colors.grey;

    if (status == 1) {
      // BISA KLAIM
      warnaBorder = Colors.blue;
      warnaBg = Colors.blue.shade50;
      iconStatus = Icons.touch_app; // Icon jari
      warnaIcon = Colors.blue;
    } else if (status == 2) {
      // SELESAI
      warnaBorder = Colors.green.withOpacity(0.5);
      warnaBg = Colors.green.shade50;
      iconStatus = Icons.check_circle;
      warnaIcon = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
          color: warnaBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: warnaBorder, width: status == 1 ? 2 : 1),
          boxShadow: status == 1
              ? [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4))
                ]
              : []),
      child: Row(
        children: [
          // Icon Status
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: warnaIcon.withOpacity(0.5))),
            child: Icon(iconStatus, size: 20, color: warnaIcon),
          ),
          const SizedBox(width: 16),

          // Teks Judul & XP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(misi['judul'],
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration:
                            status == 2 ? TextDecoration.lineThrough : null,
                        color: status == 2 ? Colors.grey : Colors.black87)),
                const SizedBox(height: 4),
                Text("+${misi['xp']} XP",
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Tombol Aksi
          if (status == 1)
            ElevatedButton(
              onPressed: () => _klaimMisi(index),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              child: const Text("Klaim",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            )
          else if (status == 0)
            const Text("Belum",
                style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            const Text("Selesai",
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHeaderStatistik(int misiSelesai) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.local_fire_department, Colors.orange,
              "$_streakHari Hari", "Streak"),
          Container(height: 40, width: 1, color: Colors.white24),
          _statItem(Icons.star, Colors.yellow, "$_totalXp", "Total XP"),
          Container(height: 40, width: 1, color: Colors.white24),
          _statItem(Icons.task_alt, Colors.lightGreenAccent,
              "$misiSelesai / ${_misiHarian.length}", "Misi"),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildKalenderMingguan() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _HariCircle(hari: "S", aktif: _mingguanAktif[0]),
          _HariCircle(hari: "S", aktif: _mingguanAktif[1]),
          _HariCircle(hari: "R", aktif: _mingguanAktif[2]),
          _HariCircle(hari: "K", aktif: _mingguanAktif[3]),
          _HariCircle(hari: "J", aktif: _mingguanAktif[4]),
          _HariCircle(hari: "S", aktif: _mingguanAktif[5]),
          _HariCircle(hari: "M", aktif: _mingguanAktif[6]),
        ],
      ),
    );
  }
}

class _HariCircle extends StatelessWidget {
  final String hari;
  final bool aktif;
  const _HariCircle({required this.hari, required this.aktif});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: aktif ? Colors.blue : Colors.grey[100],
              shape: BoxShape.circle),
          child: Text(hari,
              style: TextStyle(
                  color: aktif ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Icon(aktif ? Icons.check_circle : Icons.circle,
            size: 8, color: aktif ? Colors.green : Colors.transparent),
      ],
    );
  }
}
