import 'package:flutter/material.dart';
import '../../models/krupuk_model.dart';
import '../../services/api_service.dart';

class KrupukFormDialog extends StatefulWidget {
  final Krupuk? krupuk; // null jika mode tambah, isi jika mode edit

  const KrupukFormDialog({super.key, this.krupuk});

  @override
  State<KrupukFormDialog> createState() => _KrupukFormDialogState();
}

class _KrupukFormDialogState extends State<KrupukFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _hargaController;
  late final TextEditingController _deskripsiController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.krupuk?.namaKrupuk ?? '');
    _hargaController = TextEditingController(
      text: widget.krupuk != null ? widget.krupuk!.harga.toInt().toString() : '',
    );
    _deskripsiController = TextEditingController(text: widget.krupuk?.deskripsi ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nama = _namaController.text.trim();
      final harga = double.tryParse(_hargaController.text.trim()) ?? 0.0;
      final deskripsi = _deskripsiController.text.trim();

      String message;
      if (widget.krupuk == null) {
        // Insert
        message = await ApiService().insertKrupuk(
          namaKrupuk: nama,
          harga: harga,
          deskripsi: deskripsi,
        );
      } else {
        // Update
        message = await ApiService().updateKrupuk(
          idKrupuk: widget.krupuk!.idKrupuk,
          namaKrupuk: nama,
          harga: harga,
          deskripsi: deskripsi,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.krupuk != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isEdit ? Icons.edit : Icons.add_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(isEdit ? 'Edit Varian Kerupuk' : 'Tambah Varian Baru'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kerupuk',
                  hintText: 'Contoh: Kerupuk Bawang Renyah',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama kerupuk wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _hargaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Jual Satuan (Rp)',
                  hintText: 'Contoh: 15000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Harga wajib diisi';
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) {
                    return 'Masukkan harga yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi / Kemasan',
                  hintText: 'Contoh: Kemasan 250gr, isi 20 bungkus/bal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(isEdit ? 'Perbarui' : 'Simpan'),
        ),
      ],
    );
  }
}

