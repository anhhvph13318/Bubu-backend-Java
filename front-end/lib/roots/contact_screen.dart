import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wide = MediaQuery.of(context).size.width > 800;

    const items = [
      (Icons.location_on_outlined, 'Địa chỉ', 'Số 1, Đường ABC, Hà Nội'),
      (Icons.phone_outlined, 'Hotline', '0123 456 789'),
      (Icons.mail_outline, 'Email', 'hello@bubushoes.vn'),
      (Icons.schedule_outlined, 'Giờ làm việc', '8:00 – 21:00, mỗi ngày'),
    ];

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(i.$1, color: Color(0xFF14183A)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.$2,
                        style: const TextStyle(
                          color: Color(0xFF6B7090),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i.$3,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    final form = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          TextField(decoration: deco('Họ và tên')),
          const SizedBox(height: 12),
          TextField(
            decoration: deco('Số điện thoại'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(decoration: deco('Nội dung cần tư vấn'), maxLines: 4),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã gửi! Shop sẽ liên hệ bạn sớm.'),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Color(0xFFFF5C8A),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Gửi liên hệ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );

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
                        'LIÊN HỆ',
                        style: const TextStyle(
                          color: Color(0xFFFF5C8A),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Chúng tôi luôn sẵn sàng hỗ trợ bạn',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: info),
                      const SizedBox(width: 32),
                      Expanded(child: form),
                    ],
                  )
                else ...[
                  info,
                  const SizedBox(height: 8),
                  form,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
