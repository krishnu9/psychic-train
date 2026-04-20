import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// GitHub-style workout heatmap.
///
/// Renders a fixed [weeks] × 7 grid of rounded cells. The rightmost column is
/// the current week, with cells below it representing yesterday and earlier.
/// Each cell's color is chosen by its bucket — [0, 1, 2, 3, 4+] workouts that day.
class ConsistencyHeatmap extends StatelessWidget {
  final Map<DateTime, int> data;
  final int weeks;

  const ConsistencyHeatmap({
    super.key,
    required this.data,
    this.weeks = 15,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start date = (weeks-1)*7 days back, aligned to the start of that week.
    // To keep it simple, we anchor columns to `today`: column index 0 = oldest.
    final totalDays = weeks * 7;
    final firstDay = today.subtract(Duration(days: totalDays - 1));

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final cell = (constraints.maxWidth - (weeks - 1) * gap) / weeks;

        return SizedBox(
          height: 7 * cell + 6 * gap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weeks, (col) {
              return Padding(
                padding: EdgeInsets.only(right: col == weeks - 1 ? 0 : gap),
                child: Column(
                  children: List.generate(7, (row) {
                    final dayOffset = col * 7 + row;
                    final date = firstDay.add(Duration(days: dayOffset));
                    final count = data[date] ?? 0;
                    final isFuture = date.isAfter(today);

                    return Padding(
                      padding: EdgeInsets.only(bottom: row == 6 ? 0 : gap),
                      child: Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: isFuture
                              ? AppColors.surfaceLight.withValues(alpha: 0.4)
                              : _colorFor(count),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  static Color _colorFor(int count) {
    if (count <= 0) return AppColors.surfaceLight;
    if (count == 1) return AppColors.primary.withValues(alpha: 0.30);
    if (count == 2) return AppColors.primary.withValues(alpha: 0.55);
    if (count == 3) return AppColors.primary.withValues(alpha: 0.80);
    return AppColors.primary;
  }
}

/// Legend strip: "Less ▪▪▪▪ More" using the same intensity buckets.
class ConsistencyHeatmapLegend extends StatelessWidget {
  const ConsistencyHeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget swatch(int count) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: ConsistencyHeatmap._colorFor(count),
            borderRadius: BorderRadius.circular(2),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Less',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(width: 4),
        swatch(0),
        swatch(1),
        swatch(2),
        swatch(3),
        swatch(4),
        const SizedBox(width: 4),
        const Text(
          'More',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
