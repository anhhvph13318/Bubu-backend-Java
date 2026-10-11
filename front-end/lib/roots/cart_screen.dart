import 'package:bubu_web_client/utils/string_utils.dart';
import 'package:bubu_web_client/widgets/footer_widget.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../utils/global.dart';

// ======================================================================
// MODEL + STORE (tách ra file riêng, ví dụ models/cart_model.dart, nếu muốn)
// Hiện lưu trong bộ nhớ; khi có API giỏ hàng thì thay phần thân các hàm.
// ======================================================================
class CartItem {
  final int id; // productDetailId (id của biến thể size + màu)
  final int productId;
  final String name;
  final String imageUrl;
  final String size;
  final String color;
  final int price;
  final int qty;
  final int maxQty;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.size,
    required this.color,
    required this.price,
    required this.qty,
    this.maxQty = 10,
  });

  CartItem copyWith({int? qty}) => CartItem(
    id: id,
    productId: productId,
    name: name,
    imageUrl: imageUrl,
    size: size,
    color: color,
    price: price,
    qty: qty ?? this.qty,
    maxQty: maxQty,
  );
}

class CartStore {
  static final ValueNotifier<List<CartItem>> items = ValueNotifier([]);

  static int get count => items.value.fold(0, (s, e) => s + e.qty);

  static void add(CartItem item) {
    final list = [...items.value];
    final i = list.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      final merged = (list[i].qty + item.qty).clamp(1, list[i].maxQty);
      list[i] = list[i].copyWith(qty: merged);
    } else {
      list.add(item);
    }
    items.value = list;
  }

  static void setQty(int id, int qty) {
    items.value = [
      for (final e in items.value) e.id == id ? e.copyWith(qty: qty) : e,
    ];
  }

  static void remove(int id) {
    items.value = items.value.where((e) => e.id != id).toList();
  }

  static void clear() => items.value = [];
}

