import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'data_konversi_tosa.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // --- STATE JAWABAN USER ---
  // Map untuk menyimpan jawaban: Key="section_paket_soal", Value=IndexJawaban (0-3)
  final Map<String, int> _jawabanUser = {};

  // --- STATE TIMER & AUDIO ---
  int _sisaWaktu = durasiPerSection;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;
  String? _currentPlayingUrl;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ambilDataDariSupabase();

    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted)
        setState(() => _isAudioPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged
        .listen((d) => setState(() => _audioDuration = d));
    _audioPlayer.onPositionChanged
        .listen((p) => setState(() => _audioPosition = p));
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
      setState(() => _currentPlayingUrl = url);
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

  // --- FUNGSI SIMPAN JAWABAN (TANPA PINDAH SOAL) ---
  void _pilihJawaban(int indexOpsi) {
    String key = "$_currentSectionIdx-$_currentPaketIdx-$_currentSoalIdx";
    setState(() {
      _jawabanUser[key] = indexOpsi;
    });
  }

  // --- LOGIKA NAVIGASI TOMBOL ---
  void _keSoalSebelumnya() {
    // Stop audio kalau pindah
    _audioPlayer.stop();
    _currentPlayingUrl = null;

    var currentSection = _dataTes[_currentSectionIdx];
    var currentPaketList = currentSection['paket_list'] as List;

    setState(() {
      if (_currentSoalIdx > 0) {
        _currentSoalIdx--;
      } else if (_currentPaketIdx > 0) {
        _currentPaketIdx--;
        // Set ke soal terakhir di paket sebelumnya
        var prevSoalList =
            currentPaketList[_currentPaketIdx]['simulasi_soal'] as List;
        _currentSoalIdx = prevSoalList.length - 1;
      }
    });
  }

  void _keSoalSelanjutnya() {
    // Cek apakah ini Instruksi? Kalau instruksi gak wajib jawab
    var currentItem = (_dataTes[_currentSectionIdx]['paket_list']
        as List)[_currentPaketIdx]['simulasi_soal'][_currentSoalIdx];
    bool isInstruksi = currentItem['tipe'] == 'instruksi';

    // Validasi Jawaban (Kecuali Instruksi)
    String key = "$_currentSectionIdx-$_currentPaketIdx-$_currentSoalIdx";
    if (!isInstruksi && !_jawabanUser.containsKey(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Pilih jawaban dulu ya!"),
            duration: Duration(milliseconds: 1000)),
      );
      return;
    }

    _audioPlayer.stop();
    _currentPlayingUrl = null;

    var currentSection = _dataTes[_currentSectionIdx];
    var currentPaketList = currentSection['paket_list'] as List;
    var currentSoalList =
        currentPaketList[_currentPaketIdx]['simulasi_soal'] as List;

    if (_currentSoalIdx < currentSoalList.length - 1) {
      setState(() => _currentSoalIdx++);
    } else if (_currentPaketIdx < currentPaketList.length - 1) {
      setState(() {
        _currentPaketIdx++;
        _currentSoalIdx = 0;
      });
    } else {
      // Akhir Section
      if (_currentSectionIdx < _dataTes.length - 1) {
        _tampilKonfirmasiSelesaiSection();
      } else {
        _selesaiTes();
      }
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
      barrierDismissible: false,
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

  Future<void> _selesaiTes() async {
    _timer?.cancel();
    _audioPlayer.stop();

    final userFirebase = FirebaseAuth.instance.currentUser;
    if (userFirebase == null) return;

    // Hitung Laporan Akhir dari Map Jawaban
    List<Map<String, dynamic>> laporanFinal = [];

    // Loop semua soal untuk mencocokkan jawaban
    for (int sIdx = 0; sIdx < _dataTes.length; sIdx++) {
      var section = _dataTes[sIdx];
      var paketList = section['paket_list'] as List;

      for (int pIdx = 0; pIdx < paketList.length; pIdx++) {
        var soalList = paketList[pIdx]['simulasi_soal'] as List;

        for (int qIdx = 0; qIdx < soalList.length; qIdx++) {
          var soal = soalList[qIdx];

          // Skip instruksi
          if (soal['tipe'] == 'instruksi') continue;

          String key = "$sIdx-$pIdx-$qIdx";
          int? userAnsIdx = _jawabanUser[key];
          int kunciIdx =
              soal['kunci']; // Pastikan di DB kuncinya integer (0,1,2,3)

          bool isCorrect = (userAnsIdx != null && userAnsIdx == kunciIdx);

          List<dynamic> opsi = [
            soal['opsi_a'],
            soal['opsi_b'],
            soal['opsi_c'],
            soal['opsi_d']
          ];

          laporanFinal.add({
            'section': section['nama_section'],
            'pertanyaan': soal['pertanyaan'],
            'jawaban_user': userAnsIdx != null ? opsi[userAnsIdx] : "-",
            'jawaban_benar': opsi[kunciIdx],
            'status': isCorrect
          });
        }
      }
    }

    int benarIstima = laporanFinal
        .where((e) => e['section'] == "Istima'" && e['status'] == true)
        .length;
    int benarQiraah = laporanFinal
        .where((e) => e['section'] == "Qira'ah" && e['status'] == true)
        .length;
    int benarTarakib = laporanFinal
        .where((e) => e['section'] == "Tarakib" && e['status'] == true)
        .length;

    int skorFinalTosa = DataKonversiTosa.hitungSkorAkhir(
        benarIstima: benarIstima,
        benarTarakib: benarTarakib,
        benarQiraah: benarQiraah);

    // Ambil Avatar
    String? currentAvatarUrl;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userFirebase.uid)
          .get();
      if (userDoc.exists) currentAvatarUrl = userDoc.get('avatar_url');
    } catch (e) {}

    // Simpan ke Supabase
    try {
      final supabase = Supabase.instance.client;
      String namaUser =
          userFirebase.displayName ?? userFirebase.email ?? "Siswa Firebase";

      await supabase.from('profil_siswa').upsert({
        'id': userFirebase.uid,
        'nama': namaUser,
        'email': userFirebase.email,
        'avatar_url': currentAvatarUrl,
      });

      await supabase.from('riwayat_skor').insert({
        'user_id': userFirebase.uid,
        'nama_siswa': namaUser,
        'skor_akhir': skorFinalTosa,
        'predikat': _hitungPredikat(skorFinalTosa),
        'benar_istima': benarIstima,
        'benar_tarakib': benarTarakib,
        'benar_qiraah': benarQiraah,
        'jenis': 'simulasi',
        'judul_materi': 'Simulasi TOSA'
      });
    } catch (e) {
      print("Gagal simpan: $e");
    }

    if (mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HasilSimulasiPage(
                  skorAkhir: skorFinalTosa, laporan: laporanFinal)));
    }
  }

  String get _formatWaktu {
    int menit = _sisaWaktu ~/ 60;
    int detik = _sisaWaktu % 60;
    return "${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}";
  }

  String _getIndikatorSoal() {
    int totalSoalPG = 0;
    int currentPGIndex = 0;

    var currentItem = (_dataTes[_currentSectionIdx]['paket_list']
        as List)[_currentPaketIdx]['simulasi_soal'][_currentSoalIdx];
    if (currentItem['tipe'] == 'instruksi') return "Petunjuk";

    var section = _dataTes[_currentSectionIdx];
    var listPaket = section['paket_list'] as List;

    for (int i = 0; i < listPaket.length; i++) {
      var p = listPaket[i];
      var listS = p['simulasi_soal'] as List;
      for (int j = 0; j < listS.length; j++) {
        var item = listS[j];
        if (item['tipe'] != 'instruksi') {
          totalSoalPG++;
          if (i < _currentPaketIdx ||
              (i == _currentPaketIdx && j < _currentSoalIdx)) {
            currentPGIndex++;
          }
        }
      }
    }
    return "${currentPGIndex + 1} / $totalSoalPG";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_dataTes.isEmpty)
      return const Scaffold(
          body: Center(child: Text("Belum ada soal simulasi.")));

    var section = _dataTes[_currentSectionIdx];
    var paket = section['paket_list'][_currentPaketIdx];
    var item = paket['simulasi_soal'][_currentSoalIdx];

    bool isInstruksi = item['tipe'] == 'instruksi';
    String teksPertanyaan = (item['pertanyaan'] ?? '-').toString().trim();
    bool textIsDash = teksPertanyaan == '-';
    bool hasItemAudio =
        item['audio_url'] != null && item['audio_url'].toString().isNotEmpty;
    bool isAudioActive =
        _isAudioPlaying && _currentPlayingUrl == item['audio_url'];

    Color warnaTema = Colors.blue;
    if (section['nama_section'] == "Qira'ah") warnaTema = Colors.orange;
    if (section['nama_section'] == "Tarakib") warnaTema = Colors.purple;

    // Cek tombol nav visibility
    bool isFirstQuestion = _currentSectionIdx == 0 &&
        _currentPaketIdx == 0 &&
        _currentSoalIdx == 0;
    bool isLastInSection = false;
    // Logic last in section agak kompleks, kita biarkan tombol 'Selanjutnya' handle

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
                child: Text(section['nama_section'],
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black))),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- BAGIAN 1: STIMULUS ---
                  Builder(builder: (context) {
                    bool adaJudul = paket['judul_paket'] != null &&
                        paket['judul_paket'].toString().trim().isNotEmpty &&
                        paket['judul_paket'] != '-';
                    bool adaTeks = paket['jenis_konten'] == 'teks' &&
                        paket['konten_url'] != null &&
                        paket['konten_url'].toString().trim().isNotEmpty &&
                        paket['konten_url'] != '-';
                    bool adaAudio = paket['jenis_konten'] == 'audio' &&
                        paket['konten_url'] != null;

                    if (!adaJudul && !adaTeks && !adaAudio)
                      return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: warnaTema.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: warnaTema.withOpacity(0.5))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              paket['jenis_konten'] == 'teks'
                                  ? "Bacaan / Nash"
                                  : "Stimulus / Pengantar Soal",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: warnaTema)),
                          const SizedBox(height: 10),
                          if (adaJudul)
                            Text(paket['judul_paket'],
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.justify,
                                textDirection: TextDirection.rtl),
                          if (adaTeks)
                            Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 300),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.grey.shade300)),
                                child: SingleChildScrollView(
                                    child: Text(paket['konten_url'],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Arial',
                                            height: 1.8),
                                        textAlign: TextAlign.justify,
                                        textDirection: TextDirection.rtl))),
                          if (adaAudio)
                            Row(children: [
                              IconButton(
                                  icon: Icon((_isAudioPlaying &&
                                          _currentPlayingUrl ==
                                              paket['konten_url'])
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  onPressed: () =>
                                      _toggleAudio(paket['konten_url'])),
                              const Expanded(
                                  child: Text("Audio Induk",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)))
                            ]),
                        ],
                      ),
                    );
                  }),

                  // --- BAGIAN 2: ITEM SOAL ---
                  if (hasItemAudio && textIsDash) ...[
                    SizedBox(
                      height: 350,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              isInstruksi
                                  ? "Simak Audio Pengantar"
                                  : "Simak Audio Soal",
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                  item['pertanyaan'] != '-'
                                      ? item['pertanyaan']
                                      : (isInstruksi
                                          ? "Dengarkan materi ini baik-baik."
                                          : "Dengarkan audio lalu pilih jawaban."),
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600]),
                                  textAlign: TextAlign.center)),
                          const SizedBox(height: 30),
                          GestureDetector(
                              onTap: () => _toggleAudio(item['audio_url']),
                              child: Container(
                                  padding: const EdgeInsets.all(25),
                                  decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle),
                                  child: Icon(
                                      isAudioActive
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 80,
                                      color: Colors.blue))),
                          const SizedBox(height: 20),
                          if (isAudioActive)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(children: [
                                  Text(_audioPosition
                                      .toString()
                                      .split('.')
                                      .first
                                      .substring(2)),
                                  Expanded(
                                      child: Slider(
                                          value: _audioPosition.inSeconds
                                              .toDouble(),
                                          max: _audioDuration.inSeconds
                                                      .toDouble() >
                                                  0
                                              ? _audioDuration.inSeconds
                                                  .toDouble()
                                              : 1,
                                          onChanged: (v) => _audioPlayer.seek(
                                              Duration(seconds: v.toInt())))),
                                  Text(_audioDuration
                                      .toString()
                                      .split('.')
                                      .first
                                      .substring(2))
                                ])),
                        ],
                      ),
                    ),
                  ] else ...[
                    if (hasItemAudio)
                      Center(
                          child: ElevatedButton.icon(
                              onPressed: () => _toggleAudio(item['audio_url']),
                              icon: Icon(isAudioActive
                                  ? Icons.pause
                                  : Icons.play_circle_fill),
                              label: Text(isAudioActive
                                  ? "Pause Audio"
                                  : "Putar Audio"))),
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

                  // --- BAGIAN 3: OPSI JAWABAN ---
                  if (!isInstruksi)
                    Column(children: [
                      _buildOpsiButton(0, item['opsi_a']),
                      _buildOpsiButton(1, item['opsi_b']),
                      _buildOpsiButton(2, item['opsi_c']),
                      _buildOpsiButton(3, item['opsi_d']),
                    ]),
                ],
              ),
            ),
          ),

          // --- BAGIAN 4: NAVIGASI BAWAH ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))
            ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isFirstQuestion)
                  ElevatedButton.icon(
                    onPressed: _keSoalSebelumnya,
                    icon: const Icon(Icons.arrow_back_ios,
                        size: 16, color: Colors.black54),
                    label: const Text("Kembali",
                        style: TextStyle(color: Colors.black54)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200),
                  )
                else
                  const SizedBox(width: 100), // Spacer

                Directionality(
                  textDirection: TextDirection.rtl,
                  child: ElevatedButton.icon(
                    onPressed: _keSoalSelanjutnya,
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: Colors.white),
                    label: Text(
                        (_currentSectionIdx == _dataTes.length - 1 &&
                                _currentPaketIdx ==
                                    (section['paket_list'] as List).length -
                                        1 &&
                                _currentSoalIdx ==
                                    (paket['simulasi_soal'] as List).length - 1)
                            ? "Selesai"
                            : "Selanjutnya",
                        style: const TextStyle(color: Colors.white)),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOpsiButton(int index, String? text) {
    // Cek apakah opsi ini dipilih?
    String key = "$_currentSectionIdx-$_currentPaketIdx-$_currentSoalIdx";
    bool isSelected = _jawabanUser[key] == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _pilihJawaban(index),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue.shade100 : Colors.white,
            foregroundColor: isSelected ? Colors.blue.shade900 : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: isSelected ? 0 : 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1)),
          ),
          child: Text(text ?? "-",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              textDirection: TextDirection.rtl),
        ),
      ),
    );
  }
}

