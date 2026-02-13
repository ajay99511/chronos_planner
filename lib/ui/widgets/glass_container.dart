import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GlassContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final List<Color>? borderGradientColors;
  final double blurSigma;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderGradientColors,
    this.blurSigma = 10,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasBorderGradient = widget.borderGradientColors != null &&
        widget.borderGradientColors!.length >= 2;

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: AnimatedScale(
        scale: _scale,
        duration: AppAnimDurations.fast,
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: widget.color ?? AppColors.glassFill,
                border: hasBorderGradient
                    ? null
                    : Border.all(color: AppColors.glassBorder),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                gradient: hasBorderGradient ? null : null,
              ),
              foregroundDecoration: hasBorderGradient
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 1.5,
                      ),
                    )
                  : null,
              child: hasBorderGradient
                  ? CustomPaint(
                      painter: _GradientBorderPainter(
                        colors: widget.borderGradientColors!,
                        radius: AppRadius.xl,
                      ),
                      child: widget.child,
                    )
                  : widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double radius;

  _GradientBorderPainter({required this.colors, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return colors != oldDelegate.colors || radius != oldDelegate.radius;
  }
}