// ======================================================================
// MÀN HÌNH GIỎ HÀNG
// ======================================================================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _ink = Color(0xFF14183A);
  static const _pink = Color(0xFFFF5C8A);
  static const _border = Color(0xFFE6E3F5);
  static const _soft = Color(0xFFF7F6FC);

  static const int freeShipFrom = 500000;
  static const int shippingFee = 30000;

  final voucherController = TextEditingController();
  int discountPercent = 0;
  String appliedCode = '';

  @override
  void dispose() {
    voucherController.dispose();
    super.dispose();
  }

  // ---------- tính tiền ----------
  int subtotal(List<CartItem> items) =>
      items.fold(0, (s, e) => s + e.price * e.qty);

  int shipping(int sub) => (sub == 0 || sub >= freeShipFrom) ? 0 : shippingFee;

  int discount(int sub) => sub * discountPercent ~/ 100;

  void applyVoucher() {
    final code = voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    // TODO: gọi API kiểm tra mã giảm giá
    if (code == 'BUBU10') {
      setState(() {
        discountPercent = 10;
        appliedCode = code;
      });
      showToast('Đã áp dụng mã $code (-10%)', ToastificationType.success);
    } else {
      showToast('Mã giảm giá không hợp lệ', ToastificationType.error);
    }
  }

  void removeVoucher() {
    setState(() {
      discountPercent = 0;
      appliedCode = '';
      voucherController.clear();
    });
  }

  void checkout() {
    // TODO: chuyển sang màn hình thanh toán / gọi API tạo đơn
    showToast('Chuyển tới thanh toán...', ToastificationType.info);
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartStore.items,
        builder: (context, items, _) {
          return LayoutBuilder(
            builder: (context, viewport) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  // nội dung ngắn hơn màn hình thì vẫn cao bằng màn hình
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ----- Phần nội dung -----
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _header(items),
                                const SizedBox(height: 20),
                                if (items.isEmpty)
                                  _emptyState()
                                else
                                  LayoutBuilder(
                                    builder: (context, c) {
                                      final narrow = c.maxWidth < 900;
                                      final list = _itemList(items);
                                      final summary = _summary(items);
                                      if (narrow) {
                                        return Column(
                                          children: [
                                            list,
                                            const SizedBox(height: 24),
                                            summary,
                                          ],
                                        );
                                      }
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(flex: 7, child: list),
                                          const SizedBox(width: 32),
                                          Expanded(flex: 4, child: summary),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const FooterWidget(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------- header ----------
  Widget _header(List<CartItem> items) {
    final count = items.fold(0, (s, e) => s + e.qty);
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).maybePop(),
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
        ),
        const Spacer(),
        const Text(
          'Giỏ hàng',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count sản phẩm',
              style: const TextStyle(
                color: _pink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(),
        // giữ cân đối với nút Quay lại
        const SizedBox(width: 90),
      ],
    );
  }

  // ---------- danh sách ----------
  Widget _itemList(List<CartItem> items) {
    final sub = subtotal(items);
    final remain = freeShipFrom - sub;

    return Column(
      children: [
        // Thanh tiến độ miễn phí vận chuyển
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 20,
                    color: remain <= 0 ? Colors.green : _ink,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remain <= 0
                          ? 'Bạn được miễn phí vận chuyển'
                          : 'Mua thêm ${remain.formatThousand()}đ để được miễn phí vận chuyển',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (sub / freeShipFrom).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  color: remain <= 0 ? Colors.green : _pink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final item in items) ...[
          _itemCard(item),
          const SizedBox(height: 14),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              CartStore.clear();
              removeVoucher();
            },
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text('Xóa tất cả'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _itemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 104,
              height: 104,
              child: Image.network(
                '$baseUrl${item.imageUrl}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 104,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => CartStore.remove(item.id),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [_tag('Size ${item.size}'), _tag(item.color)],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.price.formatThousand(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _pink,
                          ),
                        ),
                      ),
                      _qtyStepper(item),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: _soft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _qtyStepper(CartItem item) {
    Widget btn(IconData icon, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.grey.shade400 : _ink,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(
            Icons.remove_rounded,
            item.qty > 1 ? () => CartStore.setQty(item.id, item.qty - 1) : null,
          ),
          SizedBox(
            width: 26,
            child: Text(
              '${item.qty}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
          btn(
            Icons.add_rounded,
            item.qty < item.maxQty
                ? () => CartStore.setQty(item.id, item.qty + 1)
                : null,
          ),
        ],
      ),
    );
  }

  // ---------- tóm tắt đơn hàng ----------
  Widget _summary(List<CartItem> items) {
    final sub = subtotal(items);
    final ship = shipping(sub);
    final disc = discount(sub);
    final total = sub + ship - disc;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tóm tắt đơn hàng',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 18),

          // Mã giảm giá
          if (appliedCode.isEmpty)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: voucherController,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => applyVoucher(),
                    decoration: InputDecoration(
                      hintText: 'Mã giảm giá',
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 20,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: applyVoucher,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Áp dụng'),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$appliedCode · giảm $discountPercent%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: removeVoucher,
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          _row('Tạm tính', sub.formatThousand()),
          const SizedBox(height: 12),
          _row(
            'Phí vận chuyển',
            ship == 0 ? 'Miễn phí' : ship.formatThousand(),
            valueColor: ship == 0 ? Colors.green : null,
          ),
          if (disc > 0) ...[
            const SizedBox(height: 12),
            _row('Giảm giá', '-${disc.formatThousand()}', valueColor: _pink),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: _border, height: 1),
          ),
          Row(
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const Spacer(),
              Text(
                total.formatThousand(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: checkout,
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: const Text('Thanh toán'),
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                minimumSize: const Size.fromHeight(54),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Tiếp tục mua sắm'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.5, color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor ?? _ink,
          ),
        ),
      ],
    );
  }

  // ---------- giỏ hàng trống ----------
  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: _soft, shape: BoxShape.circle),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: _pink,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Giỏ hàng của bạn đang trống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy chọn vài đôi giày bạn thích nhé.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                minimumSize: const Size(200, 50),
                shape: const StadiumBorder(),
              ),
              child: const Text('Tiếp tục mua sắm'),
            ),
          ],
        ),
      ),
    );
  }
}
