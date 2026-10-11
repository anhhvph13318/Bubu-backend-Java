import '../models/login_model.dart';
import '../utils/global.dart';
import '../utils/http_service.dart';

class AdminService {
  Future<LoginResponse> registerLogIn(RegisterRequest request) async {
    String url = "$baseUrl/api/auth/register";
    try {
      final response = await httpService.post(url, body: request);
      return LoginResponse.fromJson(response);
    } catch (e) {
      return LoginResponse("FAIL", e.toString());
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    String url = "$baseUrl/api/auth/login";
    try {
      final response = await httpService.post(url, body: request);
      return LoginResponse.fromJson(response);
    } catch (e) {
      return LoginResponse("FAIL", e.toString());
    }
  }
}
