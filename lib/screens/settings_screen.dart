import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConfig.webAppUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveUrl() {
    final input = _urlController.text.trim();
    setState(() {
      AppConfig.webAppUrl = input;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL Web App Google Apps Script berhasil disimpan!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _testConnection() async {
    final input = _urlController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _testResult = 'Harap isi URL terlebih dahulu.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      AppConfig.webAppUrl = input;
      _isTesting = true;
      _testResult = null;
    });

    try {
      final list = await ApiService().fetchKrupuk();
      setState(() {
        _isSuccess = true;
        _testResult = 'Koneksi Berhasil! Ditemukan ${list.length} varian kerupuk dari spreadsheet.';
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _testResult = 'Koneksi Gagal: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan API Cloud'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_sync, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'URL Web App Apps Script',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan URL Web App dari deployment Google Apps Script Anda (berakhiran /exec):',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'https://script.google.com/macros/s/.../exec',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.link),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _urlController.clear(),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveUrl,
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan URL'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.network_check),
                            label: const Text('Uji Koneksi'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isSuccess ? Colors.green.shade300 : Colors.red.shade300,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isSuccess ? Icons.check_circle : Icons.error,
                              color: _isSuccess ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _testResult!,
                                style: TextStyle(
                                  color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Panduan Deploy Google Apps Script:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.amber.shade50,
              elevation: 0,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Langkah melakukan Deployment:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                    ),
                    SizedBox(height: 8),
                    Text('1. Buka Google Spreadsheet data UMKM Anda.', style: TextStyle(fontSize: 13)),
                    Text('2. Klik Ekstensi (Extensions) > Apps Script.', style: TextStyle(fontSize: 13)),
                    Text('3. Tempel kode doPost & doGet Google Apps Script yang sudah disiapkan.', style: TextStyle(fontSize: 13)),
                    Text('4. Klik tombol "Deploy" (Terapkan) berwarna biru di kanan atas > "Deployment Baru" (New Deployment).', style: TextStyle(fontSize: 13)),
                    Text('5. Pilih tipe: "Aplikasi Web" (Web app).', style: TextStyle(fontSize: 13)),
                    Text('6. Pada bagian "Jalankan sebagai" (Execute as): pilih "Saya" (Me).', style: TextStyle(fontSize: 13)),
                    Text('7. Pada "Siapa yang memiliki akses" (Who has access): PILIH "SIAPA SAJA" (ANYONE). Penting agar Flutter dapat mengakses tanpa login browser.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    Text('8. Klik Deploy, setujui izin (Authorize access), lalu salin URL Web App dan tempel pada input di atas.', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

