import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

class HalamanKuisPage extends StatefulWidget {
  final String title;
  // Kita butuh filter Kategori & Pola untuk ambil soal yang tepat
  final String kategoriFilter; // Misal: "Istima'"
  final String polaFilter; // Misal: "Pola 1"

  const HalamanKuisPage({
    super.key,
    required this.title,
    required this.kategoriFilter,
    required this.polaFilter,
  });

  @override
  State<HalamanKuisPage> createState() => _HalamanKuisPageState();
}

class _HalamanKuisPageState extends State<HalamanKuisPage> {
  // Variabel & Audio Player
  int _currentIndex = 0;
  int _score = 0;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  // Variabel Penampung Soal dari Database
  List<Map<String, dynamic>> _soalList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete
        .listen((event) => setState(() => _isPlaying = false));

    // Panggil Fungsi Ambil Soal
    _ambilSoal();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Wajib dimatikan biar gak bocor memori
    super.dispose();
  }

  // --- AMBIL SOAL DARI SUPABASE ---
  void _ambilSoal() async {
    try {
      final response = await Supabase.instance.client
          .from('bank_soal')
          .select()
          .eq('kategori', widget.kategoriFilter) // Filter Kategori
          .eq('pola', widget.polaFilter); // Filter Pola

      setState(() {
        _soalList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error ambil soal: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI PUTAR AUDIO ---
  void _playAudio(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(
            UrlSource(url)); // PENTING: Pakai UrlSource untuk link internet
      }
      setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      print("Gagal putar audio: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Gagal memutar audio")));
    }
  }

  // --- FUNGSI JAWAB SOAL (LOGIKA PENILAIAN) ---
  void _jawabSoal(int indexJawaban) {
    // 1. Matikan audio dulu sebelum pindah soal
    _audioPlayer.stop();
    setState(() => _isPlaying = false);

    // 2. Cek Jawaban
    // Di database Supabase, kunci disimpan sebagai angka (0, 1, 2, 3)
    int kunci = _soalList[_currentIndex]['kunci'];

    if (indexJawaban == kunci) {
      _score += 10; // Tambah 10 poin kalau benar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Benar! 🎉"),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 500)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Salah! ❌"),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 500)),
      );
    }

    // 3. Pindah Soal / Selesai
    if (_currentIndex < _soalList.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _tampilkanSkor();
    }
  }

  void _tampilkanSkor() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Latihan Selesai"),
        content: Text("Nilai Kamu: $_score"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke menu bab
            },
            child: const Text("Selesai"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_soalList.isEmpty) {
      return Scaffold(
          appBar: AppBar(
              title: Text(widget.title),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black),
          body: const Center(child: Text("Belum ada soal untuk materi ini.")));
    }

    // Ambil Data Soal Aktif
    final soal = _soalList[_currentIndex];
    final String pertanyaan = soal['pertanyaan'] ?? "Pertanyaan Kosong";
    final String? pathAudio = soal['audio_url'];
    final List<dynamic> opsi =
        soal['opsi'] ?? []; // Pastikan list opsi tidak null

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _soalList.length,
              color: const Color(0xFF42A5F5),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 10),
            Text("Soal ${_currentIndex + 1}/${_soalList.length}",
                textAlign: TextAlign.end,
                style: TextStyle(color: Colors.grey[600])),

            const SizedBox(height: 20),

            // --- KOTAK SOAL ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  // 1. LOGIKA ICON AUDIO (Hanya muncul jika ada file audio)
                  if (pathAudio != null && pathAudio.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _playAudio(pathAudio),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: _isPlaying
                            ? Colors.redAccent
                            : const Color(0xFF42A5F5),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause
                              : Icons.volume_up_rounded, // Icon berubah
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPlaying
                          ? "Sedang Memutar..."
                          : "Klik untuk mendengarkan",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                  ],

                  // 2. TEKS PERTANYAAN
                  Text(
                    pertanyaan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- PILIHAN JAWABAN ---
            Expanded(
              child: ListView.builder(
                itemCount: opsi.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () => _jawabSoal(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        elevation: 0,
                      ),
                      child: Text(opsi[index].toString(),
                          style: const TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
