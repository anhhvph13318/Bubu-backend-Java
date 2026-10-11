import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/order_service.dart';
import '../utils/global.dart';

enum PayResult { paid, failed, dismissed }

/// Mở trang VNPay ở tab mới, trong lúc đó tab của app hiện hộp thoại chờ và
/// cứ 3 giây hỏi lại GET /api/orders/track/{trackingCode} để biết đã thanh toán chưa.
/// Trả về [PayResult] khi đóng.
class VnpayDialog extends StatefulWidget {
  final OrderService service;
  final String trackingCode;
  final String orderCode;
  final String paymentUrl;

  const VnpayDialog({
    super.key,
    required this.service,
    required this.trackingCode,
    required this.orderCode,
    required this.paymentUrl,
  });

  @override
  State<VnpayDialog> createState() => _VnpayDialogState();
}

class _VnpayDialogState extends State<VnpayDialog> {
  static const _ink = Color(0xFF14183A);
  static const _pink = Color(0xFFFF5C8A);

  // Giá trị theo backend: paymentStatus 1 = đã thanh toán, status 4 = đã hủy
  static const int paidStatus = 1;
  static const int cancelledStatus = 4;

  Timer? _timer;
  bool _checking = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _open(); // thử tự mở tab VNPay, nếu trình duyệt chặn popup thì khách bấm nút
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(widget.paymentUrl);
    if (uri == null || !uri.hasScheme) {
      showToast('Liên kết thanh toán không hợp lệ', ToastificationType.error);
      return;
    }
    try {
      final ok = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!ok) {
        showToast(
          'Trình duyệt đã chặn cửa sổ mới, hãy cho phép popup cho trang này',
          ToastificationType.warning,
        );
      }
    } catch (e) {
      log(e.toString());
      showToast('Không mở được trang thanh toán: $e', ToastificationType.error);
    }
  }

  Future<void> _check({bool manual = false}) async {
    if (_checking || _done) return;
    _checking = true;
    final res = await widget.service.trackOrder(widget.trackingCode);
    _checking = false;
    if (!mounted || _done) return;

    if (res.errorMessage.isNotEmpty) {
      if (manual) showToast(res.errorMessage, ToastificationType.error);
      return;
    }

    final order = res.order;
    if (order.paymentStatus == paidStatus) {
      _finish(PayResult.paid);
    } else if (order.status == cancelledStatus) {
      _finish(PayResult.failed);
    } else if (manual) {
      showToast(
        'Chưa ghi nhận thanh toán, vui lòng thử lại sau ít giây',
        ToastificationType.info,
      );
    }
  }

  void _finish(PayResult result) {
    _done = true;
    _timer?.cancel();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Thanh toán qua VNPay',
        style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đang chờ thanh toán đơn ${widget.orderCode}...',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Trang thanh toán VNPay đã được mở ở tab mới. Hãy hoàn tất '
              'thanh toán ở đó, hệ thống sẽ tự cập nhật khi nhận được kết quả. '
              'Nếu không thấy tab mới, bấm "Mở trang thanh toán".',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => _finish(PayResult.dismissed),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          child: const Text('Đóng'),
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => _check(manual: true),
              style: TextButton.styleFrom(foregroundColor: _pink),
              child: const Text('Tôi đã thanh toán'),
            ),
            FilledButton(
              onPressed: _open,
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                shape: const StadiumBorder(),
              ),
              child: const Text('Mở trang thanh toán'),
            ),
          ],
        ),
      ],
    );
  }
}
