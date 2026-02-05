import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'halaman_baca_pdf.dart'; // Pastikan file ini ada

class HalamanEvaluasiIstima extends StatefulWidget {
  const HalamanEvaluasiIstima({super.key});

  @override
  State<HalamanEvaluasiIstima> createState() => _HalamanEvaluasiIstimaState();
}

class _HalamanEvaluasiIstimaState extends State<HalamanEvaluasiIstima> {
  // --- STATE DATA ---
  List<Map<String, dynamic>> _daftarSoal = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Menyimpan Jawaban User: Map<IndexSoal, List<Kode>>
  final Map<int, List<String>> _jawabanUser = {};

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ambilSoal();
    _bgmPlayer.setReleaseMode(ReleaseMode.stop);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _bgmPlayer.dispose();
    super.dispose();
  }

  Future<void> _ambilSoal() async {
    try {
      final response = await Supabase.instance.client
          .from('evaluasi_soal')
          .select()
          .eq('kategori', 'Istima')
          .order('id', ascending: true);

      List<Map<String, dynamic>> dataMentah =
          List<Map<String, dynamic>>.from(response);

      // PROSES ACAK JAWABAN
      for (var soal in dataMentah) {
        List<Map<String, String>> opsiList = [];
        if (soal['opsi_a'] != null)
          opsiList.add({'kode': 'a', 'isi': soal['opsi_a']});
        if (soal['opsi_b'] != null)
          opsiList.add({'kode': 'b', 'isi': soal['opsi_b']});
        if (soal['opsi_c'] != null)
          opsiList.add({'kode': 'c', 'isi': soal['opsi_c']});

        opsiList.shuffle();
        soal['opsi_acak'] = opsiList;
      }

      setState(() {
        _daftarSoal = dataMentah;
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _playAudio(String url) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.play(UrlSource(url));
    }
  }

  void _pilihJawaban(String kode, bool isMulti) {
    setState(() {
      List<String> currentAnswers = _jawabanUser[_currentIndex] ?? [];
      if (isMulti) {
        if (currentAnswers.contains(kode)) {
          currentAnswers.remove(kode);
        } else {
          currentAnswers.add(kode);
        }
      } else {
        currentAnswers = [kode];
      }
      _jawabanUser[_currentIndex] = currentAnswers;
    });
  }

  void _navigasi(int arah) {
    _audioPlayer.stop();
    if (arah == 1) {
      if (_currentIndex < _daftarSoal.length - 1) {
        setState(() => _currentIndex++);
      } else {
        _selesaiEvaluasi();
      }
    } else {
      if (_currentIndex > 0) {
        setState(() => _currentIndex--);
      }
    }
  }

  // --- HITUNG SKOR & SIAPKAN RIWAYAT ---
  void _selesaiEvaluasi() async {
    await _audioPlayer.stop();
    _bgmPlayer.play(AssetSource('audio/selesai.mp3'));

    int skorTotal = 0;
    int benar = 0;
    List<Map<String, dynamic>> riwayatFinal = [];

    for (int i = 0; i < _daftarSoal.length; i++) {
      var soal = _daftarSoal[i];

      // Ambil Kunci
      String rawKunci = soal['kunci'] ?? "";
      List<String> kunciList = rawKunci.split(',');
      kunciList.sort();

      // Ambil Jawaban User
      List<String> userList = _jawabanUser[i] ?? [];
      userList.sort();

      bool isCorrect = false;
      if (kunciList.isNotEmpty && kunciList.join(',') == userList.join(',')) {
        isCorrect = true;
        benar++;
      }

      // --- PERSIAPAN UNTUK HALAMAN REVIEW ---
      // Kita perlu ubah kode ('a', 'b') menjadi teks ('Pasar', 'Sekolah')
      List<Map<String, String>> opsi =
          (soal['opsi_acak'] as List).cast<Map<String, String>>();

      String userText = userList.map((kode) {
        var op = opsi.firstWhere((e) => e['kode'] == kode,
            orElse: () => {'isi': '-'});
        return op['isi'];
      }).join(", ");

      String kunciText = kunciList.map((kode) {
        var op = opsi.firstWhere((e) => e['kode'] == kode,
            orElse: () => {'isi': '-'});
        return op['isi'];
      }).join(", ");

      riwayatFinal.add({
        'pertanyaan': soal['pertanyaan'] ?? "Soal Audio/Gambar",
        'jawaban_user': userText.isEmpty ? "-" : userText,
        'kunci': kunciText,
        'status': isCorrect
      });
    }

    if (_daftarSoal.isNotEmpty) {
      skorTotal = (benar / _daftarSoal.length * 100).round();
    }

    if (mounted) {
      _tampilkanPopUpHasil(skorTotal, riwayatFinal);
    }
  }

  // --- TAMPILAN POP UP HASIL (PREMIUM UI) ---
  void _tampilkanPopUpHasil(int skor, List<Map<String, dynamic>> riwayat) {
    // Tentukan Tema berdasarkan Nilai
    String pesan = "";
    String emoji = "";
    Color warnaTema = Colors.blue;

    if (skor == 100) {
      pesan = "MUMTAZ!";
      emoji = "🏆";
      warnaTema = Colors.green;
    } else if (skor >= 80) {
      pesan = "JAYYID JIDDAN!";
      emoji = "🎉";
      warnaTema = Colors.blue;
    } else if (skor >= 60) {
      pesan = "JAYYID!";
      emoji = "👍";
      warnaTema = Colors.orange;
    } else {
      pesan = "HAMASAH!";
      emoji = "💪";
      warnaTema = Colors.redAccent;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // KOTAK PUTIH
            Container(
              margin: const EdgeInsets.only(top: 40),
              padding: const EdgeInsets.only(
                  top: 60, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pesan,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: warnaTema,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  const Text("Nilai Kamu",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text("$skor",
                      style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87)),

                  const SizedBox(height: 20),

                  // TOMBOL 1: LIHAT JAWABAN
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => HalamanReviewJawaban(
                                  riwayatJawaban: riwayat))),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Text("LIHAT JAWABAN SAYA",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // TOMBOL 2: PEMBAHASAN PDF
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF66BB6A),
                        Color(0xFF2E7D32)
                      ]), // Hijau
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // BUKA PDF KUNCI JAWABAN ISTIMA
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HalamanBacaPdf(
                              judul: "Pembahasan Istima'",
                              pathPdf:
                                  "assets/pdfs/kj_kuis_istima.pdf", // FILE PDF PEMBAHASAN
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Text("PEMBAHASAN (PDF)",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // TOMBOL 3: SELESAI
                  TextButton(
                    onPressed: () {
                      _bgmPlayer.stop();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text("Selesai & Kembali",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ),
                ],
              ),
            ),

            // ICON MELAYANG
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: warnaTema, width: 4),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5))
                  ],
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 50)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_daftarSoal.isEmpty)
      return const Scaffold(body: Center(child: Text("Soal Kosong")));

    final soal = _daftarSoal[_currentIndex];
    List<Map<String, String>> opsiAcak =
        soal['opsi_acak'] as List<Map<String, String>>;
    String tipe = soal['tipe_soal'] ?? 'teks';
    bool isMultiSelect = tipe == 'teks_multi';
    String instruksiText = soal['instruksi'] ?? '-';
    bool showInstruksi =
        instruksiText != '-' && instruksiText.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Evaluasi ${_currentIndex + 1} / ${_daftarSoal.length}"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showInstruksi) ...[
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200)),
                      child: Row(children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(instruksiText,
                                style: const TextStyle(fontSize: 14)))
                      ]),
                    ),
                    const SizedBox(height: 30),
                  ],
                  GestureDetector(
                    onTap: () {
                      if (soal['audio_url'] != null)
                        _playAudio(soal['audio_url']);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade200, blurRadius: 10)
                          ]),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: _isPlaying
                                  ? Colors.red.shade50
                                  : Colors.blue.shade50,
                              shape: BoxShape.circle),
                          child: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 50,
                              color: _isPlaying ? Colors.red : Colors.blue),
                        ),
                        const SizedBox(height: 10),
                        Text(_isPlaying ? "Memutar..." : "Putar Audio",
                            style: TextStyle(color: Colors.grey[600]))
                      ]),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Pilih Jawaban:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        if (isMultiSelect)
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(5)),
                              child: const Text("Boleh > 1",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)))
                      ]),
                  const SizedBox(height: 15),
                  if (tipe == 'gambar')
                    _buildPilihanGambar(opsiAcak)
                  else if (isMultiSelect)
                    _buildPilihanMulti(opsiAcak)
                  else
                    _buildPilihanTeks(opsiAcak),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  TextButton.icon(
                      onPressed: () => _navigasi(-1),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                      label: const Text("Kembali"))
                else
                  const SizedBox(width: 80),
                ElevatedButton(
                  onPressed: () {
                    List<String> jawaban = _jawabanUser[_currentIndex] ?? [];
                    if (jawaban.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Pilih jawaban dulu!"),
                          duration: Duration(milliseconds: 1000)));
                      return;
                    }
                    _navigasi(1);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  child: Row(children: [
                    Text(_currentIndex == _daftarSoal.length - 1
                        ? "Selesai"
                        : "Selanjutnya"),
                    const SizedBox(width: 5),
                    Icon(
                        _currentIndex == _daftarSoal.length - 1
                            ? Icons.check_circle
                            : Icons.arrow_forward,
                        size: 18)
                  ]),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPilihanGambar(List<Map<String, String>> opsiList) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: opsiList.map((opsi) {
        return Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _kartuGambar(opsi['kode']!, opsi['isi'])));
      }).toList(),
    );
  }

  Widget _kartuGambar(String kode, String? url) {
    if (url == null) return const SizedBox();
    List<String> jawaban = _jawabanUser[_currentIndex] ?? [];
    bool isSelected = jawaban.contains(kode);
    return GestureDetector(
      onTap: () => _pilihJawaban(kode, false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 110,
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 3 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.error))),
      ),
    );
  }

  Widget _buildPilihanTeks(List<Map<String, String>> opsiList) {
    return Column(
        children: opsiList
            .map((opsi) => _tombolTeks(opsi['kode']!, opsi['isi'], false))
            .toList());
  }

  Widget _buildPilihanMulti(List<Map<String, String>> opsiList) {
    return Column(
        children: opsiList
            .map((opsi) => _tombolTeks(opsi['kode']!, opsi['isi'], true))
            .toList());
  }

  Widget _tombolTeks(String kode, String? teks, bool isMulti) {
    List<String> jawaban = _jawabanUser[_currentIndex] ?? [];
    bool isSelected = jawaban.contains(kode);
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _pilihJawaban(kode, isMulti),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue.shade50 : Colors.white,
            foregroundColor: isSelected ? Colors.blue.shade900 : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
            elevation: isSelected ? 0 : 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1)),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(
                isMulti
                    ? (isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank)
                    : (isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                color: isSelected ? Colors.blue : Colors.grey),
            Expanded(
                child: Text(teks ?? "-",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontFamily: 'Arial'),
                    textDirection: TextDirection.rtl)),
          ]),
        ),
      ),
    );
  }
}

