import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../utils/global.dart';
import 'my_orders_screen.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final controller = TextEditingController();
  final service = OrderService();
  MyOrderView? order;
  bool loading = false;
  String? error;

  Future<void> search() async {
    final code = controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
      order = null;
    });

    final res = await service.lookupOrder(code);
    if (res.errorMessage.isEmpty) {
      order = res.order;
    } else {
      error = res.errorMessage;
    }
    if (mounted) setState(() => loading = false);
  }

  // thêm vào _TrackOrderScreenState
  Future<void> cancel() async {
    final o = order;
    if (o == null) return;
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
    showToast(
      res.errorMessage.isEmpty ? "Đã hủy đơn" : res.errorMessage,
      res.errorMessage.isEmpty
          ? ToastificationType.success
          : ToastificationType.error,
    );
    search(); // tải lại trạng thái đơn
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              "Tra cứu đơn hàng",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Vui lòng điền mã tra cứu (tracking code) mà chúng tôi đã cung cấp "
                      "khi đặt hàng, không phải mã đơn hàng (ví dụ DH1015).",
                      style: TextStyle(fontSize: 13.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => search(),
                    decoration: InputDecoration(
                      hintText: "Mã tra cứu",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: loading ? null : search,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(100, 56),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Tra cứu"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            if (order != null)
              OrderCard(
                order: order!,
                onCancel: (isLoggedIn && order!.canCancel) ? cancel : null,
              ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text("Xem đơn đã đặt"),
            ),
          ],
        ),
      ),
    );
  }
}
