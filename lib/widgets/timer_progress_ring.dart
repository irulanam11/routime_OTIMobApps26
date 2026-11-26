import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class TimerProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Widget child;

  const TimerProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: normalizedProgress),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  backgroundColor: AppColors.ringBackground,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.ringBackground,
                  ),
                ),
              ),
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: animatedProgress,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              Container(
                width: size - 36,
                height: size - 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}
