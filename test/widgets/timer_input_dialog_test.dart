
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:routime/widgets/timer_input_dialog.dart';

void main() {
  Future<void> openTimerDialog(
    WidgetTester tester, {
    String title = 'Atur Countdown',
    List<int> initialValues = const [25],
    List<String> labels = const ['Durasi (menit)'],
    required ValueChanged<List<int>?> onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<List<int>>(
                    context: context,
                    builder: (context) {
                      return TimerInputDialog(
                        title: title,
                        initialValues: initialValues,
                        labels: labels,
                      );
                    },
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

  group('TimerInputDialog', () {
    testWidgets('Menampilkan judul dan input dengan benar', (
      tester,
    ) async {
      List<int>? result;

      await openTimerDialog(
        tester,
        title: 'Atur Countdown',
        initialValues: [25],
        labels: ['Durasi (menit)'],
        onResult: (value) => result = value,
      );

      expect(find.text('Atur Countdown'), findsOneWidget);
      expect(find.text('Durasi (menit)'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);

      final textField = tester.widget<TextField>(
        find.byType(TextField),
      );

      expect(textField.controller!.text, '25');
      expect(result, isNull);
    });

    testWidgets('Menampilkan beberapa input Pomodoro', (
      tester,
    ) async {
      await openTimerDialog(
        tester,
        title: 'Atur Pomodoro',
        initialValues: [25, 5, 15, 4],
        labels: [
          'Fokus (menit)',
          'Istirahat pendek (menit)',
          'Istirahat panjang (menit)',
          'Sesi sebelum istirahat panjang',
        ],
        onResult: (_) {},
      );

      expect(find.text('Atur Pomodoro'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4));

      final fields = tester.widgetList<TextField>(
        find.byType(TextField),
      );

      expect(
        fields.map((field) => field.controller!.text).toList(),
        ['25', '5', '15', '4'],
      );

      expect(find.text('Fokus (menit)'), findsOneWidget);
      expect(find.text('Istirahat pendek (menit)'), findsOneWidget);
      expect(find.text('Istirahat panjang (menit)'), findsOneWidget);
      expect(
        find.text('Sesi sebelum istirahat panjang'),
        findsOneWidget,
      );
    });

    testWidgets('Mengembalikan nilai ketika tombol Mulai ditekan', (
      tester,
    ) async {
      List<int>? result;

      await openTimerDialog(
        tester,
        initialValues: [25],
        labels: ['Durasi (menit)'],
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      expect(result, [25]);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Mengembalikan nilai input yang sudah diubah', (
      tester,
    ) async {
      List<int>? result;

      await openTimerDialog(
        tester,
        initialValues: [25, 5],
        labels: ['Fokus', 'Istirahat'],
        onResult: (value) => result = value,
      );

      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), '30');
      await tester.enterText(fields.at(1), '10');

      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      expect(result, [30, 10]);
    });

    testWidgets('Tidak menutup dialog jika input bernilai nol', (
      tester,
    ) async {
      await openTimerDialog(
        tester,
        initialValues: [25],
        labels: ['Durasi (menit)'],
        onResult: (_) {},
      );

      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Masukkan angka yang valid dan lebih dari 0.'),
        findsOneWidget,
      );
    });

    testWidgets('Tidak menutup dialog jika input kosong', (
      tester,
    ) async {
      await openTimerDialog(
        tester,
        initialValues: [25],
        labels: ['Durasi (menit)'],
        onResult: (_) {},
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Masukkan angka yang valid dan lebih dari 0.'),
        findsOneWidget,
      );
    });

    testWidgets('Tidak menutup dialog jika input bukan angka', (
      tester,
    ) async {
      await openTimerDialog(
        tester,
        initialValues: [25],
        labels: ['Durasi (menit)'],
        onResult: (_) {},
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Masukkan angka yang valid dan lebih dari 0.'),
        findsOneWidget,
      );
    });

    testWidgets('Menutup dialog ketika tombol Batal ditekan', (
      tester,
    ) async {
      List<int>? result = [99];

      await openTimerDialog(
        tester,
        initialValues: [25],
        labels: ['Durasi (menit)'],
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
