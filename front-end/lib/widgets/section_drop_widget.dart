import 'package:flutter/material.dart';

class SectionDropWidget extends StatelessWidget {
  final String title;
  final String body;
  final bool initiallyOpen;
  const new({
    super.key,
    required this.title,
    required this.body,
    this.initiallyOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE6E3F5))),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyOpen,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: Color(0xFF14183A),
          collapsedIconColor: Color(0xFF14183A),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF14183A),
            ),
          ),
          children: [
            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF6B7090),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
