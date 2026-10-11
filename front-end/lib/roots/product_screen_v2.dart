import 'package:bubu_web_client/roots/product_detail_screen.dart';
import 'package:bubu_web_client/widgets/footer_widget.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../utils/global.dart';
import '../widgets/product_card_widget.dart';

enum SortOption {
  none('Mặc định', Icons.sort_rounded),
  priceAsc('Giá: thấp → cao', Icons.arrow_upward_rounded),
  priceDesc('Giá: cao → thấp', Icons.arrow_downward_rounded),
  nameAsc('Tên: A → Z', Icons.sort_by_alpha_rounded),
  nameDesc('Tên: Z → A', Icons.sort_by_alpha_rounded);

  final String label;
  final IconData icon;
  const SortOption(this.label, this.icon);
}

class ProductScreenV2 extends StatefulWidget {
  const ProductScreenV2({super.key});

  @override
  State<ProductScreenV2> createState() => _ProductScreenV2State();
}

class _ProductScreenV2State extends State<ProductScreenV2>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  static const _ink = Color(0xFF14183A);
  static const _muted = Color(0xFF6B7090);
  static const _bg = Color(0xFFF7F5FF);

  ProductService service = ProductService();

  List<Product> products = [];
  List<Product> filterProducts = [];
  List<Category> categories = [];
  List<ProductSize> sizes = [];
  List<ProductColor> colors = [];
  List<ProductDetail> productDetails = [];

  Category? selectedCategory;
  ProductSize? selectedSize;
  ProductColor? selectedColor;
  SortOption sortOption = SortOption.none;

  @override
  void initState() {
    super.initState();
    getProducts();
    getDetails();
    getCategories();
    getColors();
    getSizes();
  }

  void applyFilters() {
    final categoryId = selectedCategory?.id;
    final sizeId = selectedSize?.id;
    final colorId = selectedColor?.id;

    final result = products.where((p) {
      if (categoryId != null && p.categoryId != categoryId) return false;

      if (sizeId != null || colorId != null) {
        final matched = productDetails.any(
          (d) =>
              d.productId == p.id &&
              d.quantity > 0 &&
              (sizeId == null || d.sizeId == sizeId) &&
              (colorId == null || d.colorId == colorId),
        );
        if (!matched) return false;
      }
      return true;
    }).toList();

    switch (sortOption) {
      case SortOption.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.nameDesc:
        result.sort((a, b) => b.name.compareTo(a.name));
      case SortOption.none:
        break;
    }

    setState(() => filterProducts = result);
  }

  void clearFilters() {
    selectedCategory = null;
    selectedSize = null;
    selectedColor = null;
    sortOption = SortOption.none;
    applyFilters();
  }

  void getProducts() async {
    final response = await service.getProducts();
    if (!mounted) return;
    if (response.errorMessage.isEmpty) {
      products = response.products;
      applyFilters();
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void getDetails() async {
    final response = await service.getProductDetails();
    if (!mounted) return;
    if (response.errorMessage.isEmpty) {
      productDetails = response.productDetails;
      applyFilters();
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void getCategories() async {
    final response = await service.getCategories();
    if (!mounted) return;
    if (response.errorMessage.isEmpty) {
      setState(() => categories = response.categories);
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void getColors() async {
    final response = await service.getCoLors();
    if (!mounted) return;
    if (response.errorMessage.isEmpty) {
      setState(() => colors = response.colors);
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void getSizes() async {
    final response = await service.getSizes();
    if (!mounted) return;
    if (response.errorMessage.isEmpty) {
      setState(() => sizes = response.sizes);
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  void pushToDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterBar(),
                        const SizedBox(height: 19),
                        const Divider(height: 1, color: Color(0xFFE3E0F5)),
                        const SizedBox(height: 15),
                        getListShoes(constraints, filterProducts),
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

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _filterDropdown<Category>(
            hint: 'Danh mục',
            value: selectedCategory,
            options: categories,
            labelOf: (e) => e.name,
            onChanged: (v) {
              selectedCategory = v;
              applyFilters();
            },
          ),
          _filterDropdown<ProductSize>(
            hint: 'Size',
            value: selectedSize,
            options: sizes,
            labelOf: (e) => e.name,
            onChanged: (v) {
              selectedSize = v;
              applyFilters();
            },
          ),
          _filterDropdown<ProductColor>(
            hint: 'Màu',
            value: selectedColor,
            options: colors,
            labelOf: (e) => e.name,
            onChanged: (v) {
              selectedColor = v;
              applyFilters();
            },
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sortOption != SortOption.none
                  ? const Color(0xFFEEEBFF)
                  : const Color(0xFFF7F5FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sortOption != SortOption.none
                    ? const Color(0xFF5B4BFF)
                    : const Color(0xFFE3E0F5),
                width: 1.2,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SortOption>(
                value: sortOption,
                isDense: true,
                borderRadius: BorderRadius.circular(14),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF14183A),
                ),
                selectedItemBuilder: (context) => SortOption.values
                    .map(
                      (o) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            o.icon,
                            size: 18,
                            color: const Color(0xFF5B4BFF),
                          ),
                          const SizedBox(width: 8),
                          Text('Sắp xếp: ${o.label}'),
                        ],
                      ),
                    )
                    .toList(),
                items: SortOption.values
                    .map(
                      (o) => DropdownMenuItem(
                        value: o,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              o.icon,
                              size: 18,
                              color: const Color(0xFF6B7090),
                            ),
                            const SizedBox(width: 10),
                            Text(o.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  sortOption = v ?? SortOption.none;
                  applyFilters();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getListShoes(BoxConstraints constraints, List<Product> items) {
    final width = constraints.maxWidth;
    final columns = width >= 1500
        ? 6
        : (width >= 1200 ? 5 : (width >= 1000 ? 4 : (width >= 640 ? 3 : 2)));

    return items.isEmpty
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'Không có sản phẩm phù hợp. Hãy thử thay đổi bộ lọc.',
                style: TextStyle(color: _muted),
              ),
            ),
          )
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.76,
            ),
            itemBuilder: (context, index) {
              final p = items[index];
              return ProductCardWidget(
                product: p,
                onTap: () => pushToDetail(p),
              );
            },
          );
  }
}

Widget _filterDropdown<T>({
  required String hint,
  required T? value,
  required List<T> options,
  required String Function(T) labelOf,
  required ValueChanged<T?> onChanged,
}) {
  return Container(
    width: 200,
    decoration: BoxDecoration(
      color: value != null ? const Color(0xFFEEEBFF) : const Color(0xFFF7F5FF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: value != null ? Color(0xFF5B4BFF) : Colors.grey.shade300,
        width: 1.2,
      ),
    ),
    child: DropdownButtonFormField<T?>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: Text(
            '$hint: Tất cả',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14183A),
            ),
          ),
        ),
        ...options.map(
          (e) => DropdownMenuItem<T?>(value: e, child: Text(labelOf(e))),
        ),
      ],
      onChanged: onChanged,
    ),
  );
}
