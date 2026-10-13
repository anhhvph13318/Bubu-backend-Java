import 'package:bubu_web_client/models/action_result.dart';

import '../utils/fields.dart';
import '../utils/string_utils.dart';

class Product {
  int id = 0;
  String code = "";
  String name = "";
  int price = 0;
  String description = "";
  String imageUrl = "";
  int categoryId = 0;
  String categoryName = "";
  int status = 0;
  int totalQuantity = 0;
  Product();

  factory Product.fromJson(Map<String, dynamic> json) {
    Product product = Product();

    product.id = json[F_ID] ?? 0;
    product.code = json[F_CODE] ?? "";
    product.name = json[F_NAME] ?? "";

    product.price = json[F_PRICE] ?? 0;

    product.description = json[F_DESCRIPTION] ?? "";
    product.imageUrl = json[F_IMAGE_URL] ?? "";
    product.categoryId = json[F_CATEGORY_ID] ?? 0;
    product.categoryName = json[F_CATEGORY_NAME] ?? "";

    product.status = json[F_STATUS] ?? 0;
    product.totalQuantity = json[F_TOTAL_QUANTITY] ?? 0;

    return product;
  }
}

class ProductResponse extends ActionResult {
  List<Product> products = [];

  ProductResponse(super.errorCode, super.errorMessage);

  // API trả về List nên nhận List<dynamic>
  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    ProductResponse response = ProductResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    var prds = json[F_DATA];
    if (prds != null) {
      response.products = (prds as List)
          .map((e) => Product.fromJson(e))
          .toList();
    }

    return response;
  }
}

// ===================== COLOR =====================
class ProductColor {
  int id = 0;
  String name = "";
  String hexCode = ""; // Mã màu hiển thị, ví dụ #FF99CC (có thể để trống)
  bool active = true;

  ProductColor();

  factory ProductColor.fromJson(Map<String, dynamic> json) {
    ProductColor color = ProductColor();

    color.id = json[F_ID] ?? 0;
    color.name = json[F_NAME] ?? "";
    color.hexCode = json[F_HEX_CODE] ?? "";
    color.active = json[F_ACTIVE] ?? true;

    return color;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_ID: id,
      F_NAME: name,
      F_HEX_CODE: hexCode,
      F_ACTIVE: active,
    };

    return map;
  }
}

class ProductColorResponse extends ActionResult {
  List<ProductColor> colors = [];

  ProductColorResponse(super.errorCode, super.errorMessage);

  factory ProductColorResponse.fromJson(Map<String, dynamic> json) {
    ProductColorResponse response = ProductColorResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    var colors = json[F_DATA];
    if (colors != null) {
      response.colors = (colors as List)
          .map((e) => ProductColor.fromJson(e))
          .toList();
    }

    return response;
  }
}

// ===================== CATEGORY =====================
class Category {
  int id = 0;
  String name = "";
  String description = "";
  bool isDeleted = false;

  Category();

  factory Category.fromJson(Map<String, dynamic> json) {
    Category category = Category();

    category.id = json[F_ID] ?? 0;
    category.name = json[F_NAME] ?? "";
    category.description = json[F_DESCRIPTION] ?? "";
    category.isDeleted = json[F_IS_DELETED] ?? false;

    return category;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_ID: id,
      F_NAME: name,
      F_DESCRIPTION: description,
      F_IS_DELETED: isDeleted,
    };

    return map;
  }
}

class CategoryResponse extends ActionResult {
  List<Category> categories = [];

  CategoryResponse(super.errorCode, super.errorMessage);

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    CategoryResponse response = CategoryResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    var cates = json[F_DATA];
    if (cates != null) {
      response.categories = (cates as List)
          .map((e) => Category.fromJson(e))
          .toList();
    }

    return response;
  }
}

// ===================== SIZE =====================
class ProductSize {
  int id = 0;
  String name = "";
  bool active = true;

  ProductSize();

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    ProductSize size = ProductSize();

    size.id = json[F_ID] ?? 0;
    size.name = json[F_NAME] ?? "";
    size.active = json[F_ACTIVE] ?? true;

    return size;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {F_ID: id, F_NAME: name, F_ACTIVE: active};

    return map;
  }
}

class ProductSizeResponse extends ActionResult {
  List<ProductSize> sizes = [];

  ProductSizeResponse(super.errorCode, super.errorMessage);

  factory ProductSizeResponse.fromJson(Map<String, dynamic> json) {
    ProductSizeResponse response = ProductSizeResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    var sizes = json[F_DATA];
    if (sizes != null) {
      response.sizes = (sizes as List)
          .map((e) => ProductSize.fromJson(e))
          .toList();
    }

    return response;
  }
}

// ===================== PRODUCT DETAIL =====================
class ProductDetail {
  int id = 0;
  int productId = 0;
  int sizeId = 0;
  int colorId = 0;
  int quantity = 0;

  // Tên size/màu: API chi tiết sản phẩm có trả về, không có trong entity Java
  String size = "";
  String color = "";

  ProductDetail();

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    ProductDetail detail = ProductDetail();

    detail.id = json[F_ID] ?? 0;
    detail.productId = json[F_PRODUCT_ID] ?? 0;
    detail.sizeId = json[F_SIZE_ID] ?? 0;
    detail.colorId = json[F_COLOR_ID] ?? 0;
    detail.quantity = json[F_QUANTITY] ?? 0;
    detail.size = json[F_SIZE] ?? "";
    detail.color = json[F_COLOR] ?? "";

