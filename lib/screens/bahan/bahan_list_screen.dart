import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/bahan_model.dart';
import '../../services/api_service.dart';
import 'add_bahan_screen.dart';

class BahanListScreen extends StatefulWidget {
  const BahanListScreen({super.key});

  @override
  State<BahanListScreen> createState() => _BahanListScreenState();
}

class _BahanListScreenState extends State<BahanListScreen> {
  List<BahanBaku> _bahanList = [];
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
      final list = await ApiService().fetchBahan();
      setState(() {
        _bahanList = list.reversed.toList(); // Urutan terbaru di atas
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

  Future<void> _deleteItem(BahanBaku item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan Belanja?'),
        content: Text(
          'Yakin ingin menghapus belanja "${item.namaBahan}" sebesar ${AppConfig.formatRupiah(item.totalBiaya)}?',
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
          sheetName: 'belanja_bahan_baku',
          id: item.idBahan,
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

  double get _totalPengeluaran {
    return _bahanList.fold(0.0, (sum, item) => sum + item.totalBiaya);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belanja Bahan Baku (Kas Keluar)'),
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
          // Banner Total Kas Keluar
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.deepOrange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.25),
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
                    Icon(Icons.arrow_upward, color: Colors.white70, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'TOTAL KAS KELUAR (BELANJA BAHAN)',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppConfig.formatRupiah(_totalPengeluaran),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_bahanList.length} transaksi pembelian bahan tercatat',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // List Bahan Baku
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
                    : _bahanList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada catatan belanja bahan baku.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _bahanList.length,
                              itemBuilder: (context, index) {
                                final item = _bahanList[index];

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
                                      backgroundColor: Colors.red.shade50,
                                      child: const Icon(Icons.arrow_upward, color: Colors.red),
                                    ),
                                    title: Text(
                                      item.namaNamaBahanDisplay,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kuantitas: ${item.kuantitas}',
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppConfig.formatDate(item.tanggalPembelian),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          'ID: ${item.idBahan}',
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '-${AppConfig.formatRupiah(item.totalBiaya)}',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          tooltip: 'Hapus Belanja',
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
            MaterialPageRoute(builder: (context) => const AddBahanScreen()),
          );
          if (res == true) {
            _fetchData();
          }
        },
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Catat Belanja'),
      ),
    );
  }
}

extension on BahanBaku {
  String get namaNamaBahanDisplay => namaBahan.isEmpty ? 'Bahan Tanpa Nama' : namaBahan;
}
