import 'package:bubu_web_client/utils/global.dart';
import 'package:flutter/material.dart';

import '../models/product_model.dart';

class ProductCardWidget extends StatefulWidget {
  final Product product;
  final bool liked;
  final Function()? onAdd;
  final Function()? onTap;
  final Function()? onLike;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.liked = false,
    this.onAdd,
    this.onTap,
    this.onLike,
  });

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget> {
  bool hovering = false;
  bool hoveringAdd = false;

  static const _radius = 20.0;
  static const _accent = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, hovering ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: const Color(0xFFF0F0F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(hovering ? 0.12 : 0.05),
              blurRadius: hovering ? 24 : 12,
              offset: Offset(0, hovering ? 10 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildImage(p)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatPrice(p.price),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                        ),
                      ),
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

  Widget _buildImage(Product p) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: AnimatedScale(
            scale: hovering ? 1.06 : 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: p.imageUrl.isEmpty
                ? _placeholder()
                : Image.network(
                    '$baseUrl${p.imageUrl}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFF4F4F8),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        _placeholder(),
                  ),
          ),
        ),

        // Gradient mờ ở đáy ảnh
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 70,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(hovering ? 0.25 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Nút yêu thích
        Positioned(
          right: 10,
          top: 10,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black26,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onLike,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    widget.liked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(widget.liked),
                    size: 20,
                    color: widget.liked ? _accent : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Nút thêm giỏ hàng
        Positioned(
          right: 10,
          bottom: 10,
          child: MouseRegion(
            onEnter: (_) => setState(() => hoveringAdd = true),
            onExit: (_) => setState(() => hoveringAdd = false),
            child: AnimatedScale(
              scale: hoveringAdd ? 1.12 : 1,
              duration: const Duration(milliseconds: 150),
              child: Tooltip(
                message: 'Thêm vào giỏ hàng',
                child: Material(
                  color: Colors.black,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: Colors.black38,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onAdd,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.add_shopping_cart,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF4F4F8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_walk,
        size: 64,
        color: Color(0xFFB8B8C4),
      ),
    );
  }

  String formatPrice(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}₫';
  }
}
