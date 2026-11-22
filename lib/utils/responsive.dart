import 'package:material_ui/material_ui.dart';

/// Lebar minimum (dalam dp) agar dianggap layar lebar/tablet.
const double kWideBreakpoint = 720;

/// Membatasi lebar konten dan menengahkannya.
/// Tanpa ini, konten melebar penuh di tablet dan terlihat janggal.
class MaxWidth extends StatelessWidget {
  final Widget child;
  final double width;
  const MaxWidth({super.key, required this.child, this.width = 720});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}