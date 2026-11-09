import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/krupuk_model.dart';
import '../models/penjualan_model.dart';
import '../models/bahan_model.dart';
import '../services/api_service.dart';
import 'krupuk/krupuk_list_screen.dart';
import 'krupuk/krupuk_form_dialog.dart';
import 'penjualan/penjualan_list_screen.dart';
import 'penjualan/add_penjualan_screen.dart';
import 'bahan/bahan_list_screen.dart';
import 'bahan/add_bahan_screen.dart';
import 'settings_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;

  List<Krupuk> _krupukList = [];
  List<Penjualan> _penjualanList = [];
  List<BahanBaku> _bahanList = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService().fetchKrupuk().catchError((e) => <Krupuk>[]),
        ApiService().fetchPenjualan().catchError((e) => <Penjualan>[]),
        ApiService().fetchBahan().catchError((e) => <BahanBaku>[]),
      ]);

      setState(() {
        _krupukList = results[0] as List<Krupuk>;
        _penjualanList = results[1] as List<Penjualan>;
        _bahanList = results[2] as List<BahanBaku>;
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

  double get _totalPemasukan {
    return _penjualanList.fold(0.0, (sum, item) => sum + item.totalPenjualan);
  }

  double get _totalPengeluaran {
    return _bahanList.fold(0.0, (sum, item) => sum + item.totalBiaya);
  }

  double get _saldoKas {
    return _totalPemasukan - _totalPengeluaran;
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning jika URL Apps Script belum diisi
            if (AppConfig.webAppUrl.trim().isEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.brown),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'URL Web App Belum Diatur',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Atur URL Google Apps Script Anda di menu Pengaturan agar data tersimpan ke spreadsheet.',
                            style: TextStyle(fontSize: 12, color: Colors.brown),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              ).then((_) => _loadAllData());
                            },
                            child: const Text(
                              'Buka Pengaturan API ->',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Card Saldo Kas Utama
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Colors.amber.shade800,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SALDO KAS OPERASIONAL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_done, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Cloud Realtime', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConfig.formatRupiah(_saldoKas),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Pemasukan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_downward, color: Colors.lightGreenAccent, size: 14),
                                  SizedBox(width: 4),
                                  Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppConfig.formatRupiah(_totalPemasukan),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        const SizedBox(width: 12),
                        // Pengeluaran
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_upward, color: Colors.orangeAccent, size: 14),
                                  SizedBox(width: 4),
                                  Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppConfig.formatRupiah(_totalPengeluaran),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Aksi Cepat (Quick Actions)
            const Text(
              'Aksi Cepat Input Nota',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    title: 'Catat Penjualan',
                    subtitle: 'Kalkulator Pintar',
                    icon: Icons.add_shopping_cart,
                    color: Colors.green,
                    onTap: () async {
                      final res = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (context) => const AddPenjualanScreen()),
                      );
                      if (res == true) _loadAllData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    title: 'Belanja Bahan',
                    subtitle: 'Tepung, Minyak, Gas',
                    icon: Icons.receipt_long,
                    color: Colors.red.shade600,
                    onTap: () async {
                      final res = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (context) => const AddBahanScreen()),
                      );
                      if (res == true) _loadAllData();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              title: 'Kelola Varian Kerupuk',
              subtitle: 'Tambah produk baru atau ubah harga inflasi',
              icon: Icons.cookie_outlined,
              color: Colors.amber.shade800,
              onTap: () async {
                final res = await showDialog<bool>(
                  context: context,
                  builder: (context) => const KrupukFormDialog(),
                );
                if (res == true) _loadAllData();
              },
            ),
            const SizedBox(height: 24),

            // Ringkasan Katalog Produk
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Katalog Produk UMKM',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _currentIndex = 3);
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            if (_krupukList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Belum ada varian kerupuk terdaftar. Tekan "Kelola Varian Kerupuk" untuk menambahkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _krupukList.length,
                  itemBuilder: (context, index) {
                    final item = _krupukList[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.namaKrupuk,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConfig.formatRupiah(item.harga),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.deskripsi.isNotEmpty ? item.deskripsi : 'Varian Kerupuk',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Aktivitas Transaksi Terbaru
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktivitas Penjualan & Belanja Terakhir',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadAllData,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_penjualanList.isEmpty && _bahanList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long, size: 40, color: Colors.black26),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada riwayat transaksi kas masuk maupun kas keluar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              )
            else ...[
              // Tampilkan 3 penjualan terbaru
              ..._penjualanList.take(3).map((penjualan) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: const Icon(Icons.arrow_downward, color: Colors.green, size: 18),
                    ),
                    title: Text(
                      'Penjualan (${penjualan.jumlahDijual} pcs)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      AppConfig.formatDate(penjualan.tanggalPenjualan),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      '+${AppConfig.formatRupiah(penjualan.totalPenjualan)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),

              // Tampilkan 3 belanja terbaru
              ..._bahanList.take(3).map((bahan) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: const Icon(Icons.arrow_upward, color: Colors.red, size: 18),
                    ),
                    title: Text(
                      bahan.namaBahan.isNotEmpty ? bahan.namaBahan : 'Bahan Baku',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${bahan.kuantitas} • ${AppConfig.formatDate(bahan.tanggalPembelian)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      '-${AppConfig.formatRupiah(bahan.totalBiaya)}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 20,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildDashboardTab(),
      const PenjualanListScreen(),
      const BahanListScreen(),
      const KrupukListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.storefront,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIKAS Mobile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Kas & Stok UMKM Kerupuk',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan API Cloud',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadAllData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Data',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Penjualan',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Belanja',
          ),
          NavigationDestination(
            icon: Icon(Icons.cookie_outlined),
            selectedIcon: Icon(Icons.cookie),
            label: 'Katalog',
          ),
        ],
      ),
    );
  }
}

