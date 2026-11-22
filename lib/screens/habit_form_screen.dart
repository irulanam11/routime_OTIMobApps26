import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';

// Layar ini StatefulWidget karena ada data yang berubah di dalamnya
// (warna yang sedang dipilih).
class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  // Kunci untuk memeriksa (validasi) isi form
  final _formKey = GlobalKey<FormState>();

  // Pengendali untuk membaca teks yang diketik pengguna
  final _nameController = TextEditingController();

  // Warna yang sedang dipilih (awalnya hijau)
  int _selectedColor = 0xFF2F7D4F;

  // Daftar pilihan warna
  static const _colors = [
    0xFF2F7D4F, // hijau
    0xFFF2A83B, // kuning
    0xFF4A7FB5, // biru
    0xFFC4566B, // merah
  ];

  // Membersihkan controller saat layar ditutup
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Dijalankan saat tombol Simpan ditekan
  void _save() {
    // Jika nama kosong, berhenti dan tampilkan pesan error
    if (!_formKey.currentState!.validate()) return;

    // Kirim data ke provider
    context
        .read<HabitProvider>()
        .addHabit(_nameController.text, colorValue: _selectedColor);

    // Tutup layar form, kembali ke Home
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kebiasaan Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kolom nama
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama kebiasaan',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Nama tidak boleh kosong'
                          : null,
                ),
                const SizedBox(height: 24),

                // 2. Pilihan warna
                const Text('Warna',
                    style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    for (final c in _colors)
                      GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            // Lingkaran terpilih diberi garis tepi
                            border: _selectedColor == c
                                ? Border.all(
                                    color: AppColors.text, width: 3)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // 3. Tombol simpan
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}