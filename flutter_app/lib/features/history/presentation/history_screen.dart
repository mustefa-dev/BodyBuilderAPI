import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../session/presentation/session_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('HISTORY')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load history', style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => ref.invalidate(historyProvider), child: const Text('Retry')),
            ],
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No workouts yet', style: GoogleFonts.oswald(fontSize: 20, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  const Text('Complete your first workout to see it here', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final s = sessions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check, color: AppColors.success),
                  ),
                  title: Text(s.title, style: GoogleFonts.oswald(fontSize: 16, color: AppColors.textPrimary)),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy - h:mm a').format(s.checkInTime.toLocal()),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  trailing: Text(
                    s.formattedDuration,
                    style: GoogleFonts.oswald(fontSize: 18, color: AppColors.primary),
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