    return detail;
  }

  // Map<String, dynamic> toJson() {
  //   Map<String, dynamic> map = {
  //     F_ID: id,
  //     F_PRODUCT_ID: productId,
  //     F_SIZE_ID: sizeId,
  //     F_COLOR_ID: colorId,
  //     F_QUANTITY: quantity,
  //   };

  //   return map;
  // }
}

class DetailResponse extends ActionResult {
  List<ProductDetail> productDetails = [];

  DetailResponse(super.errorCode, super.errorMessage);

  factory DetailResponse.fromJson(Map<String, dynamic> json) {
    DetailResponse response = DetailResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );
    var details = json[F_DATA];
    if (details != null) {
      response.productDetails = (details as List)
          .map((e) => ProductDetail.fromJson(e))
          .toList();
    }

    return response;
  }
}

class ProductImage {
  int id = 0;
  int productId = 0;
  String fileName = "";
  String imageUrl = "";
  bool main = false;
  int sortOrder = 0;
  int version = 1;

  ProductImage();

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    ProductImage image = ProductImage();

    image.id = json[F_ID] ?? 0;
    image.productId = json[F_PRODUCT_ID] ?? 0;
    image.fileName = json[F_FILE_NAME] ?? "";
    image.imageUrl = json[F_IMAGE_URL] ?? "";
    image.main = json[F_MAIN] ?? false;
    image.sortOrder = json[F_SORT_ORDER] ?? 0;
    image.version = json[F_VERSION] ?? 1;

    return image;
  }

  // Map<String, dynamic> toJson() {
  //   Map<String, dynamic> map = {
  //     F_ID: id,
  //     F_PRODUCT_ID: productId,
  //     F_FILE_NAME: fileName,
  //     F_MAIN: main,
  //     F_SORT_ORDER: sortOrder,
  //     F_VERSION: version,
  //   };

  //   return map;
  // }

  String url(String baseUrl) => "$baseUrl$imageUrl?v=$version";
}

class ProductDetailResponse extends ActionResult {
  List<ProductImage> images = [];
  Product product = Product();
  List<ProductDetail> productDetails = [];
  ProductDetailResponse(super.errorCode, super.errorMessage);

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    ProductDetailResponse response = ProductDetailResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    final data = json[F_DATA];
    if (data != null) {
      final images = data[F_IMAGES];
      if (images != null) {
        response.images = (images as List)
            .map((e) => ProductImage.fromJson(e))
            .toList();
      }

      if (data[F_PRODUCT] != null) {
        response.product = Product.fromJson(data[F_PRODUCT]);
      }

      final details = data[F_PRODUCT_DETAILS];
      if (details != null) {
        response.productDetails = (details as List)
            .map((e) => ProductDetail.fromJson(e))
            .toList();
      }
    }

    return response;
  }
}

class Favorite {
  int id = 0;
  int accountId = 0;
  int productId = 0;
  DateTime? createdAt;

  Favorite();

  factory Favorite.fromJson(Map<String, dynamic> json) {
    Favorite f = Favorite();

    f.id = json[F_ID] ?? 0;
    f.accountId = json[F_ACCOUNT_ID] ?? 0;
    f.productId = json[F_PRODUCT_ID] ?? 0;
    f.createdAt = json[F_CREATED_AT] != null
        ? DateTime.tryParse(json[F_CREATED_AT].toString())
        : null;

    return f;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_ID: id,
      F_ACCOUNT_ID: accountId,
      F_PRODUCT_ID: productId,
      F_CREATED_AT: createdAt?.toIso8601String(),
    };

    return map;
  }
}

class FavoriteItem {
  int productId = 0;
  String name = '';
  int price = 0;
  String imageUrl = '';
  int quantity = 0;

  FavoriteItem();

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    final f = FavoriteItem();
    f.productId = json[F_PRODUCT_ID] ?? json[F_ID] ?? 0;
    f.name = json[F_NAME] ?? json[F_PRODUCT_NAME] ?? '';
    f.price = (json[F_PRICE] ?? 0).toInt();
    f.imageUrl = json[F_IMAGE_URL] ?? '';
    f.quantity = json[F_QUANTITY] ?? json[F_STOCK] ?? 0;
    return f;
  }

  Product toProduct() {
    final p = Product();
    p.id = productId;
    p.name = name;
    p.price = price;
    p.imageUrl = imageUrl;
    return p;
  }
}

class FavoriteListResponse extends ActionResult {
  List<FavoriteItem> items = [];

  FavoriteListResponse(super.errorCode, super.errorMessage);

  factory FavoriteListResponse.fromJson(Map<String, dynamic> json) {
    final r = FavoriteListResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    r.items = ((json[F_DATA] ?? []) as List)
        .map((e) => FavoriteItem.fromJson(e))
        .toList();
    return r;
  }
}

class FavoriteIdsResponse extends ActionResult {
  List<int> ids = [];

  FavoriteIdsResponse(super.errorCode, super.errorMessage);

  factory FavoriteIdsResponse.fromJson(Map<String, dynamic> json) {
    final r = FavoriteIdsResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    r.ids = ((json[F_DATA] ?? []) as List).map((e) => e as int).toList();
    return r;
  }
}

/// Dùng cho POST/DELETE không trả dữ liệu.
class FavoriteActionResponse {
  String status = '';
  String errorMessage = '';

  FavoriteActionResponse(this.status, this.errorMessage);

  factory FavoriteActionResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] == false) {
      return FavoriteActionResponse('FAIL', json['message'] ?? 'Có lỗi xảy ra');
    }
    return FavoriteActionResponse('OK', '');
  }
}
