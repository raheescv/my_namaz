import 'package:flutter/material.dart';

import '../models/prayer_enum.dart';
import '../theme/colors.dart';

class PrayerCard extends StatelessWidget {
  final Prayer prayer;
  final bool completed;
  final VoidCallback onTap;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.completed,
    required this.onTap,
  });

  IconData _iconFor() {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.wb_twilight;
      case Prayer.dhuhr:
        return Icons.wb_sunny_outlined;
      case Prayer.asr:
        return Icons.wb_cloudy_outlined;
      case Prayer.maghrib:
        return Icons.nights_stay_outlined;
      case Prayer.isha:
        return Icons.dark_mode_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = completed
        ? AppColors.primaryGreen.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest;
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.primaryGreen.withValues(alpha: 0.2)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(),
                    color: completed
                        ? AppColors.primaryGreen
                        : theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prayer.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(prayer.arabic,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 16)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.primaryGreen
                      : Colors.transparent,
                  border: Border.all(
                    color: completed
                        ? AppColors.primaryGreen
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: completed
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
