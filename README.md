# Inventory Mobile (Flutter)

Aplikasi mobile untuk **Inventory Dashboard** — versi Flutter yang terhubung ke backend Next.js yang sama (`inventory-dashboard`). Dibangun mengikuti fitur dan alur kerja versi web: multi-tenant, role-based access, Master Barang, Pengadaan & Penjualan (dengan diskon/PPN/metode bayar), Akuntansi (Chart of Akun, Jurnal, Hutang & Piutang, Laporan), dan Manajemen User.

## Cakupan Fitur

| Modul | Status |
|---|---|
| Login & Registrasi Perusahaan | ✅ Lengkap |
| Dashboard (stat cards, grafik, stok menipis) | ✅ Lengkap |
| Master Barang (CRUD + quick-add kategori) | ✅ Lengkap |
| Pengadaan Barang (multi-item, diskon, PPN, metode bayar, quick-add supplier, edit, batal) | ✅ Lengkap |
| Penjualan Barang (sama + validasi stok + quick-add pelanggan) | ✅ Lengkap |
| Akuntansi — Chart of Akun | ✅ CRUD lengkap |
| Akuntansi — Jurnal Umum (otomatis + manual) | ✅ Lengkap |
| Akuntansi — Hutang & Piutang (bayar, riwayat, batalkan) | ✅ Lengkap |
| Akuntansi — Laporan (Laba Rugi, Neraca Saldo) | ✅ Tampilan data (belum ada filter tanggal custom seperti web) |
| Manajemen User | ✅ CRUD lengkap (khusus Admin) |
| **Cetak/Print laporan** | ❌ Belum ada — di web pakai `window.print()` browser, tidak relevan untuk app mobile native. Kalau dibutuhkan, bisa ditambahkan lewat share PDF (butuh package tambahan, lihat bagian "Pengembangan Lanjutan"). |

Role & permission (Admin/Manager/Staff) di-porting 1:1 dari `src/lib/rbac.ts` versi web ke `lib/core/rbac.dart`, jadi menu yang muncul otomatis menyesuaikan role yang login — sama seperti sidebar di web.

## Arsitektur Singkat

```
lib/
  core/            # theme, api client, storage token, formatter, rbac
  models/          # representasi data (Barang, Pengadaan, Penjualan, Akun, dst)
  services/        # pemanggil API per modul (1:1 dengan route Next.js)
  providers/       # AuthProvider (state login global, pakai package `provider`)
  screens/         # UI per modul, dikelompokkan per folder
  widgets/         # komponen reusable (badge, stat card, empty/error state)
```

Pola state management sengaja dibuat sederhana: `AuthProvider` (global, lewat `provider` package) untuk status login, sisanya pakai `StatefulWidget` + `setState` biasa per layar — cukup untuk kompleksitas CRUD di aplikasi ini tanpa perlu Riverpod/Bloc.

## PENTING: Autentikasi Mobile vs Web

Backend Next.js aslinya pakai **NextAuth session cookie** (cocok untuk browser, tidak cocok untuk app mobile). Karena itu, backend sudah saya tambahkan **jalur token khusus mobile** tanpa mengubah satupun endpoint yang sudah ada:

- `POST /api/mobile/login` — login dengan email/password, mengembalikan token JWT (bukan cookie).
- `GET /api/mobile/me` — cek validitas token & ambil data user terbaru (dipakai saat app dibuka, untuk auto-login).
- Semua endpoint API lain (barang, pengadaan, dst) otomatis menerima token ini lewat header `Authorization: Bearer <token>` — lihat `src/lib/apiAuth.ts` di project backend (`inventory-dashboard`), fungsi `requirePermission()` sudah dimodifikasi untuk mendukung dua jalur autentikasi (cookie utk web, Bearer token utk mobile) secara transparan.

Token disimpan di HP lewat `flutter_secure_storage` (Keychain di iOS, EncryptedSharedPreferences di Android) — bukan `SharedPreferences` biasa.

> **Pastikan backend `inventory-dashboard` yang Anda jalankan sudah termasuk perubahan ini** (file `src/lib/mobileAuth.ts`, `src/app/api/mobile/login/route.ts`, `src/app/api/mobile/me/route.ts`, dan `src/lib/apiAuth.ts` yang sudah diupdate). Tanpa ini, aplikasi mobile tidak akan bisa login.

## Instalasi & Menjalankan

### 1. Prasyarat
- Flutter SDK 3.x sudah terinstall (`flutter --version` untuk cek)
- Backend `inventory-dashboard` (Next.js) sudah jalan dan bisa diakses dari HP/emulator Anda

