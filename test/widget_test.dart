import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizilens_app_baru/main.dart'; // <--- Import yang sudah diperbaiki

void main() {
  testWidgets('Cek tampilan awal GiziLens', (WidgetTester tester) async {
    // 1. Jalankan aplikasi (MyApp)
    await tester.pumpWidget(const MyApp());

    // 2. Cek apakah tulisan "GiziLens" ada di layar? (Harusnya ada di halaman Login)
    expect(find.text('GiziLens'), findsWidgets);

    // 3. Cek apakah tombol tambah (+) ada? (Harusnya TIDAK ada, karena ini bukan aplikasi Counter)
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
