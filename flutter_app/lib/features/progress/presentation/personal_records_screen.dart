import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium.dart';
import '../../session/presentation/session_provider.dart';

class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(personalRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERSONAL\nRECORDS',
                    style: GoogleFonts.lexend(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -1, height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'HALL OF FAME',
                    style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Total PRs badge ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: prsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (records) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'TOTAL PRS',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${records.length}',
                          style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── PR list ──
            Expanded(
              child: prsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(personalRecordsProvider),
                        child: Text('Retry', style: GoogleFonts.inter(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No PRs yet', style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Text('Hit the gym to set your first records', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final pr = records[index];
                      return _PREntry(pr: pr);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PREntry extends StatelessWidget {
  final dynamic pr;
  const _PREntry({required this.pr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        color: AppColors.surfaceLow,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Exercise name + weight
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pr.name.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${pr.personalBestWeight.toStringAsFixed(1)}',
                    style: GoogleFonts.lexend(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1),
                  ),
                  Text(
                    'kg',
                    style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
