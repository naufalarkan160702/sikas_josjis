class Penjualan {
  final String idPenjualan;
  final String idDataKrupuk;
  final int jumlahDijual;
  final double totalPenjualan;
  final String tanggalPenjualan;
  
  // Property pembantu untuk tampilan nama produk jika ditemukan dari katalog
  String? namaKrupuk;

  Penjualan({
    required this.idPenjualan,
    required this.idDataKrupuk,
    required this.jumlahDijual,
    required this.totalPenjualan,
    required this.tanggalPenjualan,
    this.namaKrupuk,
  });

  factory Penjualan.fromJson(Map<String, dynamic> json) {
    return Penjualan(
      idPenjualan: json['id_penjualan']?.toString() ?? '',
      idDataKrupuk: json['id_data_krupuk']?.toString() ?? '',
      jumlahDijual: int.tryParse(json['jumlah_dijual']?.toString() ?? '0') ?? 0,
      totalPenjualan: double.tryParse(json['total_penjualan']?.toString() ?? '0') ?? 0.0,
      tanggalPenjualan: json['tanggal_penjualan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_penjualan': idPenjualan,
      'id_data_krupuk': idDataKrupuk,
      'jumlah_dijual': jumlahDijual,
      'total_penjualan': totalPenjualan,
      'tanggal_penjualan': tanggalPenjualan,
    };
  }
}
