# Laporan Proyek Individu
## Mobile Programming Course

**Nama:** Ivan Raditya  *(Mohon pastikan/ubah jika tidak sesuai)*
**NIM:** [Masukkan NIM Anda]
**Nama Aplikasi yang Dibangun:** Libra Go

---

## BAB I: PENDAHULUAN

**1.1 Latar Belakang dan Deskripsi Aplikasi**
**Libra Go** adalah aplikasi mobile pintar berbasis kerangka kerja Flutter yang dibangun untuk menjadi asisten pribadi digital bagi pengguna dalam merencanakan perjalanan dan liburan. Aplikasi ini tidak hanya berfungsi sebagai pengingat jadwal (*itinerary*), melainkan juga dilengkapi dengan berbagai fitur pencatatan dan pengelolaan keuangan terintegrasi, yang seringkali menjadi permasalahan utama wisatawan (seperti manajemen anggaran *budgeting*, pelacakan pengeluaran *expense tracking*, hingga pembagian tagihan *split bill*).

**1.2 Rincian Fitur-Fitur Aplikasi**
Aplikasi Libra Go telah dirancang dengan arsitektur komprehensif yang memuat fitur-fitur utama sebagai berikut:

*   **Otentikasi dan Manajemen Profil (Authentication):**
    Aplikasi memfasilitasi pembuatan akun baru, *login* yang aman, pemulihan kata sandi (*forgot password*), serta pengaturan data pribadi dan keamanan berlapis (termasuk ganti PIN/Password). Data autentikasi dilindungi dengan aman menggunakan layanan *backend* terintegrasi.
*   **Manajemen Perjalanan (Vacation Management):**
    Pengguna dapat membuat (*create*), melihat (*read*), memperbarui (*update*), dan menghapus rencana perjalanan mereka. Selain itu, fitur kolaboratif disisipkan agar pengguna dapat mengundang rekan perjalanannya ke dalam sistem (*Invite Member*), sehingga perencanaan dan pembagian biaya bisa dilakukan secara bersama-sama dalam satu grup.
*   **Pencatatan Keuangan dan Anggaran (Budget & Expense Tracking):**
    Sistem pintar untuk mengatur *budget* maksimal dari suatu liburan. Setiap pengeluaran (*expense*) dapat dicatat, dikategorikan (contoh: transportasi, konsumsi, penginapan), dan dilengkapi dengan fitur unggah foto/struk bukti bayar (melalui kamera atau galeri lokal). Fitur *Split Bill* juga ditambahkan agar tagihan bersama dapat dihitung dan dibagi secara otomatis kepada anggota liburan.
*   **Eksplorasi Destinasi Terpadu (Destination Guide):**
    Pengguna disediakan modul untuk menelusuri informasi komprehensif terkait destinasi liburan yang dituju. Modul ini dipecah lebih spesifik meliputi informasi Akomodasi, Pusat Kuliner, Lokasi Belanja, hingga Opsi Transportasi.
*   **Integrasi Peta Interaktif (Trip Map Navigation):**
    Aplikasi memanfaatkan layanan pemetaan (*flutter_map* dan koordinat *latlong*) untuk memvisualisasikan rute perjalanan dan melihat detail lokasi titik destinasi secara akurat dari dalam aplikasi.
*   **Sistem Notifikasi Pintar (Push Notifications):**
    Penerapan sistem *push notification* berbasis Firebase Cloud Messaging (FCM), memungkinkan setiap anggota perjalanan menerima notifikasi secara langsung terkait undangan grup, pembaruan jadwal, atau penambahan pengeluaran baru.

---

## 2. Deskripsi Aplikasi

### a. Screenshot Tampilan beserta Fungsinya

1.  **Tampilan Home Screen**
    *   *(Masukkan Screenshot Home Screen di sini)*
    *   **Fungsi:** Halaman utama dashboard pengguna yang menampilkan ringkasan pengeluaran, daftar liburan yang akan datang, destinasi populer, serta akses cepat ke menu lainnya.

2.  **Tampilan Trips Screen / All Trips**
    *   *(Masukkan Screenshot Trips Screen di sini)*
    *   **Fungsi:** Menampilkan daftar seluruh rencana perjalanan pengguna, baik yang sedang direncanakan maupun yang sudah berlalu.

3.  **Tampilan Add Expense Screen**
    *   *(Masukkan Screenshot Add Expense Screen di sini)*
    *   **Fungsi:** Formulir untuk mencatat pengeluaran baru, mengkategorikan pengeluaran (makanan, transportasi, dll.), memasukkan nominal, serta mengunggah foto bukti pembayaran.

