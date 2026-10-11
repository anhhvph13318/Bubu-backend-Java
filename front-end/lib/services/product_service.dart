import 'dart:convert';
import 'dart:developer';

import 'package:bubu_web_client/models/product_model.dart';

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
      log(jsonEncode(response));
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
}
