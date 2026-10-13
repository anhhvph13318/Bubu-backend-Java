import 'package:bubu_web_client/models/login_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:toastification/toastification.dart';

double sidePadding(double width) =>
    width >= 1400 ? 64 : (width >= 1040 ? 40 : 24);
const primaryColor = Color(0xFF14183A);

bool get isLoggedIn => loginResponse.id > 0;
FlutterSecureStorage secureStorage = const FlutterSecureStorage();
final ValueNotifier<int> cartCount = ValueNotifier<int>(0);
final ValueNotifier<Set<int>> favoriteIds = ValueNotifier(<int>{});
const String baseUrl = "http://localhost:8080";
LoginRequest loginRequest = LoginRequest();
LoginResponse loginResponse = LoginResponse("", "");

Future<void> saveData(String key, String value) async {
  await secureStorage.write(key: key, value: value);
}

Future<String?> readData(String key) async {
  return secureStorage.read(key: key);
}

void showToast(String msg, ToastificationType type) {
  toastification.show(
    title: Text(msg),
    type: type,
    style: ToastificationStyle.flatColored,
    alignment: Alignment.bottomCenter,
    autoCloseDuration: Duration(seconds: 3),
  );
}
