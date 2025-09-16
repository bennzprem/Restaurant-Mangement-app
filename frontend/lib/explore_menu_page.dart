import 'dart:ui';
import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets/header_widget.dart';
import 'widgets/explore_sections/explore_by_category_section.dart';
import 'widgets/explore_sections/all_day_picks_section.dart';
import 'widgets/explore_sections/fitness_categories_section.dart';
import 'widgets/explore_sections/subscription_combo_section.dart';

class ExploreMenuPage extends StatelessWidget {
  const ExploreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 95),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: const [
                _SectionWrapper(title: 'Explore by Category', route: '/menu', child: ExploreByCategorySection()),
                SizedBox(height: 20),
                _SectionWrapper(title: 'All-Day Picks', route: '/explore/special-diet', child: AllDayPicksSection()),
                SizedBox(height: 20),
                _SectionWrapper(title: 'Fitness Categories', route: '/explore/fitness', child: FitnessCategoriesSection()),
                SizedBox(height: 20),
                _SectionWrapper(title: 'Subscription & Combo Categories', route: '/explore/subscription-combo', child: SubscriptionComboSection()),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(
              active: HeaderActive.menu,
              showBack: true,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  final String title;
  final String route;
  final Widget child;
  const _SectionWrapper({required this.title, required this.route, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.35) : Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, route),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}


