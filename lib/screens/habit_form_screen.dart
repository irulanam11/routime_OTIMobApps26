import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit;

  const HabitFormScreen({super.key, this.habit});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedColor = 0xFF2F7D4F;
  bool _useTimer = false;
  bool _isSaving = false;

  bool get _isEditing => widget.habit != null;

  static const _colors = [0xFF2F7D4F, 0xFFF2A83B, 0xFF4A7FB5, 0xFFC4566B];

  @override
  void initState() {
    super.initState();

    final habit = widget.habit;

    if (habit != null) {
      _nameController.text = habit.name;
      _descriptionController.text = habit.description;
      _selectedColor = habit.colorValue;
      _useTimer = habit.useTimer;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final habitProvider = context.read<HabitProvider>();

      if (_isEditing) {
        await habitProvider.updateHabit(
          id: widget.habit!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          colorValue: _selectedColor,
          useTimer: _useTimer,
          timerProvider: context.read<TimerProvider>(),
        );
      } else {
        habitProvider.addHabit(
          _nameController.text,
          description: _descriptionController.text,
          colorValue: _selectedColor,
          useTimer: _useTimer,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan Habit: $error')));

      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Kebiasaan' : 'Kebiasaan Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nama kebiasaan',
                    hintText: 'Contoh: Membaca buku',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Jelaskan kebiasaan yang ingin dilakukan',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Warna', style: TextStyle(color: AppColors.muted)),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    for (final color in _colors)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: _selectedColor == color
                                ? Border.all(color: AppColors.text, width: 3)
                                : null,
                          ),
                          child: _selectedColor == color
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 28),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gunakan Timer'),
                  subtitle: const Text(
                    'Aktifkan timer untuk membantu mengatur waktu kebiasaan.',
                  ),
                  value: _useTimer,
                  onChanged: (value) {
                    setState(() {
                      _useTimer = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Simpan Perubahan' : 'Simpan'),
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
