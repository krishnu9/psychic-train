import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useLbs = ref.watch(useLbsProvider);
    final restDuration = ref.watch(restTimerDurationProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),

            // ─── Profile ──────────────────────────────
            _SettingsSection(
              title: 'Profile',
              children: [
                _SettingsTile(
                  icon: Icons.person_rounded,
                  title: ref.watch(userEmailProvider),
                  subtitle: 'Account',
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    await SupabaseService.signOut();
                  },
                ),
              ],
            ),

            // ─── Unit preference ──────────────────────
            _SettingsSection(
              title: 'Units',
              children: [
                _SettingsTile(
                  icon: Icons.straighten_rounded,
                  title: 'Weight Unit',
                  subtitle: useLbs ? 'Pounds (lbs)' : 'Kilograms (kg)',
                  trailing: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('kg')),
                      ButtonSegment(value: true, label: Text('lbs')),
                    ],
                    selected: {useLbs},
                    onSelectionChanged: (value) {
                      ref.read(useLbsProvider.notifier).state =
                          value.first;
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary.withValues(alpha: 0.2);
                        }
                        return AppColors.surfaceLight;
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary;
                        }
                        return AppColors.textSecondary;
                      }),
                    ),
                  ),
                ),
              ],
            ),

            // ─── Rest timer ───────────────────────────
            _SettingsSection(
              title: 'Rest Timer',
              children: [
                _SettingsTile(
                  icon: Icons.timer_rounded,
                  title: 'Default Rest Duration',
                  subtitle: '${restDuration}s (${restDuration ~/ 60}:${(restDuration % 60).toString().padLeft(2, '0')})',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: restDuration > 15
                            ? () => ref
                                .read(restTimerDurationProvider.notifier)
                                .state = restDuration - 15
                            : null,
                        icon: const Icon(Icons.remove_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: restDuration < 300
                            ? () => ref
                                .read(restTimerDurationProvider.notifier)
                                .state = restDuration + 15
                            : null,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ─── About ───────────────────────────────
            _SettingsSection(
              title: 'About',
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'GymApp',
                  subtitle: 'Version 1.0.0 · MVP',
                ),
                _SettingsTile(
                  icon: Icons.code_rounded,
                  title: 'Built with Flutter',
                  subtitle: 'Drift + Riverpod',
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
