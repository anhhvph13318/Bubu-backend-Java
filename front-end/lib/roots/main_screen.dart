import 'package:bubu_web_client/roots/cart_screen.dart';
import 'package:bubu_web_client/roots/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../models/login_model.dart';
import '../utils/fields.dart';
import '../utils/global.dart';
import '../utils/page_router.dart';
import '../widgets/menu_item_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController pageController = PageController();
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  int selectedIndex = 0;
  List<String> tabs = [];
  void pushToLogin() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  void openCart() {
    navKey.currentState
      ?..popUntil((route) => route.isFirst)
      ..push(MaterialPageRoute(builder: (_) => CartScreen()));
  }

  void logout() async {
    loginResponse = LoginResponse("", "");
    await saveData(F_USER_NAME, "");
    await saveData(F_PASSWORD, "");

    if (!mounted) return;
    setState(() {});
    showToast("Đã đăng xuất", ToastificationType.success);
  }

  @override
  void initState() {
    super.initState();
    tabs = pages.keys.toList();
  }

  void changePage(int index) {
    navKey.currentState?.popUntil((route) => route.isFirst);
    setState(() => selectedIndex = index);

    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            // Navigator lồng nhau: mọi push bên trong sẽ nằm dưới header
            child: Navigator(
              key: navKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => PageView(
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: pages.values.map((e) => e.page).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset("assets/images/logo-preview.png"),
          ),
          Spacer(),
          Row(
            children: List.generate(
              tabs.length,
              (index) => MenuItemWidget(
                label: pages[tabs[index]]!.label,
                selected: selectedIndex == index,
                onTap: () => changePage(index),
              ),
            ),
          ),
          Spacer(),
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          SizedBox(width: 20),
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: CartStore.items,
            builder: (context, items, _) {
              final count = items.fold(0, (s, e) => s + e.qty);
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                backgroundColor: const Color(0xFFFF5C8A),
                child: IconButton(
                  onPressed: openCart,
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
              );
            },
          ),
          SizedBox(width: 20),
          loginResponse.fullName.isNotEmpty
              ? _buildUserMenu()
              : IconButton(onPressed: pushToLogin, icon: Icon(Icons.person)),
        ],
      ),
    );
  }

  Widget _buildUserMenu() {
    final String initial = loginResponse.fullName.isNotEmpty
        ? loginResponse.fullName[0].toUpperCase()
        : "?";
    final String roleLabel = loginResponse.role.toUpperCase() == "CUSTOMER"
        ? "Khách hàng"
        : loginResponse.role;

    return PopupMenuButton<String>(
      tooltip: "",
      offset: const Offset(0, 52),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 260),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        switch (value) {
          case "profile":
            break;
          case "orders":
            break;
          case "logout":
            logout();
            break;
        }
      },
      itemBuilder: (context) => [
        // Phần đầu: thông tin người dùng
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loginResponse.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (loginResponse.email.isNotEmpty)
                        Text(
                          loginResponse.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        _menuItem("profile", Icons.person_outline, "Thông tin tài khoản"),
        _menuItem("orders", Icons.receipt_long_outlined, "Đơn hàng của tôi"),
        const PopupMenuDivider(height: 1),
        _menuItem("logout", Icons.logout, "Đăng xuất", color: Colors.red),
      ],

      // Nút hiển thị trên header
      child: Container(
        padding: const EdgeInsets.only(left: 6, right: 10, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.blue,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                loginResponse.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final Color c = color ?? Colors.black87;
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: c, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
