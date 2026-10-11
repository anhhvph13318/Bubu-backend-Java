import 'package:flutter/material.dart';

import '../utils/global.dart';

class BannerWidget extends StatelessWidget {
  final bool wide;
  const new({super.key, required this.wide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: wide ? 56 : 32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Bộ sưu tập mới giảm đến 30%',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Bước nhẹ tênh,\nđi xa cùng BuBu.',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    letterSpacing: -1.5,
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 400,
                  child: Text(
                    'Giày êm chân, form gọn, màu sắc vui mắt. Chọn một đôi và mang theo suốt ngày dài mà không mỏi.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF6B7090),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  height: 45,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Mua ngay',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor, width: 1.5),
                            padding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Xem bộ sưu tập',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 400,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: wide ? 450 : 290,
                    height: wide ? 450 : 290,
                    decoration: BoxDecoration(
                      color: Color(0xffff5c8a),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Positioned(
                    right: wide ? 20 : 0,
                    top: wide ? 30 : 10,
                    child: Container(
                      width: wide ? 90 : 60,
                      height: wide ? 90 : 60,
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: wide ? 10 : 0,
                    bottom: wide ? 40 : 20,
                    child: Container(
                      width: wide ? 56 : 40,
                      height: wide ? 56 : 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: -0.35,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=900',
                        width: wide ? 350 : 250,
                        height: wide ? 350 : 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
