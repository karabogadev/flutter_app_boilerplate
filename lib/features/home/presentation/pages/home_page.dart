import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Placeholder home screen.
///
/// Uses one [CustomScrollView] with lazily built slivers instead of
/// shrink-wrapped grids and lists inside a `SingleChildScrollView`, so only
/// visible items are laid out. Copy this structure for real content.
@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _recentActivityCount = 5;

  static const _quickActions = [
    (icon: Icons.person, labelKey: LocaleKeys.homeProfile),
    (icon: Icons.notifications, labelKey: LocaleKeys.homeNotifications),
    (icon: Icons.favorite, labelKey: LocaleKeys.homeFavorites),
    (icon: Icons.history, labelKey: LocaleKeys.homeHistory),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.homeTitle.tr())),
      body: BlocSelector<AuthBloc, AuthState, User?>(
        selector: (state) => state is Authenticated ? state.user : null,
        builder: (context, user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(child: _WelcomeCard(user: user)),
                    _SectionTitle(LocaleKeys.homeQuickActions.tr()),
                    SliverGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.5,
                      children: [
                        for (final action in _quickActions)
                          _QuickActionCard(
                            icon: action.icon,
                            label: action.labelKey.tr(),
                            onTap: () {},
                          ),
                      ],
                    ),
                    _SectionTitle(LocaleKeys.homeRecentActivity.tr()),
                    DecoratedSliver(
                      decoration: BoxDecoration(
                        color: context.theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      sliver: SliverList.separated(
                        itemCount: _recentActivityCount,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _ActivityTile(index: index),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.name?.isNotEmpty == true ? user.name! : user.email;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: context.colorScheme.primary,
              child: Text(
                displayName[0].toUpperCase(),
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.homeWelcomeBack.tr(),
                    style: context.textTheme.bodyMedium,
                  ),
                  Text(displayName, style: context.textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      sliver: SliverToBoxAdapter(
        child: Text(title, style: context.textTheme.titleMedium),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        // Rounds the ripple without clipping the card (no clip layer).
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: context.colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: context.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final hours = index + 1;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(Icons.access_time, color: context.colorScheme.primary),
      ),
      title: Text(LocaleKeys.homeActivity.tr(namedArgs: {'index': '$hours'})),
      subtitle: Text(LocaleKeys.homeHoursAgo.plural(hours)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
