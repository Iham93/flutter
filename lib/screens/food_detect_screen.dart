import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/food_api.dart';
import '../api_service.dart';
import '../utils/gizi_mapper.dart';

class FoodDetectScreen extends StatefulWidget {
  const FoodDetectScreen({super.key});

  @override
  State<FoodDetectScreen> createState() => _FoodDetectScreenState();
}

class _FoodDetectScreenState extends State<FoodDetectScreen> {
  // List menampung 3 file gambar (0: Pagi, 1: Siang, 2: Sore)
  List<File?> _images = [null, null, null];
  final List<String> _sessions = ["Pagi", "Siang", "Sore"];

  Map<String, dynamic>? result;
  bool loading = false;

  // List untuk menampung rincian makanan dari semua sesi
  List<Map<String, dynamic>> detectedItems = [];
  String _manualInput = "";

  // CONTROLLER UNTUK INPUT DATA LENGKAP (UTUH)
  final _namaCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _usiaCtrl = TextEditingController();
  final _bbCtrl = TextEditingController();
  final _tbCtrl = TextEditingController();
  final _posyanduCtrl = TextEditingController();
  final _kaderCtrl = TextEditingController();
  final _kaloriCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();

  Future<void> pickImage(int index, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _images[index] = File(picked.path);
        // Hapus data scan lama khusus sesi ini jika gambar diganti
        detectedItems.removeWhere((item) => item['sesi_index'] == index);
      });
    }
  }

  Future<void> detectFood(int index) async {
    if (_images[index] == null) return;
    setState(() => loading = true);

    try {
      final res = await FoodApi.detectFood(_images[index]!);

      // Bersihkan data lama khusus untuk sesi ini sebelum mengisi yang baru
      detectedItems.removeWhere((item) => item['sesi_index'] == index);

      if (res["detections"] != null) {
        for (var item in res["detections"]) {
          String label = item["label"].toString().toLowerCase();
          final data = giziMap[label];

          if (data != null) {
            double kal =
                double.tryParse(
                  data["kalori"]!.replaceAll(RegExp(r'[^0-9.]'), ''),
                ) ??
                0;
            double prot =
                double.tryParse(
                  data["protein"]!.replaceAll(RegExp(r'[^0-9.]'), ''),
                ) ??
                0;

            // Grouping item yang sama dalam satu sesi
            int existingIdx = detectedItems.indexWhere(
              (it) => it['nama'] == label && it['sesi_index'] == index,
            );

            if (existingIdx != -1) {
              detectedItems[existingIdx]['jumlah'] += 1;
              detectedItems[existingIdx]['total_kalori'] += kal;
              detectedItems[existingIdx]['total_protein'] += prot;
            } else {
              detectedItems.add({
                "sesi_index": index,
                "sesi_nama": _sessions[index],
                "nama": label[0].toUpperCase() + label.substring(1),
                "jumlah": 1,
                "total_kalori": kal,
                "total_protein": prot,
              });
            }
          }
        }
      }

      // Hitung akumulasi total harian dari semua sesi
      double totalDayKal = 0;
      double totalDayProt = 0;
      for (var item in detectedItems) {
        totalDayKal += (item['total_kalori'] as double);
        totalDayProt += (item['total_protein'] as double);
      }

      setState(() {
        result = res;
        _kaloriCtrl.text = totalDayKal.toStringAsFixed(0);
        _proteinCtrl.text = totalDayProt.toStringAsFixed(1);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal Deteksi: $e")));
    }
  }

  Future<void> finalizeAndSave(String aiSummary) async {
    if (_namaCtrl.text.isEmpty || _nikCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama dan NIK wajib diisi!")),
      );
      return;
    }

    if (_images.every((img) => img == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal unggah 1 foto makanan!")),
      );
      return;
    }

    setState(() => loading = true);
    final api = ApiService();

    // Buat string rincian detail untuk database
    String rincianTeks = detectedItems
        .map((e) => "${e['nama']} x${e['jumlah']} (${e['sesi_nama']})")
        .join(", ");
    String daftarAkhir = _manualInput.isEmpty
        ? rincianTeks
        : "$rincianTeks, $_manualInput (manual)";

    double cal = double.tryParse(_kaloriCtrl.text) ?? 0;
    int usia = int.tryParse(_usiaCtrl.text) ?? 0;
    bool isCrit = cal > 0 && cal < 800; // Contoh kriteria kritis

    // MENGIRIM DATA UTUH KE API
    final success = await api.saveSurvey({
      "nama_balita": _namaCtrl.text,
      "nik": _nikCtrl.text,
      "nomor_wa": _waCtrl.text,
      "usia_bulan": usia,
      "berat_badan": double.tryParse(_bbCtrl.text) ?? 0.0,
      "tinggi_badan": double.tryParse(_tbCtrl.text) ?? 0.0,
      "wilayah": _posyanduCtrl.text,
      "kader_nama": _kaderCtrl.text,
      "total_kalori": cal,
      "total_protein": double.tryParse(_proteinCtrl.text) ?? 0,
      "status_gizi": isCrit ? "Critical / Perlu Perbaikan" : "Normal / Layak",
      "ai_risk": isCrit ? "critical" : "normal",
      "hasil_deteksi": daftarAkhir,
      "ai_summary": aiSummary,
    }, _images);

    setState(() => loading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Laporan Berhasil Disimpan!"),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Gagal Simpan. Periksa ApiService/Server."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double currentKalori = double.tryParse(_kaloriCtrl.text) ?? 0;
    bool isCritical = currentKalori > 0 && currentKalori < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          "Screening Gizi Harian AI",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInput(_namaCtrl, "Nama Balita", Icons.person_outline),
              _buildInput(
                _nikCtrl,
                "NIK Balita",
                Icons.badge_outlined,
                isNum: true,
              ),
              _buildInput(
                _waCtrl,
                "Nomor WA Ortu",
                Icons.phone_android_outlined,
                isNum: true,
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      _usiaCtrl,
                      "Usia (bulan)",
                      Icons.cake_outlined,
                      isNum: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInput(
                      _posyanduCtrl,
                      "Posyandu",
                      Icons.location_on_outlined,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      _bbCtrl,
                      "Berat Badan (kg)",
                      Icons.monitor_weight_outlined,
                      isNum: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInput(
                      _tbCtrl,
                      "Tinggi Badan (cm)",
                      Icons.height,
                      isNum: true,
                    ),
                  ),
                ],
              ),
              _buildInput(
                _kaderCtrl,
                "Nama Kader",
                Icons.assignment_ind_outlined,
              ),

              const SizedBox(height: 20),
              const Text(
                "Dokumentasi Makan (Upload Pagi, Siang, Sore)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(child: _buildSessionImagePicker(index)),
                ),
              ),

              const SizedBox(height: 25),
              if (loading) const Center(child: CircularProgressIndicator()),

              if (detectedItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildStatusBanner(
                  isCritical ? "RISIKO ASUPAN RENDAH" : "ASUPAN HARI INI BAIK",
                  isCritical,
                ),
                const SizedBox(height: 20),
                ...detectedItems
                    .map((item) => _buildFoodItemRow(item))
                    .toList(),
              ],

              const Divider(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      _kaloriCtrl,
                      "Total Kalori",
                      Icons.bolt,
                      isNum: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInput(
                      _proteinCtrl,
                      "Total Protein",
                      Icons.egg_outlined,
                      isNum: true,
                    ),
                  ),
                ],
              ),
              _buildManualInputArea(),

              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton("Tanya AI", () async {
                      String rincian = detectedItems
                          .map(
                            (e) =>
                                "${e['nama']} x${e['jumlah']} (${e['sesi_nama']})",
                          )
                          .join(", ");
                      final chatResult = await Navigator.pushNamed(
                        context,
                        "/chat",
                        arguments: {
                          "nama_balita": _namaCtrl.text,
                          "total_kalori": _kaloriCtrl.text,
                          "daftar_makanan": rincian,
                          "status_gizi": isCritical ? "Kurang" : "Cukup",
                          "context":
                              "Balita makan $rincian hari ini. Berikan rencana menu 7 hari.",
                        },
                      );
                      if (chatResult != null && chatResult is String)
                        finalizeAndSave(chatResult);
                    }, color: Colors.indigo),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      "Simpan",
                      () => finalizeAndSave(""),
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItemRow(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal.withOpacity(0.1),
            child: Text(
              item['sesi_nama'][0],
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${item['nama']} x${item['jumlah']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${item['total_kalori'].toStringAsFixed(0)} kkal | ${item['total_protein'].toStringAsFixed(1)}g Protein",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
        ],
      ),
    );
  }

  Widget _buildSessionImagePicker(int index) {
    return Column(
      children: [
        Text(
          _sessions[index],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _showPickerOptions(index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            height: 85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _images[index] != null ? Colors.teal : Colors.grey[300]!,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
              ],
            ),
            child: _images[index] == null
                ? const Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.grey,
                    size: 28,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      _images[index]!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
          ),
        ),
        if (_images[index] != null)
          TextButton(
            onPressed: () => detectFood(index),
            child: const Text(
              "Scan",
              style: TextStyle(
                fontSize: 10,
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  void _showPickerOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Ambil Foto"),
              onTap: () {
                Navigator.pop(context);
                pickImage(index, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Pilih dari Galeri"),
              onTap: () {
                Navigator.pop(context);
                pickImage(index, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status, bool isCritical) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCritical ? Colors.red : Colors.green),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isCritical ? Colors.red : Colors.green,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNum = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildManualInputArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Koreksi Menu Manual",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        TextField(
          onChanged: (val) => setState(() => _manualInput = val),
          decoration: const InputDecoration(
            hintText: "Misal: Tambah 1 Potong Ikan",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
