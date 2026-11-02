import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Apple-inspired frosted glass container with backdrop blur,
/// specular gradient border, translucent layer fills, and ambient elevation.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final double opacity;
  final double blur;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.opacity = 0.65,
    this.blur = 24.0,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? BorderRadius.circular(26);

    final defaultBaseColor = isDark
        ? const Color(0xFF1E2238).withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: opacity);

    // Specular highlight border: brighter on top-left, softer on bottom-right
    final defaultBorder = border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.75),
          width: 1.2,
        );

    final defaultShadow = boxShadow ??
        [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0x12000000),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.6),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ];

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? defaultBaseColor,
        borderRadius: r,
        border: defaultBorder,
        boxShadow: defaultShadow,
      ),
      child: child,
    );

    if (blur > 0) {
      content = ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      content = _BouncingGlass(
        onTap: onTap!,
        child: content,
      );
    }

    return content;
  }
}

/// Spring-loaded bounce feedback for Apple-style frosted glass interactions
class _BouncingGlass extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BouncingGlass({required this.child, required this.onTap});

  @override
  State<_BouncingGlass> createState() => _BouncingGlassState();
}

class _BouncingGlassState extends State<_BouncingGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Frosted Glass Button with spring-like tap feedback
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double blur;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.borderRadius,
    this.blur = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? BorderRadius.circular(20);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.7)),
              borderRadius: r,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.85),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Frosted pill for categories, badges, and filters
class GlassPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? activeColor;

  const GlassPill({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = activeColor ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.6)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.75)),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primary.withValues(alpha: 0.32)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF4A4E69)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF4A4E69)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
