import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'data_konversi_tosa.dart'; // <--- Tambahkan ini
import 'package:firebase_auth/firebase_auth.dart';

class HalamanSimulasiPage extends StatefulWidget {
  const HalamanSimulasiPage({super.key});

  @override
  State<HalamanSimulasiPage> createState() => _HalamanSimulasiPageState();
}

class _HalamanSimulasiPageState extends State<HalamanSimulasiPage> {
  // --- KONFIGURASI ---
  static const int durasiPerSection = 20 * 60; // 20 Menit

  // --- STATE DATA ---
  bool _isLoading = true;
  List<Map<String, dynamic>> _dataTes = [];

  // --- STATE PROGRESS ---
  int _currentSectionIdx = 0;
  int _currentPaketIdx = 0;
  int _currentSoalIdx = 0;

  // --- STATE TIMER & AUDIO ---
  int _sisaWaktu = durasiPerSection;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;

  // URL Audio yang sedang aktif
  String? _currentPlayingUrl;

  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  // --- STATE SKOR ---
  int _totalSkor = 0;
  List<Map<String, dynamic>> _laporanHasil = [];

  @override
  void initState() {
    super.initState();
    _ambilDataDariSupabase();

    // Agar audio stop total saat selesai
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    // Listener Status Player
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isAudioPlaying = state == PlayerState.playing);
      }
    });

    // Listener Durasi & Posisi
    _audioPlayer.onDurationChanged
        .listen((d) => setState(() => _audioDuration = d));
    _audioPlayer.onPositionChanged
        .listen((p) => setState(() => _audioPosition = p));

    // Reset state saat audio selesai
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = false;
          _audioPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- LOGIKA AUDIO ---
  void _toggleAudio(String url) async {
    if (url.isEmpty) return;

    if (_currentPlayingUrl == url && _isAudioPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));

      setState(() {
        _currentPlayingUrl = url;
      });
    }
  }

  // --- LOGIKA DATA ---
  Future<void> _ambilDataDariSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final responsePaket = await supabase
          .from('simulasi_paket')
          .select('*, simulasi_soal(*)')
          .order('urutan', ascending: true);

      Map<String, List<Map<String, dynamic>>> grouped = {
        "Istima'": [],
        "Qira'ah": [],
        "Tarakib": []
      };

      for (var paket in responsePaket) {
        String section = paket['section'] ?? "Lainnya";
        if (paket['simulasi_soal'] != null &&
            (paket['simulasi_soal'] as List).isNotEmpty) {
          // Sortir soal berdasarkan id
          (paket['simulasi_soal'] as List)
              .sort((a, b) => a['id'].compareTo(b['id']));
          if (grouped.containsKey(section)) grouped[section]!.add(paket);
        }
      }

      List<Map<String, dynamic>> finalData = [];
      grouped.forEach((key, value) {
        if (value.isNotEmpty)
          finalData.add({'nama_section': key, 'paket_list': value});
      });

      setState(() {
        _dataTes = finalData;
        _isLoading = false;
      });

      if (_dataTes.isNotEmpty) startTimer();
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA TIMER ---
  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sisaWaktu > 0) {
        setState(() => _sisaWaktu--);
      } else {
        _pindahSectionOtomatis();
      }
    });
  }

  void _pindahSectionOtomatis() {
    _timer?.cancel();
    _audioPlayer.stop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title:
            const Text("Waktu Habis! ⏰", style: TextStyle(color: Colors.red)),
        content: Text(
            "Waktu untuk ${_dataTes[_currentSectionIdx]['nama_section']} selesai. Lanjut?"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _lanjutSection();
            },
            child: const Text("Lanjut"),
          )
        ],
      ),
    );
  }

  // --- LOGIKA JAWAB & NAVIGASI ---
  void _jawabSoal(int indexOpsi, Map<String, dynamic> soalData) {
    int kunci = soalData['kunci'];
    bool benar = indexOpsi == kunci;

    // HAPUS BARIS INI: if (benar) _totalSkor += 10;  <-- HAPUS AJA

    List<dynamic> opsi = [
      soalData['opsi_a'],
      soalData['opsi_b'],
      soalData['opsi_c'],
      soalData['opsi_d']
    ];

    // Simpan status benar/salah ke laporan
    _laporanHasil.add({
      'section': _dataTes[_currentSectionIdx][
          'nama_section'], // Penting! Nama harus sesuai (Istima', Tarakib, Qira'ah)
      'pertanyaan': soalData['pertanyaan'],
      'jawaban_user': opsi[indexOpsi],
      'jawaban_benar': opsi[kunci],
      'status': benar
    });

    _lanjutSoal();
  }

  void _lanjutSoal() {
    var currentSection = _dataTes[_currentSectionIdx];
    var currentPaketList = currentSection['paket_list'] as List;
    var currentSoalList =
        currentPaketList[_currentPaketIdx]['simulasi_soal'] as List;

    _audioPlayer.stop();
    _currentPlayingUrl = null;
    _audioPosition = Duration.zero;

    if (_currentSoalIdx < currentSoalList.length - 1) {
      setState(() => _currentSoalIdx++);
    } else if (_currentPaketIdx < currentPaketList.length - 1) {
      setState(() {
        _currentPaketIdx++;
        _currentSoalIdx = 0;
      });
    } else if (_currentSectionIdx < _dataTes.length - 1) {
      _tampilKonfirmasiSelesaiSection();
    } else {
      _selesaiTes();
    }
  }

  void _lanjutSection() {
    if (_currentSectionIdx < _dataTes.length - 1) {
      setState(() {
        _currentSectionIdx++;
        _currentPaketIdx = 0;
        _currentSoalIdx = 0;
        _sisaWaktu = durasiPerSection;
        _audioPlayer.stop();
        _currentPlayingUrl = null;
      });
      startTimer();
    } else {
      _selesaiTes();
    }
  }

  void _tampilKonfirmasiSelesaiSection() {
    _timer?.cancel();
    _audioPlayer.stop();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bagian Selesai"),
        content: const Text("Lanjut ke bagian berikutnya?"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _lanjutSection();
            },
            child: const Text("Lanjut"),
          ),
        ],
      ),
    );
  }

  String _hitungPredikat(int skor) {
    if (skor >= 500) return "MUMTAZ";
    if (skor >= 400) return "JAYYID JIDDAN";
    if (skor >= 300) return "JAYYID";
    if (skor >= 200) return "MAQBUL";
    return "RASIB";
  }

  // UPDATE FUNGSI INI
  Future<void> _selesaiTes() async {
    _timer?.cancel();
    _audioPlayer.stop();

    // 1. Cek User Login (PAKAI FIREBASE)
    final userFirebase = FirebaseAuth.instance.currentUser;

    if (userFirebase == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error: Anda belum login! Hasil tidak tersimpan.")),
        );
      }
      return;
    }

    // 2. Hitung Nilai
    int benarIstima = _laporanHasil
        .where((e) => e['section'] == "Istima'" && e['status'] == true)
        .length;
    int benarQiraah = _laporanHasil
        .where((e) => e['section'] == "Qira'ah" && e['status'] == true)
        .length;
    int benarTarakib = _laporanHasil
        .where((e) => e['section'] == "Tarakib" && e['status'] == true)
        .length;

    int skorFinalTosa = DataKonversiTosa.hitungSkorAkhir(
        benarIstima: benarIstima,
        benarTarakib: benarTarakib,
        benarQiraah: benarQiraah);

    // 3. Simpan ke Database Supabase (Kirim UID Firebase)
    try {
      final supabase = Supabase.instance.client;

      // Ambil nama dari Firebase (displayName) atau Email, atau Default
      String namaUser =
          userFirebase.displayName ?? userFirebase.email ?? "Siswa Firebase";

      await supabase.from('riwayat_skor').insert({
        'user_id': userFirebase.uid, // <--- ID STRING DARI FIREBASE
        'nama_siswa': namaUser,
        'skor_akhir': skorFinalTosa,
        'predikat': _hitungPredikat(skorFinalTosa),
        'benar_istima': benarIstima,
        'benar_tarakib': benarTarakib,
        'benar_qiraah': benarQiraah,
      });

      print("Berhasil simpan untuk user: ${userFirebase.uid}");
    } catch (e) {
      print("Gagal simpan riwayat: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal simpan: $e")));
      }
    }

    // 4. Pindah Halaman
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HasilSimulasiPage(
                skorAkhir: skorFinalTosa, laporan: _laporanHasil)),
      );
    }
  }

  String get _formatWaktu {
    int menit = _sisaWaktu ~/ 60;
    int detik = _sisaWaktu % 60;
    return "${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}";
  }

