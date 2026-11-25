
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:routime/widgets/confirm_delete_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester, {
    required ValueChanged<bool> onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await confirmDeleteHabit(
                    context,
                    'Belajar Flutter',
                  );

                  onResult(result);
                },
                child: const Text('Buka Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Dialog'));
    await tester.pumpAndSettle();
  }

  group('ConfirmDeleteDialog', () {
    testWidgets('Menampilkan judul dan nama Habit', (tester) async {
      bool? result;

      await openDialog(
        tester,
        onResult: (value) => result = value,
      );

      expect(find.text('Hapus kebiasaan?'), findsOneWidget);
      expect(
        find.text('"Belajar Flutter" dan riwayatnya akan dihapus.'),
        findsOneWidget,
      );

      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets('Mengembalikan true ketika Hapus ditekan', (
      tester,
    ) async {
      bool? result;

      await openDialog(
        tester,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(result, true);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Mengembalikan false ketika Batal ditekan', (
      tester,
    ) async {
      bool? result;

      await openDialog(
        tester,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(result, false);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Mengembalikan false ketika dialog ditutup', (
      tester,
    ) async {
      bool? result;

      await openDialog(
        tester,
        onResult: (value) => result = value,
      );

      // Menutup dialog menggunakan tombol Back sistem.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(result, false);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
