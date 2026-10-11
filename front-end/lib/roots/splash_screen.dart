import 'package:flutter/material.dart';

import 'package:bubu_web_client/roots/main_screen.dart';
import 'package:toastification/toastification.dart';

import '../services/admin_service.dart';
import '../utils/fields.dart';
import '../utils/global.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void initApp() async {
    String username = await readData(F_USERNAME) ?? "";
    String password = await readData(F_PASSWORD) ?? "";

    if (username.isNotEmpty && password.isNotEmpty) {
      loginRequest.username = username;
      loginRequest.password = password;
      final response = await AdminService().login(loginRequest);
      if (response.errorMessage.isEmpty) {
        loginResponse = response;
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        showToast(response.errorMessage, ToastificationType.error);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo-preview.png',
              fit: BoxFit.fitHeight,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
