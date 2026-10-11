import 'package:bubu_web_client/roots/contact_screen.dart';
import 'package:bubu_web_client/roots/home_screen.dart';
import 'package:bubu_web_client/roots/information_screen.dart';
import 'package:bubu_web_client/roots/product_screen_v2.dart';
import 'package:flutter/material.dart';

import '../models/tab_item.dart';
import 'fields.dart';

Map<String, TabItem> pages = {
  HOME_TAB: TabItem(
    icon: Icons.home_outlined,
    label: 'Trang chủ',
    module: "",
    page: HomeScreen(),
  ),
  PRODUCT_TAB: TabItem(
    icon: Icons.inventory_2,
    label: 'Sản phẩm',
    module: "",
    page: ProductScreenV2(),
  ),
  CONTACT_TAB: TabItem(
    icon: Icons.contacts,
    label: 'Liên hệ',
    module: "",
    page: ContactScreen(),
  ),
  INFORMATION_TAB: TabItem(
    icon: Icons.camera_alt_outlined,
    label: 'Về chúng tôi',
    module: "",
    page: InformationScreen(),
  ),
};
