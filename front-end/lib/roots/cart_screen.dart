import 'package:bubu_web_client/utils/string_utils.dart';
import 'package:bubu_web_client/widgets/footer_widget.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../utils/global.dart';
import '../widgets/vnpay_dialog.dart';

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

  // Phương thức thanh toán (khớp với paymentMethod của backend)
  static const int payCod = 0; // thanh toán khi nhận hàng
  static const int payOnline = 1; // thanh toán trực tuyến

  final OrderService service = OrderService();
  final voucherController = TextEditingController();

  // Thông tin nhận hàng
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final noteController = TextEditingController();
  int paymentMethod = payCod;
  bool submitting = false;

  List<CartViewItem> items = [];
  bool loading = true;

  int discountPercent = 0;
  String appliedCode = '';

  @override
  void initState() {
    super.initState();
    // Đã đăng nhập thì điền sẵn tên và số điện thoại
    if (isLoggedIn) {
      nameController.text = loginResponse.fullName;
      phoneController.text = loginResponse.phone;
    }
    loadCart();
  }

  @override
  void dispose() {
    voucherController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    noteController.dispose();
    super.dispose();
  }

  // ===================== GỌI API =====================
  Future<void> loadCart() async {
    final res = await service.getCart();
    if (!mounted) return;
    if (res.errorMessage.isEmpty) {
      cartCount.value = res.cart.totalQuantity;
      setState(() {
        items = res.cart.items;
        loading = false;
      });
    } else {
      setState(() => loading = false);
      showToast(res.errorMessage, ToastificationType.error);
    }
  }

  Future<void> _apply(Future<CartResponse> call) async {
    final res = await call;
    if (!mounted) return;
    if (res.errorMessage.isEmpty) {
      cartCount.value = res.cart.totalQuantity;
      setState(() => items = res.cart.items);
    } else {
      showToast(res.errorMessage, ToastificationType.error);
    }
  }

  void setQty(CartViewItem item, int qty) =>
      _apply(service.updateQuantity(item.productDetailId, qty));

  void removeItem(CartViewItem item) =>
      _apply(service.removeItem(item.productDetailId));

  void clearAll() {
    _apply(service.clearCart());
    removeVoucher();
  }

  // ===================== TÍNH TIỀN =====================
  int subtotal(List<CartViewItem> items) =>
      items.fold(0, (s, e) => s + e.price * e.quantity);

  int shipping(int sub) => (sub == 0 || sub >= freeShipFrom) ? 0 : shippingFee;

  int discount(int sub) => sub * discountPercent ~/ 100;

  void applyVoucher() {
    final code = voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;
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

  // ===================== ĐẶT HÀNG =====================
  Future<void> checkout() async {
    if (submitting || items.isEmpty) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.replaceAll(RegExp(r'\s'), '');
    final address = addressController.text.trim();
    final note = noteController.text.trim();

    if (name.isEmpty) {
      showToast('Vui lòng nhập họ tên người nhận', ToastificationType.warning);
      return;
    }
    if (!RegExp(r'^(0|\+84)\d{9}$').hasMatch(phone)) {
      showToast('Số điện thoại không hợp lệ', ToastificationType.warning);
      return;
    }
    if (address.isEmpty) {
      showToast('Vui lòng nhập địa chỉ nhận hàng', ToastificationType.warning);
      return;
    }
    if (items.any((e) => !e.available)) {
      showToast(
        'Giỏ hàng có sản phẩm không còn khả dụng, vui lòng kiểm tra lại',
        ToastificationType.warning,
      );
      return;
    }

    setState(() => submitting = true);

    final method = paymentMethod;
    final res = await service.createOrder(
      CreateOrderRequest(
        customerName: name,
        phone: phone,
        address: address,
        note: note,
        paymentMethod: method,
        items: items
            .map((e) => ItemRequest(e.productDetailId, e.quantity))
            .toList(),
      ),
    );
    if (!mounted) return;

    if (res.errorMessage.isNotEmpty) {
      setState(() => submitting = false);
      showToast(res.errorMessage, ToastificationType.error);
      return;
    }

    // Đơn đã được tạo trên server: dọn giỏ ngay (cả COD lẫn VNPay)
    // để khách không thể bấm đặt lại và tạo trùng đơn.
    await _apply(service.clearCart());
    if (!mounted) return;
    removeVoucher();

    if (method == payOnline) {
      await _payOnline(res.order);
    } else {
      await _showSuccess(res.order, method);
    }
    if (!mounted) return;
    setState(() => submitting = false);
  }

  Future<void> _payOnline(Order order) async {
    if (order.trackingCode.isEmpty) {
      showToast(
        'Đơn ${order.orderCode} đã được tạo nhưng không nhận được mã tra cứu '
        'để thanh toán. Vui lòng liên hệ cửa hàng.',
        ToastificationType.error,
      );
      return;
    }

    final link = await service.createVnpayLink(order.trackingCode);
    if (!mounted) return;
    if (link.errorMessage.isNotEmpty || link.paymentUrl.isEmpty) {
      showToast(
        'Đơn ${order.orderCode} đã được tạo nhưng chưa tạo được liên kết '
        'thanh toán. Vui lòng liên hệ cửa hàng.',
        ToastificationType.error,
      );
      return;
    }

    final result = await showDialog<PayResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VnpayDialog(
        service: service,
        trackingCode: order.trackingCode,
        orderCode: order.orderCode,
        paymentUrl: link.paymentUrl,
      ),
    );
    if (!mounted) return;

    switch (result) {
      case PayResult.paid:
        await _showSuccess(order, payOnline);
      case PayResult.failed:
        showToast(
          'Thanh toán không thành công, đơn ${order.orderCode} đã bị hủy. '
          'Bạn có thể chọn lại sản phẩm để đặt đơn mới.',
          ToastificationType.error,
        );
      default:
        showToast(
          'Đơn ${order.orderCode} đang chờ thanh toán. Vui lòng không đặt lại '
          'để tránh trùng đơn, nếu đã thanh toán đơn sẽ được cập nhật sau ít phút.',
          ToastificationType.info,
        );
    }
  }

  Future<void> _showSuccess(Order order, int method) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text(
              'Đặt hàng thành công',
              style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã đơn hàng: ${order.orderCode}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tổng tiền: ${order.totalAmount.toInt().formatThousand()}',
              style: const TextStyle(fontSize: 14.5, color: _ink),
            ),
            const SizedBox(height: 8),
            Text(
              method == payCod
                  ? 'Bạn sẽ thanh toán khi nhận hàng.'
                  : 'Đơn hàng đã được thanh toán qua VNPay.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              shape: const StadiumBorder(),
            ),
            child: const Text('Tiếp tục mua sắm'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
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
                            if (loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 80),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (items.isEmpty)
                              _emptyState()
                            else
                              LayoutBuilder(
                                builder: (context, c) {
                                  final narrow = c.maxWidth < 900;
                                  // bên trái: danh sách sản phẩm + thông tin nhận hàng
                                  final list = Column(
                                    children: [
                                      _itemList(items),
                                      const SizedBox(height: 24),
                                      _checkoutForm(),
                                    ],
                                  );
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
      ),
    );
  }

  // ---------- header ----------
  Widget _header(List<CartViewItem> items) {
    final count = items.fold(0, (s, e) => s + e.quantity);
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
  Widget _itemList(List<CartViewItem> items) {
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
            onPressed: clearAll,
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text('Xóa tất cả'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _itemCard(CartViewItem item) {
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
                        onTap: () => removeItem(item),
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

  Widget _qtyStepper(CartViewItem item) {
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
            item.quantity > 1 ? () => setQty(item, item.quantity - 1) : null,
          ),
          SizedBox(
            width: 26,
            child: Text(
              '${item.quantity}',
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
            item.quantity < item.stock
                ? () => setQty(item, item.quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }

  // ---------- thông tin nhận hàng + phương thức thanh toán ----------
  Widget _checkoutForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin nhận hàng',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final name = _field(
                nameController,
                'Họ và tên',
                Icons.person_outline,
              );
              final phone = _field(
                phoneController,
                'Số điện thoại',
                Icons.phone_outlined,
                type: TextInputType.phone,
              );
              if (c.maxWidth < 520) {
                return Column(
                  children: [name, const SizedBox(height: 14), phone],
                );
              }
              return Row(
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 14),
                  Expanded(child: phone),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _field(
            addressController,
            'Địa chỉ nhận hàng',
            Icons.location_on_outlined,
          ),
          const SizedBox(height: 14),
          _field(
            noteController,
            'Ghi chú (không bắt buộc)',
            Icons.edit_note_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          _payTile(
            value: payCod,
            icon: Icons.payments_outlined,
            title: 'Thanh toán khi nhận hàng (COD)',
            subtitle: 'Trả tiền mặt cho nhân viên giao hàng',
          ),
          const SizedBox(height: 10),
          _payTile(
            value: payOnline,
            icon: Icons.credit_card_outlined,
            title: 'Thanh toán trực tuyến',
            subtitle: 'Thanh toán qua cổng thanh toán điện tử',
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: _soft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _payTile({
    required int value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = paymentMethod == value;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _pink.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _pink : _border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _pink : _ink),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 22,
              color: selected ? _pink : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- tóm tắt đơn hàng ----------
  Widget _summary(List<CartViewItem> items) {
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
              onPressed: submitting ? null : checkout,
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline_rounded, size: 18),
              label: Text(submitting ? 'Đang xử lý...' : 'Đặt hàng'),
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
