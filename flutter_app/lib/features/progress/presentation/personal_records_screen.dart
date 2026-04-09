import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium.dart';
import '../../session/presentation/session_provider.dart';

class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(personalRecordsProvider);

    return Scaffold(
      body: GlowBackground(
        glow1: AppColors.gold,
        glow2: AppColors.accent1,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text('Personal Records', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1.5)),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: prsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                        const SizedBox(height: 12),
                        TextButton(onPressed: () => ref.invalidate(personalRecordsProvider), child: const Text('Retry')),
                      ],
                    ),
                  ),
                  data: (records) {
                    if (records.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 16),
                            Text('No PRs yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pr.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(DateFormat('MMM d, yyyy').format(pr.dateAchieved.toLocal()), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Text(
                                '${pr.personalBestWeight.toStringAsFixed(1)} kg',
                                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gold, letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
