// File: lib/data_konversi_tosa.dart

class DataKonversiTosa {
  // --- SECTION 1: LISTENING / ISTIMA' (Max 25 Soal) ---
  static const Map<int, int> istima = {
    25: 68,
    24: 66,
    23: 63,
    22: 61,
    21: 59,
    20: 57,
    19: 56,
    18: 54,
    17: 53,
    16: 52,
    15: 51,
    14: 49,
    13: 48,
    12: 47,
    11: 46,
    10: 45,
    9: 43,
    8: 41,
    7: 39,
    6: 37,
    5: 33,
    4: 32,
    3: 30,
    2: 28,
    1: 26,
    0: 24,
  };

  // --- SECTION 2: STRUCTURE / TARAKIB (Max 20 Soal) ---
  static const Map<int, int> tarakib = {
    20: 68,
    19: 65,
    18: 61,
    17: 58,
    16: 56,
    15: 54,
    14: 52,
    13: 50,
    12: 48,
    11: 46,
    10: 44,
    9: 43,
    8: 40,
    7: 38,
    6: 36,
    5: 33,
    4: 29,
    3: 26,
    2: 23,
    1: 21,
    0: 20,
  };

  // --- SECTION 3: READING / QIRA'AH (Max 25 Soal) ---
  static const Map<int, int> qiraah = {
    25: 67,
    24: 65,
    23: 61,
    22: 59,
    21: 57,
    20: 55,
    19: 54,
    18: 52,
    17: 51,
    16: 49,
    15: 48,
    14: 46,
    13: 45,
    12: 43,
    11: 42,
    10: 40,
    9: 38,
    8: 36,
    7: 34,
    6: 31,
    5: 29,
    4: 28,
    3: 26,
    2: 24,
    1: 23,
    0: 21,
  };

  // --- RUMUS HITUNG SKOR AKHIR ---
  static int hitungSkorAkhir(
      {required int benarIstima,
      required int benarTarakib,
      required int benarQiraah}) {
    // 1. Ambil Nilai Konversi (Default ke nilai terendah jika tidak ketemu)
    int n1 = istima[benarIstima] ?? 24;
    int n2 = tarakib[benarTarakib] ?? 20;
    int n3 = qiraah[benarQiraah] ?? 21;

    // 2. Rumus: (Total Nilai Konversi / 3) * 10
    double rataRata = (n1 + n2 + n3) / 3;
    double skorFinal = rataRata * 10;

    return skorFinal.round(); // Bulatkan agar tidak koma
  }
}
