import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../session/presentation/session_provider.dart';

class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(personalRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PERSONAL RECORDS')),
      body: prsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load PRs', style: TextStyle(color: AppColors.error)),
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
                  const Icon(Icons.emoji_events, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No PRs yet', style: GoogleFonts.oswald(fontSize: 20, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  const Text('Start lifting to set your records', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final pr = records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events, color: AppColors.gold, size: 24),
                  ),
                  title: Text(pr.name, style: GoogleFonts.oswald(fontSize: 16, color: AppColors.textPrimary)),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy').format(pr.dateAchieved.toLocal()),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  trailing: Text(
                    '${pr.personalBestWeight.toStringAsFixed(1)} kg',
                    style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