// --- HITUNG POSISI SOAL (Hanya Tipe PG) ---
  String _getIndikatorSoal() {
    int totalSoalPG = 0;
    int currentPGIndex = 0;

    // Cek apakah item saat ini adalah instruksi?
    var currentItem = (_dataTes[_currentSectionIdx]['paket_list']
        as List)[_currentPaketIdx]['simulasi_soal'][_currentSoalIdx];
    if (currentItem['tipe'] == 'instruksi') {
      return "Petunjuk"; // Jika sedang instruksi, tampilkan teks "Petunjuk"
    }

    var section = _dataTes[_currentSectionIdx];
    var listPaket = section['paket_list'] as List;

    for (int i = 0; i < listPaket.length; i++) {
      var p = listPaket[i];
      var listS = p['simulasi_soal'] as List;

      for (int j = 0; j < listS.length; j++) {
        var item = listS[j];
        if (item['tipe'] != 'instruksi') {
          totalSoalPG++; // Hitung total soal PG di section ini

          // Cek posisi kita sekarang
          if (i < _currentPaketIdx ||
              (i == _currentPaketIdx && j < _currentSoalIdx)) {
            currentPGIndex++;
          }
        }
      }
    }

    // Return format "1 / 10" (Posisi + 1 karena index mulai dari 0)
    return "${currentPGIndex + 1} / $totalSoalPG";
  }

  @override
  Widget build(BuildContext context) {
    // 1. Cek Loading & Data Kosong
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_dataTes.isEmpty)
      return const Scaffold(
          body: Center(child: Text("Belum ada soal simulasi.")));

    // 2. Ambil Data Saat Ini
    var section = _dataTes[_currentSectionIdx];
    var paket = section['paket_list'][_currentPaketIdx];
    var item = paket['simulasi_soal'][_currentSoalIdx];

    // 3. Logika & Variabel
    bool isInstruksi = item['tipe'] == 'instruksi'; // Cek tipe dari database
    String teksPertanyaan = (item['pertanyaan'] ?? '-').toString().trim();
    bool textIsDash = teksPertanyaan == '-'; // Apakah teksnya cuma strip?
    bool hasItemAudio =
        item['audio_url'] != null && item['audio_url'].toString().isNotEmpty;
    bool isAudioActive =
        _isAudioPlaying && _currentPlayingUrl == item['audio_url'];

    // Warna Tema
    Color warnaTema = Colors.blue;
    if (section['nama_section'] == "Qira'ah") warnaTema = Colors.orange;
    if (section['nama_section'] == "Tarakib") warnaTema = Colors.purple;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                section['nama_section'],
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_getIndikatorSoal(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: _sisaWaktu < 60
                      ? Colors.red.shade100
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15)),
              child: Row(children: [
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 5),
                Text(_formatWaktu,
                    style: const TextStyle(fontWeight: FontWeight.bold))
              ]),
            )
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // BAGIAN 1: STIMULUS (PAKET INDUK)
            // ============================================================
