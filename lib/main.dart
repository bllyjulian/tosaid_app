import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Tambahkan 'hide User' di belakangnya
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

// --- IMPORT HALAMAN ---
import 'daftar_bab.dart'; // Import ini PENTING
import 'halaman_simulasi.dart';
import 'halaman_forum.dart';
import 'halaman_login.dart';
import 'halaman_leaderboard.dart';
import 'halaman_target.dart';
import 'halaman_rapor.dart';
import 'halaman_profil.dart';
import 'halaman_pengantar_kategori.dart'; // Import ini PENTING

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBAk5uIcvgIS7bfg9uNeW25uDtGE-PW43U",
          appId: "1:636662978544:web:f3a4deb5f3e43da1696f35",
          messagingSenderId: "636662978544",
          projectId: "tosaapp-18c4b",
          storageBucket: "tosaapp-18c4b.firebasestorage.app",
        ),
      );
    } else {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCzydnnY3YD2mbAOHoE6EFGdYcNOtra784",
          appId: "1:636662978544:android:bdad5339b8837789696f35",
          messagingSenderId: "636662978544",
          projectId: "tosaapp-18c4b",
          storageBucket: "tosaapp-18c4b.firebasestorage.app",
        ),
      );
    }
  } catch (e) {
    print("FATAL ERROR FIREBASE: $e");
  }
  await Supabase.initialize(
    url: 'https://nibjtzhsngsnugjihzzc.supabase.co', // Ganti Project URL
    anonKey: 'sb_secret_fbqOGIZFz7lSO99_G5wbmQ_FRLd9OHv', // Ganti Anon Key
  );
  runApp(const TosaApp());
}

