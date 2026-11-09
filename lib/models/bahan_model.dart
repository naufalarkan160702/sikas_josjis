class BahanBaku {
  final String idBahan;
  final String namaBahan;
  final String kuantitas;
  final double totalBiaya;
  final String tanggalPembelian;

  BahanBaku({
    required this.idBahan,
    required this.namaBahan,
    required this.kuantitas,
    required this.totalBiaya,
    required this.tanggalPembelian,
  });

  factory BahanBaku.fromJson(Map<String, dynamic> json) {
    return BahanBaku(
      idBahan: json['id_bahan']?.toString() ?? '',
      namaBahan: json['nama_bahan']?.toString() ?? '',
      kuantitas: json['kuantitas']?.toString() ?? '',
      totalBiaya: double.tryParse(json['total_biaya']?.toString() ?? '0') ?? 0.0,
      tanggalPembelian: json['tanggal_pembelian']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_bahan': idBahan,
      'nama_bahan': namaBahan,
      'kuantitas': kuantitas,
      'total_biaya': totalBiaya,
      'tanggal_pembelian': tanggalPembelian,
    };
  }
}