4.  **Tampilan Vacation Detail & Itinerary**
    *   *(Masukkan Screenshot Vacation Detail di sini)*
    *   **Fungsi:** Menampilkan informasi detail dari satu perjalanan khusus, termasuk jadwal harian, anggaran yang tersisa, dan daftar anggota perjalanan.

5.  **Tampilan Login / Register Screen**
    *   *(Masukkan Screenshot Login Screen di sini)*
    *   **Fungsi:** Halaman autentikasi bagi pengguna untuk masuk ke dalam akun mereka atau mendaftar jika belum memiliki akun.

*(Silakan tambahkan atau sesuaikan screenshot lainnya sesuai preferensi Anda).*

### b. Topik Kuliah yang Diterapkan

Berikut adalah penerapan materi perkuliahan dalam pembangunan aplikasi Libra Go:

*   **Minggu 4: Arsitektur Flutter (Engine, Framework, Widget Tree)**
    *   **Penerapan:** Saya terapkan dalam pembentukan struktur proyek aplikasi (pemisahan direktori `lib/screens`, `lib/models`, `lib/services`). Pemahaman *Widget Tree* diaplikasikan pada setiap halaman, seperti menyusun kerangka UI dengan menumpuk `Scaffold`, `Column`, `Row`, dan `Container`.
*   **Minggu 5: Bahasa Dart – sintaks dasar dan tipe data**
    *   **Penerapan:** Diaplikasikan secara menyeluruh, contohnya penggunaan tipe data `String` untuk nama pengguna, `int` dan `double` untuk kalkulasi anggaran pengeluaran, serta `List` dan `Map` untuk memanipulasi data dari database sebelum ditampilkan.
*   **Minggu 7: OOP pada Dart**
    *   **Penerapan:** Diaplikasikan dengan membuat model data berbasis Class (seperti kelas `Destination`), melakukan *inheritance* (pewarisan sifat dari `StatelessWidget` atau `StatefulWidget`), dan mengkapsulasi logika API dalam Service Class (`SupabaseService`, `FirebaseNotificationService`).
*   **Minggu 8: Widget**
    *   **Penerapan:** Diaplikasikan melalui penggunaan berbagai *built-in widgets* seperti `ListView.builder` untuk menampilkan daftar perjalanan/pengeluaran secara efisien, `Card` untuk mempercantik UI per-item, serta pembuatan *custom widgets* (komponen UI yang dapat dipakai ulang).
*   **Minggu 10: Navigasi dan Routing**
    *   **Penerapan:** Diaplikasikan untuk perpindahan antar halaman dalam aplikasi menggunakan `Navigator.push`, `Navigator.pop`, dan `Navigator.pushReplacement` (misalnya navigasi dari `home_screen` menuju `add_vacation_screen` sambil membawa parameter data tertentu).
*   **Minggu 11: Form, Input, dan Validasi**
    *   **Penerapan:** Diaplikasikan dengan menggunakan widget `Form` dan `TextFormField` pada halaman login, registrasi, dan pencatatan pengeluaran. Saya juga menyertakan logika validasi untuk memastikan input pengguna (seperti format email atau nominal uang tidak boleh kosong) sebelum disubmit.
*   **Minggu 13: Akses Data (Rest API)**
    *   **Penerapan:** Diaplikasikan dengan mengintegrasikan aplikasi dengan Backend-as-a-Service (Supabase) via API HTTP/REST untuk melakukan operasi CRUD (membuat trip, membaca data destinasi, memperbarui profile). Proses asinkron diatasi menggunakan sintaks `Future`, `async`, dan `await`.

### c. Link Repository
**GitHub:** https://github.com/Ivan-Raditya/Libra-Go

---

## 3. Penilaian yang Disarankan

**Nilai yang disarankan:** 95
**Alasan:**
Aplikasi Libra Go bukan sekadar purwarupa (prototype) biasa, melainkan aplikasi yang sudah menerapkan fungsionalitas secara utuh (*end-to-end*). Saya telah mengimplementasikan konsep fundamental Flutter dari materi perkuliahan hingga integrasi yang cukup kompleks seperti pengelolaan basis data secara real-time via REST API (Supabase), sistem otentikasi, akses kamera/penyimpanan lokal untuk unggah *file/image picker*, peta interaktif (*flutter_map*), dan notifikasi (*Firebase*). Semua elemen dari minggu 4 hingga 13 dikombinasikan dengan baik untuk menciptakan aplikasi dengan fungsionalitas yang sangat menunjang studi kasus sesungguhnya.
