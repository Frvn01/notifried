import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/schedule.dart';

/// Displays the live countdown string for [nextClass], updating periodically.
/// Guaranteed to render crisply both inside the Flutter app and in offscreen
/// bitmap captures for Android home screen widgets.
class CountdownText extends StatefulWidget {
  const CountdownText({
    super.key,
    this.nextClass,
    this.style,
  });

  final Schedule? nextClass;
  final TextStyle? style;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late String _status;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _status = _currentStatus();
    _startTimer();
  }

  @override
  void didUpdateWidget(CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _currentStatus();
    if (next != _status) {
      setState(() => _status = next);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _currentStatus() =>
      widget.nextClass?.countdownStatus ?? 'No upcoming class';

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final next = _currentStatus();
      if (next != _status && mounted) {
        setState(() => _status = next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ??
        Theme.of(context).textTheme.titleMedium ??
        const TextStyle(fontSize: 17, fontWeight: FontWeight.w700);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        _status,
        style: textStyle,
        maxLines: 1,
      ),
    );
  }
}
