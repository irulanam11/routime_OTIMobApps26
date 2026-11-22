import 'package:material_ui/material_ui.dart';

/// Menampilkan dialog konfirmasi hapus.
/// Mengembalikan true jika pengguna menekan "Hapus", false jika "Batal"
/// atau menutup dialog.
Future<bool> confirmDeleteHabit(BuildContext context, String habitName) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus kebiasaan?'),
      content: Text('"$habitName" dan riwayatnya akan dihapus.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  // Jika dialog ditutup tanpa memilih (result null), anggap batal
  return result ?? false;
}