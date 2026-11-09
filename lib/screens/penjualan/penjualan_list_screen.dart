import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/penjualan_model.dart';
import '../../models/krupuk_model.dart';
import '../../services/api_service.dart';
import 'add_penjualan_screen.dart';

class PenjualanListScreen extends StatefulWidget {
  const PenjualanListScreen({super.key});

  @override
  State<PenjualanListScreen> createState() => _PenjualanListScreenState();
}

class _PenjualanListScreenState extends State<PenjualanListScreen> {
  List<Penjualan> _penjualanList = [];
  Map<String, String> _krupukNameMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch data penjualan dan data katalog kerupuk secara paralel
      final results = await Future.wait([
        ApiService().fetchPenjualan(),
        ApiService().fetchKrupuk().catchError((_) => <Krupuk>[]),
      ]);

      final penjualan = results[0] as List<Penjualan>;
      final krupuk = results[1] as List<Krupuk>;

      final nameMap = <String, String>{};
      for (final k in krupuk) {
        nameMap[k.idKrupuk] = k.namaKrupuk;
      }

      setState(() {
        _penjualanList = penjualan.reversed.toList(); // Urutan terbaru di atas
        _krupukNameMap = nameMap;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(Penjualan item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan Penjualan?'),
        content: Text(
          'Yakin ingin menghapus data transaksi ${item.idPenjualan} sebesar ${AppConfig.formatRupiah(item.totalPenjualan)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final msg = await ApiService().deleteRecord(
          sheetName: 'penjualan_kerupuk',
          id: item.idPenjualan,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green),
          );
        }
        _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  double get _totalPemasukan {
    return _penjualanList.fold(0.0, (sum, item) => sum + item.totalPenjualan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penjualan (Kas Masuk)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Total Kas Masuk
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.teal.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.white70, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'TOTAL KAS MASUK (PENJUALAN)',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppConfig.formatRupiah(_totalPemasukan),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_penjualanList.length} transaksi tercatat di database',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // List Transaksi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off, size: 56, color: Colors.orange),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _fetchData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _penjualanList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada riwayat penjualan kerupuk.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _penjualanList.length,
                              itemBuilder: (context, index) {
                                final item = _penjualanList[index];
                                final namaKrupuk = _krupukNameMap[item.idDataKrupuk] ??
                                    'Produk (${item.idDataKrupuk})';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 1.5,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.green.shade50,
                                      child: const Icon(Icons.arrow_downward, color: Colors.green),
                                    ),
                                    title: Text(
                                      namaKrupuk,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kuantitas: ${item.jumlahDijual} pcs',
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppConfig.formatDate(item.tanggalPenjualan),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          'ID: ${item.idPenjualan}',
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '+${AppConfig.formatRupiah(item.totalPenjualan)}',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          tooltip: 'Hapus Nota',
                                          onPressed: () => _deleteItem(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddPenjualanScreen()),
          );
          if (res == true) {
            _fetchData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Catat Penjualan'),
      ),
    );
  }
}

