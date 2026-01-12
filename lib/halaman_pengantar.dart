import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'halaman_kuis.dart';

class HalamanPengantarPage extends StatefulWidget {
  final String title;
  final String kategoriFilter;
  final String polaFilter;
  final String kodeKategori;
  final String kodePola;

  const HalamanPengantarPage({
    super.key,
    required this.title,
    required this.kategoriFilter,
    required this.polaFilter,
    required this.kodeKategori,
    required this.kodePola,
  });

  @override
  State<HalamanPengantarPage> createState() => _HalamanPengantarPageState();
}

class _HalamanPengantarPageState extends State<HalamanPengantarPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  String? _audioUrl;
  bool _isLoading = true;

  // --- TAMBAHAN UNTUK DURASI ---
  Duration _duration = Duration.zero; // Durasi total audio
  Duration _position = Duration.zero; // Posisi detik yang sedang diputar

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // 1. Listener: Kalau audio selesai
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero; // Reset ke awal
      });
    });

    // 2. Listener: Ambil durasi total saat file dimuat
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    // 3. Listener: Update posisi setiap detik (biar slider jalan)
    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });

    _siapkanAudio();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- HELPER: FORMAT WAKTU (01:30) ---
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _siapkanAudio() {
    String namaFile = "${widget.kodeKategori}_${widget.kodePola}_pengantar.mp3";
    try {
      final url = Supabase.instance.client.storage
          .from('audio_soal')
          .getPublicUrl(namaFile);

      if (mounted) {
        setState(() {
          _audioUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error get url: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _playPause() async {
    if (_audioUrl == null) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(_audioUrl!));
      }
      setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memutar audio pengantar")));
    }
  }

  void _lanjutKeKuis() {
    _audioPlayer.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HalamanKuisPage(
          title: widget.title,
          kategoriFilter: widget.kategoriFilter,
          polaFilter: widget.polaFilter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pengantar Latihan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Simak Audio Pengantar\n(${widget.polaFilter})",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Dengarkan materi ini baik-baik sebelum memulai menjawab soal latihan.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // --- PLAYER ANIMASI ---
            GestureDetector(
              onTap: _playPause,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color:
                      _isPlaying ? Colors.orange.shade100 : Colors.blue.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _isPlaying ? Colors.orange : Colors.blue,
                      width: 4),
                  boxShadow: [
                    if (_isPlaying)
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 70,
                  color: _isPlaying ? Colors.orange : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- SLIDER & DURASI ---
            Column(
              children: [
                Slider(
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  value: _position.inSeconds
                      .toDouble()
                      .clamp(0, _duration.inSeconds.toDouble()),
                  activeColor: const Color(0xFF42A5F5),
                  inactiveColor: Colors.grey.shade300,
                  onChanged: (value) async {
                    // Fitur Geser Slider (Seeking)
                    final position = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(position);

                    // Resume kalau tadinya lagi play
                    // if (!_isPlaying) {
                    //   await _audioPlayer.resume();
                    //   setState(() => _isPlaying = true);
                    // }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTime(_position),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                      Text(_formatTime(_duration),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // --- TOMBOL LANJUT ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _lanjutKeKuis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: const Text(
                  "MULAI MENGERJAKAN SOAL",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
