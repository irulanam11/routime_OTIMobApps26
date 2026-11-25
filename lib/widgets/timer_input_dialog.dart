import 'package:material_ui/material_ui.dart';

class TimerInputDialog extends StatefulWidget {
  const TimerInputDialog({
    super.key,
    required this.title,
    required this.initialValues,
    required this.labels,
  });

  final String title;
  final List<int> initialValues;
  final List<String> labels;

  @override
  State<TimerInputDialog> createState() => _TimerInputDialogState();
}

class _TimerInputDialogState extends State<TimerInputDialog> {
  late List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();

    controllers = widget.initialValues
        .map(
          (value) => TextEditingController(
            text: value.toString(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _submit() {
    final values = <int>[];

    for (final controller in controllers) {
      final value = int.tryParse(controller.text.trim());

      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Masukkan angka yang valid dan lebih dari 0.',
            ),
          ),
        );
        return;
      }

      values.add(value);
    }

    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            controllers.length,
            (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[index],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.labels[index],
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Mulai'),
        ),
      ],
    );
  }
}