// ... Class HasilSimulasiPage tetap sama seperti sebelumnya ...
class HasilSimulasiPage extends StatelessWidget {
  final int skorAkhir;
  final List<Map<String, dynamic>> laporan;

  const HasilSimulasiPage(
      {super.key, required this.skorAkhir, required this.laporan});

  // Helper Predikat
  String _getPredikat(int skor) {
    if (skor >= 500) return "MUMTAZ (Istimewa)";
    if (skor >= 400) return "JAYYID JIDDAN (Sangat Baik)";
    if (skor >= 300) return "JAYYID (Baik)";
    if (skor >= 200) return "MAQBUL (Cukup)";
    return "RASIB (Kurang)";
  }

  @override
  Widget build(BuildContext context) {
    // 1. Hitung Rincian
    int benarIstima = laporan
        .where((e) => e['section'] == "Istima'" && e['status'] == true)
        .length;
    int benarTarakib = laporan
        .where((e) => e['section'] == "Tarakib" && e['status'] == true)
        .length;
    int benarQiraah = laporan
        .where((e) => e['section'] == "Qira'ah" && e['status'] == true)
        .length;

    // Skor Konversi
    int skIstima = DataKonversiTosa.istima[benarIstima] ?? 24;
    int skTarakib = DataKonversiTosa.tarakib[benarTarakib] ?? 20;
    int skQiraah = DataKonversiTosa.qiraah[benarQiraah] ?? 21;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          title: const Text("Hasil Tes TOSA"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Skor
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.blue.shade800, Colors.blue.shade400]),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10))
                  ]),
              child: Column(children: [
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
                    child: Text(_getPredikat(skorAkhir),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)))
              ]),
            ),
            const SizedBox(height: 30),
            // Rincian
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  _buildStatCard(
                      title: "Istima' (Listening)",
                      icon: Icons.headset,
                      color: Colors.blue,
                      benar: benarIstima,
                      totalSoal: 25,
                      skorKonversi: skIstima),
                  _buildStatCard(
                      title: "Tarakib (Structure)",
                      icon: Icons.build,
                      color: Colors.purple,
                      benar: benarTarakib,
                      totalSoal: 20,
                      skorKonversi: skTarakib),
                  _buildStatCard(
                      title: "Qira'ah (Reading)",
                      icon: Icons.menu_book,
                      color: Colors.orange,
                      benar: benarQiraah,
                      totalSoal: 25,
                      skorKonversi: skQiraah),
                ])),
            const SizedBox(height: 30),
            // Tombol Kembali
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade800,
                            side: BorderSide(
                                color: Colors.blue.shade800, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        child: const Text("KEMBALI KE BERANDA",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16))))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
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
      child: Row(children: [
        Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28)),
        const SizedBox(width: 15),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text("Benar: $benar dari $totalSoal Soal",
              style: TextStyle(color: Colors.grey[600], fontSize: 13))
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3))),
            child: Column(children: [
              const Text("Nilai",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text("$skorKonversi",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color))
            ]))
      ]),
    );
  }
}
