import 'package:bubu_web_client/models/product_model.dart';
import 'package:bubu_web_client/roots/product_detail_screen.dart';
import 'package:bubu_web_client/services/product_service.dart';
import 'package:bubu_web_client/widgets/banner_widget.dart';
import 'package:bubu_web_client/widgets/footer_widget.dart';
import 'package:bubu_web_client/widgets/product_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../utils/global.dart';

class HomeScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  TextEditingController emailController = TextEditingController();
  int selectedCategory = 0;
  List<String> categories = [
    'Tất cả',
    'Chạy bộ',
    'Sneaker',
    'Đi làm',
    'Sandal',
  ];

  ProductService service = ProductService();
  List<Product> products = [];

  void getProducts() async {
    final response = await service.getProducts();
    if (!mounted) return;
    if (response.errorMessage.isEmpty) {
      final all = response.products;
      final latest = all.length > 10 ? all.sublist(all.length - 10) : all;

      setState(() => products = latest.reversed.toList());
    } else {
      showToast(response.errorMessage, ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    getProducts();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Color(0xFFF7F5FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = MediaQuery.of(context).size.width >= 900;
          return SingleChildScrollView(
            child: Column(
              children: [
                BannerWidget(wide: wide),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 25,
                          children: [
                            cardDecoration(
                              Icons.local_shipping_outlined,
                              'Giao nhanh toàn quốc',
                              'Nhận hàng sau 1–3 ngày',
                            ),
                            cardDecoration(
                              Icons.sync_alt_rounded,
                              'Đổi size trong 30 ngày',
                              'Không vừa chân, đổi miễn phí',
                            ),
                            cardDecoration(
                              Icons.verified_outlined,
                              'Chính hãng 100%',
                              'Bảo hành đế và đường may',
                            ),
                            cardDecoration(
                              Icons.payments_outlined,
                              'Trả tiền khi nhận hàng',
                              'Kiểm tra giày rồi mới thanh toán',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Sản phẩm mới',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Những đôi giày mới trong tháng.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7090),
                        ),
                      ),
                      SizedBox(height: 20),
                      getListShoes(constraints),
                      SizedBox(height: 20),
                      promoWidget(wide),
                    ],
                  ),
                ),

                SizedBox(height: 20),
                FooterWidget(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget getListShoes(BoxConstraints constraints) {
    return products.isNotEmpty
        ? GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250, // chiều rộng tối đa mỗi card
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return ValueListenableBuilder<Set<int>>(
                valueListenable: favoriteIds,
                builder: (context, ids, _) => ProductCardWidget(
                  product: product,
                  liked: ids.contains(product.id),
                  onLike: () async {
                    final error = await service.toggle(product.id);
                    if (error.isNotEmpty) {
                      showToast(error, ToastificationType.error);
                    }
                  },
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  ),
                ),
              );
            },
          )
        : Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'Chưa có đôi nào trong nhóm này. Hãy thử chọn nhóm khác.',
                style: TextStyle(color: Color(0xFF6B7090)),
              ),
            ),
          );
  }

  Widget promoWidget(bool wide) {
    return Container(
      padding: EdgeInsets.all(wide ? 48 : 28),
      decoration: BoxDecoration(
        color: Color(0xFFFF5C8A),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nhận ngay 100.000đ\ncho đơn đầu tiên',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Đăng ký email để nhận mã giảm giá và báo trước khi có mẫu mới.',
                style: TextStyle(fontSize: 14.5, color: Colors.white70),
              ),
            ],
          ),
          Container(
            width: wide ? 400 : double.infinity,
            height: 54,
            padding: const EdgeInsets.only(left: 20, right: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email của bạn',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Đăng ký'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget cardDecoration(IconData icon, String firstText, String secondText) {
    return SizedBox(
      width: 250,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  secondText,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
