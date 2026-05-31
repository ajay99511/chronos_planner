import 'package:flutter/material.dart';
import 'package:chronosky/core/theme/app_theme.dart';

/// A premium futuristic button with neon glow and gradient effects.
class NeoButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color>? gradientColors;
  final Color? glowColor;
  final double? width;
  final double height;
  final bool isSecondary;

  const NeoButton({
    super.key,
    this.onPressed,
    required this.child,
    this.gradientColors,
    this.glowColor,
    this.width,
    this.height = 48,
    this.isSecondary = false,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null) setState(() => _scale = 0.96);
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed != null) setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final defaultGradient = widget.isSecondary
        ? [AppColors.surface, AppColors.surface.withValues(alpha: 0.8)]
        : [AppColors.neonBlue, AppColors.neonPurple];

    final colors = widget.gradientColors ?? defaultGradient;
    final glow = widget.glowColor ?? colors.first;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _scale,
          duration: AppAnimDurations.fast,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: AppAnimDurations.normal,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled ? colors : [Colors.grey.shade800, Colors.grey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: (enabled && _isHovered)
                  ? [
                      BoxShadow(
                        color: glow.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
              border: Border.all(
                color: widget.isSecondary
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: DefaultTextStyle.merge(
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
