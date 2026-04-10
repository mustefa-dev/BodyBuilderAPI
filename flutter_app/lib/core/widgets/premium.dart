import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

// ============================================================
//  KINETIC LOGO
// ============================================================
class KineticLogo extends StatelessWidget {
  final double size;
  const KineticLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: size),
        const SizedBox(width: 6),
        Text('KINETIC', style: GoogleFonts.lexend(fontSize: size * 0.85, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 2)),
      ],
    );
  }
}

// ============================================================
//  LIME CTA BUTTON - gradient lime with dark text
// ============================================================
class LimeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;

  const LimeButton({super.key, required this.label, this.onPressed, this.isLoading = false, this.icon, this.height = 56});

  @override
  State<LimeButton> createState() => _LimeButtonState();
}

class _LimeButtonState extends State<LimeButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.isLoading ? null : () { HapticFeedback.lightImpact(); widget.onPressed?.call(); },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.isLoading ? null : AppColors.primaryGradient,
            color: widget.isLoading ? AppColors.surfaceHigh : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label, style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.onPrimary, letterSpacing: 1)),
                      if (widget.icon != null) ...[const SizedBox(width: 8), Icon(widget.icon, color: AppColors.onPrimary, size: 20)],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  SECTION LABEL - uppercase muted label
// ============================================================
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.w700, color: color ?? AppColors.textMuted, letterSpacing: 1.5));
  }
}

// ============================================================
//  SURFACE CARD - no borders, uses background contrast
// ============================================================
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double borderRadius;

  const SurfaceCard({super.key, required this.child, this.padding, this.margin, this.color, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

// ============================================================
//  HEAVY STEPPER - oversized +/- for gym use (64x64)
// ============================================================
class HeavyStepper extends StatelessWidget {
  final String value;
  final String? unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final List<Widget>? extraButtons;

  const HeavyStepper({super.key, required this.value, this.unit, required this.onMinus, required this.onPlus, this.extraButtons});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepBtn(Icons.remove, onMinus),
            const SizedBox(width: 16),
            SizedBox(
              width: 140,
              child: Column(
                children: [
                  Text(value, style: GoogleFonts.lexend(fontSize: 64, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1)),
                  if (unit != null) Text(unit!, style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _stepBtn(Icons.add, onPlus),
          ],
        ),
        if (extraButtons != null) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: extraButtons!),
        ],
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: AppColors.textPrimary, size: 28),
      ),
    );
  }
}
