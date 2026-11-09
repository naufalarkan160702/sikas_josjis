class Krupuk {
  final String idKrupuk;
  final String namaKrupuk;
  final double harga;
  final String deskripsi;

  Krupuk({
    required this.idKrupuk,
    required this.namaKrupuk,
    required this.harga,
    required this.deskripsi,
  });

  factory Krupuk.fromJson(Map<String, dynamic> json) {
    return Krupuk(
      idKrupuk: json['id_krupuk']?.toString() ?? '',
      namaKrupuk: json['nama_krupuk']?.toString() ?? '',
      harga: double.tryParse(json['harga']?.toString() ?? '0') ?? 0.0,
      deskripsi: json['deskripsi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_krupuk': idKrupuk,
      'nama_krupuk': namaKrupuk,
      'harga': harga,
      'deskripsi': deskripsi,
    };
  }

  Krupuk copyWith({
    String? idKrupuk,
    String? namaKrupuk,
    double? harga,
    String? deskripsi,
  }) {
    return Krupuk(
      idKrupuk: idKrupuk ?? this.idKrupuk,
      namaKrupuk: namaKrupuk ?? this.namaKrupuk,
      harga: harga ?? this.harga,
      deskripsi: deskripsi ?? this.deskripsi,
    );
  }
}