class TosaApp extends StatelessWidget {
  const TosaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TOSA App',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePageContent(),
    const HalamanTargetPage(),
    const HalamanRaporPage(),
    const HalamanProfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1)
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF009688),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            _buildNavItem('assets/icons/nav_home.png', "Home"),
            _buildNavItem('assets/icons/nav_target.png', "Target"),
            _buildNavItem('assets/icons/nav_rapor.png', "Rapor"),
            _buildNavItem('assets/icons/nav_profil.png', "Profil"),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(String assetPath, String label) {
    return BottomNavigationBarItem(
      icon: ImageIcon(AssetImage(assetPath), size: 24),
      label: label,
    );
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderSection(),
            const SizedBox(height: 24),
            const TargetCard(),
            const SizedBox(height: 24),
            const Text(
              "Materi & Latihan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // GRID MENU UTAMA
            Row(
              children: [
                // === MENU 1: ISTIMA' ===
                Expanded(
                  child: MenuCard(
                    title: "Istima'",
                    percent: 0.3,
                    color: const Color(0xFF42A5F5),
                    imagePath: 'assets/images/istima.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HalamanPengantarKategoriPage(
                            title: "Pengantar Istima'",
                            pathPdf:
                                "assets/pdfs/1_intro.pdf", // Pastikan file ada di assets

                            // DATA YANG DIBAWA UNTUK HALAMAN SELANJUTNYA:
                            titleDaftarBab: "Istima' (Listening)",
                            colorDaftarBab: const Color(0xFF42A5F5),
                            kategoriDatabase: "Istima'",
                            kodeKategoriFile: "1",

                            // LIST DATA BAB (JANGAN PAKAI const DI DEPAN LIST INI)
                            dataBab: [
                              // --- BAB 1 ---
                              {
                                'judul': "an-Naw‘ al-Awwal",
                                'sub_bab': [
                                  {
                                    'judul_arab': 'Petunjuk Pola Pertama',
                                    'judul_latin': 'Baca terlebih dahulu',
                                    'file_pdf':
                                        'assets/pdfs/1_pola1_materi1.pdf'
                                  },
                                  {
                                    'judul_arab':
                                        'التَّحِيَّاتُ فِي الْعَرَبِيَّةِ',
                                    'judul_latin': 'Sapaan Dalam Bahasa Arab',
                                    'file_pdf':
                                        'assets/pdfs/1_pola1_materi2.pdf'
                                  },
                                ],
                                'latihan': [],
                              },
                              // --- BAB 2 ---
                              {
                                'judul': "an-Naw‘ ats-Tsānī",
                                'sub_bab': [
                                  {
                                    'judul_arab': 'Materi Pola 2',
                                    'judul_latin': 'Dialog Singkat',
                                    'file_pdf':
                                        'assets/pdfs/1_pola2_materi1.pdf'
                                  },
                                ],
                                'latihan': [],
                              },
                              // --- BAB 3 ---
                              {
                                'judul': "an-Naw‘ ats-Tsālis",
                                'sub_bab': [
                                  {
                                    'judul_arab': 'Materi Pola 3',
                                    'judul_latin': 'Dialog Panjang',
                                    'file_pdf':
                                        'assets/pdfs/1_pola3_materi1.pdf'
                                  },
                                ],
                                'latihan': [],
                              },
                              // --- BAB 4 ---
                              {
                                'judul': "an-Naw‘ ar-Rābi‘",
                                'sub_bab': [
                                  {
                                    'judul_arab': 'Materi Pola 4',
                                    'judul_latin': 'Teks / Pidato',
                                    'file_pdf':
                                        'assets/pdfs/1_pola4_materi1.pdf'
                                  },
                                ],
                                'latihan': [],
                              },
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // === MENU 2: QIRA'AH ===
                Expanded(
                  child: MenuCard(
                    title: "Qira'ah",
                    percent: 0.15,
                    color: const Color(0xFFFF9800),
                    imagePath: 'assets/images/qiraah.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HalamanPengantarKategoriPage(
                            title: "Pengantar Qira'ah",
                            pathPdf: "assets/pdfs/2_intro.pdf",
                            titleDaftarBab: "Qira'ah (Reading)",
                            colorDaftarBab: const Color(0xFFFF9800),
                            kategoriDatabase: "Qira'ah",
                            kodeKategoriFile: "2",
                            dataBab: [
                              {
                                'judul': "Ta' yinu al Maudhu",
                                'sub_bab': [
                                  {
                                    'judul_arab': "Ta' yinu al Maudhu",
                                    'judul_latin': 'Menentukan topik bacaan',
                                    'file_pdf':
                                        'assets/pdfs/2_pola1_materi1.pdf'
                                  }
                                ],
                                'latihan': [],
                              },
                              {
                                'judul': "Ta‘yīnu al-Fikrah al-Ra’īsiyyah",
                                'sub_bab': [
                                  {
                                    'judul_arab':
                                        "تَعْيِينُ الْفِكْرَةِ الرَّئِيسِيَّةِ",
                                    'judul_latin': 'Menentukan ide pokok',
                                    'file_pdf':
                                        'assets/pdfs/2_pola2_materi1.pdf'
                                  }
                                ],
                                'latihan': [],
                              },
                              {
                                'judul': "Marja‘u al-Kalimah",
                                'sub_bab': [
                                  {
                                    'judul_arab': "مَرْجِعُ الْكَلِمَةِ",
                                    'judul_latin': 'Menentukan rujukan kata',
                                    'file_pdf':
                                        'assets/pdfs/2_pola3_materi1.pdf'
                                  }
                                ],
                                'latihan': [],
                              },
                              {
                                'judul': "Istinbāṭu an-Nash",
                                'sub_bab': [
                                  {
                                    'judul_arab': "اسْتِنْبَاطُ النَّصِّ",
                                    'judul_latin':
                                        'Memahami teks secara literal',
                                    'file_pdf':
                                        'assets/pdfs/2_pola4_materi1.pdf'
                                  }
                                ],
                                'latihan': [],
                              },
                              {
                                'judul': "Ta‘yīnu Ma‘na al-Kalimah",
                                'sub_bab': [
                                  {
                                    'judul_arab':
                                        "تَعْيِينُ مَعْنَى الْكَلِمَةِ",
                                    'judul_latin': 'Memahami makna kata',
                                    'file_pdf':
                                        'assets/pdfs/2_pola5_materi1.pdf'
                                  }
                                ],
                                'latihan': [],
                              },
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // GRID BARIS 2 (TARAKIB)
            Row(
              children: [
                Expanded(
                  child: MenuCard(
                    title: "Tarakib",
                    percent: 0.78,
                    color: const Color(0xFF9C27B0),
                    imagePath: 'assets/images/tarakib.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HalamanPengantarKategoriPage(
                            title: "Pengantar Tarakib",
                            pathPdf: "assets/pdfs/3_intro.pdf",
                            titleDaftarBab: "Tarakib (Struktur)",
                            colorDaftarBab: const Color(0xFF9C27B0),
                            kategoriDatabase: "Tarakib",
                            kodeKategoriFile: "3",
                            dataBab: [
                              {
                                'judul': "Takmīl al-Jumlah",
                                'sub_bab': [
                                  {
                                    'judul_arab': "تَكْمِيلُ الْجُمْلَةِ",
                                    'judul_latin': 'Melengkapi kalimat',
                                    'file_pdf':
                                        'assets/pdfs/3_pola1_materi1.pdf'
                                  }
                                ],
                                'latihan': [],
                              },
                              {
                                'judul': "Taḥlil al-Akhathā’",
                                'sub_bab': [
                                  {
                                    'judul_arab': "تَحْلِيلُ الأَخْطَاءِ",
                                    'judul_latin': 'Mengidentifikasi kesalahan',
                                    'file_pdf':
                                        'assets/pdfs/3_pola2_materi1.pdf'
                                  }
                                ],
                                'latihan': [],
                              },
                              {
                                'judul': "Qawa’id",
                                'sub_bab': [
                                  {
                                    'judul_arab': "Mubtada Khabar",
                                    'judul_latin':
                                        'kalimat yang tidak diawali kata kerja',
                                    'file_pdf':
                                        'assets/pdfs/3_pola3_materi1.pdf',
                                    'instruksi': '''
1. Perhatikan kalimat bahasa Arab yang tersedia dengan cermat.
2. Seret kata yang tepat ke kolom Mubtada’ dan Khabar sesuai fungsinya.
3. Perhatikan ketentuan berikut:
   - Mubtada’ → marfū‘ (مرفوع)
   - Khabar → marfū‘ (مرفوع)
4. Jika khabar berbentuk:
   - Satu kata → disebut khabar mufrad
   - Kalimat → disebut khabar jumlah (harus memiliki ḍhamīr yang kembali ke mubtada’)
   - Keterangan tempat/waktu → disebut khabar syibh jumlah
Perhatikan urutan kalimat:
   - Umumnya mubtada’ terlebih dahulu, lalu khabar.
''',
                                  },
                                  {
                                    'judul_arab': "Kana wa Akhwatuha",
                                    'judul_latin':
                                        'menunjukkan waktu atau perubahan keadaan',
                                    'file_pdf':
                                        'assets/pdfs/3_pola3_materi2.pdf',
                                    'instruksi': '''
1. Perhatikan setiap kalimat bahasa Arab yang tersedia dengan saksama.
2. Identifikasi kata kerja yang termasuk كَانَ وَأَخَوَاتُهَا  dalam kalimat.
3. Seret kata yang tepat ke kolom Isim Kana dan Khabar Kana sesuai fungsinya.
4. Perhatikan ketentuan berikut:
   - Isim Kana → marfū‘ (مرفوع)
   - Khabar Kana → manshūb (منصوب)

''',
                                  },
                                  {
                                    'judul_arab': "Inna wa Akhwatuha",
                                    'judul_latin':
                                        'memberi penegasan, harapan, perbandingan, atau pengecualian',
                                    'file_pdf':
                                        'assets/pdfs/3_pola3_materi3.pdf',
                                    'instruksi': '''
1. Perhatikan setiap kalimat bahasa Arab yang tersedia dengan cermat.
2. Identifikasi huruf yang termasuk إِنَّ وَأَخَوَاتُهَا  dalam kalimat.
3. Tentukan Isim Inna (اسم إنّ), yaitu kata benda yang terletak setelah Inna dan ber-i‘rāb manshūb.
4. Tentukan Khabar Inna (خبر إنّ), yaitu keterangan dari isim Inna yang tetap ber-i‘rāb marfū‘.
5. Seret kata yang tepat ke kolom Isim Inna dan Khabar Inna sesuai fungsinya dalam kalimat.
6. Perhatikan ketentuan berikut:
   - Isim Inna → manshūb (منصوب)
   - Khabar Inna → marfū‘ (مرفوع)
''',
                                  },
                                  {
                                    'judul_arab': "Fi'il Fa'il",
                                    'judul_latin':
                                        'setiap perbuatan pasti ada pelakunya',
                                    'file_pdf':
                                        'assets/pdfs/3_pola3_materi4.pdf',
                                    'instruksi': '''
1. Perhatikan setiap kalimat bahasa Arab yang tersedia dengan cermat.
2. Tentukan fi‘il (فِعْل), yaitu kata kerja yang menunjukkan suatu perbuatan atau kejadian.
3. Tentukan fa‘il (فَاعِل), yaitu pelaku dari perbuatan tersebut.
4. Seret kata yang tepat ke kolom Fi‘il dan Fa‘il sesuai dengan fungsinya dalam kalimat.
5. Perhatikan ciri-ciri fi‘il, antara lain:
   - Dapat berupa fi‘il māḍhī (lampau), fi‘il muḍhāri‘ (sedang/akan), atau fi‘il amr (perintah).
6. Perhatikan ciri-ciri fa‘il, yaitu:
   - Selalu ber-i‘rāb marfū‘
   - Biasanya terletak setelah fi‘il
   - Dapat berupa isim ẓāhir (kata benda jelas) atau ḍhamīr (kata ganti), baik tampak maupun tersembunyi.
''',
                                  },
                                  {
                                    'judul_arab': "Maf'ul bih",
                                    'judul_latin':
                                        'Objek yang dikenai pekerjaan',
                                    'file_pdf':
                                        'assets/pdfs/3_pola3_materi5.pdf',
                                    'instruksi': '''
1. Perhatikan setiap kalimat bahasa Arab yang disajikan dengan saksama.
2. Identifikasi unsur kalimat yang berupa fi‘il (kata kerja) dan fa‘il (pelaku).
3. Tentukan kata yang menjadi objek dan dikenai perbuatan, yaitu maf‘ūl bih.
4. Seret kata yang tepat ke kolom maf‘ūl bih (objek) sesuai dengan kalimat.
5. Pastikan kata yang dipilih memenuhi ciri-ciri maf‘ūl bih, yaitu:
   - Berupa isim (kata benda)
   - Berkedudukan sebagai objek perbuatan
   - Ber-i‘rāb manshūb
6. Perhatikan tanda nashab pada akhir kata maf‘ūl bih, seperti:
   - Fatḥah untuk isim mufrad dan jamak taksīr
   - Yā’ (ـيـ) untuk isim mutsannā dan jamak mudzakkar sālīm
   - Kasrah untuk jamak mu’annats sālīm
''',
                                  },
                                  {
                                    'judul_arab': "Na'at wa Man'ut",
                                    'judul_latin':
                                        'Hubungan antara kata benda dan kata sifatnya',
                                    'file_pdf':
                                        'assets/pdfs/3_pola3_materi6.pdf',
                                    'instruksi': '''
1. Perhatikan kalimat bahasa Arab yang tersedia.
2. Seret kata ke kolom Man‘ūt (kata yang disifati) dan Na‘at (kata sifat).
3. Pastikan na‘at sesuai dengan man‘ūt dalam:
   - i‘rab
   - jenis kelamin
   - jumlah
   - ma‘rifah–nakirah
''',
                                  },
                                  {
                                    'judul_arab': "Tawabi'",
                                    'judul_latin':
                                        'mengikuti i‘rab kata sebelumnya',
                                    'file_pdf':
                                        'assets/pdfs/3_pola3_materi7.pdf',
                                    'instruksi': '''
1. Bacalah setiap kalimat bahasa Arab dengan cermat.
2. Perhatikan kata yang ditanyakan pada setiap soal.
3. Tentukan jenis tawābi‘ dari kata tersebut.
4. Seret (drag) pilihan jawaban yang tersedia ke kolom yang sesuai.
5. Pilihan jawaban terdiri dari:
   - نَعْت (sifat)
   - عَطْف (penghubung)
   - تَوْكِيد (penegas)
   - بَدَل (pengganti)
''',
                                  },
                                  {
                                    'judul_arab': "Maf'ulat",
                                    'judul_latin': 'keterangan tambahan',
                                    'file_pdf':
                                        'assets/pdfs/3_pola3_materi8.pdf',
                                    'instruksi': '''
1. Bacalah setiap jumlah fi‘liyah dengan cermat.
2. Perhatikan kata yang ditanyakan.
3. Tentukan jenis maf‘ūlāt dari kata tersebut.
4. Seret (drag) jawaban yang tepat ke kolom yang tersedia.
Pilihan jawaban:
   - مَفْعُولٌ فِيهِ
   - مَفْعُولٌ لِأَجْلِهِ
   - مَفْعُولٌ مَعَهُ
''',
                                  },
                                  {
                                    'judul_arab': "A'dad",
                                    'judul_latin': 'memiliki aturan khusus',
                                    'file_pdf':
                                        'assets/pdfs/3_pola3_materi9.pdf',
                                    'instruksi': '''
1. Bacalah setiap kalimat dengan cermat.
2. Perhatikan konteks bilangan dan kata benda dalam kalimat.
3. Seret (drag) kata yang paling tepat ke tempat kosong )….).
4. Setiap soal hanya memiliki satu jawaban yang benar.
5. Pastikan jawaban sesuai dengan kaidah الأعداد (kata bilangan) dalam bahasa Arab.
''',
                                  },
                                ],
                                'latihan': [],
                              },
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // MENU SAMPING KANAN (FORUM & LEADERBOARD)
                Expanded(
                  child: Column(
                    children: [
                      SmallMenuCard(
                        title: "Forum Diskusi",
                        subtitle: "-Tanya Jawab",
                        color: const Color(0xFF009688),
                        imagePath: 'assets/images/diskusi.png',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const HalamanForumPage()));
                        },
                      ),
                      const SizedBox(height: 16),
                      SmallMenuCard(
                        title: "Leaderboard",
                        subtitle: "-Peringkat",
                        color: const Color(0xFFFFC107),
                        imagePath: 'assets/images/peringkat.png',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const HalamanLeaderboardPage()));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SimulasiCard(),
          ],
        ),
      ),
    );
  }
}

// === WIDGETS PENDUKUNG ===

class HeaderSection extends StatefulWidget {
  const HeaderSection({super.key});

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  String _namaUser = "Loading...";
  String _levelUser = "Level 1 - Mubtadi";

  @override
  void initState() {
    super.initState();
    _ambilDataUser();
  }

  void _ambilDataUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _namaUser = userDoc.get('nama');
          });
        } else {
          setState(() {
            _namaUser = user.displayName ?? "User";
          });
        }
      } catch (e) {
        setState(() => _namaUser = "User");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundImage: AssetImage('assets/images/profil.png'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, $_namaUser!",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(_levelUser,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Image.asset('assets/icons/koin.png', width: 20),
              const SizedBox(width: 6),
              const Text("1250 XP",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        )
      ],
    );
  }
}

class TargetCard extends StatelessWidget {
  const TargetCard({super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HalamanTargetPage()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Target & Progres Harian",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              padding: EdgeInsets.zero,
              lineHeight: 20.0,
              percent: 0.2,
              center: const Text("20% Selesai",
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              barRadius: const Radius.circular(10),
              progressColor: const Color(0xFF4CAF50),
              backgroundColor: Colors.grey.shade200,
              animation: true,
            ),
            const SizedBox(height: 10),
            const Text("Ayo Semangat! Selesaikan 1 Sesi lagi hari ini",
                style: TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final String title;
  final double percent;
  final Color color;
  final String imagePath;
  final VoidCallback? onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.percent,
    required this.color,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 165,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 12,
                top: 12,
                child: Text("${(percent * 100).toInt()}%",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Center(
                child: CircularPercentIndicator(
                  radius: 42.0,
                  lineWidth: 6.0,
                  percent: percent,
                  center: Container(
                    padding: const EdgeInsets.all(12),
                    child:
                        Image.asset(imagePath, width: 40, color: Colors.white),
                  ),
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SmallMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String imagePath;
  final VoidCallback? onTap;

  const SmallMenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              Image.asset(imagePath, width: 32, height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class SimulasiCard extends StatelessWidget {
  const SimulasiCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
            image: AssetImage('assets/icons/timer.png'),
            opacity: 0.1,
            alignment: Alignment.centerRight,
            scale: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Simulasi Tes TOSA",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Uji Kemampuanmu Sekarang Dengan Waktu Nyata!",
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HalamanSimulasiPage(),
                  ),
                );
              },
              icon: Image.asset('assets/icons/timer.png',
                  width: 20, color: Colors.white),
              label: const Text("Mulai Tes",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), // Merah
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          )
        ],
      ),
    );
  }
}
