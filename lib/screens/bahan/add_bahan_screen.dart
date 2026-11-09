import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';

class AddBahanScreen extends StatefulWidget {
  const AddBahanScreen({super.key});

  @override
  State<AddBahanScreen> createState() => _AddBahanScreenState();
}

class _AddBahanScreenState extends State<AddBahanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kuantitasController = TextEditingController();
  final _biayaController = TextEditingController();

  bool _isSubmitting = false;

  // Rekomendasi bahan baku umum produsen kerupuk
  final List<String> _quickBahanList = [
    'Tepung Tapioka / Aci',
    'Minyak Goreng',
    'Bawang Putih',
    'Penyedap Rasa / Kaldu',
    'Garam Halus',
    'Gas LPG 3kg',
    'Plastik Kemasan / Sablon',
    'Pewarna Makanan Alami',
  ];

  @override
  void dispose() {
    _namaController.dispose();
    _kuantitasController.dispose();
    _biayaController.dispose();
    super.dispose();
  }

  Future<void> _submitBahan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final nama = _namaController.text.trim();
      final kuantitas = _kuantitasController.text.trim();
      final totalBiaya = double.tryParse(_biayaController.text.trim()) ?? 0.0;

      final message = await ApiService().insertBahan(
        namaBahan: nama,
        kuantitas: kuantitas,
        totalBiaya: totalBiaya,
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
          SnackBar(content: Text('Gagal mencatat belanja: $e'), backgroundColor: Colors.red),
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
        title: const Text('Catat Belanja Bahan Baku'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tips Belanja
              Card(
                color: Colors.red.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Colors.deepOrange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Catat setiap pengeluaran produksi kerupuk agar laporan arus kas operasional tercatat akurat dan transparan.',
                          style: TextStyle(fontSize: 12, color: Colors.brown),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pilihan Cepat Bahan Baku
              const Text(
                'Pilihan Cepat Bahan Baku:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _quickBahanList.map((bahan) {
                  return ActionChip(
                    label: Text(bahan, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _namaController.text = bahan;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Input Nama Bahan
              const Text(
                'Nama Bahan Baku / Kebutuhan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  hintText: 'Misal: Tepung Tapioka Cap Gunung',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.shopping_cart_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama bahan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input Kuantitas
              const Text(
                'Kuantitas / Jumlah Barang Didapat:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _kuantitasController,
                decoration: InputDecoration(
                  hintText: 'Misal: 50 kg / 2 karung / 3 tabung',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.scale_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Kuantitas bahan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input Total Biaya
              const Text(
                'Total Nominal Biaya (Rp):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _biayaController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Misal: 450000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nominal pengeluaran wajib diisi';
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) {
                    return 'Masukkan nominal yang valid';
                  }
                  return null;
                },
              ),

              if (_biayaController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Terbilang: ${AppConfig.formatRupiah(double.tryParse(_biayaController.text.trim()) ?? 0)}',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Tombol Submit
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitBahan,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSubmitting ? 'Menyimpan Pengeluaran...' : 'Simpan Belanja Bahan',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.red.shade700,
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