### 2. Generate folder platform (Android/iOS)

Project ini saya siapkan hanya berisi `lib/` dan `pubspec.yaml` (kode Dart murni) — folder platform native (`android/`, `ios/`, dll) **perlu digenerate di komputer Anda** karena isinya bergantung pada versi Flutter SDK yang terpasang:

```bash
cd inventory_mobile
flutter create . --org com.perusahaan_anda --project-name inventory_mobile
```

Perintah ini aman dijalankan di folder yang sudah ada `lib/`/`pubspec.yaml` — Flutter akan menambahkan folder `android/`, `ios/`, dll tanpa menimpa kode yang sudah ada.

### 3. Install dependency

```bash
flutter pub get
```

### 4. Izinkan koneksi HTTP (khusus development lokal)

Kalau backend Anda masih jalan di `http://` (bukan `https://`) — normal untuk development lokal — Android 9+ akan **memblokir** koneksi HTTP secara default. Tambahkan file berikut supaya development lancar:

**`android/app/src/main/res/xml/network_security_config.xml`** (buat file & foldernya):
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">localhost</domain>
        <!-- Tambahkan IP lokal komputer Anda kalau testing dari HP fisik, contoh: -->
        <!-- <domain includeSubdomains="true">192.168.1.10</domain> -->
    </domain-config>
</network-security-config>
```

Lalu di `android/app/src/main/AndroidManifest.xml`, tambahkan atribut berikut ke tag `<application>`:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

> Untuk **produksi** (backend sudah pakai HTTPS), langkah ini tidak diperlukan.

### 5. Jalankan aplikasi

Base URL API di-set lewat `--dart-define` supaya gampang ganti-ganti tanpa edit kode:

```bash
# Emulator Android (backend jalan di localhost komputer)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Simulator iOS
flutter run --dart-define=API_BASE_URL=http://localhost:3000

# HP fisik (ganti dengan IP lokal komputer Anda, satu jaringan wifi)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000

# Build produksi (arahkan ke domain server yang sudah di-deploy)
flutter build apk --dart-define=API_BASE_URL=https://inventory.perusahaan-anda.com
```

> Untuk emulator Android, base URL yang benar adalah `http://10.0.2.2:3000` — `10.0.2.2` adalah alias khusus emulator Android untuk mengakses `localhost` komputer host (bukan alamat asal, jangan diketik ulang manual supaya tidak salah ketik).

Kalau lupa set `--dart-define`, default-nya adalah `http://10.0.2.2:3000` (cocok untuk emulator Android + backend lokal) — lihat `lib/core/constants.dart`.

## Akun Demo

Sama seperti web (kalau backend sudah di-seed lewat `npm run prisma:seed`):
```
admin@toko.com   / password123  (Administrator)
manager@toko.com / password123  (Manajer)
staff@toko.com   / password123  (Staff)
```

## Pengembangan Lanjutan (Belum Termasuk)

- **Cetak/export PDF** — versi web pakai dialog print browser (`window.print()`), yang secara natural tidak ada di app mobile. Kalau dibutuhkan versi mobile, opsinya: (a) buka halaman print versi web lewat `WebView`/browser eksternal dari dalam app, atau (b) generate PDF native pakai package `pdf` + `printing` (butuh `flutter pub add pdf printing`, tidak saya include supaya dependency tetap minimal).
- **Notifikasi push** (mis. stok menipis, hutang jatuh tempo) — belum ada, perlu setup Firebase Cloud Messaging kalau diperlukan.
- **Mode offline** — semua data selalu fetch langsung dari API, belum ada local caching/offline-first.
- **Filter tanggal custom di Laporan** — saat ini Laba Rugi selalu menampilkan bulan berjalan (default backend); tinggal tambahkan date range picker yang memanggil `AkuntansiService.labaRugi(start:, end:)` yang sudah disiapkan.

## Troubleshooting

- **"Connection refused" / tidak bisa konek** → cek `API_BASE_URL` sudah benar untuk platform yang dipakai (lihat tabel di langkah 5), dan backend Next.js benar-benar sedang jalan (`npm run dev` di project backend).
- **Login gagal padahal password benar** → pastikan backend sudah punya endpoint `/api/mobile/login` (lihat bagian "PENTING: Autentikasi Mobile vs Web" di atas). Kalau backend Anda versi lama yang belum ada endpoint ini, update dulu.
- **Error `CLEARTEXT communication not permitted`** di Android → ikuti langkah 4 di atas (network security config).
