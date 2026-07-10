import 'package:flutter/foundation.dart';

/// Dinaikkan nilainya setiap kali status dosis sebuah obat berubah dari *luar*
/// widget yang saat ini memiliki daftar tersebut — terutama saat sebuah dosis
/// dikonfirmasi dari layar alarm berbunyi layar penuh. Layar seperti HomePage
/// mendengarkan (listen) perubahan ini lalu memuat ulang, sehingga "jadwal
/// terdekat" langsung ter-update tanpa pengguna harus berpindah tab navigasi
/// bawah untuk memaksa pembangunan ulang (rebuild).
final ValueNotifier<int> medicineDataRevision = ValueNotifier<int>(0);

/// Memberi sinyal bahwa data obat/dosis berubah dan layar yang terbuka sebaiknya menyegarkan tampilan.
void notifyMedicineDataChanged() => medicineDataRevision.value++;
