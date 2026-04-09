import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class RestTimerSheet extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback onDone;

  const RestTimerSheet({super.key, required this.totalSeconds, required this.onDone});

  static Future<void> show(BuildContext context, {required int seconds, required VoidCallback onDone}) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => RestTimerSheet(totalSeconds: seconds, onDone: onDone),
    );
  }

  @override
  State<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<RestTimerSheet> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 300), () {
          HapticFeedback.heavyImpact();
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          HapticFeedback.heavyImpact();
        });
        _dismiss();
      } else {
        setState(() => _remaining--);
        if (_remaining <= 5) HapticFeedback.lightImpact();
      }
    });
  }

  void _dismiss() {
    _timer?.cancel();
    widget.onDone();
    if (mounted) Navigator.of(context).pop();
  }

  Color get _bgColor {
    if (_remaining <= 5) return AppColors.error;
    if (_remaining <= 15) return AppColors.warning;
    return AppColors.accent2;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = _remaining ~/ 60;
    final secs = _remaining % 60;

    return Container(
      decoration: BoxDecoration(
        color: _bgColor.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('REST', style: GoogleFonts.oswald(fontSize: 20, color: Colors.white70, letterSpacing: 4)),
          const SizedBox(height: 16),
          Text(
            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: GoogleFonts.oswald(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _dismiss,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('SKIP REST', style: GoogleFonts.oswald(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
