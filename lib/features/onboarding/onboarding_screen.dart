import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = [
    _OnboardingStep(
      icon: Icons.psychology_outlined,
      titleKey: 'onboarding.step1_title',
      subtitleKey: 'onboarding.step1_subtitle',
      descriptionKey: 'onboarding.step1_desc',
      featureKeys: [
        'onboarding.step1_f1',
        'onboarding.step1_f2',
        'onboarding.step1_f3',
      ],
    ),
    _OnboardingStep(
      icon: Icons.timer_outlined,
      titleKey: 'onboarding.step2_title',
      subtitleKey: 'onboarding.step2_subtitle',
      descriptionKey: 'onboarding.step2_desc',
      featureKeys: [
        'onboarding.step2_f1',
        'onboarding.step2_f2',
        'onboarding.step2_f3',
      ],
    ),
    _OnboardingStep(
      icon: Icons.bar_chart_rounded,
      titleKey: 'onboarding.step3_title',
      subtitleKey: 'onboarding.step3_subtitle',
      descriptionKey: 'onboarding.step3_desc',
      featureKeys: [
        'onboarding.step3_f1',
        'onboarding.step3_f2',
        'onboarding.step3_f3',
      ],
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (mounted) context.go('/timer');
  }

  void _next() {
    if (_page < _steps.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextButton(
                  onPressed: _complete,
                  child: Text(
                    'onboarding.skip'.tr(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) =>
                    _PageContent(step: _steps[i], index: i),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _next,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_page == _steps.length - 1
                        ? 'onboarding.get_started'.tr()
                        : 'onboarding.continue'.tr()),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.step, required this.index});
  final _OnboardingStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: index == 0
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/images/volo.png',
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(step.icon, size: 68, color: AppColors.primary),
            ),
          )
              .animate(key: ValueKey(index))
              .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 500.ms,
                  curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 32),
          Text(
            step.titleKey.tr(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title$index'))
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 8),
          Text(
            step.subtitleKey.tr(),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('sub$index'))
              .fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 16),
          Text(
            step.descriptionKey.tr(),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('desc$index'))
              .fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 28),
          ...step.featureKeys.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    e.value.tr(),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                )
                    .animate(key: ValueKey('f${index}_${e.key}'))
                    .fadeIn(delay: (250 + e.key * 80).ms, duration: 400.ms)
                    .slideX(begin: 0.1, end: 0),
              )),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.descriptionKey,
    required this.featureKeys,
  });
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final String descriptionKey;
  final List<String> featureKeys;
}
