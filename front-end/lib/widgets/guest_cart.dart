import 'dart:convert';

import '../models/order_model.dart';
import '../utils/fields.dart';
import '../utils/global.dart';

/// Giỏ hàng của khách chưa đăng nhập.
/// Chỉ lưu [productDetailId] + [quantity] (đúng định dạng backend cần cho
/// /preview và /merge), còn tên, ảnh, giá, tồn kho sẽ lấy từ API preview.
/// Dữ liệu lưu qua readData/saveData (flutter_secure_storage -> localStorage trên web).
class GuestCart {
  static const _key = 'guest_cart';

  static Future<List<ItemRequest>> load() async {
    try {
      final raw = await readData(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (e) => ItemRequest(
              (e[F_PRODUCT_DETAIL_ID] as num).toInt(),
              (e[F_QUANTITY] as num).toInt(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<ItemRequest> items) =>
      saveData(_key, jsonEncode(items.map((e) => e.toJson()).toList()));

  /// Thêm vào giỏ, nếu đã có thì cộng dồn (không vượt quá [stock] nếu có).
  static Future<void> add(int productDetailId, int qty, {int? stock}) async {
    final items = await load();
    final i = items.indexWhere((e) => e.productDetailId == productDetailId);
    if (i >= 0) {
      var q = items[i].quantity + qty;
      if (stock != null && q > stock) q = stock;
      items[i] = ItemRequest(productDetailId, q < 1 ? 1 : q);
    } else {
      items.add(ItemRequest(productDetailId, qty));
    }
    await _save(items);
  }

  static Future<void> setQty(int productDetailId, int qty) async {
    final items = await load();
    final i = items.indexWhere((e) => e.productDetailId == productDetailId);
    if (i < 0) return;
    items[i] = ItemRequest(productDetailId, qty);
    await _save(items);
  }

  static Future<void> remove(int productDetailId) async {
    final items = await load();
    items.removeWhere((e) => e.productDetailId == productDetailId);
    await _save(items);
  }

  static Future<void> clear() => saveData(_key, '');
}
