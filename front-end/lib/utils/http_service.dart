import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'http_client_factory_web.dart';

final HttpService httpService = HttpService();

class HttpService {
  final JsonDecoder _decoder = const JsonDecoder();
  final JsonEncoder _encoder = const JsonEncoder();

  // On web this is a BrowserClient with withCredentials = true so the
  // browser attaches cross-origin cookies; on other platforms it's the
  // default client and cookies are handled manually below.
  final http.Client _client = createHttpClient();

  Map<String, String> headers = {"content-type": "application/json"};
  Map<String, String> cookies = {};

  void _updateCookie(http.Response response) {
    String? allSetCookie = response.headers['set-cookie'];

    if (allSetCookie != null) {
      var setCookies = allSetCookie.split(',');

      for (var setCookie in setCookies) {
        var cookies = setCookie.split(';');

        for (var cookie in cookies) {
          _setCookie(cookie);
        }
      }

      headers['cookie'] = _generateCookieHeader();
    }
  }

  void _setCookie(String? rawCookie) {
    if (rawCookie != null) {
      var keyValue = rawCookie.split('=');
      if (keyValue.length == 2) {
        var key = keyValue[0].trim();
        var value = keyValue[1];

        // ignore keys that aren't cookies
        if (key == 'path' || key == 'expires') return;

        cookies[key] = value;
      }
    }
  }

  String _generateCookieHeader() {
    String cookie = "";

    for (var key in cookies.keys) {
      if (cookie.isNotEmpty) cookie += ";";
      cookie += "$key=${cookies[key]!}";
    }

    return cookie;
  }

  Future<dynamic> get(String url, {body}) async {
    try {
      http.Response response;

      if (body == null) {
        response = await _client.get(Uri.parse(url), headers: headers);
      } else {
        final request = http.Request('GET', Uri.parse(url))
          ..headers.addAll(headers)
          ..body = body is String ? body : _encoder.convert(body);

        final streamed = await _client.send(request);
        response = await http.Response.fromStream(streamed);
      }

      final String res = utf8.decode(response.bodyBytes);
      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode == 200 || statusCode == 400) {
        try {
          if (res.isNotEmpty) {
            return _decoder.convert(res);
          } else {
            return _decoder.convert("{}");
          }
        } catch (e) {
          throw Exception("Có lỗi xảy ra khi đọc dữ liệu, hãy thử lại!");
        }
      } else {
        throw Exception("Error while fetching data");
      }
    } on http.ClientException {
      throw Exception("Lỗi kết nối mạng!");
    } on Exception {
      throw Exception("Error while fetching data");
    }
  }

  Future<dynamic> post(String url, {body, encoding}) async {
    String msg = body == null ? "{}" : _encoder.convert(body);
    try {
      http.Response response = await _client.post(
        Uri.parse(url),
        body: msg,
        headers: headers,
        encoding: encoding,
      );

      final String res = utf8.decode(response.bodyBytes);
      final int statusCode = response.statusCode;

      _updateCookie(response);

      final bool hasApiBody = statusCode >= 200 && statusCode < 600;

      if (hasApiBody) {
        try {
          if (res.isNotEmpty) {
            return _decoder.convert(res);
          } else {
            return _decoder.convert("{}");
          }
        } catch (e, stack) {
          if (kDebugMode) {
            print("stack: $stack");
          }
          throw Exception("Có lỗi xảy ra khi đọc dữ liệu, hãy thử lại!");
        }
      } else {
        throw Exception("Error while fetching data ($statusCode)");
      }
    } on http.ClientException {
      throw Exception("Lỗi kết nối mạng!");
    }
  }

  Future<dynamic> delete(String url, {body, encoding}) async {
    try {
      http.Response response = await _client.delete(
        Uri.parse(url),
        body: body == null ? null : _encoder.convert(body),
        headers: headers,
        encoding: encoding,
      );

      final String res = utf8.decode(response.bodyBytes);
      final int statusCode = response.statusCode;

      _updateCookie(response);

      final bool hasApiBody = statusCode >= 200 && statusCode < 600;

      if (hasApiBody) {
        try {
          if (res.isNotEmpty) {
            return _decoder.convert(res);
          } else {
            return _decoder.convert("{}");
          }
        } catch (e, stack) {
          if (kDebugMode) {
            print("stack: $stack");
          }
          throw Exception("Có lỗi xảy ra khi đọc dữ liệu, hãy thử lại!");
        }
      } else {
        throw Exception("Error while fetching data ($statusCode)");
      }
    } on http.ClientException {
      throw Exception("Lỗi kết nối mạng!");
    }
  }

  Future<dynamic> put(String url, {body, encoding}) async {
    String msg = body == null ? "{}" : _encoder.convert(body);
    try {
      http.Response response = await _client.put(
        Uri.parse(url),
        body: msg,
        headers: headers,
        encoding: encoding,
      );

      final String res = utf8.decode(response.bodyBytes);
      final int statusCode = response.statusCode;

      _updateCookie(response);

      final bool hasApiBody = statusCode >= 200 && statusCode < 600;

      if (hasApiBody) {
        try {
          if (res.isNotEmpty) {
            return _decoder.convert(res);
          } else {
            return _decoder.convert("{}");
          }
        } catch (e, stack) {
          if (kDebugMode) {
            print("stack: $stack");
          }
          throw Exception("Có lỗi xảy ra khi đọc dữ liệu, hãy thử lại!");
        }
      } else {
        throw Exception("Error while fetching data ($statusCode)");
      }
    } on http.ClientException {
      throw Exception("Lỗi kết nối mạng!");
    }
  }
  // Future<dynamic> put(String url, {body, encoding}) async {
  //   http.Response response = await http
  //       .put(Uri.parse(url),
  //           body: _encoder.convert(body), headers: headers, encoding: encoding)
  //       .onError((error, stackTrace) => throw Exception(error));

  //   final String res = response.body;
  //   final int statusCode = response.statusCode;

  //   _updateCookie(response);

  //   if (statusCode == 200 || statusCode == 400) {
  //     try {
  //       if (res.isNotEmpty) {
  //         return _decoder.convert(res);
  //       } else {
  //         return _decoder.convert("{}");
  //       }
  //     } catch (e, stack) {
  //       print("stack: ${stack}");
  //       throw Exception("Có lỗi xảy ra khi đọc dữ liệu, hãy thử lại!");
  //     }
  //   } else {
  //     throw Exception("Error while fetching data");
  //   }
  // }
}
