import 'package:bubu_web_client/models/action_result.dart';

import '../utils/fields.dart';
import '../utils/string_utils.dart';

class Cart {
  int id = 0;
  int accountId = 0;
  DateTime? createdAt;
  DateTime? updatedAt;

  Cart();

  factory Cart.fromJson(Map<String, dynamic> json) {
    Cart cart = Cart();

    cart.id = json[F_ID] ?? 0;
    cart.accountId = json[F_ACCOUNT_ID] ?? 0;
    cart.createdAt = json[F_CREATED_AT] != null
        ? DateTime.tryParse(json[F_CREATED_AT].toString())
        : null;
    cart.updatedAt = json[F_UPDATED_AT] != null
        ? DateTime.tryParse(json[F_UPDATED_AT].toString())
        : null;

    return cart;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_ID: id,
      F_ACCOUNT_ID: accountId,
      F_CREATED_AT: createdAt?.toIso8601String(),
      F_UPDATED_AT: updatedAt?.toIso8601String(),
    };

    return map;
  }
}

class CartItem {
  int id = 0;
  int cartId = 0;
  int productDetailId = 0;
  int quantity = 0;
  DateTime? createdAt;

  CartItem();

  factory CartItem.fromJson(Map<String, dynamic> json) {
    CartItem item = CartItem();

    item.id = json[F_ID] ?? 0;
    item.cartId = json[F_CART_ID] ?? 0;
    item.productDetailId = json[F_PRODUCT_DETAIL_ID] ?? 0;
    item.quantity = json[F_QUANTITY] ?? 0;
    item.createdAt = json[F_CREATED_AT] != null
        ? DateTime.tryParse(json[F_CREATED_AT].toString())
        : null;

    return item;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_ID: id,
      F_CART_ID: cartId,
      F_PRODUCT_DETAIL_ID: productDetailId,
      F_QUANTITY: quantity,
      F_CREATED_AT: createdAt?.toIso8601String(),
    };

    return map;
  }
}

class Order {
  int id = 0;
  String orderCode = "";
  String customerName = "";
  String phone = "";
  String address = "";
  String note = "";
  double totalAmount = 0;
  int paymentMethod = 0;
  int paymentStatus = 0;
  int status = 0;
  DateTime? createdAt;
  int? accountId; // null = khách vãng lai

  Order();

  factory Order.fromJson(Map<String, dynamic> json) {
    Order order = Order();

    order.id = json[F_ID] ?? 0;
    order.orderCode = json[F_ORDER_CODE] ?? "";
    order.customerName = json[F_CUSTOMER_NAME] ?? "";
    order.phone = json[F_PHONE] ?? "";
    order.address = json[F_ADDRESS] ?? "";
    order.note = json[F_NOTE] ?? "";
    order.totalAmount = (json[F_TOTAL_AMOUNT] as num?)?.toDouble() ?? 0;
    order.paymentMethod = json[F_PAYMENT_METHOD] ?? 0;
    order.paymentStatus = json[F_PAYMENT_STATUS] ?? 0;
    order.status = json[F_STATUS] ?? 0;
    order.createdAt = json[F_CREATED_AT] != null
        ? DateTime.tryParse(json[F_CREATED_AT].toString())
        : null;
    order.accountId = json[F_ACCOUNT_ID];

    return order;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_ID: id,
      F_ORDER_CODE: orderCode,
      F_CUSTOMER_NAME: customerName,
      F_PHONE: phone,
      F_ADDRESS: address,
      F_NOTE: note,
      F_TOTAL_AMOUNT: totalAmount,
      F_PAYMENT_METHOD: paymentMethod,
      F_PAYMENT_STATUS: paymentStatus,
      F_STATUS: status,
      F_CREATED_AT: createdAt?.toIso8601String(),
      F_ACCOUNT_ID: accountId,
    };

    return map;
  }
}

class OrderDetail {
  int id = 0;
  int orderId = 0;
  int productDetailId = 0;
  int quantity = 0;
  double price = 0;

  OrderDetail();

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    OrderDetail detail = OrderDetail();

    detail.id = json[F_ID] ?? 0;
    detail.orderId = json[F_ORDER_ID] ?? 0;
    detail.productDetailId = json[F_PRODUCT_DETAIL_ID] ?? 0;
    detail.quantity = json[F_QUANTITY] ?? 0;
    detail.price = (json[F_PRICE] as num?)?.toDouble() ?? 0;

    return detail;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_ID: id,
      F_ORDER_ID: orderId,
      F_PRODUCT_DETAIL_ID: productDetailId,
      F_QUANTITY: quantity,
      F_PRICE: price,
    };

    return map;
  }
}

class ItemRequest {
  int productDetailId = 0;
  int quantity = 1;

  ItemRequest(this.productDetailId, this.quantity);

  Map<String, dynamic> toJson() => {
    F_PRODUCT_DETAIL_ID: productDetailId,
    F_QUANTITY: quantity,
  };
}

class UpdateQuantityRequest {
  int quantity = 1;

  UpdateQuantityRequest(this.quantity);

  Map<String, dynamic> toJson() => {F_QUANTITY: quantity};
}

// dùng cho merge và preview
class CartItemsRequest {
  List<ItemRequest> items = [];

  CartItemsRequest(this.items);

  Map<String, dynamic> toJson() => {
    F_ITEMS: items.map((e) => e.toJson()).toList(),
  };
}

class CartView {
  List<CartViewItem> items = [];
  double totalAmount = 0;

  CartView();

  factory CartView.fromJson(Map<String, dynamic> json) {
    CartView cart = CartView();

    cart.items = (json[F_ITEMS] as List? ?? [])
        .map((e) => CartViewItem.fromJson(e))
        .toList();
    cart.totalAmount = (json[F_TOTAL_AMOUNT] as num?)?.toDouble() ?? 0;

    return cart;
  }
}

class CartViewItem {
  int productDetailId = 0;
  int productId = 0;
  String name = "";
  String imageUrl = "";
  String size = "";
  String color = "";
  double price = 0;
  int quantity = 0;
  int stock = 10;

  CartViewItem();

  factory CartViewItem.fromJson(Map<String, dynamic> json) {
    CartViewItem item = CartViewItem();

    item.productDetailId = json[F_PRODUCT_DETAIL_ID] ?? 0;
    item.productId = json[F_PRODUCT_ID] ?? 0;
    item.name = json[F_NAME] ?? "";
    item.imageUrl = json[F_IMAGE_URL] ?? "";
    item.size = json[F_SIZE]?.toString() ?? "";
    item.color = json[F_COLOR] ?? "";
    item.price = (json[F_PRICE] as num?)?.toDouble() ?? 0;
    item.quantity = json[F_QUANTITY] ?? 0;
    item.stock = json[F_STOCK] ?? 10;

    return item;
  }
}

class CartResponse extends ActionResult {
  CartView cart = CartView();

  CartResponse(super.errorCode, super.errorMessage);

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    CartResponse response = CartResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    if (json[F_DATA] != null) {
      response.cart = CartView.fromJson(json[F_DATA]);
    }
    return response;
  }

  factory CartResponse.fromCartJson(Map<String, dynamic> json) {
    CartResponse response = CartResponse("OK", "");
    response.cart = CartView.fromJson(json);
    return response;
  }
}
