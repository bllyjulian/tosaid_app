import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart'; // <--- IMPORT ANIMASI

class HalamanTargetPage extends StatefulWidget {
  const HalamanTargetPage({super.key});

  @override
  State<HalamanTargetPage> createState() => _HalamanTargetPageState();
}

class _HalamanTargetPageState extends State<HalamanTargetPage> {
  int _totalXp = 0;
  bool _isLoading = true;

  // Misi Harian
  List<Map<String, dynamic>> _misiHarian = [];

  // Pilihan Target User (Disimpan di memori sementara)
  List<String> _targetTerpilih = [];

  // --- DATA MIND MAP (PETA KONSEP) SESUAI TABEL ---
  final List<Map<String, dynamic>> _petaKonsepData = [
    {
      "skill": "1. Istimā’ (Menyimak)",
      "color": Colors.orange,
      "icon": Icons.headset_mic_rounded,
      "items": [
        {
          "tipe": "An-Naw‘ al-Awwal",
          "desc": "Menangkap gagasan umum dari dialog pendek"
        },
        {
          "tipe": "An-Naw‘ al-Tsānī",
          "desc": "Mengidentifikasi info spesifik (tokoh, tempat, waktu)"
        },
        {
          "tipe": "An-Naw‘ al-Tsāliṡ",
          "desc": "Menentukan makna ungkapan dialog panjang"
        },
        {
          "tipe": "An-Naw‘ al-Rābi‘",
          "desc": "Menyimpulkan tujuan pembicara (monolog/pidato)"
        },
      ]
    },
    {
      "skill": "2. Qirā’ah (Membaca)",
      "color": Colors.green,
      "icon": Icons.menu_book_rounded,
      "items": [
        {
          "tipe": "Ta‘yīnu al-Mawḍū‘",
          "desc": "Menentukan topik atau judul bacaan"
        },
        {
          "tipe": "Fikrah al-Ra’īsiyyah",
          "desc": "Menentukan ide pokok paragraf"
        },
        {"tipe": "Marja‘ al-Kalimah", "desc": "Menentukan rujukan kata/ḍhamīr"},
        {
          "tipe": "Ma‘nā al-Kalimah",
          "desc": "Menentukan makna kata sesuai konteks"
        },
        {"tipe": "Istinbāṭu an-Naṣṣ", "desc": "Menarik kesimpulan dari bacaan"},
      ]
    },
    {
      "skill": "3. Tarākīb (Struktur)",
      "color": Colors.purple,
      "icon": Icons.extension_rounded,
      "items": [
        {
          "tipe": "Takmīl al-Jumlah",
          "desc": "Melengkapi kalimat sesuai kaidah nahwu/sharaf"
        },
        {
          "tipe": "Taḥlīl al-Akhaṭā’",
          "desc": "Mengidentifikasi kesalahan struktur kalimat"
        },
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _inisialisasiHalaman();
  }

  Future<void> _inisialisasiHalaman() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // 1. Ambil XP Profil
      final profil = await supabase
          .from('profil_siswa')
          .select('total_xp')
          .eq('id', user.uid)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _totalXp = profil != null ? (profil['total_xp'] ?? 0) : 0;
        });
      }

      // 2. Cek & Load Misi Hari Ini
      await _cekDanGenerateMisi(user.uid);

      // 3. Cek Apakah Misi Selesai (Validasi dengan Riwayat Skor)
      await _validasiMisi(user.uid);
    } catch (e) {
      print("Error init: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA 1: GENERATE MISI (CUSTOM / DEFAULT) ---
  Future<void> _cekDanGenerateMisi(String uid) async {
    final supabase = Supabase.instance.client;
    String hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // Cek apakah sudah ada misi hari ini di DB?
      final cekMisi = await supabase
          .from('misi_harian')
          .select()
          .eq('user_id', uid)
          .eq('tanggal', hariIni)
          .maybeSingle();

      if (cekMisi != null) {
        // Jika sudah ada, pakai yang dari DB
        List<dynamic> rawList = cekMisi['daftar_misi'];
        if (mounted) {
          setState(() {
            _misiHarian = List<Map<String, dynamic>>.from(rawList);
          });
        }
      } else {
        // Jika belum ada, buat misi default (Random 2 Latihan)
        List<Map<String, dynamic>> misiDefault = _generateMisiDariPilihan([]);

        if (mounted) setState(() => _misiHarian = misiDefault);

        // Simpan ke DB
        await supabase.from('misi_harian').insert(
            {'user_id': uid, 'tanggal': hariIni, 'daftar_misi': misiDefault});
      }
    } catch (e) {
      print("Error generate misi: $e");
    }
  }

  // Fungsi Pembantu: Membuat List Misi dari String Pilihan
  List<Map<String, dynamic>> _generateMisiDariPilihan(List<String> pilihan) {
    List<Map<String, dynamic>> hasil = [];

    // 1. Misi Login (Selalu Ada)
    hasil.add({
      'judul': 'Absen Masuk Aplikasi',
      'xp': 10,
      'tipe': 'login',
      'status': 1 // Otomatis bisa klaim
    });

    // 2. Misi Latihan
    if (pilihan.isEmpty) {
      // Default kalau user malas pilih: Kasih 2 random
      hasil.add(_buatTemplateMisi("Istima' Pola 1"));
      hasil.add(_buatTemplateMisi("Qira'ah Pola 1"));
    } else {
      // Generate sesuai kemauan user
      for (String target in pilihan) {
        hasil.add(_buatTemplateMisi(target));
      }
    }
    return hasil;
  }

  Map<String, dynamic> _buatTemplateMisi(String namaMateri) {
    return {
      'judul': "Latihan $namaMateri",
      'xp': 50,
      'tipe': 'latihan_spesifik',
      'kunci_pencarian': "Latihan $namaMateri",
      'status': 0 // 0: Belum, 1: Klaim, 2: Selesai
    };
  }

  // --- DIALOG PILIH TARGET ---
  void _tampilkanDialogPilihTarget() {
    final List<String> opsiTersedia = [
      "Istima' Pola 1",
      "Istima' Pola 2",
      "Istima' Pola 3",
      "Istima' Pola 4",
      "Qira'ah Pola 1",
      "Tarakib Pola 1",
      "Tarakib Pola 2",
      "Tarakib Pola 3"
    ];

    List<String> tempSelected = [];

    for (var m in _misiHarian) {
      if (m['tipe'] == 'latihan_spesifik') {
        String judul = m['judul'].toString().replaceAll("Latihan ", "");
        if (opsiTersedia.contains(judul)) {
          tempSelected.add(judul);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Mau belajar apa hari ini? 🎯",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("Pilih materi yang ingin kamu kuasai hari ini.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: opsiTersedia.length,
                      itemBuilder: (context, index) {
                        final item = opsiTersedia[index];
                        final isSelected = tempSelected.contains(item);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.blue.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade200),
                          ),
                          child: CheckboxListTile(
                            title: Text(item,
                                style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.blue.shade800
                                        : Colors.black87)),
                            value: isSelected,
                            activeColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelected.add(item);
                                } else {
                                  tempSelected.remove(item);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: const Text("Nanti Aja"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _updateMisiCustom(tempSelected);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: const Text("Siap Belajar! 🚀",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateMisiCustom(List<String> pilihanBaru) async {
    if (pilihanBaru.isEmpty) return;
    setState(() {
      _isLoading = true;
      _targetTerpilih = pilihanBaru;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> misiBaru = _generateMisiDariPilihan(pilihanBaru);
    String hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final supabase = Supabase.instance.client;

    await supabase
        .from('misi_harian')
        .update({'daftar_misi': misiBaru})
        .eq('user_id', user.uid)
        .eq('tanggal', hariIni);
    await _inisialisasiHalaman();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Target belajar berhasil diatur! Semangat! 🔥"),
        backgroundColor: Colors.blue));
  }

  Future<void> _validasiMisi(String uid) async {
    final supabase = Supabase.instance.client;
    DateTime now = DateTime.now();
    DateTime startLocal = DateTime(now.year, now.month, now.day);
    DateTime endLocal = DateTime(now.year, now.month, now.day, 23, 59, 59);
    String startUtc = startLocal.toUtc().toIso8601String();
    String endUtc = endLocal.toUtc().toIso8601String();

    try {
      final response = await supabase
          .from('riwayat_skor')
          .select()
          .eq('user_id', uid)
          .gte('created_at', startUtc)
          .lte('created_at', endUtc);

      List<dynamic> riwayatHariIni = response as List<dynamic>;
      bool adaPerubahan = false;
      String hariIni = DateFormat('yyyy-MM-dd').format(now);

      for (var misi in _misiHarian) {
        if (misi['status'] == 0) {
          bool completed = false;
          if (misi['tipe'] == 'simulasi') {
            completed = riwayatHariIni
                .any((r) => r['jenis'] == 'simulasi' || r['jenis'] == null);
          } else if (misi['tipe'] == 'latihan_spesifik') {
            String kunci = (misi['kunci_pencarian'] ?? "").toLowerCase().trim();
            completed = riwayatHariIni.any((r) {
              String judulDiDb =
                  (r['judul_materi'] ?? "").toString().toLowerCase().trim();
              return judulDiDb.contains(kunci);
            });
          }
          if (completed) {
            misi['status'] = 1;
            adaPerubahan = true;
          }
        }
      }

      if (adaPerubahan) {
        await supabase
            .from('misi_harian')
            .update({'daftar_misi': _misiHarian})
            .eq('user_id', uid)
            .eq('tanggal', hariIni);
        if (mounted) setState(() {});
      }
    } catch (e) {
      print("Error validasi misi: $e");
    }
  }

  Future<void> _klaimMisi(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    String hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int xpDidapat = _misiHarian[index]['xp'];

    try {
      _misiHarian[index]['status'] = 2;
      await supabase
          .from('misi_harian')
          .update({'daftar_misi': _misiHarian})
          .eq('user_id', user.uid)
          .eq('tanggal', hariIni);

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

      setState(() {
        _totalXp = newTotal;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Mantap! Kamu dapat +$xpDidapat XP 🎉"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      print("Gagal klaim: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int misiSelesai = _misiHarian.where((e) => e['status'] == 2).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Target Belajar",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _inisialisasiHalaman,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ANIMASI HEADER (Slide Down)
                    _buildHeaderStatistik(misiSelesai)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.2, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 24),

                    // 2. JUDUL MISI HARIAN (Fade In)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Misi Hari Ini 🔥",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _tampilkanDialogPilihTarget,
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text("Atur Target"),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: 10),

                    // 3. ANIMASI LIST MISI (Staggered - Muncul satu per satu)
                    if (_misiHarian.isEmpty)
                      const Center(child: Text("Belum ada target hari ini."))
                    else
                      ..._misiHarian.asMap().entries.map((entry) {
                        return _buildKartuMisi(entry.value, entry.key)
                            .animate(
                                delay: (200 * entry.key).ms) // Delay bertahap
                            .fadeIn(duration: 500.ms)
                            .slideX(begin: -0.1, end: 0); // Masuk dari kiri
                      }).toList(),

                    const SizedBox(height: 30),

                    // 4. BAGIAN MIND MAP (Fade In)
                    const Text("Peta Konsep Belajar 🗺️",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))
                        .animate(delay: 400.ms)
                        .fadeIn(),
                    const SizedBox(height: 5),
                    Text("Alur materi yang akan kamu pelajari:",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]))
                        .animate(delay: 500.ms)
                        .fadeIn(),
                    const SizedBox(height: 16),

                    // 5. ANIMASI PETA KONSEP (Staggered Vertical)
                    _buildMindMapVertical(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  // --- WIDGET MIND MAP VERTIKAL (Dengan Animasi) ---
  Widget _buildMindMapVertical() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        children: _petaKonsepData.asMap().entries.map((entry) {
          int index = entry.key;
          var skill = entry.value;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: skill['color'].withOpacity(0.1),
                          shape: BoxShape.circle),
                      child:
                          Icon(skill['icon'], color: skill['color'], size: 20),
                    ),
                    Expanded(
                      child: Container(
                          width: 2,
                          color: Colors.grey.shade200,
                          margin: const EdgeInsets.symmetric(vertical: 4)),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(skill['skill'],
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: skill['color'])),
                        const SizedBox(height: 12),
                        ...(skill['items'] as List).map((item) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade100)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['tipe'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(item['desc'],
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        height: 1.3)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              // ANIMASI SETIAP ITEM PETA KONSEP
              .animate(
                  delay: (600 + (200 * index)).ms) // Mulai setelah Misi selesai
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.1, end: 0); // Masuk dari bawah
        }).toList(),
      ),
    );
  }

  Widget _buildKartuMisi(Map<String, dynamic> misi, int index) {
    int status = misi['status'];
    Color warnaBorder = Colors.grey.shade200;
    Color warnaBg = Colors.white;
    Color warnaTeks = Colors.black87;
    IconData iconStatus = Icons.circle_outlined;
    Color warnaIcon = Colors.grey;

    if (status == 1) {
      warnaBorder = Colors.blue.shade200;
      warnaBg = Colors.blue.shade50;
      iconStatus = Icons.card_giftcard;
      warnaIcon = Colors.blue;
    } else if (status == 2) {
      warnaBorder = Colors.green.shade200;
      warnaBg = Colors.green.shade50;
      iconStatus = Icons.check_circle;
      warnaIcon = Colors.green;
      warnaTeks = Colors.grey.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: warnaBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warnaBorder),
        boxShadow: status == 1
            ? [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: warnaIcon.withOpacity(0.3))),
            child: Icon(iconStatus, size: 20, color: warnaIcon),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(misi['judul'],
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: warnaTeks,
                        decoration:
                            status == 2 ? TextDecoration.lineThrough : null)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade100)),
                  child: Text("+${misi['xp']} XP",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (status == 1)
            ElevatedButton(
              onPressed: () => _klaimMisi(index),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2),
              child: const Text("Klaim",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            )
                // ANIMASI SHIMMER DI TOMBOL KLAIM
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .shimmer(
                    duration: 1500.ms, color: Colors.white.withOpacity(0.5))
          else if (status == 0)
            const Icon(Icons.chevron_right, color: Colors.grey)
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
            end: Alignment.bottomRight),
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
          _statItem(Icons.star_rounded, "$_totalXp", "Total XP"),
          Container(height: 40, width: 1, color: Colors.white24),
          _statItem(Icons.task_alt_rounded,
              "$misiSelesai / ${_misiHarian.length}", "Misi Selesai"),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.yellowAccent, size: 32),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
