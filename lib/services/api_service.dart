import 'dart:convert';
import 'dart:io';
import '../config/app_config.dart';
import '../models/krupuk_model.dart';
import '../models/penjualan_model.dart';
import '../models/bahan_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Helper method untuk GET request dengan penanganan redirect Google Apps Script
  Future<String> _get(String action) async {
    final baseUrl = AppConfig.webAppUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('URL Web App Google Apps Script belum disetting. Silakan buka menu Pengaturan (ikon gerigi).');
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: {'action': action});
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(uri);
      // Ikuti redirect otomatis untuk GET
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 400) {
        return responseBody;
      } else {
        throw Exception('Server mengembalikan kode error: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      throw Exception('Tidak ada koneksi internet atau server Google Apps Script tidak dapat dihubungi.');
    } finally {
      client.close();
    }
  }

  // Helper method untuk POST request khusus Google Apps Script (menangani 302 redirect)
  Future<String> _post(Map<String, String> params) async {
    final baseUrl = AppConfig.webAppUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('URL Web App Google Apps Script belum disetting. Silakan buka menu Pengaturan (ikon gerigi).');
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      // Pada Google Apps Script, mengirim parameter via query params atau form-urlencoded
      // Membantu memastikan e.parameter terbaca dengan presisi
      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final request = await client.postUrl(uri);
      
      // Jangan auto follow redirect pada POST karena Google Apps Script melakukan redirect 302 ke GET echo
      request.followRedirects = false;
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');

      final bodyString = params.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      request.write(bodyString);

      final response = await request.close().timeout(const Duration(seconds: 20));

      // Google Apps Script merespons 302 ke URL script.googleusercontent.com
      if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 303) {
        final redirectUrl = response.headers.value(HttpHeaders.locationHeader);
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          final getReq = await client.getUrl(Uri.parse(redirectUrl));
          getReq.followRedirects = true;
          final getResp = await getReq.close().timeout(const Duration(seconds: 15));
          final respBody = await getResp.transform(utf8.decoder).join();
          return respBody;
        }
      }

      final respBody = await response.transform(utf8.decoder).join();
      return respBody;
    } on SocketException catch (_) {
      throw Exception('Gagal mengirim data. Periksa koneksi internet Anda.');
    } finally {
      client.close();
    }
  }

  // ==========================================
  // 1. DATA MASTER KERUPUK (data_krupuk)
  // ==========================================
  Future<List<Krupuk>> fetchKrupuk() async {
    final jsonString = await _get('read_krupuk');
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((item) => Krupuk.fromJson(item as Map<String, dynamic>)).toList();
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
    return await _post(params);
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
    return await _post(params);
  }

  // ==========================================
  // 2. KAS MASUK / PENJUALAN (penjualan_kerupuk)
  // ==========================================
  Future<List<Penjualan>> fetchPenjualan() async {
    final jsonString = await _get('read_penjualan');
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((item) => Penjualan.fromJson(item as Map<String, dynamic>)).toList();
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
    return await _post(params);
  }

  // ==========================================
  // 3. KAS KELUAR / BELANJA BAHAN (belanja_bahan_baku)
  // ==========================================
  Future<List<BahanBaku>> fetchBahan() async {
    final jsonString = await _get('read_bahan');
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((item) => BahanBaku.fromJson(item as Map<String, dynamic>)).toList();
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
    return await _post(params);
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
    return await _post(params);
  }
}

