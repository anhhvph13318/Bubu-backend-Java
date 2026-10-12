import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../utils/global.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final service = OrderService();
  late Future<MyOrderListResponse> future;

  @override
  void initState() {
    super.initState();
    future = service.getMyOrders();
  }

  void reload() {
    setState(() {
      future = service.getMyOrders();
    });
  }

  Future<void> cancel(MyOrderView o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hủy đơn hàng?"),
        content: Text("Bạn chắc chắn muốn hủy đơn ${o.orderCode}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Không"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hủy đơn"),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final res = await service.cancelMyOrder(o.id);
    if (!mounted) return;
    final done = res.errorMessage.isEmpty;
    showToast(
      done ? "Đã hủy đơn" : res.errorMessage,
      done ? ToastificationType.success : ToastificationType.error,
    );
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: FutureBuilder<MyOrderListResponse>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final res = snap.data;
            final orders = res?.orders ?? [];
            for (final o in orders) {
              debugPrint(
                'order=${o.orderCode} status=${o.status} canCancel=${o.canCancel} loggedIn=$isLoggedIn',
              );
            }
            final error = res?.errorMessage ?? "";

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  isLoggedIn
                      ? "Đơn hàng của tôi"
                      : "Đơn hàng đã đặt (khách vãng lai)",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isLoggedIn)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Chỉ hiển thị các đơn đặt trên trình duyệt này.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 16),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (orders.isEmpty && error.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text("Chưa có đơn hàng nào")),
                  ),
                for (final o in orders)
                  OrderCard(
                    order: o,
                    onCancel: o.canCancel ? () => cancel(o) : null,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final MyOrderView order;
  final VoidCallback? onCancel;
  const OrderCard({super.key, required this.order, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == 4;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffeeeeee)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Đơn ${order.orderCode}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cancelled ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cancelled
                        ? Colors.red.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (order.createdAt != null)
            Text(
              "${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          const Divider(height: 24),
          Text("${order.customerName} · ${order.phone}"),
          const SizedBox(height: 2),
          Text(order.address, style: const TextStyle(color: Colors.grey)),
          const Divider(height: 24),
          Row(
            children: [
              const Text("Tổng cộng"),
              const Spacer(),
              Text(
                _money(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (onCancel != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: const Text(
                  "Hủy đơn",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _money(double v) {
    final s = v.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return "$b₫";
  }
}
