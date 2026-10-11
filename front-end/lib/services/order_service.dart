import 'dart:convert';
import 'dart:developer';

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
}
