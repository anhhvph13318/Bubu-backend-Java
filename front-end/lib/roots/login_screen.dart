import 'package:bubu_web_client/models/login_model.dart';
import 'package:bubu_web_client/roots/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../services/admin_service.dart';
import '../utils/fields.dart';
import '../utils/global.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isRegisterMode = false; // false = Đăng nhập, true = Đăng ký
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool rememberPassword = false;
  bool isLoginProcess = false;
  bool isRegisterProcess = false;
  bool reconnect = false;
  bool loginBackground = false;

  // Đăng nhập
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Đăng ký
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final regUsernameController = TextEditingController();
  final regPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  AdminService service = AdminService();
  RegisterRequest registerRequest = RegisterRequest();
  KeyEventResult keyboardPressHandler(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      isRegisterMode ? register() : login();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void login() async {
    if (!_loginKey.currentState!.validate()) return;
    if (isLoginProcess) return;

    loginRequest.username = usernameController.text.trim();
    loginRequest.password = passwordController.text;

    setState(() => isLoginProcess = true);

    final response = await AdminService().login(loginRequest);

    if (!mounted) return;
    setState(() => isLoginProcess = false);

    // Lỗi từ server (sai mật khẩu, lỗi mạng...)
    if (response.errorMessage.isNotEmpty) {
      setState(() => loginBackground = false);
      passwordController.clear();
      showToast(response.errorMessage, ToastificationType.error);
      return;
    }

    // Tài khoản ADMIN không được đăng nhập ở trang này
    if (response.role.toUpperCase() == "ADMIN") {
      setState(() => loginBackground = false);
      passwordController.clear();
      await saveData(F_USERNAME, "");
      await saveData(F_PASSWORD, "");
      showToast(
        "Tài khoản quản trị không được đăng nhập ở trang này",
        ToastificationType.error,
      );
      return;
    }

    // Tài khoản bị khóa
    if (!response.active) {
      setState(() => loginBackground = false);
      passwordController.clear();
      showToast("Tài khoản đã bị khóa", ToastificationType.error);
      return;
    }

    // Đăng nhập thành công
    loginResponse = response;
    TextInput.finishAutofillContext();

    if (rememberPassword) {
      await saveData(F_USERNAME, loginRequest.username);
      await saveData(F_PASSWORD, loginRequest.password);
    } else {
      await saveData(F_USERNAME, "");
      await saveData(F_PASSWORD, "");
    }

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));
    }
  }

  void register() async {
    if (!_registerKey.currentState!.validate()) return;
    if (isRegisterProcess) return;

    registerRequest.fullName = fullNameController.text.trim();
    registerRequest.email = emailController.text.trim();
    registerRequest.phone = phoneController.text.trim();
    registerRequest.username = regUsernameController.text.trim();
    registerRequest.password = regPasswordController.text;
    registerRequest.confirmPassword = confirmPasswordController.text;

    setState(() => isRegisterProcess = true);

    final response = await service.registerLogIn(registerRequest);

    if (!mounted) return;
    setState(() => isRegisterProcess = false);

    if (response.errorMessage.isNotEmpty) {
      showToast(response.errorMessage, ToastificationType.error);
      return;
    }

    // Đăng ký thành công -> quay về form đăng nhập
    final registeredUsername = registerRequest.username;

    // Xóa dữ liệu form đăng ký
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    regUsernameController.clear();
    regPasswordController.clear();
    confirmPasswordController.clear();
    _registerKey.currentState?.reset();

    showToast(
      "Đăng ký thành công! Vui lòng đăng nhập.",
      ToastificationType.success,
    );

    setState(() {
      isRegisterMode = false;
      passwordVisible = false;
      confirmPasswordVisible = false;
    });

    // Điền sẵn tên đăng nhập, để người dùng chỉ cần nhập mật khẩu
    usernameController.text = registeredUsername;
    passwordController.clear();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    regUsernameController.dispose();
    regPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return loginBackground
        ? Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/skysoft_logo_ok_h80.png',
                    fit: BoxFit.fitHeight,
                  ),
                  SizedBox(height: 30),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          )
        : Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/images_back.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Focus(
              autofocus: true,
              onKeyEvent: keyboardPressHandler,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: loginCard(),
              ),
            ),
          );
  }

  Widget loginCard() {
    return Center(
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          height: isRegisterMode ? 600 : 500,
          child: Row(
            children: [
              Expanded(
                child: SizedBox.expand(
                  child: Image.asset(
                    'assets/images/images_back.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Center(
                    child: SingleChildScrollView(
                      child: isRegisterMode ? registerForm() : loginForm(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== ĐĂNG NHẬP =====================
  Widget loginForm() {
    return Form(
      key: _loginKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đăng nhập',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng nhập thông tin đăng nhập của bạn',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên đăng nhập';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: usernameController,
              autofillHints: [AutofillHints.username],
              decoration: InputDecoration(
                labelText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: passwordController,
              obscureText: !passwordVisible,
              autofillHints: [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    passwordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      passwordVisible = !passwordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: rememberPassword,
                  onChanged: (value) {
                    setState(() {
                      rememberPassword = value!;
                    });
                  },
                ),
                Text('Ghi nhớ đăng nhập'),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  isRegisterMode ? register() : login();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoginProcess
                    ? SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Chưa có tài khoản?'),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isRegisterMode = true;
                      passwordVisible = false;
                    });
                  },
                  child: Text(
                    'Đăng ký ngay',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget registerForm() {
    return Form(
      key: _registerKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đăng ký',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Điền thông tin để tạo tài khoản',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),

            // Họ và tên
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: fullNameController,
                    keyboardType: TextInputType.name,
                    autofillHints: [AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      final regex = RegExp(
                        r'^[\w\.\-+]+@([\w\-]+\.)+[\w\-]{2,}$',
                      );
                      if (!regex.hasMatch(value.trim())) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
              ],
            ),

            // Email
            SizedBox(height: 12),

            // Số điện thoại + Tên đăng nhập
            TextFormField(
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nhập số điện thoại';
                }
                // SĐT Việt Nam: 0xxxxxxxxx hoặc +84xxxxxxxxx
                if (!RegExp(r'^(0|\+84)\d{9}$').hasMatch(value.trim())) {
                  return 'SĐT không hợp lệ';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                LengthLimitingTextInputFormatter(12),
              ],
              autofillHints: [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nhập tên đăng nhập';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: regUsernameController,
              autofillHints: [AutofillHints.newUsername],
              decoration: InputDecoration(
                labelText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 12),

            // Mật khẩu + Xác nhận mật khẩu
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nhập mật khẩu';
                }
                if (value.length < 6) {
                  return 'Tối thiểu 6 ký tự';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: regPasswordController,
              obscureText: !passwordVisible,
              autofillHints: [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    passwordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      passwordVisible = !passwordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nhập lại mật khẩu';
                }
                if (value != regPasswordController.text) {
                  return 'Không khớp';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: confirmPasswordController,
              obscureText: !confirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                prefixIcon: Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    confirmPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      confirmPasswordVisible = !confirmPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 16),

            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isRegisterProcess
                    ? SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        'Đăng ký',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Đã có tài khoản?'),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isRegisterMode = false;
                      passwordVisible = false;
                      confirmPasswordVisible = false;
                    });
                  },
                  child: Text(
                    'Đăng nhập',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
