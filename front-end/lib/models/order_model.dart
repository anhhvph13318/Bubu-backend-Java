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
  String trackingCode = "";
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
    order.trackingCode = json[F_TRACKING_CODE] ?? "";
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
      F_TRACKING_CODE: trackingCode,
      F_STATUS: status,
      F_CREATED_AT: createdAt?.toIso8601String(),
      F_ACCOUNT_ID: accountId,
    };

    return map;
  }
}

class PaymentLinkResponse extends ActionResult {
  String orderCode = "";
  String paymentUrl = "";

  PaymentLinkResponse(super.errorCode, super.errorMessage);

  factory PaymentLinkResponse.fromJson(Map<String, dynamic> json) {
    PaymentLinkResponse response = PaymentLinkResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    final data = json[F_DATA];
    if (data is Map<String, dynamic>) {
      response.orderCode = data[F_ORDER_CODE] ?? "";
      response.paymentUrl = data[F_PAYMENT_URL] ?? "";
    }
    return response;
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

class CreateOrderRequest {
  String customerName;
  String phone;
  String address;
  String note;
  int paymentMethod; // 0: COD, 1: trực tuyến
  List<ItemRequest> items;

  CreateOrderRequest({
    required this.customerName,
    required this.phone,
    required this.address,
    required this.note,
    required this.paymentMethod,
    required this.items,
  });

  // Không gửi accountId: server tự lấy từ session
  Map<String, dynamic> toJson() => {
    F_CUSTOMER_NAME: customerName,
    F_PHONE: phone,
    F_ADDRESS: address,
    F_NOTE: note,
    F_PAYMENT_METHOD: paymentMethod,
    F_ITEMS: items.map((e) => e.toJson()).toList(),
  };
}

class OrderResponse extends ActionResult {
  Order order = Order();

  OrderResponse(super.errorCode, super.errorMessage);

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    OrderResponse response = OrderResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    if (json[F_DATA] != null) {
      response.order = Order.fromJson(json[F_DATA]);
    }
    return response;
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
  int totalQuantity = 0;
  int totalAmount = 0;
  bool hasIssues = false;

  CartView();

  factory CartView.fromJson(Map<String, dynamic> json) {
    CartView cart = CartView();

    cart.items = (json[F_ITEMS] as List? ?? [])
        .map((e) => CartViewItem.fromJson(e))
        .toList();
    cart.totalQuantity =
        (json[F_TOTAL_QUANTITY] as num?)?.toInt() ??
        cart.items.fold(0, (s, e) => s + e.quantity);
    cart.totalAmount = (json[F_TOTAL_AMOUNT] as num?)?.toInt() ?? 0;
    cart.hasIssues = json[F_HAS_ISSUES] ?? false;

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
  String? colorHex;
  int price = 0;
  int quantity = 0;
  int stock = 10;
  int lineTotal = 0;
  bool available = true;
  String? message;

  CartViewItem();

  factory CartViewItem.fromJson(Map<String, dynamic> json) {
    CartViewItem item = CartViewItem();

    item.productDetailId = json[F_PRODUCT_DETAIL_ID] ?? 0;
    item.productId = json[F_PRODUCT_ID] ?? 0;
    item.name = (json[F_PRODUCT_NAME] ?? json[F_NAME] ?? "").toString();
    item.imageUrl = json[F_IMAGE_URL] ?? "";
    item.size = (json[F_SIZE_NAME] ?? json[F_SIZE] ?? "").toString();
    item.color = (json[F_COLOR_NAME] ?? json[F_COLOR] ?? "").toString();
    item.colorHex = json[F_COLOR_HEX];
    item.price = ((json[F_UNIT_PRICE] ?? json[F_PRICE]) as num?)?.toInt() ?? 0;
    item.quantity = json[F_QUANTITY] ?? 0;
    item.stock = json[F_STOCK] ?? 10;
    item.lineTotal = (json[F_LINE_TOTAL] as num?)?.toInt() ?? 0;
    item.available = json[F_AVAILABLE] ?? true;
    item.message = json[F_MESSAGE];

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

class MyOrderView {
  int id = 0;
  String orderCode = "";
  int status = 0;
  String statusText = "";
  int paymentMethod = 0;
  int paymentStatus = 0;
  double totalAmount = 0;
  DateTime? createdAt;
  String customerName = "";
  String phone = "";
  String address = "";
  String note = "";
  bool canCancel = false;

  MyOrderView();

  factory MyOrderView.fromJson(Map<String, dynamic> json) {
    MyOrderView o = MyOrderView();

    o.id = json[F_ID] ?? 0;
    o.orderCode = json[F_ORDER_CODE] ?? "";
    o.status = json[F_STATUS] ?? 0;
    o.statusText = json[F_STATUS_TEXT] ?? "";
    o.paymentMethod = json[F_PAYMENT_METHOD] ?? 0;
    o.paymentStatus = json[F_PAYMENT_STATUS] ?? 0;
    o.totalAmount = (json[F_TOTAL_AMOUNT] as num?)?.toDouble() ?? 0;
    o.createdAt = json[F_CREATED_AT] != null
        ? DateTime.tryParse(json[F_CREATED_AT].toString())
        : null;
    o.customerName = json[F_CUSTOMER_NAME] ?? "";
    o.phone = json[F_PHONE] ?? "";
    o.address = json[F_ADDRESS] ?? "";
    o.note = json[F_NOTE] ?? "";
    o.canCancel = json[F_CAN_CANCEL] ?? false;

    return o;
  }
}

// 1 đơn: dùng cho track và cancel
class MyOrderResponse extends ActionResult {
  MyOrderView order = MyOrderView();

  MyOrderResponse(super.errorCode, super.errorMessage);

  factory MyOrderResponse.fromJson(Map<String, dynamic> json) {
    MyOrderResponse response = MyOrderResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    if (json[F_DATA] is Map<String, dynamic>) {
      response.order = MyOrderView.fromJson(json[F_DATA]);
    } else if (response.errorMessage.isEmpty) {
      // Spring trả lỗi 404/401/400 dạng {"message": "..."}
      response.errorMessage = nvl(json[F_MESSAGE]).isEmpty
          ? "Không tìm thấy đơn hàng"
          : nvl(json["message"]);
    }
    return response;
  }
}

class MyOrderListResponse extends ActionResult {
  List<MyOrderView> orders = [];

  MyOrderListResponse(super.errorCode, super.errorMessage);

  factory MyOrderListResponse.fromJson(Map<String, dynamic> json) {
    MyOrderListResponse response = MyOrderListResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    response.orders = (json[F_DATA] as List? ?? [])
        .map((e) => MyOrderView.fromJson(e))
        .toList();
    if (json[F_DATA] == null && json[F_MESSAGE] != null) {
      response.errorMessage = nvl(json[F_MESSAGE]);
    }
    return response;
  }
}