// ============================================================
            // BAGIAN 1: STIMULUS (PAKET INDUK) - LOGIKA BARU
            // ============================================================
            Builder(builder: (context) {
              // Cek Judul Paket
              bool adaJudul = paket['judul_paket'] != null &&
                  paket['judul_paket'].toString().trim().isNotEmpty &&
                  paket['judul_paket'].toString().trim() != '-';

              // Cek Konten Teks (Qira'ah) - Pastikan bukan "-"
              bool adaTeks = paket['jenis_konten'] == 'teks' &&
                  paket['konten_url'] != null &&
                  paket['konten_url'].toString().trim().isNotEmpty &&
                  paket['konten_url'].toString().trim() !=
                      '-'; // Tambahan cek "-"

              // Cek Audio Induk
              bool adaAudio = paket['jenis_konten'] == 'audio' &&
                  paket['konten_url'] != null;

              // Jika semua kosong, jangan tampilkan apa-apa
              if (!adaJudul && !adaTeks && !adaAudio) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: warnaTema.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: warnaTema.withOpacity(0.5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Kecil (Opsional)
                    Text(
                      paket['jenis_konten'] == 'teks'
                          ? "Bacaan / Nash"
                          : "Stimulus / Pengantar Soal",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: warnaTema),
                    ),
                    const SizedBox(height: 10),

                    // A. TAMPILKAN JUDUL PAKET (Jika Ada)
                    if (adaJudul) ...[
                      Text(paket['judul_paket'],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl),
                      const SizedBox(height: 10),
                    ],

                    // B. TAMPILKAN TEKS BACAAN (QIRA'AH)
                    if (adaTeks) ...[
                      Container(
                          constraints: const BoxConstraints(
                              maxHeight: 300), // Scrollable
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300)),
                          child: SingleChildScrollView(
                            child: Text(paket['konten_url'],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Arial',
                                    height: 1.8 // Spasi antar baris enak dibaca
                                    ),
                                textAlign: TextAlign.justify,
                                textDirection: TextDirection.rtl),
                          ))
                    ],

                    // C. TAMPILKAN AUDIO INDUK
                    if (adaAudio) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        IconButton(
                            icon: Icon((_isAudioPlaying &&
                                    _currentPlayingUrl == paket['konten_url'])
                                ? Icons.pause
                                : Icons.play_arrow),
                            onPressed: () => _toggleAudio(paket['konten_url'])),
                        const Expanded(
                            child: Text("Audio Induk / Stimulus",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ])
                    ]
                  ],
                ),
              );
            }),

            // ============================================================
            // BAGIAN 2: ITEM (SOAL / AUDIO UTAMA)
            // ============================================================

            // JIKA: Teks "-" DAN Ada Audio -> TAMPILKAN PLAYER BESAR (UI BIRU KONSISTEN)
