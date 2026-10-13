import 'dart:math';

import 'package:bubu_web_client/utils/string_utils.dart';
import 'package:bubu_web_client/widgets/footer_widget.dart';
import 'package:bubu_web_client/widgets/section_drop_widget.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../models/order_model.dart' hide CartItem;
import '../models/product_model.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../utils/global.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const _ink = Color(0xFF14183A);
  static const _pink = Color(0xFFFF5C8A);
  static const _border = Color(0xFFE6E3F5);

  ProductService service = ProductService();
  OrderService orderService = OrderService();
  ProductDetailResponse? detail;
  bool loadingDetail = true;

  List<Product> products = [];
  bool loadingRecmd = true;

  int imageIndex = 0;
  int? selectedSizeId;
  int? selectedColorId;
  int qty = 1;

  List<ProductDetail> get variants => detail?.productDetails ?? [];

  List<ProductImage> get images {
    final list = [...(detail?.images ?? <ProductImage>[])];
    list.sort((a, b) {
      if (a.main != b.main) return a.main ? -1 : 1; // ảnh chính lên đầu
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return list;
  }

  List<ProductDetail> get sizeOptions {
    final seen = <int>{};
    final list = variants.where((v) => seen.add(v.sizeId)).toList();
    list.sort((a, b) {
      final x = int.tryParse(a.size);
      final y = int.tryParse(b.size);
      if (x != null && y != null) return x.compareTo(y);
      return a.size.compareTo(b.size);
    });
    return list;
  }

  List<ProductDetail> get colorOptions {
    final seen = <int>{};
    return variants.where((v) => seen.add(v.colorId)).toList();
  }

  bool sizeAvailable(int sizeId) => variants.any(
    (v) =>
        v.sizeId == sizeId &&
        v.quantity > 0 &&
        (selectedColorId == null || v.colorId == selectedColorId),
  );

  bool colorAvailable(int colorId) => variants.any(
    (v) =>
        v.colorId == colorId &&
        v.quantity > 0 &&
        (selectedSizeId == null || v.sizeId == selectedSizeId),
  );

  ProductDetail? get selectedVariant {
    if (selectedSizeId == null || selectedColorId == null) return null;
    for (final v in variants) {
      if (v.sizeId == selectedSizeId && v.colorId == selectedColorId) {
        return v;
      }
    }
    return null;
  }

  int get maxQty {
    final q = selectedVariant?.quantity ?? 10;
    return max(1, min(10, q));
  }

  Future<void> addToCart() async {
    if (variants.isNotEmpty && selectedSizeId == null) {
      showToast('Vui lòng chọn size', ToastificationType.warning);
      return;
    }
    if (variants.isNotEmpty && selectedColorId == null) {
      showToast('Vui lòng chọn màu', ToastificationType.warning);
      return;
    }
    final v = selectedVariant;
    if (v == null || v.quantity <= 0) {
      showToast('Phiên bản này đã hết hàng', ToastificationType.warning);
      return;
    }

    final response = await orderService.addItem(
      ItemRequest(v.id, qty),
      stock: v.quantity,
    );
    if (!mounted) return;

    if (response.errorMessage.isEmpty) {
      showToast('Đã thêm vào giỏ hàng', ToastificationType.success);
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  Future<void> toggleFavorite() async {
    final wasLiked = favoriteIds.value.contains(widget.product.id);
    final error = await service.toggle(widget.product.id);
    if (!mounted) return;
    if (error.isEmpty) {
      showToast(
        wasLiked ? 'Đã bỏ khỏi yêu thích' : 'Đã thêm vào yêu thích',
        ToastificationType.success,
      );
    } else {
      showToast(error, ToastificationType.error);
    }
  }

  void selectSize(int id) {
    setState(() {
      if (selectedSizeId == id) {
        selectedSizeId = null;
      } else {
        selectedSizeId = id;
        if (selectedColorId != null && !colorAvailable(selectedColorId!)) {
          selectedColorId = null;
        }
      }
      qty = qty.clamp(1, maxQty);
    });
  }

  void selectColor(int id) {
    setState(() {
      if (selectedColorId == id) {
        selectedColorId = null;
      } else {
        selectedColorId = id;
        if (selectedSizeId != null && !sizeAvailable(selectedSizeId!)) {
          selectedSizeId = null;
        }
      }
      qty = qty.clamp(1, maxQty);
    });
  }

  // ===================== GỌI API =====================
  Future<void> getDetailProduct() async {
    final response = await service.getDetailProduct(widget.product.id);
    if (!mounted) return;
    if (response.errorMessage.isEmpty) {
      setState(() {
        detail = response;
        loadingDetail = false;
      });
    } else {
      setState(() => loadingDetail = false);
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  Future<void> getProducts() async {
    final response = await service.getProducts();
    if (!mounted) return;
    if (response.errorMessage.isEmpty) {
      final all = response.products
          .where((p) => p.id != widget.product.id)
          .toList();
      final latest = all.length > 10 ? all.sublist(all.length - 10) : all;
      setState(() {
        products = latest.reversed.toList();
        loadingRecmd = false;
      });
    } else {
      setState(() => loadingRecmd = false);
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    getDetailProduct();
    getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _backBar(),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, c) {
                          final narrow = c.maxWidth < 800;
                          final image = _productImage();
                          final info = _productInfo();
                          if (narrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                image,
                                const SizedBox(height: 24),
                                info,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: image),
                              const SizedBox(width: 40),
                              Expanded(child: info),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'Có thể bạn cũng thích',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _recommendList(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 56),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }

  Widget _backBar() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_rounded, size: 18, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              'Quay lại',
              style: TextStyle(
                color: primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== GALLERY ẢNH =====================
  Widget _productImage() {
    final imgs = images;
    final mainUrl = imgs.isNotEmpty
        ? imgs[imageIndex.clamp(0, imgs.length - 1)].url(baseUrl)
        : '$baseUrl${widget.product.imageUrl}';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: loadingDetail && imgs.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox.expand(
                            child: Image.network(
                              mainUrl,
                              key: ValueKey(mainUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: ValueListenableBuilder<Set<int>>(
                    valueListenable: favoriteIds,
                    builder: (context, ids, _) {
                      final liked = ids.contains(widget.product.id);
                      return Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: toggleFavorite,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              liked ? Icons.favorite : Icons.favorite_border,
                              color: liked ? _pink : _ink,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (imgs.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imgs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final selected = i == imageIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => imageIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? primaryColor : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imgs[i].url(baseUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            Container(color: Colors.grey.shade100),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ===================== THÔNG TIN SẢN PHẨM =====================
  Widget _productInfo() {
    final description = detail?.product.description ?? '';
    final total = detail?.product.totalQuantity ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.product.price.formatThousand(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: _pink,
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: _border, height: 1),
        const SizedBox(height: 24),

        if (loadingDetail)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Size
        if (sizeOptions.isNotEmpty) ...[
          _label('Chọn size'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sizeOptions.map(_sizeChip).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Màu
        if (colorOptions.isNotEmpty) ...[
          _label('Chọn màu'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colorOptions.map(_colorChip).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Tồn kho
        if (!loadingDetail)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              selectedVariant != null
                  ? 'Còn ${selectedVariant!.quantity} sản phẩm'
                  : 'Tổng còn $total sản phẩm',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),

        // Số lượng + thêm vào giỏ
        _label('Số lượng'),
        const SizedBox(height: 12),
        Row(
          children: [
            _qtyBox(),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: addToCart,
                icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                label: Text(
                  'Thêm vào giỏ · ${(widget.product.price * qty).formatThousand()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Mô tả
        SectionDropWidget(
          title: 'Mô tả sản phẩm',
          initiallyOpen: true,
          body: description.isNotEmpty
              ? description
              : 'Form giày ôm chân, đế cao su êm và bám tốt, phù hợp đi học, '
                    'đi làm lẫn tập nhẹ. Thân giày thoáng khí, đường chỉ chắc chắn '
                    'và dễ phối với nhiều kiểu trang phục hằng ngày.',
        ),
        SectionDropWidget(
          title: 'Giao hàng & đổi trả',
          body:
              'Miễn phí vận chuyển cho đơn từ 500.000đ. Đổi size trong 7 ngày '
              'nếu giày chưa qua sử dụng và còn nguyên hộp.',
        ),
        SectionDropWidget(
          title: 'Hướng dẫn bảo quản',
          body:
              'Lau bằng khăn ẩm, tránh ngâm nước lâu. Phơi nơi thoáng mát, '
              'không phơi trực tiếp dưới nắng gắt để giữ form và màu giày.',
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _ink,
    ),
  );

  Widget _optionChip({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.white,
          border: Border.all(
            color: selected ? primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : _ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _sizeChip(ProductDetail v) {
    final selected = selectedSizeId == v.sizeId;
    final enabled = selected || sizeAvailable(v.sizeId);
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? () => selectSize(v.sizeId) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 50,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: selected ? primaryColor : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            v.size,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _colorChip(ProductDetail v) {
    final selected = selectedColorId == v.colorId;
    final enabled = selected || colorAvailable(v.colorId);
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: _optionChip(
        text: v.color,
        selected: selected,
        onTap: enabled ? () => selectColor(v.colorId) : () {},
      ),
    );
  }

  Widget _qtyBox() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: qty > 1 ? () => setState(() => qty--) : null,
            icon: const Icon(Icons.remove_rounded, size: 20),
            color: _ink,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
          IconButton(
            onPressed: qty < maxQty ? () => setState(() => qty++) : null,
            icon: const Icon(Icons.add_rounded, size: 20),
            color: _ink,
          ),
        ],
      ),
    );
  }

  // ===================== DANH SÁCH GỢI Ý =====================
  Widget _recommendList() {
    if (loadingRecmd) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (products.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Chưa có sản phẩm gợi ý')),
      );
    }

    const cardWidth = 190.0;
    return SizedBox(
      height: cardWidth * 1.1 + 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => SizedBox(width: 16),
        itemBuilder: (_, i) {
          final r = products[i];
          return SizedBox(
            width: cardWidth,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: r),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox.expand(
                        child: Image.network(
                          '$baseUrl${r.imageUrl}',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    r.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.price.formatThousand(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _pink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
