import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class SetInputRow extends StatefulWidget {
  final int setNumber;
  final double? prefillWeight;
  final int? prefillReps;
  final bool isCompleted;
  final bool isLoading;
  final Function(double weight, int reps, bool failure) onLog;

  const SetInputRow({
    super.key,
    required this.setNumber,
    this.prefillWeight,
    this.prefillReps,
    this.isCompleted = false,
    this.isLoading = false,
    required this.onLog,
  });

  @override
  State<SetInputRow> createState() => _SetInputRowState();
}

class _SetInputRowState extends State<SetInputRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  bool _failure = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.prefillWeight?.toStringAsFixed(1) ?? '');
    _repsCtrl = TextEditingController(text: widget.prefillReps?.toString() ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _adjustWeight(double delta) {
    final current = double.tryParse(_weightCtrl.text) ?? 0;
    final next = (current + delta).clamp(0, 999);
    _weightCtrl.text = next.toStringAsFixed(1);
  }

  void _adjustReps(int delta) {
    final current = int.tryParse(_repsCtrl.text) ?? 0;
    final next = (current + delta).clamp(0, 99);
    _repsCtrl.text = next.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text('Set ${widget.setNumber}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const Spacer(),
            Text('${_weightCtrl.text} kg  x  ${_repsCtrl.text}',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            if (_failure) ...[
              const SizedBox(width: 6),
              const Text('F', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 32,
            child: Text('${widget.setNumber}', style: GoogleFonts.oswald(fontSize: 18, color: AppColors.textMuted)),
          ),
          // Weight
          _StepperField(
            controller: _weightCtrl,
            suffix: 'kg',
            decimal: true,
            onMinus: () => _adjustWeight(-2.5),
            onPlus: () => _adjustWeight(2.5),
          ),
          const SizedBox(width: 8),
          // Reps
          _StepperField(
            controller: _repsCtrl,
            suffix: 'rps',
            decimal: false,
            onMinus: () => _adjustReps(-1),
            onPlus: () => _adjustReps(1),
          ),
          const SizedBox(width: 6),
          // Failure toggle
          GestureDetector(
            onTap: () => setState(() => _failure = !_failure),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _failure ? AppColors.error.withValues(alpha: 0.2) : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _failure ? AppColors.error : AppColors.textMuted.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text('F',
                    style: TextStyle(
                      color: _failure ? AppColors.error : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    )),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // LOG button
          SizedBox(
            height: 40,
            width: 64,
            child: ElevatedButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      final weight = double.tryParse(_weightCtrl.text) ?? 0;
                      final reps = int.tryParse(_repsCtrl.text) ?? 0;
                      if (weight > 0 && reps > 0) {
                        HapticFeedback.mediumImpact();
                        widget.onLog(weight, reps, _failure);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: widget.isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('LOG', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  final bool decimal;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _StepperField({
    required this.controller,
    required this.suffix,
    required this.decimal,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          _SmallButton(icon: Icons.remove, onTap: onMinus),
          const SizedBox(width: 2),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: decimal),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  suffixText: suffix,
                  suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                onTap: () => controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length),
              ),
            ),
          ),
          const SizedBox(width: 2),
          _SmallButton(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
