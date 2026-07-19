/// PENTING: ganti [apiBaseUrl] sesuai alamat server Next.js Anda.
///
/// - Emulator Android: backend yang jalan di localhost komputer diakses lewat
///   `http://10.0.2.2:3000` (bukan `localhost`, karena dari sudut pandang
///   emulator, `localhost` merujuk ke emulator itu sendiri).
/// - Simulator iOS: `http://localhost:3000` bisa langsung dipakai.
/// - HP fisik (kabel/wifi satu jaringan dengan komputer): pakai IP lokal
///   komputer Anda, mis. `http://192.168.1.10:3000`.
/// - Produksi: pakai domain server yang sudah di-deploy, mis.
///   `https://inventory.perusahaan-anda.com`.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://inventory.sicerdiq.my.id',
  );

  static const String appName = 'Inventory Dashboard';
}
