import 'package:flutter/material.dart';
import '../api_service.dart';

class EditSurveyScreen extends StatefulWidget {
  final Map<String, dynamic> survey;
  const EditSurveyScreen({super.key, required this.survey});

  @override
  State<EditSurveyScreen> createState() => _EditSurveyScreenState();
}

class _EditSurveyScreenState extends State<EditSurveyScreen> {
  late TextEditingController _namaCtrl;
  late TextEditingController _usiaCtrl;
  late TextEditingController _bbCtrl;
  late TextEditingController _tbCtrl;
  late TextEditingController _hasilCtrl;
  late TextEditingController _aiSummaryCtrl; // Untuk menyimpan ringkasan AI
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.survey['nama_balita']);
    _usiaCtrl = TextEditingController(
      text: widget.survey['usia_bulan'].toString(),
    );
    _bbCtrl = TextEditingController(
      text: widget.survey['berat_badan'].toString(),
    );
    _tbCtrl = TextEditingController(
      text: widget.survey['tinggi_badan'].toString(),
    );
    _hasilCtrl = TextEditingController(text: widget.survey['hasil_deteksi']);
    _aiSummaryCtrl = TextEditingController(
      text: widget.survey['ai_summary'] ?? "",
    );
  }

  // FUNGSI ANALISIS ULANG VIA CHAT AI
  Future<void> _reAnalyzeWithAI() async {
    // Navigasi ke Chat dan kirim data terbaru yang ada di TextField
    final chatResult = await Navigator.pushNamed(
      context,
      "/chat",
      arguments: {
        "nama_balita": _namaCtrl.text,
        "usia_bulan": _usiaCtrl.text,
        "total_kalori": widget.survey['total_kalori']
            .toString(), // Data tetap dari DB
        "daftar_makanan": _hasilCtrl.text,
        "status_gizi": widget.survey['status_gizi'],
      },
    );

    // Jika AI memberikan jawaban baru, masukkan ke controller ringkasan AI
    if (chatResult != null && chatResult is String) {
      setState(() {
        _aiSummaryCtrl.text = chatResult;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Analisis AI telah diperbarui!")),
      );
    }
  }

  Future<void> _handleUpdate() async {
    setState(() => _loading = true);

    final payload = {
      "nama_balita": _namaCtrl.text,
      "usia_bulan": int.tryParse(_usiaCtrl.text) ?? 0,
      "berat_badan": double.tryParse(_bbCtrl.text) ?? 0,
      "tinggi_badan": double.tryParse(_tbCtrl.text) ?? 0,
      "hasil_deteksi": _hasilCtrl.text,
      "ai_summary": _aiSummaryCtrl.text, // Mengirim hasil analisis AI terbaru
    };

    final success = await ApiService().updateSurvey(
      widget.survey['id'],
      payload,
    );

    setState(() => _loading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Data Berhasil Diperbarui"),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Gagal Memperbarui Data"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          "Edit & Analisis Ulang",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Informasi Balita"),
            _buildTextField(_namaCtrl, "Nama Balita", Icons.person_outline),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _usiaCtrl,
                    "Usia (Bulan)",
                    Icons.cake_outlined,
                    isNum: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _bbCtrl,
                    "BB (kg)",
                    Icons.monitor_weight_outlined,
                    isNum: true,
                  ),
                ),
              ],
            ),
            _buildTextField(
              _tbCtrl,
              "Tinggi Badan (cm)",
              Icons.height,
              isNum: true,
            ),

            const SizedBox(height: 15),
            _buildSectionTitle("Konten Survei"),
            _buildTextField(
              _hasilCtrl,
              "Hasil Deteksi/Catatan Menu",
              Icons.restaurant_menu,
              maxLines: 3,
            ),

            const SizedBox(height: 15),
            _buildSectionTitle("Analisis AI"),
            _buildTextField(
              _aiSummaryCtrl,
              "Ringkasan Saran AI",
              Icons.auto_awesome,
              maxLines: 4,
              readOnly: true,
            ),

            const SizedBox(height: 10),
            // TOMBOL ANALISIS ULANG AI
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _reAnalyzeWithAI,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text("TANYA ULANG AI (Gunakan Data Baru)"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: const BorderSide(color: Colors.indigo),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            // TOMBOL SIMPAN PERUBAHAN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SIMPAN SEMUA PERUBAHAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNum = false,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
        ],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal[600], size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey[50] : Colors.white,
        ),
      ),
    );
  }
}
