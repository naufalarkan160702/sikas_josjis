import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/krupuk_model.dart';
import '../models/penjualan_model.dart';
import '../models/bahan_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // In-memory Cache
  List<Krupuk>? _cachedKrupuk;
  DateTime? _cachedKrupukTime;

  List<Penjualan>? _cachedPenjualan;
  DateTime? _cachedPenjualanTime;

  List<BahanBaku>? _cachedBahan;
  DateTime? _cachedBahanTime;

  // Durasi cache 3 menit untuk meminimalkan beban Google Apps Script
  static const Duration _cacheDuration = Duration(minutes: 3);

  void invalidateCache({bool krupuk = true, bool penjualan = true, bool bahan = true}) {
    if (krupuk) {
      _cachedKrupuk = null;
      _cachedKrupukTime = null;
    }
    if (penjualan) {
      _cachedPenjualan = null;
      _cachedPenjualanTime = null;
    }
    if (bahan) {
      _cachedBahan = null;
      _cachedBahanTime = null;
    }
  }

  // Helper method untuk GET request dengan batas waktu yang lebih toleran (50 detik)
  Future<String> _get(String action) async {
    final baseUrl = AppConfig.webAppUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception(
          'URL Web App Google Apps Script belum disetting. Silakan buka menu Pengaturan (ikon gerigi).');
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: {'action': action});

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 50));

      if (response.statusCode >= 200 && response.statusCode < 400) {
        return response.body;
      } else {
        throw Exception('Server mengembalikan kode status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
            'Koneksi waktu habis (Timeout). Server Google Apps Script sedang warming up atau jaringan lambat. Silakan coba lagi.');
      }
      if (e is Exception) rethrow;
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  // Helper method untuk POST request (Cross-platform Android, iOS, Web, Desktop)
  Future<String> _post(Map<String, String> params) async {
    final baseUrl = AppConfig.webAppUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception(
          'URL Web App Google Apps Script belum disetting. Silakan buka menu Pengaturan (ikon gerigi).');
    }

    final uri = Uri.parse(baseUrl);

    try {
      final response = await http.post(
        uri,
        body: params,
      ).timeout(const Duration(seconds: 50));

      if (response.statusCode >= 200 && response.statusCode < 400) {
        return response.body;
      } else if (response.statusCode == 302 ||
          response.statusCode == 301 ||
          response.statusCode == 303) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          final redirResp =
              await http.get(Uri.parse(redirectUrl)).timeout(const Duration(seconds: 35));
          return redirResp.body;
        }
      }
      return response.body;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi waktu habis saat menyimpan data. Silakan coba lagi.');
      }
      if (e is Exception) rethrow;
      throw Exception('Gagal mengirim data ke server: $e');
    }
  }

  // ==========================================
  // 1. DATA MASTER KERUPUK (data_krupuk)
  // ==========================================
  Future<List<Krupuk>> fetchKrupuk({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedKrupuk != null &&
        _cachedKrupukTime != null &&
        DateTime.now().difference(_cachedKrupukTime!) < _cacheDuration) {
      return _cachedKrupuk!;
    }

    final jsonString = await _get('read_krupuk');
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final list = decoded
            .map((item) => Krupuk.fromJson(item as Map<String, dynamic>))
            .toList();
        _cachedKrupuk = list;
        _cachedKrupukTime = DateTime.now();
        return list;
      }
      return [];
    } catch (e) {
      if (jsonString.contains('Action GET')) {
        throw Exception('Action read_krupuk tidak dikenali oleh Google Apps Script.');
      }
      throw Exception('Format data respon tidak valid: $jsonString');
    }
  }

  Future<String> insertKrupuk({
    required String namaKrupuk,
    required double harga,
    required String deskripsi,
  }) async {
    final params = {
      'action': 'insert_krupuk',
      'nama_krupuk': namaKrupuk,
      'harga': harga.toInt().toString(),
      'deskripsi': deskripsi,
    };
    final res = await _post(params);
    invalidateCache(krupuk: true);
    return res;
  }

  Future<String> updateKrupuk({
    required String idKrupuk,
    required String namaKrupuk,
    required double harga,
    required String deskripsi,
  }) async {
    final params = {
      'action': 'update_krupuk',
      'id_krupuk': idKrupuk,
      'nama_krupuk': namaKrupuk,
      'harga': harga.toInt().toString(),
      'deskripsi': deskripsi,
    };
    final res = await _post(params);
    invalidateCache(krupuk: true);
    return res;
  }

  // ==========================================
  // 2. KAS MASUK / PENJUALAN (penjualan_kerupuk)
  // ==========================================
  Future<List<Penjualan>> fetchPenjualan({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedPenjualan != null &&
        _cachedPenjualanTime != null &&
        DateTime.now().difference(_cachedPenjualanTime!) < _cacheDuration) {
      return _cachedPenjualan!;
    }

    final jsonString = await _get('read_penjualan');
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final list = decoded
            .map((item) => Penjualan.fromJson(item as Map<String, dynamic>))
            .toList();
        _cachedPenjualan = list;
        _cachedPenjualanTime = DateTime.now();
        return list;
      }
      return [];
    } catch (e) {
      if (jsonString.contains('Action GET')) {
        throw Exception('Action read_penjualan tidak dikenali oleh Google Apps Script.');
      }
      throw Exception('Format data respon tidak valid: $jsonString');
    }
  }

  Future<String> insertPenjualan({
    required String idDataKrupuk,
    required int jumlahDijual,
    required double totalPenjualan,
  }) async {
    final params = {
      'action': 'insert_penjualan',
      'id_data_krupuk': idDataKrupuk,
      'jumlah_dijual': jumlahDijual.toString(),
      'total_penjualan': totalPenjualan.toInt().toString(),
    };
    final res = await _post(params);
    invalidateCache(penjualan: true);
    return res;
  }

  // ==========================================
  // 3. KAS KELUAR / BELANJA BAHAN (belanja_bahan_baku)
  // ==========================================
  Future<List<BahanBaku>> fetchBahan({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedBahan != null &&
        _cachedBahanTime != null &&
        DateTime.now().difference(_cachedBahanTime!) < _cacheDuration) {
      return _cachedBahan!;
    }

    final jsonString = await _get('read_bahan');
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final list = decoded
            .map((item) => BahanBaku.fromJson(item as Map<String, dynamic>))
            .toList();
        _cachedBahan = list;
        _cachedBahanTime = DateTime.now();
        return list;
      }
      return [];
    } catch (e) {
      if (jsonString.contains('Action GET')) {
        throw Exception('Action read_bahan tidak dikenali oleh Google Apps Script.');
      }
      throw Exception('Format data respon tidak valid: $jsonString');
    }
  }

  Future<String> insertBahan({
    required String namaBahan,
    required String kuantitas,
    required double totalBiaya,
  }) async {
    final params = {
      'action': 'insert_bahan',
      'nama_bahan': namaBahan,
      'kuantitas': kuantitas,
      'total_biaya': totalBiaya.toInt().toString(),
    };
    final res = await _post(params);
    invalidateCache(bahan: true);
    return res;
  }

  // ==========================================
  // 4. LOGIKA DELETE (Dinamis untuk semua sheet)
  // ==========================================
  Future<String> deleteRecord({
    required String sheetName,
    required String id,
  }) async {
    final params = {
      'action': 'delete',
      'sheet_name': sheetName,
      'id': id,
    };
    final res = await _post(params);
    if (sheetName.contains('krupuk')) {
      invalidateCache(krupuk: true);
    } else if (sheetName.contains('penjualan')) {
      invalidateCache(penjualan: true);
    } else if (sheetName.contains('bahan')) {
      invalidateCache(bahan: true);
    } else {
      invalidateCache();
    }
    return res;
  }
}
