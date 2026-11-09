import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/penjualan_model.dart';
import '../../models/krupuk_model.dart';
import '../../services/api_service.dart';
import 'add_penjualan_screen.dart';

enum PeriodeFilter { semua, hariIni, bulanIni }

class PenjualanListScreen extends StatefulWidget {
  const PenjualanListScreen({super.key});

  @override
  State<PenjualanListScreen> createState() => _PenjualanListScreenState();
}

class _PenjualanListScreenState extends State<PenjualanListScreen> {
  List<Penjualan> _allPenjualan = [];
  Map<String, String> _krupukNameMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  PeriodeFilter _selectedFilter = PeriodeFilter.semua;
  String _searchQuery = '';

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
        _allPenjualan = penjualan.reversed.toList();
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

  List<Penjualan> get _filteredList {
    final now = DateTime.now();

    return _allPenjualan.where((item) {
      // 1. Filter Periode Waktu
      if (_selectedFilter != PeriodeFilter.semua) {
        DateTime? dt;
        try {
          final cleanStr = item.tanggalPenjualan.trim().replaceFirst(' ', 'T');
          dt = DateTime.tryParse(cleanStr);
        } catch (_) {}

        if (dt != null) {
          if (_selectedFilter == PeriodeFilter.hariIni) {
            final isSameDay =
                dt.year == now.year && dt.month == now.month && dt.day == now.day;
            if (!isSameDay) return false;
          } else if (_selectedFilter == PeriodeFilter.bulanIni) {
            final isSameMonth = dt.year == now.year && dt.month == now.month;
            if (!isSameMonth) return false;
          }
        }
      }

      // 2. Filter Pencarian Teks
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nama = (_krupukNameMap[item.idDataKrupuk] ?? '').toLowerCase();
        final id = item.idPenjualan.toLowerCase();
        if (!nama.contains(q) && !id.contains(q)) return false;
      }

      return true;
    }).toList();
  }

  double get _totalPemasukanFiltered {
    return _filteredList.fold(0.0, (sum, item) => sum + item.totalPenjualan);
  }

  Future<void> _deleteItem(Penjualan item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan Penjualan?'),
        content: Text(
          'Yakin ingin menghapus transaksi "${item.idPenjualan}" sebesar ${AppConfig.formatRupiah(item.totalPenjualan)} dari Google Sheets?',
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

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;

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
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.white70, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'TOTAL PENJUALAN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _selectedFilter == PeriodeFilter.semua
                            ? 'Semua Waktu'
                            : _selectedFilter == PeriodeFilter.hariIni
                                ? 'Hari Ini'
                                : 'Bulan Ini',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppConfig.formatRupiah(_totalPemasukanFiltered),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${list.length} transaksi ditampilkan',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Filter Periode Waktu (Chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                const Text('Periode: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Semua', style: TextStyle(fontSize: 12)),
                  selected: _selectedFilter == PeriodeFilter.semua,
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = PeriodeFilter.semua);
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Hari Ini', style: TextStyle(fontSize: 12)),
                  selected: _selectedFilter == PeriodeFilter.hariIni,
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = PeriodeFilter.hariIni);
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Bulan Ini', style: TextStyle(fontSize: 12)),
                  selected: _selectedFilter == PeriodeFilter.bulanIni,
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = PeriodeFilter.bulanIni);
                  },
                ),
              ],
            ),
          ),

          // List Data Transaksi
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
                    : list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _allPenjualan.isEmpty
                                      ? 'Belum ada riwayat penjualan kerupuk.'
                                      : 'Tidak ada transaksi pada periode yang dipilih.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final item = list[index];
                                final namaKrupuk =
                                    _krupukNameMap[item.idDataKrupuk] ?? 'Produk (${item.idDataKrupuk})';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 1.5,
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