// ============================================================
            // BAGIAN 2: ITEM (SOAL / AUDIO UTAMA)
            // ============================================================

            // JIKA: Teks "-" DAN Ada Audio -> TAMPILKAN PLAYER BESAR (UI BIRU KONSISTEN)
            if (hasItemAudio && textIsDash) ...[
              SizedBox(
                height: 400, // Atur tinggi sesuai kebutuhan
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. Judul Besar (Dinamis: Cek apakah Instruksi atau Soal)
                    Text(
                      isInstruksi
                          ? "Simak Audio Pengantar"
                          : "Simak Audio Soal", // <--- PERBAIKAN DI SINI
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // 2. Sub-judul / Instruksi
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        // Jika ada teks pertanyaan, tampilkan.
                        // Jika tidak (-), cek tipe: kalau instruksi tampilkan teks instruksi, kalau soal tampilkan teks soal.
                        item['pertanyaan'] != '-'
                            ? item['pertanyaan']
                            : (isInstruksi
                                ? "Dengarkan materi ini baik-baik sebelum memulai menjawab soal latihan."
                                : "Dengarkan audio soal dengan seksama, lalu pilih jawaban yang benar."), // <--- PERBAIKAN DI SINI
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[600], height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 3. Tombol Play Besar di Tengah (Lingkaran Biru)
                    GestureDetector(
                      onTap: () => _toggleAudio(item['audio_url']),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50, // Lingkaran biru muda
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAudioActive
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 80, // Ukuran icon sangat besar
                          color: Colors.blue, // Warna icon biru
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 4. Slider & Durasi (Sejajar)
                    if (isAudioActive) // Tampilkan slider hanya jika aktif
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            // Waktu Berjalan (misal: 00:15)
                            Text(
                              _audioPosition
                                  .toString()
                                  .split('.')
                                  .first
                                  .substring(2),
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500),
                            ),

                            // Slider
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16),
                                  activeTrackColor: Colors.blue,
                                  inactiveTrackColor: Colors.blue.shade100,
                                  thumbColor: Colors.blue,
                                ),
                                child: Slider(
                                  value: _audioPosition.inSeconds.toDouble(),
                                  max: _audioDuration.inSeconds.toDouble() > 0
                                      ? _audioDuration.inSeconds.toDouble()
                                      : 1,
                                  onChanged: (v) => _audioPlayer
                                      .seek(Duration(seconds: v.toInt())),
                                ),
                              ),
                            ),

                            // Total Durasi (misal: 02:30)
                            Text(
                              _audioDuration
                                  .toString()
                                  .split('.')
                                  .first
                                  .substring(2),
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ]
            // JIKA TIDAK (Teks Biasa) -> TAMPILAN STANDAR
            else ...[
              if (hasItemAudio)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleAudio(item['audio_url']),
                      icon: Icon(
                          isAudioActive ? Icons.pause : Icons.play_circle_fill),
                      label:
                          Text(isAudioActive ? "Pause Audio" : "Putar Audio"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade50,
                          foregroundColor: Colors.orange.shade800,
                          elevation: 0,
                          side: BorderSide(color: Colors.orange.shade200)),
                    ),
                  ),
                ),
              if (!textIsDash)
                Text(teksPertanyaan,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial'),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl),
            ],

            const SizedBox(height: 30),

            // ============================================================
            // BAGIAN 3: TOMBOL JAWABAN (A-B-C-D) ATAU LANJUT
            // ============================================================

            if (isInstruksi)
              // TOMBOL LANJUT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    onPressed: _lanjutSoal,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue), // Konsisten Biru
                    child: const Text("LANJUT (Selesai Mendengarkan)",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
              )
            else
              // TOMBOL JAWABAN
              Column(
                children: [
                  _buildOpsiButton(0, item['opsi_a']),
                  _buildOpsiButton(1, item['opsi_b']),
                  _buildOpsiButton(2, item['opsi_c']),
                  _buildOpsiButton(3, item['opsi_d']),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildOpsiButton(int index, String? text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            var section = _dataTes[_currentSectionIdx];
            var paket = section['paket_list'][_currentPaketIdx];
            var soal = paket['simulasi_soal'][_currentSoalIdx];
            _jawabSoal(index, soal);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300))),
          child: Text(text ?? "-",
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.rtl),
        ),
      ),
    );
  }
}

