import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models.dart';

class ExploreByCategorySection extends StatefulWidget {
  const ExploreByCategorySection({super.key});

  @override
  State<ExploreByCategorySection> createState() => _ExploreByCategorySectionState();
}

class _ExploreByCategorySectionState extends State<ExploreByCategorySection> {
  final ApiService _api = ApiService();
  late Future<List<String>> _futureNames;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _futureNames = _loadCategoryNames();
  }

  Future<List<String>> _loadCategoryNames() async {
    try {
      // 1) Prefer categories table
      final cats = await _api.getCategories();
      final names = cats.map((c) => (c['name'] ?? c['category_name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
      if (names.isNotEmpty) return names;
    } catch (_) {}

    // 2) Fallback: derive from menu endpoint
    try {
      final menu = await _api.fetchMenu(
        vegOnly: false,
        veganOnly: false,
        glutenFreeOnly: false,
        nutsFree: false,
      );
      final set = <String>{};
      for (final MenuCategory mc in menu) {
        set.add(mc.name);
      }
      return set.toList();
    } catch (_) {
      return <String>[];
    }
  }

  void _scrollBy(double delta) {
    final target = (_scrollController.offset + delta).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 150,
      child: FutureBuilder<List<String>>(
        future: _futureNames,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories'));
          }
          final names = snapshot.data!;
          return Stack(
            children: [
              ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: names.length,
                padding: const EdgeInsets.only(left: 4, right: 4),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final label = names[index];
                  return _CategoryCard(label: label, icon: Icons.category, subtitle: 'Discover popular ${label.toLowerCase()} picks');
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: _ArrowButton(
                  isDark: isDark,
                  icon: Icons.arrow_back_ios_new,
                  onPressed: () => _scrollBy(-260),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _ArrowButton(
                  isDark: isDark,
                  icon: Icons.arrow_forward_ios,
                  onPressed: () => _scrollBy(260),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final String subtitle;
  const _CategoryCard({required this.label, required this.icon, required this.subtitle});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/menu', arguments: {'initialCategory': widget.label}),
          borderRadius: BorderRadius.circular(16),
          splashColor: Theme.of(context).primaryColor.withOpacity(0.15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 260,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _hovered ? Theme.of(context).primaryColor : (isDark ? Colors.white12 : Colors.black12)),
              boxShadow: _hovered
                  ? [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onPressed;
  const _ArrowButton({required this.isDark, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black54 : Colors.white70,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16),
          ),
        ),
      ),
    );
  }
}


