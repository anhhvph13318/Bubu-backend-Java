import 'dart:convert';

import 'package:bubu_web_client/models/product_model.dart';

import '../utils/fields.dart';
import '../utils/global.dart';
import '../utils/http_service.dart';

class ProductService {
  Future<ProductResponse> getProducts() async {
    String url = "$baseUrl/api/products";
    try {
      final response = await httpService.get(url);
      return ProductResponse.fromJson(response);
    } catch (e) {
      return ProductResponse("FAIL", e.toString());
    }
  }

  Future<DetailResponse> getProductDetails() async {
    String url = "$baseUrl/api/product-details";
    try {
      final response = await httpService.get(url);

      return DetailResponse.fromJson(response);
    } catch (e) {
      return DetailResponse("FAIL", e.toString());
    }
  }

  Future<ProductDetailResponse> getDetailProduct(int productID) async {
    final String url = "$baseUrl/api/products/$productID";
    try {
      final response = await httpService.get(url);
      return ProductDetailResponse.fromJson(response);
    } catch (e) {
      return ProductDetailResponse("FAIL", e.toString());
    }
  }

  Future<CategoryResponse> getCategories() async {
    String url = "$baseUrl/api/categories";
    try {
      final response = await httpService.get(url);
      return CategoryResponse.fromJson(response);
    } catch (e) {
      return CategoryResponse("FAIL", e.toString());
    }
  }

  Future<ProductSizeResponse> getSizes() async {
    String url = "$baseUrl/api/sizes";
    try {
      final response = await httpService.get(url);
      return ProductSizeResponse.fromJson(response);
    } catch (e) {
      return ProductSizeResponse("FAIL", e.toString());
    }
  }

  Future<ProductColorResponse> getCoLors() async {
    String url = "$baseUrl/api/colors";
    try {
      final response = await httpService.get(url);
      return ProductColorResponse.fromJson(response);
    } catch (e) {
      return ProductColorResponse("FAIL", e.toString());
    }
  }

  Future<FavoriteListResponse> fetchMine() async {
    final String url = "$baseUrl/api/favorites";
    try {
      final response = await httpService.get(url);
      return FavoriteListResponse.fromJson(response);
    } catch (e) {
      return FavoriteListResponse("FAIL", e.toString());
    }
  }

  Future<FavoriteIdsResponse> fetchIds() async {
    final String url = "$baseUrl/api/favorites/ids";
    try {
      final response = await httpService.get(url);
      return FavoriteIdsResponse.fromJson(response);
    } catch (e) {
      return FavoriteIdsResponse("FAIL", e.toString());
    }
  }

  Future<FavoriteActionResponse> addRemote(int productId) async {
    final String url = "$baseUrl/api/favorites/$productId";
    try {
      final response = await httpService.post(url);
      return FavoriteActionResponse.fromJson(response);
    } catch (e) {
      return FavoriteActionResponse("FAIL", e.toString());
    }
  }

  Future<FavoriteActionResponse> removeRemote(int productId) async {
    final String url = "$baseUrl/api/favorites/$productId";
    try {
      final response = await httpService.delete(url);
      return FavoriteActionResponse.fromJson(response);
    } catch (e) {
      return FavoriteActionResponse("FAIL", e.toString());
    }
  }

  Future<FavoriteListResponse> mergeRemote(List<int> ids) async {
    final String url = "$baseUrl/api/favorites/merge";
    try {
      final response = await httpService.post(url, body: {'productIds': ids});
      return FavoriteListResponse.fromJson(response);
    } catch (e) {
      return FavoriteListResponse("FAIL", e.toString());
    }
  }

  Future<FavoriteListResponse> previewRemote(List<int> ids) async {
    final String url = "$baseUrl/api/favorites/preview";
    try {
      final response = await httpService.post(url, body: {'productIds': ids});
      return FavoriteListResponse.fromJson(response);
    } catch (e) {
      return FavoriteListResponse("FAIL", e.toString());
    }
  }

  Future<Set<int>> _readLocalIds() async {
    try {
      final raw = await readData(F_FAVORITES);
      if (raw == null || raw.isEmpty) return {};
      return (jsonDecode(raw) as List).map((e) => e as int).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeLocalIds(Set<int> ids) async {
    await saveData(F_FAVORITES, jsonEncode(ids.toList()));
  }

  /// Gọi khi mở app, sau đăng nhập và sau đăng xuất.
  Future<void> loadFavoriteIds() async {
    if (isLoggedIn) {
      final res = await fetchIds();
      if (res.errorMessage.isEmpty) {
        favoriteIds.value = res.ids.toSet();
        return;
      }
    }
    favoriteIds.value = await _readLocalIds();
  }

  /// Danh sách cho FavoriteScreen: (items, error)
  Future<(List<FavoriteItem>, String)> getList() async {
    FavoriteListResponse res;
    if (isLoggedIn) {
      res = await fetchMine();
    } else {
      final ids = await _readLocalIds();
      if (ids.isEmpty) {
        favoriteIds.value = {};
        return (<FavoriteItem>[], '');
      }
      res = await previewRemote(ids.toList());
    }

    if (res.errorMessage.isNotEmpty)
      return (<FavoriteItem>[], res.errorMessage);

    // đồng bộ lại trạng thái tim với dữ liệu vừa lấy
    favoriteIds.value = res.items.map((e) => e.productId).toSet();
    return (res.items, '');
  }

  /// Bật/tắt yêu thích. Trả về chuỗi lỗi, rỗng nếu thành công.
  Future<String> toggle(int productId) async {
    final liked = favoriteIds.value.contains(productId);
    final next = {...favoriteIds.value};
    liked ? next.remove(productId) : next.add(productId);

    if (isLoggedIn) {
      final res = liked
          ? await removeRemote(productId)
          : await addRemote(productId);
      if (res.errorMessage.isNotEmpty) return res.errorMessage;
    } else {
      await _writeLocalIds(next);
    }

    favoriteIds.value = next;
    return '';
  }

  /// Gộp yêu thích của khách vào tài khoản sau khi đăng nhập.
  Future<void> syncFavoritesAfterLogin() async {
    final local = await _readLocalIds();
    if (local.isNotEmpty) {
      final res = await mergeRemote(local.toList());
      if (res.errorMessage.isEmpty) await _writeLocalIds({});
    }
    await loadFavoriteIds();
  }
}
