import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/krupuk_model.dart';
import '../../services/api_service.dart';

class AddPenjualanScreen extends StatefulWidget {
  const AddPenjualanScreen({super.key});

  @override
  State<AddPenjualanScreen> createState() => _AddPenjualanScreenState();
}

class _AddPenjualanScreenState extends State<AddPenjualanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();

  List<Krupuk> _krupukList = [];
  Krupuk? _selectedKrupuk;
  bool _isLoadingKrupuk = true;
  String? _krupukError;

  double _totalHarga = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadKrupukList();
    _jumlahController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  Future<void> _loadKrupukList() async {
    setState(() {
      _isLoadingKrupuk = true;
      _krupukError = null;
    });

    try {
      final list = await ApiService().fetchKrupuk();
      setState(() {
        _krupukList = list;
        if (list.isNotEmpty) {
          _selectedKrupuk = list.first;
          _calculateTotal();
        }
      });
    } catch (e) {
      setState(() {
        _krupukError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoadingKrupuk = false;
      });
    }
  }

  void _calculateTotal() {
    final qty = int.tryParse(_jumlahController.text.trim()) ?? 0;
    final hargaSatuan = _selectedKrupuk?.harga ?? 0.0;
    setState(() {
      _totalHarga = qty * hargaSatuan;
    });
  }

  Future<void> _submitPenjualan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKrupuk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih varian kerupuk terlebih dahulu!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final qty = int.tryParse(_jumlahController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah terjual harus lebih dari 0!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final message = await ApiService().insertPenjualan(
        idDataKrupuk: _selectedKrupuk!.idKrupuk,
        jumlahDijual: qty,
        totalPenjualan: _totalHarga,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencatat penjualan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Penjualan Kerupuk'),
      ),
      body: _isLoadingKrupuk
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Memuat katalog harga kerupuk...'),
                ],
              ),
            )
          : _krupukError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 56, color: Colors.orange),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal mengambil katalog kerupuk:\n$_krupukError',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadKrupukList,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _krupukList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline, size: 56, color: Colors.blue),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada data produk di Katalog Kerupuk. Harap tambahkan varian produk terlebih dahulu.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Kembali'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card Info Kalkulator
                            Card(
                              color: Colors.amber.shade50,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.calculate, color: Colors.brown),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Kalkulator Cerdas: Total penjualan dihitung otomatis dari harga master dikali kuantitas.',
                                        style: TextStyle(fontSize: 12, color: Colors.brown),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dropdown Produk Kerupuk
                            const Text(
                              'Pilih Varian Kerupuk:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Krupuk>(
                              value: _selectedKrupuk,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.cookie),
                              ),
                              items: _krupukList.map((krupuk) {
                                return DropdownMenuItem<Krupuk>(
                                  value: krupuk,
                                  child: Text(
                                    '${krupuk.namaKrupuk} (${AppConfig.formatRupiah(krupuk.harga)})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedKrupuk = val;
                                  _calculateTotal();
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Detail Harga Satuan Terpilih
                            if (_selectedKrupuk != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Harga Satuan Terpilih:', style: TextStyle(color: Colors.black54)),
                                    Text(
                                      AppConfig.formatRupiah(_selectedKrupuk!.harga),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Input Kuantitas / Jumlah Dijual
                            const Text(
                              'Jumlah Terjual (Bungkus / Bal):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _jumlahController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Contoh: 10',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Harap masukkan jumlah';
                                }
                                final numVal = int.tryParse(val.trim());
                                if (numVal == null || numVal <= 0) {
                                  return 'Jumlah harus bilangan bulat lebih dari 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Hasil Hitung Otomatis (Total Penjualan)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade600, Colors.teal.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'TOTAL PENDAPATAN PENJUALAN',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppConfig.formatRupiah(_totalHarga),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_jumlahController.text.isEmpty ? '0' : _jumlahController.text} pcs x ${AppConfig.formatRupiah(_selectedKrupuk?.harga ?? 0)}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Tombol Submit
                            ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submitPenjualan,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                _isSubmitting ? 'Menyimpan ke Cloud...' : 'Simpan Transaksi Penjualan',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

