import '../models/order_model.dart';
import '../utils/global.dart';
import '../utils/http_service.dart';

class OrderService {
  // GET /api/carts/{accountId}
  Future<CartResponse> getCart(int accountId) async {
    String url = "$baseUrl/api/carts/$accountId";
    try {
      final response = await httpService.get(url);
      return CartResponse.fromJson(response);
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // POST /api/carts/{accountId}/items
  Future<CartResponse> addItem(int accountId, ItemRequest request) async {
    String url = "$baseUrl/api/carts/$accountId/items";
    try {
      final response = await httpService.post(url, body: request.toJson());
      return CartResponse.fromJson(response);
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // PUT /api/carts/{accountId}/items/{productDetailId}
  Future<CartResponse> updateQuantity(
    int accountId,
    int productDetailId,
    int quantity,
  ) async {
    String url = "$baseUrl/api/carts/$accountId/items/$productDetailId";
    try {
      final response = await httpService.put(
        url,
        body: UpdateQuantityRequest(quantity).toJson(),
      );
      return CartResponse.fromJson(response);
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // DELETE /api/carts/{accountId}/items/{productDetailId}
  Future<CartResponse> removeItem(int accountId, int productDetailId) async {
    String url = "$baseUrl/api/carts/$accountId/items/$productDetailId";
    try {
      final response = await httpService.delete(url);
      return CartResponse.fromJson(response);
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // DELETE /api/carts/{accountId}/items
  Future<CartResponse> clearCart(int accountId) async {
    String url = "$baseUrl/api/carts/$accountId/items";
    try {
      final response = await httpService.delete(url);
      return CartResponse.fromJson(response);
    } catch (e) {
      return CartResponse("FAIL", e.toString());
    }
  }

  // POST /api/carts/{accountId}/merge (trả CartView trực tiếp)
  Future<CartResponse> mergeCart(int accountId, List<ItemRequest> items) async {
    String url = "$baseUrl/api/carts/$accountId/merge";
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
}