// --- CLASS HALAMAN REVIEW (Ditambahkan di bawah sini agar bisa dipanggil) ---
// --- CLASS HALAMAN REVIEW (SUDAH DIPERBAIKI: Support Gambar & Multi Jawaban) ---
class HalamanReviewJawaban extends StatelessWidget {
  final List<Map<String, dynamic>> riwayatJawaban;
  const HalamanReviewJawaban({super.key, required this.riwayatJawaban});

  // Fungsi Helper: Menentukan apakah menampilkan Teks atau Gambar
  Widget _buildKontenJawaban(String rawContent, bool isCorrect) {
    // 1. Pecah jawaban jika ada koma (untuk soal multi jawaban)
    List<String> items = rawContent.split(', ');

    return Wrap(
      spacing: 10, // Jarak antar item (horizontal)
      runSpacing: 10, // Jarak antar baris (vertikal)
      children: items.map((item) {
        String bersih = item.trim();

        // 2. Cek apakah ini Link Gambar (diawali http)
        if (bersih.startsWith('http')) {
          return Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.red,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                bersih,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image, size: 30)),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                },
              ),
            ),
          );
        }

        // 3. Jika bukan link, tampilkan Teks biasa
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color:
                      isCorrect ? Colors.green.shade200 : Colors.red.shade200)),
          child: Text(
            bersih,
            style: TextStyle(
              color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 16, // Ukuran teks Arab biar jelas
              fontFamily: 'Arial', // Font standar biar Arab kebaca
            ),
            textDirection: TextDirection.rtl, // Agar teks Arab rapi
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Jawaban"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50], // Background agak abu biar card nonjol
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: riwayatJawaban.length,
        itemBuilder: (context, index) {
          final data = riwayatJawaban[index];
          bool isCorrect = data['status'];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER SOAL ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Soal ${index + 1}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 28,
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  // --- PERTANYAAN ---
                  Text(
                    data['pertanyaan'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    textDirection: TextDirection.rtl,
                  ),
                  const Divider(height: 25),

                  // --- JAWABAN KAMU ---
                  const Text("Jawaban Kamu:",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 5),
                  _buildKontenJawaban(data['jawaban_user'], isCorrect),

                  // --- KUNCI JAWABAN (Hanya muncul jika salah) ---
                  if (!isCorrect) ...[
                    const SizedBox(height: 15),
                    const Text("Kunci Jawaban:",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 5),
                    // Kunci jawaban selalu dianggap 'benar' (hijau)
                    _buildKontenJawaban(data['kunci'], true),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
