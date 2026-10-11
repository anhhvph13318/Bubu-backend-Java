import 'package:flutter/material.dart';

class MenuItemWidget extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const MenuItemWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: widget.selected || hover
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 6),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: widget.selected || hover ? 40 : 0,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
