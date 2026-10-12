import 'dart:convert';
import 'dart:developer';
import 'dart:html' as html;

import '../models/order_model.dart';
import '../utils/fields.dart';
import '../utils/global.dart';
import '../utils/http_service.dart';
import '../widgets/guest_cart.dart';

/// Các hàm giỏ hàng tự phân biệt:
/// - Đã đăng nhập (isLoggedIn): gọi API theo loginResponse.id
/// - Chưa đăng nhập: lưu giỏ trong GuestCart (localStorage) rồi gọi /preview
class OrderService {
  CartResponse _sync(CartResponse res) {
    if (res.errorMessage.isEmpty) cartCount.value = res.cart.totalQuantity;
    return res;
  }

  Future<CartResponse> _guestView() async {
    final items = await GuestCart.load();
    if (items.isEmpty) {
      cartCount.value = 0;
      return CartResponse("OK", "");
    }
    return _sync(await previewCart(items));
  }

  Future<CartResponse> getCart() async {
    if (!isLoggedIn) return _guestView();

    String url = "$baseUrl/api/carts/${loginResponse.id}";
    try {
      final response = await httpService.get(url);
      return _sync(CartResponse.fromJson(response));
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // POST /api/carts/{accountId}/items
  // stock: tồn kho của biến thể, chỉ dùng để giới hạn số lượng khi là khách
  Future<CartResponse> addItem(ItemRequest request, {int? stock}) async {
    if (!isLoggedIn) {
      await GuestCart.add(
        request.productDetailId,
        request.quantity,
        stock: stock,
      );
      return _guestView();
    }

    String url = "$baseUrl/api/carts/${loginResponse.id}/items";
    try {
      final response = await httpService.post(url, body: request.toJson());
      return _sync(CartResponse.fromJson(response));
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // PUT /api/carts/{accountId}/items/{productDetailId}
  Future<CartResponse> updateQuantity(int productDetailId, int quantity) async {
    if (!isLoggedIn) {
      await GuestCart.setQty(productDetailId, quantity);
      return _guestView();
    }

    String url =
        "$baseUrl/api/carts/${loginResponse.id}/items/$productDetailId";
    try {
      final response = await httpService.put(
        url,
        body: UpdateQuantityRequest(quantity).toJson(),
      );
      return _sync(CartResponse.fromJson(response));
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // DELETE /api/carts/{accountId}/items/{productDetailId}
  Future<CartResponse> removeItem(int productDetailId) async {
    if (!isLoggedIn) {
      await GuestCart.remove(productDetailId);
      return _guestView();
    }

    String url =
        "$baseUrl/api/carts/${loginResponse.id}/items/$productDetailId";
    try {
      final response = await httpService.delete(url);
      return _sync(CartResponse.fromJson(response));
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // DELETE /api/carts/{accountId}/items
  Future<CartResponse> clearCart() async {
    if (!isLoggedIn) {
      await GuestCart.clear();
      return _guestView();
    }

    String url = "$baseUrl/api/carts/${loginResponse.id}/items";
    try {
      final response = await httpService.delete(url);
      return _sync(CartResponse.fromJson(response));
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // POST /api/carts/{accountId}/merge (trả CartView trực tiếp)
  Future<CartResponse> mergeCart(List<ItemRequest> items) async {
    String url = "$baseUrl/api/carts/${loginResponse.id}/merge";
    try {
      final response = await httpService.post(
        url,
        body: CartItemsRequest(items).toJson(),
      );
      return _sync(CartResponse.fromCartJson(response));
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // POST /api/carts/preview (khách chưa đăng nhập, trả CartView trực tiếp)
  Future<CartResponse> previewCart(List<ItemRequest> items) async {
    String url = "$baseUrl/api/carts/preview";
    try {
      final response = await httpService.post(
        url,
        body: CartItemsRequest(items).toJson(),
      );
      return CartResponse.fromCartJson(response);
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  /// Gọi ngay sau khi đăng nhập thành công (loginResponse đã được gán):
  /// gộp giỏ localStorage vào giỏ database rồi xóa giỏ local.
  Future<CartResponse> syncAfterLogin() async {
    final local = await GuestCart.load();
    if (local.isNotEmpty) {
      final res = await mergeCart(local);
      if (res.errorMessage.isEmpty) await GuestCart.clear();
      return res;
    }
    return getCart();
  }

  // POST /api/orders
  Future<OrderResponse> createOrder(CreateOrderRequest request) async {
    String url = "$baseUrl/api/orders";
    try {
      final response = await httpService.post(url, body: request.toJson());
      return OrderResponse.fromJson(response);
    } catch (e) {
      return OrderResponse("FAIL", e.toString());
    }
  }

  // POST /api/payment/vnpay/create
  Future<PaymentLinkResponse> createVnpayLink(String trackingCode) async {
    String url = "$baseUrl/api/payment/vnpay/create";
    try {
      final response = await httpService.post(
        url,
        body: {F_TRACKING_CODE: trackingCode},
      );
      log("createVnpayLink ${jsonEncode(response)}");
      return PaymentLinkResponse.fromJson(response);
    } catch (e) {
      return PaymentLinkResponse("FAIL", e.toString());
    }
  }

  // GET /api/orders/track/{trackingCode}
  Future<OrderResponse> trackOrder(String trackingCode) async {
    String url = "$baseUrl/api/orders/track/$trackingCode";
    try {
      final response = await httpService.get(url);
      log("trackOrder ${jsonEncode(response)}");
      return OrderResponse.fromJson(response);
    } catch (e) {
      return OrderResponse("FAIL", e.toString());
    }
  }

  // ---- Đơn của khách vãng lai: lưu trackingCode trên trình duyệt ----
  static const _guestOrdersKey = "GUEST_ORDER_CODES";

  Future<List<String>> getGuestCodes() async {
    final raw = html.window.localStorage[_guestOrdersKey];
    if (raw == null || raw.isEmpty) return [];
    return raw.split(",");
  }

  Future<void> addGuestCode(String code) async {
    if (code.isEmpty) return;
    final codes = await getGuestCodes();
    if (!codes.contains(code)) {
      codes.insert(0, code);
      html.window.localStorage[_guestOrdersKey] = codes.join(",");
    }
  }

  // GET /api/orders/track/{trackingCode}
  Future<MyOrderResponse> lookupOrder(String trackingCode) async {
    String url =
        "$baseUrl/api/orders/track/${Uri.encodeComponent(trackingCode.trim())}";
    try {
      final response = await httpService.get(url);
      return MyOrderResponse.fromJson(response);
    } catch (e) {
      return MyOrderResponse("FAIL", "Không tìm thấy đơn hàng");
    }
  }

  // Đã đăng nhập: GET /api/orders/my. Vãng lai: tra từng mã đã lưu.
  Future<MyOrderListResponse> getMyOrders() async {
    if (isLoggedIn) {
      String url = "$baseUrl/api/orders/my";
      try {
        final response = await httpService.get(url);
        return MyOrderListResponse.fromJson(response);
      } catch (e) {
        return MyOrderListResponse("FAIL", e.toString());
      }
    }

    final codes = await getGuestCodes();
    final results = await Future.wait(codes.map(lookupOrder));
    final res = MyOrderListResponse("OK", "");
    res.orders = results
        .where((r) => r.errorMessage.isEmpty)
        .map((r) => r.order)
        .toList();
    return res;
  }

  // POST /api/orders/my/{id}/cancel (cần đăng nhập)
  Future<MyOrderResponse> cancelMyOrder(int id) async {
    String url = "$baseUrl/api/orders/my/$id/cancel";
    try {
      final response = await httpService.post(url, body: {});
      return MyOrderResponse.fromJson(response);
    } catch (e) {
      return MyOrderResponse("FAIL", e.toString());
    }
  }
}
