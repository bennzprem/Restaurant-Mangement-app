import 'package:flutter/material.dart';

class ExpandingSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool> onExpansionChanged;

  const ExpandingSearchBar({
    super.key,
    required this.controller,
    required this.onExpansionChanged,
  });

  @override
  State<ExpandingSearchBar> createState() => _ExpandingSearchBarState();
}

class _ExpandingSearchBarState extends State<ExpandingSearchBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasTextNow = widget.controller.text.isNotEmpty;
    if (hasTextNow != _hasText) {
      setState(() {
        _hasText = hasTextNow;
      });
    }
  }

  void _expand() {
    setState(() {
      _isExpanded = true;
      widget.onExpansionChanged(true);
    });
  }

  void _collapse() {
    setState(() {
      _isExpanded = false;
      widget.onExpansionChanged(false);
      _hasText = false;
    });
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: _isExpanded ? 260 : 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AnimatedOpacity(
            opacity: _isExpanded ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.only(left: 46, right: 36),
              child: TextField(
                controller: widget.controller,
                autofocus: _isExpanded,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          AnimatedPositioned(
            left: 4,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  if (_isExpanded) return;
                  _expand();
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: !_isExpanded
                      ? Container(
                          key: const ValueKey('search'),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.search_rounded,
                              color: Colors.grey, size: 22),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          if (_isExpanded && _hasText)
            Positioned(
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _collapse,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Container(
                      key: const ValueKey('clear'),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.grey, size: 18),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
//updated
