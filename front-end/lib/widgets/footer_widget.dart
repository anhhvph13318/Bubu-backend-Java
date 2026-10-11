import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  // Bảng màu
  static const _bgTop = Color(0xFF0E2A7A);
  static const _bgBottom = Color(0xFF091B52);
  static const _accent = Color(0xFF5CC8FF);
  static const _textMain = Colors.white;
  static final _textSoft = Colors.white.withOpacity(0.68);

  static const _shop = ['Giày nam', 'Giày nữ', 'Giày trẻ em', 'Khuyến mãi'];
  static const _support = [
    'Hướng dẫn chọn size',
    'Chính sách đổi trả',
    'Vận chuyển',
    'Câu hỏi thường gặp',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBottom],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isWide = w >= 900;
          final hPad = w >= 600 ? 48.0 : 20.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 56, hPad, 24),
                child: isWide ? _wideLayout() : _narrowLayout(w - hPad * 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: _brandBlock()),
        const SizedBox(width: 64),
        Expanded(flex: 2, child: _linkColumn('Mua sắm', _shop)),
        Expanded(flex: 2, child: _linkColumn('Hỗ trợ', _support)),
        Expanded(flex: 3, child: _contactColumn()),
      ],
    );
  }

  Widget _narrowLayout(double available) {
    final twoCols = available >= 480;
    final colWidth = twoCols ? (available - 32) / 2 : available;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _brandBlock(),
        const SizedBox(height: 40),
        Wrap(
          spacing: 32,
          runSpacing: 36,
          children: [
            SizedBox(width: colWidth, child: _linkColumn('Mua sắm', _shop)),
            SizedBox(width: colWidth, child: _linkColumn('Hỗ trợ', _support)),
            SizedBox(width: colWidth, child: _contactColumn()),
          ],
        ),
      ],
    );
  }

  // ---------- Blocks ----------

  Widget _brandBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                color: _bgBottom,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'BuBuShoes',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _textMain,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            'Giày đẹp, đi êm, giá dễ chịu. Chúng tôi làm giày để bạn thoải mái đi bất cứ đâu.',
            style: TextStyle(fontSize: 14.5, height: 1.65, color: _textSoft),
          ),
        ),
        const SizedBox(height: 24),
        const _NewsletterField(),
        const SizedBox(height: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _SocialButton(icon: Icons.facebook_rounded, tooltip: 'Facebook'),
            SizedBox(width: 10),
            _SocialButton(
              icon: Icons.camera_alt_outlined,
              tooltip: 'Instagram',
            ),
            SizedBox(width: 10),
            _SocialButton(
              icon: Icons.play_circle_outline_rounded,
              tooltip: 'YouTube',
            ),
          ],
        ),
      ],
    );
  }

  Widget _linkColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _columnTitle(title),
        const SizedBox(height: 18),
        for (final text in links) _FooterLink(text: text),
      ],
    );
  }

  Widget _contactColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _columnTitle('Liên hệ'),
        const SizedBox(height: 18),
        _contactRow(Icons.phone_rounded, 'Hotline: 1900 0000'),
        _contactRow(Icons.mail_outline_rounded, 'hello@bubushoes.vn'),
        _contactRow(Icons.schedule_rounded, '8:00 – 21:00 mỗi ngày'),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.4, color: _textSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _columnTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _textMain,
      ),
    );
  }
}

// ---------- Small components ----------

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.text}) : bottomGap = 12, small = false;

  final String text;
  final bool small;
  final double bottomGap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomGap),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () {}, // TODO: điều hướng
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 160),
            offset: _hover ? const Offset(0.03, 0) : Offset.zero,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              style: TextStyle(
                fontSize: widget.small ? 13 : 14,
                color: _hover
                    ? FooterWidget._accent
                    : Colors.white.withOpacity(0.68),
              ),
              child: Text(widget.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () {}, // TODO: mở link mạng xã hội
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? FooterWidget._accent
                  : Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _hover ? FooterWidget._bgBottom : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsletterField extends StatelessWidget {
  const _NewsletterField();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 18, right: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: FooterWidget._accent,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Email nhận ưu đãi',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Material(
              color: FooterWidget._accent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {}, // TODO: gửi email đăng ký
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: FooterWidget._bgBottom,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
