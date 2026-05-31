import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chronosky/core/theme/app_theme.dart';

/// A premium glassmorphism container with optimized blur and optional gradient border.
class GlassContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final List<Color>? borderGradientColors;
  final double blurSigma;
  final double borderRadius;
  final bool animateScale;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderGradientColors,
    this.blurSigma = 12.0,
    this.borderRadius = AppRadius.xl,
    this.animateScale = true,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null && widget.animateScale) {
      setState(() => _scale = 0.98);
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null && widget.animateScale) {
      setState(() => _scale = 1.0);
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (widget.onTap != null && widget.animateScale) {
      setState(() => _scale = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBorderGradient = widget.borderGradientColors != null &&
        widget.borderGradientColors!.length >= 2;

    Widget container = Container(
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.color ?? AppColors.glassFill,
        border: hasBorderGradient
            ? null
            : Border.all(color: AppColors.glassBorder, width: 0.5),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: widget.child,
    );

    if (hasBorderGradient) {
      container = CustomPaint(
        painter: _GradientBorderPainter(
          colors: widget.borderGradientColors!,
          radius: widget.borderRadius,
          strokeWidth: 1.2,
        ),
        child: container,
      );
    }

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: AnimatedScale(
        scale: _scale,
        duration: AppAnimDurations.fast,
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: widget.blurSigma, sigmaY: widget.blurSigma,),
            child: container,
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double radius;
  final double strokeWidth;

  _GradientBorderPainter({
    required this.colors,
    required this.radius,
    required this.strokeWidth,
  });

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
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return colors != oldDelegate.colors ||
        radius != oldDelegate.radius ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