// ... (Kode HalamanSimulasiPage di atas biarkan saja) ...

class HasilSimulasiPage extends StatelessWidget {
  final int skorAkhir;
  final List<Map<String, dynamic>> laporan;

  const HasilSimulasiPage({
    super.key,
    required this.skorAkhir,
    required this.laporan,
  });

  // Helper untuk menghitung Predikat
  String _getPredikat(int skor) {
    if (skor >= 500) return "MUMTAZ (Istimewa)";
    if (skor >= 400) return "JAYYID JIDDAN (Sangat Baik)";
    if (skor >= 300) return "JAYYID (Baik)";
    if (skor >= 200) return "MAQBUL (Cukup)";
    return "RASIB (Kurang)";
  }

  Color _getWarnaPredikat(int skor) {
    if (skor >= 500) return Colors.green;
    if (skor >= 400) return Colors.blue;
    if (skor >= 300) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Hitung Ulang Rincian dari Laporan
    int benarIstima = laporan
        .where((e) => e['section'] == "Istima'" && e['status'] == true)
        .length;
    int benarTarakib = laporan
        .where((e) => e['section'] == "Tarakib" && e['status'] == true)
        .length;
    int benarQiraah = laporan
        .where((e) => e['section'] == "Qira'ah" && e['status'] == true)
        .length;

    // Ambil Nilai Konversi per Sesi (untuk ditampilkan)
    int skIstima = DataKonversiTosa.istima[benarIstima] ?? 24;
    int skTarakib = DataKonversiTosa.tarakib[benarTarakib] ?? 20;
    int skQiraah = DataKonversiTosa.qiraah[benarQiraah] ?? 21;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Hasil Tes TOSA"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- 1. KARTU SKOR UTAMA (HEADER) ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10))
                  ]),
              child: Column(
                children: [
                  const Text("SKOR AKHIR ANDA",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text("$skorAkhir",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white30, height: 30),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      _getPredikat(skorAkhir),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Rincian Per Sesi",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 15),

            // --- 2. RINCIAN PER SESI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildStatCard(context,
                      title: "Istima' (Listening)",
                      icon: Icons.headset,
                      color: Colors.blue,
                      benar: benarIstima,
                      totalSoal: 25,
                      skorKonversi: skIstima),
                  _buildStatCard(context,
                      title: "Tarakib (Structure)",
                      icon: Icons.build,
                      color: Colors.purple,
                      benar: benarTarakib,
                      totalSoal: 20,
                      skorKonversi: skTarakib),
                  _buildStatCard(context,
                      title: "Qira'ah (Reading)",
                      icon: Icons.menu_book,
                      color: Colors.orange,
                      benar: benarQiraah,
                      totalSoal: 25,
                      skorKonversi: skQiraah),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 3. TOMBOL KEMBALI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                      side: BorderSide(color: Colors.blue.shade800, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 0),
                  child: const Text("KEMBALI KE BERANDA",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required int benar,
      required int totalSoal,
      required int skorKonversi}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 5,
                offset: const Offset(0, 2))
          ]),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),

          // Info Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Benar: $benar dari $totalSoal Soal",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),

          // Nilai Konversi (Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3))),
            child: Column(
              children: [
                const Text("Nilai",
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text("$skorKonversi",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
