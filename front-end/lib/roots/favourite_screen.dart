import 'package:bubu_web_client/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../models/product_model.dart';
import '../utils/global.dart';
import '../widgets/footer_widget.dart';
import '../widgets/product_card_widget.dart';
import 'product_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final service = ProductService();
  List<FavoriteItem> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final (list, error) = await service.getList();
    if (!mounted) return;
    setState(() {
      items = list;
      loading = false;
    });
    if (error.isNotEmpty) showToast(error, ToastificationType.error);
  }

  Future<void> unlike(FavoriteItem item) async {
    final error = await service.toggle(item.productId);
    if (!mounted) return;
    if (error.isEmpty) {
      setState(() => items.removeWhere((e) => e.productId == item.productId));
    } else {
      showToast(error, ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final columns = w >= 1500
              ? 6
              : w >= 1200
              ? 5
              : w >= 1000
              ? 4
              : w >= 640
              ? 3
              : 2;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 24, 15, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sản phẩm yêu thích',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Text(
                                'Bạn chưa có sản phẩm yêu thích nào.',
                                style: TextStyle(color: Color(0xFF6B7090)),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 0.76,
                                ),
                            itemBuilder: (_, i) {
                              final item = items[i];
                              final product = item.toProduct();
                              return ProductCardWidget(
                                product: product,
                                liked: true,
                                onLike: () => unlike(item),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const FooterWidget(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
