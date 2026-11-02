import 'package:flutter/material.dart';

/// Animated 24×24 checkbox. Draws a checkmark via [CustomPainter] and applies
/// a scale pulse + color fade when [isDone] changes.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({
    super.key,
    required this.isDone,
    required this.onToggle,
    required this.color,
  });

  final bool isDone;
  final void Function() onToggle;
  final Color color;

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Progress 0→1: check draw + color fade + scale pulse
  late final Animation<double> _checkProgress;
  late final Animation<double> _scale;
  late final Animation<Color?> _fillColor;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _checkProgress = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
    );

    // Scale: 1.0 → 1.2 → 1.0 over the full duration
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_ctrl);

    _fillColor = ColorTween(
      begin: widget.color,
      end: const Color(0xFFB0B0B0), // greyed-out when done
    ).animate(_ctrl);

    // Reflect initial state without animation
    if (widget.isDone) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDone != widget.isDone) {
      widget.isDone ? _ctrl.forward() : _ctrl.reverse();
    }
    // Update color tween end if color changed
    if (oldWidget.color != widget.color) {
      _fillColor = ColorTween(
        begin: widget.color,
        end: const Color(0xFFB0B0B0),
      ).animate(_ctrl);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final fill = _fillColor.value ?? widget.color;
          return Transform.scale(
            scale: _scale.value,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _CheckPainter(
                  progress: _checkProgress.value,
                  fillColor: fill,
                  isDone: widget.isDone,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.progress,
    required this.fillColor,
    required this.isDone,
  });

  final double progress;
  final Color fillColor;
  final bool isDone;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final bgPaint = Paint()
      ..color = progress > 0
          ? fillColor
          : fillColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, bgPaint);

    // Border when not filled
    if (progress < 0.05) {
      final borderPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawRRect(rrect, borderPaint);
    }

    // Animated checkmark path
    if (progress > 0) {
      final checkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Checkmark: two segments – short leg then long leg
      final p1 = Offset(size.width * 0.22, size.height * 0.50);
      final p2 = Offset(size.width * 0.42, size.height * 0.68);
      final p3 = Offset(size.width * 0.78, size.height * 0.32);

      // Total path length ratio: short leg ~30%, long leg ~70%
      const shortWeight = 0.35;
      const longWeight = 0.65;

      final path = Path();
      if (progress <= shortWeight) {
        final t = progress / shortWeight;
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(
          lerpDouble(p1.dx, p2.dx, t),
          lerpDouble(p1.dy, p2.dy, t),
        );
      } else {
        final t = (progress - shortWeight) / longWeight;
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
        path.lineTo(
          lerpDouble(p2.dx, p3.dx, t),
          lerpDouble(p2.dy, p3.dy, t),
        );
      }
      canvas.drawPath(path, checkPaint);
    }
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress ||
      old.fillColor != fillColor ||
      old.isDone != isDone;
}
