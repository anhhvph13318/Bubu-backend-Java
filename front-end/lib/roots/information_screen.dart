import 'package:flutter/material.dart';

class InformationScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wide = MediaQuery.of(context).size.width > 800;

    Widget value(IconData ic, String t, String d) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFFF5C8A),
            child: Icon(ic, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            t,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            d,
            style: const TextStyle(color: Color(0xFF6B7090), height: 1.5),
          ),
        ],
      ),
    );

    final values = [
      value(
        Icons.verified_outlined,
        'Chất lượng',
        'Mỗi đôi giày đều được kiểm tra kỹ trước khi giao đến tay bạn.',
      ),
      value(
        Icons.sell_outlined,
        'Giá tốt',
        'Thanh lý trực tiếp, giảm đến 47% mà vẫn giữ chất lượng.',
      ),
      value(
        Icons.favorite_border,
        'Tận tâm',
        'Tư vấn size miễn phí, đổi trả trong 7 ngày nếu chưa vừa ý.',
      ),
    ];

    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VỀ CHÚNG TÔI',
                        style: const TextStyle(
                          color: Color(0xFFFF5C8A),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Be confident in steps',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: const Text(
                    'BuBuShoes ra đời với mong muốn giúp mọi người có được đôi giày '
                    'đẹp, êm chân và giá hợp lý. Từ giày thể thao, sneaker đến '
                    'hàng nội địa Trung, chúng tôi chọn lọc từng mẫu để bạn tự '
                    'tin trong từng bước đi mỗi ngày.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: Color(0xFF14183A),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (wide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < values.length; i++) ...[
                          if (i > 0) const SizedBox(width: 16),
                          Expanded(child: values[i]),
                        ],
                      ],
                    ),
                  )
                else
                  for (final v in values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: v,
                    ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8E4FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 32,
                    runSpacing: 20,
                    children: [
                      Column(
                        children: [
                          Text(
                            '10K+',
                            style: TextStyle(
                              color: Color(0xFF14183A),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Khách hàng',
                            style: TextStyle(color: Color(0xFF6B7090)),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '500+',
                            style: TextStyle(
                              color: Color(0xFF14183A),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mẫu giày',
                            style: TextStyle(color: Color(0xFF6B7090)),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '4.9★',
                            style: TextStyle(
                              color: Color(0xFF14183A),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Đánh giá',
                            style: TextStyle(color: Color(0xFF6B7090)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
