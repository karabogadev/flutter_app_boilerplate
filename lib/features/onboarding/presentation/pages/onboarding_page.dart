import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../settings/data/repositories/settings_repository.dart';

typedef _OnboardingItem = ({
  String titleKey,
  String descriptionKey,
  IconData icon,
});

const _items = <_OnboardingItem>[
  (
    titleKey: LocaleKeys.onboardingTitle1,
    descriptionKey: LocaleKeys.onboardingDescription1,
    icon: Icons.waving_hand,
  ),
  (
    titleKey: LocaleKeys.onboardingTitle2,
    descriptionKey: LocaleKeys.onboardingDescription2,
    icon: Icons.explore,
  ),
  (
    titleKey: LocaleKeys.onboardingTitle3,
    descriptionKey: LocaleKeys.onboardingDescription3,
    icon: Icons.rocket_launch,
  ),
];

@RoutePage()
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();

  /// Only the indicator and the button depend on the page index, so they
  /// listen to this notifier instead of rebuilding the whole page.
  final _currentPage = ValueNotifier<int>(0);

  bool get _isLastPage => _currentPage.value == _items.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await context.read<SettingsRepository>().completeOnboarding();
    if (mounted) await context.router.replace(const LoginRoute());
  }

  void _next() {
    if (_isLastPage) {
      unawaited(_completeOnboarding());
    } else {
      unawaited(
        _pageController.nextPage(
          duration: AppDurations.normal,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(LocaleKeys.onboardingSkip.tr()),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => _currentPage.value = page,
                itemCount: _items.length,
                itemBuilder: (context, index) =>
                    _OnboardingSlide(item: _items[index]),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _currentPage,
              builder: (context, page, _) =>
                  _PageIndicator(count: _items.length, current: page),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ValueListenableBuilder<int>(
                valueListenable: _currentPage,
                builder: (context, _, _) => AppButton.primary(
                  text: _isLastPage
                      ? LocaleKeys.onboardingGetStarted.tr()
                      : LocaleKeys.commonNext.tr(),
                  isExpanded: true,
                  onPressed: _next,
                  suffixIcon: Icons.arrow_forward,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 120, color: context.colorScheme.primary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            item.titleKey.tr(),
            style: context.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.descriptionKey.tr(),
            style: context.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;
    return Semantics(
      label: '${current + 1} / $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              width: index == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == current
                    ? primary
                    : primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
