import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HalamanEditSimulasi extends StatefulWidget {
  final Map<String, dynamic> paketData; // Data paket yang mau diedit

  const HalamanEditSimulasi({super.key, required this.paketData});

  @override
  State<HalamanEditSimulasi> createState() => _HalamanEditSimulasiState();
}

class _HalamanEditSimulasiState extends State<HalamanEditSimulasi> {
  // --- STATE PAKET ---
  late String _selectedSection;
  late String _jenisKonten;
  late TextEditingController _teksBacaanController;
  late TextEditingController _judulPaketController;

  // File baru jika user ingin mengganti audio (opsional)
  PlatformFile? _newAudioPaketFile;
  String? _existingKontenUrl; // URL lama untuk preview

  // --- STATE SOAL ---
  List<Map<String, dynamic>> _listSoal = []; // Campuran soal lama & baru
  List<int> _deletedSoalIds = []; // ID soal lama yang dihapus user

  // Controller Form Tambah Soal
  final _tanyaCtrl = TextEditingController();
  final _optACtrl = TextEditingController();
  final _optBCtrl = TextEditingController();
  final _optCCtrl = TextEditingController();
  final _optDCtrl = TextEditingController();
  int _kunciSementara = 0;
  PlatformFile? _newAudioSoalSementara;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _initDataAwal();
  }

  void _initDataAwal() {
    final p = widget.paketData;
    _selectedSection = p['section'];
    _jenisKonten = p['jenis_konten'];
    _judulPaketController = TextEditingController(text: p['judul_paket']);
    _existingKontenUrl = p['konten_url'];

    // Jika teks, isi controller teks
    if (_jenisKonten == 'teks') {
      _teksBacaanController = TextEditingController(text: p['konten_url']);
    } else {
      _teksBacaanController = TextEditingController();
    }

    // Load Soal-soal
    if (p['simulasi_soal'] != null) {
      for (var s in p['simulasi_soal']) {
        _listSoal.add({
          'id': s['id'], // ID Database (penting untuk update)
          'pertanyaan': s['pertanyaan'],
          'opsi_a': s['opsi_a'],
          'opsi_b': s['opsi_b'],
          'opsi_c': s['opsi_c'],
          'opsi_d': s['opsi_d'],
          'kunci': s['kunci'],
          'audio_url': s['audio_url'], // URL audio lama
          'is_new': false, // Penanda ini data lama
        });
      }
    }
  }

  // --- LOGIKA FILE PICKER ---
  void _pilihAudioPaket() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['mp3', 'wav', 'm4a']);
    if (result != null) setState(() => _newAudioPaketFile = result.files.first);
  }

  void _pilihAudioSoal() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['mp3', 'wav', 'm4a']);
    if (result != null)
      setState(() => _newAudioSoalSementara = result.files.first);
  }

  // --- LOGIKA SOAL ---
  void _tambahSoalKeList() {
    if (_tanyaCtrl.text.isEmpty || _optACtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Isi pertanyaan & opsi A!")));
      return;
    }

    setState(() {
      _listSoal.add({
        'id': null, // Soal baru belum punya ID
        'pertanyaan': _tanyaCtrl.text,
        'opsi_a': _optACtrl.text,
        'opsi_b': _optBCtrl.text,
        'opsi_c': _optCCtrl.text,
        'opsi_d': _optDCtrl.text,
        'kunci': _kunciSementara,
        'file_audio': _newAudioSoalSementara, // File fisik baru
        'audio_url': null,
        'is_new': true,
      });
    });

    // Reset Form
    _tanyaCtrl.clear();
    _optACtrl.clear();
    _optBCtrl.clear();
    _optCCtrl.clear();
    _optDCtrl.clear();
    _kunciSementara = 0;
    _newAudioSoalSementara = null;
  }

  void _hapusSoalDariList(int index) {
    setState(() {
      var soal = _listSoal[index];
      // Jika ini soal lama (punya ID), catat ID-nya untuk dihapus dari DB nanti
      if (soal['id'] != null) {
        _deletedSoalIds.add(soal['id']);
      }
      _listSoal.removeAt(index);
    });
  }

  // --- LOGIKA UPDATE DATABASE ---
  void _updateData() async {
    if (_listSoal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Minimal harus ada 1 soal!")));
      return;
    }

    setState(() => _isUpdating = true);
    final supabase = Supabase.instance.client;

    try {
      String? finalKontenUrl = _existingKontenUrl;

      // 1. Cek apakah user ganti audio paket?
      if (_jenisKonten == 'audio' && _newAudioPaketFile != null) {
        String fileName = "paket_${DateTime.now().millisecondsSinceEpoch}.mp3";
        if (kIsWeb) {
          await supabase.storage
              .from('audio_soal')
              .uploadBinary(fileName, _newAudioPaketFile!.bytes!);
        } else {
          await supabase.storage
              .from('audio_soal')
              .upload(fileName, File(_newAudioPaketFile!.path!));
        }
        finalKontenUrl =
            supabase.storage.from('audio_soal').getPublicUrl(fileName);
      } else if (_jenisKonten == 'teks') {
        finalKontenUrl = _teksBacaanController.text;
      }

      // 2. Update Paket (Parent)
      await supabase.from('simulasi_paket').update({
        'section': _selectedSection,
        'jenis_konten': _jenisKonten,
        'konten_url': finalKontenUrl,
        'judul_paket': _judulPaketController.text,
      }).eq('id', widget.paketData['id']); // Update berdasarkan ID

      int paketId = widget.paketData['id'];

      // 3. Hapus Soal yang user remove
// 3. Hapus Soal yang user remove
      if (_deletedSoalIds.isNotEmpty) {
        // PERBAIKAN: Ganti .in_ menjadi .filter
        // Cara 1 (Paling aman untuk semua versi):
        await supabase
            .from('simulasi_soal')
            .delete()
            .filter('id', 'in', _deletedSoalIds);

        // ATAU Cara 2 (Jika library support):
        // await supabase.from('simulasi_soal').delete().inFilter('id', _deletedSoalIds);
      }

      // 4. Proses List Soal (Upsert / Insert)
      for (var soal in _listSoal) {
        String? audioUrl = soal['audio_url']; // Pakai URL lama defaultnya

        // Jika user upload audio BARU untuk soal ini
        if (soal['file_audio'] != null) {
          PlatformFile f = soal['file_audio'];
          String fName =
              "soal_${DateTime.now().millisecondsSinceEpoch}_${f.name}";
          if (kIsWeb)
            await supabase.storage
                .from('audio_soal')
                .uploadBinary(fName, f.bytes!);
          else
            await supabase.storage
                .from('audio_soal')
                .upload(fName, File(f.path!));
          audioUrl = supabase.storage.from('audio_soal').getPublicUrl(fName);
        }

        Map<String, dynamic> dataSoal = {
          'paket_id': paketId,
          'pertanyaan': soal['pertanyaan'],
          'opsi_a': soal['opsi_a'],
          'opsi_b': soal['opsi_b'],
          'opsi_c': soal['opsi_c'],
          'opsi_d': soal['opsi_d'],
          'kunci': soal['kunci'],
          'audio_url': audioUrl,
        };

        if (soal['is_new'] == true) {
          // INSERT soal baru
          await supabase.from('simulasi_soal').insert(dataSoal);
        } else {
          // UPDATE soal lama (jika ada perubahan teks)
          await supabase
              .from('simulasi_soal')
              .update(dataSoal)
              .eq('id', soal['id']);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Data Berhasil Diupdate!"),
            backgroundColor: Colors.green));
        Navigator.pop(context, true); // Kembali & Refresh list
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Paket Simulasi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EDIT PAKET ---
            const Text("Edit Info Paket",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedSection,
              decoration: const InputDecoration(labelText: "Section"),
              items: ["Istima'", "Qira'ah", "Tarakib"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedSection = v!;
                _jenisKonten = (v == "Istima'") ? "audio" : "teks";
              }),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _judulPaketController,
                decoration: const InputDecoration(labelText: "Judul Paket")),
            const SizedBox(height: 10),

            if (_jenisKonten == 'audio') ...[
              if (_existingKontenUrl != null)
                Text("Audio Lama Tersedia ✅",
                    style: TextStyle(
                        color: Colors.green[700], fontStyle: FontStyle.italic)),
              ElevatedButton.icon(
                  onPressed: _pilihAudioPaket,
                  icon: const Icon(Icons.upload),
                  label: Text(_newAudioPaketFile == null
                      ? "Ganti Audio (Opsional)"
                      : "File Baru: ${_newAudioPaketFile!.name}"))
            ] else ...[
              TextField(
                  controller: _teksBacaanController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: "Teks Bacaan")),
            ],

            const Divider(height: 40, thickness: 2),

            // --- LIST SOAL SAAT INI ---
            const Text("Daftar Soal (Bisa dihapus/diedit)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _listSoal.length,
              itemBuilder: (context, index) {
                var s = _listSoal[index];
                return Card(
                  color: s['is_new']
                      ? Colors.green[50]
                      : Colors.white, // Hijau muda kalau soal baru
                  child: ListTile(
                    title: Text(s['pertanyaan']),
                    subtitle:
                        Text("Kunci: ${['A', 'B', 'C', 'D'][s['kunci']]}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _hapusSoalDariList(index),
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 40),

            // --- FORM TAMBAH SOAL BARU ---
            const Text("Tambah Soal Baru",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextField(
                controller: _tanyaCtrl,
                decoration: const InputDecoration(labelText: "Pertanyaan")),
            if (_selectedSection == "Istima'") ...[
              const SizedBox(height: 5),
              ElevatedButton.icon(
                  onPressed: _pilihAudioSoal,
                  icon: const Icon(Icons.volume_up),
                  label: Text(_newAudioSoalSementara == null
                      ? "Audio Soal (Opsional)"
                      : "Audio Terpilih"))
            ],
            _buildOpsi("A", _optACtrl, 0),
            _buildOpsi("B", _optBCtrl, 1),
            _buildOpsi("C", _optCCtrl, 2),
            _buildOpsi("D", _optDCtrl, 3),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _tambahSoalKeList,
                child: const Text("Masukan ke Daftar")),

            const SizedBox(height: 30),

            // --- TOMBOL SIMPAN PERUBAHAN ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: _isUpdating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("UPDATE DATA",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOpsi(String label, TextEditingController ctrl, int val) {
    return Row(children: [
      Radio(
          value: val,
          groupValue: _kunciSementara,
          onChanged: (v) => setState(() => _kunciSementara = v as int)),
      Expanded(
          child: TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: "Opsi $label")))
    ]);
  }
}
