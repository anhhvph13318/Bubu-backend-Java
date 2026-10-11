import 'package:bubu_web_client/models/action_result.dart';

import '../utils/fields.dart';
import '../utils/string_utils.dart';

class LoginRequest {
  String username = "";
  String password = "";

  LoginRequest();

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    LoginRequest request = LoginRequest();

    request.username = json[F_USERNAME] ?? "";
    request.password = json[F_PASSWORD] ?? "";

    return request;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {F_USERNAME: username, F_PASSWORD: password};

    return map;
  }
}

class LoginResponse extends ActionResult {
  int id = 0;
  String username = "";
  String fullName = "";
  bool active = false;
  String role = "";
  String email = "";
  String phone = "";

  LoginResponse(super.errorCode, super.errorMessage);

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    LoginResponse response = LoginResponse(
      nvl(json[F_ERROR_CODE]),
      nvl(json[F_ERROR_MESSAGE]),
    );

    final data = json[F_DATA];
    if (data is Map<String, dynamic>) {
      response.id = data[F_ID] ?? 0;
      response.username = data[F_USERNAME] ?? "";
      response.fullName = data[F_FULL_NAME] ?? "";
      response.active = data[F_ACTIVE] ?? false;
      response.role = data[F_ROLE] ?? "";
      response.email = data[F_EMAIL] ?? "";
      response.phone = data[F_PHONE] ?? "";
    }

    return response;
  }
}

// Map<String, dynamic> toJson() {
//   Map<String, dynamic> map = {
//     F_ID: id,
//     F_USERNAME: username,
//     F_FULL_NAME: fullName,
//     F_ACTIVE: active,
//     F_ROLE: role,
//     F_EMAIL: email,
//     F_PHONE: phone,
//   };

//   return map;
// }

class RegisterRequest {
  String username = "";
  String password = "";

  // Không bắt buộc; nếu gửi thì phải khớp với password
  String confirmPassword = "";
  String fullName = "";
  String email = "";
  String phone = "";

  RegisterRequest();

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    RegisterRequest request = RegisterRequest();

    request.username = json[F_USERNAME] ?? "";
    request.password = json[F_PASSWORD] ?? "";
    request.confirmPassword = json[F_CONFIRM_PASSWORD] ?? "";
    request.fullName = json[F_FULL_NAME] ?? "";
    request.email = json[F_EMAIL] ?? "";
    request.phone = json[F_PHONE] ?? "";

    return request;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      F_USERNAME: username,
      F_PASSWORD: password,
      F_FULL_NAME: fullName,
      F_EMAIL: email,
      F_PHONE: phone,
    };

    // confirmPassword không bắt buộc, chỉ gửi khi có giá trị
    if (confirmPassword.isNotEmpty) {
      map[F_CONFIRM_PASSWORD] = confirmPassword;
    }

    return map;
  }
}
