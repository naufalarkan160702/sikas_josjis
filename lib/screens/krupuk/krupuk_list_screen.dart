import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/krupuk_model.dart';
import '../../services/api_service.dart';
import 'krupuk_form_dialog.dart';

class KrupukListScreen extends StatefulWidget {
  const KrupukListScreen({super.key});

  @override
  State<KrupukListScreen> createState() => _KrupukListScreenState();
}

class _KrupukListScreenState extends State<KrupukListScreen> {
  List<Krupuk> _allKrupuk = [];
  List<Krupuk> _filteredKrupuk = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService().fetchKrupuk();
      setState(() {
        _allKrupuk = list;
        _applySearch(_searchController.text);
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

  void _applySearch(String query) {
    if (query.trim().isEmpty) {
      _filteredKrupuk = List.from(_allKrupuk);
    } else {
      final q = query.toLowerCase();
      _filteredKrupuk = _allKrupuk.where((k) {
        return k.namaKrupuk.toLowerCase().contains(q) ||
            k.deskripsi.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> _showFormDialog([Krupuk? krupuk]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => KrupukFormDialog(krupuk: krupuk),
    );

    if (result == true) {
      _fetchData();
    }
  }

  Future<void> _deleteKrupuk(Krupuk krupuk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Varian Kerupuk?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${krupuk.namaKrupuk}"? Data yang dihapus dari spreadsheet tidak dapat dikembalikan.',
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
        final message = await ApiService().deleteRecord(
          sheetName: 'data_krupuk',
          id: krupuk.idKrupuk,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Varian Kerupuk'),
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _applySearch(val);
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari varian kerupuk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _applySearch('');
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Content
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
                              const Icon(Icons.cloud_off, size: 64, color: Colors.orange),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black87),
                              ),
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
                    : _filteredKrupuk.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _allKrupuk.isEmpty
                                      ? 'Belum ada data varian kerupuk di katalog.'
                                      : 'Tidak ada kerupuk yang cocok dengan pencarian.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredKrupuk.length,
                              itemBuilder: (context, index) {
                                final item = _filteredKrupuk[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 1.5,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      child: Icon(
                                        Icons.cookie_outlined,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      item.namaKrupuk,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          AppConfig.formatRupiah(item.harga),
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (item.deskripsi.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.deskripsi,
                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                        ],
                                        Text(
                                          'ID: ${item.idKrupuk}',
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          tooltip: 'Edit Harga / Info',
                                          onPressed: () => _showFormDialog(item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          tooltip: 'Hapus',
                                          onPressed: () => _deleteKrupuk(item),
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
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kerupuk'),
      ),
    );
  }
}

