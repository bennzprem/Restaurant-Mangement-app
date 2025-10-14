import 'package:flutter/material.dart';
import 'menu_screen.dart';
import '../models/models.dart';

class MenuScreenWithLocation extends StatefulWidget {
  final String? tableSessionId;
  final String? initialCategory;
  final int? initialItemId;
  final OrderMode mode;

  const MenuScreenWithLocation({
    super.key,
    this.tableSessionId,
    this.initialCategory,
    this.initialItemId,
    this.mode = OrderMode.delivery,
  });

  @override
  State<MenuScreenWithLocation> createState() => _MenuScreenWithLocationState();
}

class _MenuScreenWithLocationState extends State<MenuScreenWithLocation> {
  @override
  Widget build(BuildContext context) {
    return MenuScreen(
      tableSessionId: widget.tableSessionId,
      initialCategory: widget.initialCategory,
      initialItemId: widget.initialItemId,
      mode: widget.mode,
    );
  }
}
