import 'package:bubu_web_client/utils/global.dart';
import 'package:flutter/material.dart';

import '../models/product_model.dart';

class ProductCardWidget extends StatefulWidget {
  final Product product;
  final bool liked;
  final Function()? onAdd;
  final Function()? onTap;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.liked = false,
    this.onAdd,
    this.onTap,
  });

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedScale(
                      scale: hovering ? 1.05 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: p.imageUrl.isEmpty
                          ? Container(
                              color: const Color(0xFFEDECF3),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.directions_walk,
                                size: 70,
                                color: Colors.grey,
                              ),
                            )
                          : Image.network(
                              '$baseUrl${p.imageUrl}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.directions_walk,
                                    size: 70,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                    ),

                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          widget.liked ? Icons.favorite : Icons.favorite_border,
                          color: widget.liked ? Colors.red : Colors.black87,
                        ),
                      ),
                    ),

                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: FloatingActionButton.small(
                        heroTag: null,
                        backgroundColor: Colors.black,
                        onPressed: widget.onAdd,
                        child: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 6),
            Text(
              formatPrice(p.price),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String formatPrice(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}₫';
  }
}
