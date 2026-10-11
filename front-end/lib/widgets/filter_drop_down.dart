import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FilterDropDown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const FilterDropDown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEEEBFF) : const Color(0xFFF7F5FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? const Color(0xFF5B4BFF) : const Color(0xFFE3E0F5),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF14183A),
          ),
          selectedItemBuilder: (context) => [
            _selectedRow(
              icon,
              'Tất cả $label'
                      .toLowerCase()
                      .replaceFirst('tất cả ', '$label: ')
                      .isEmpty
                  ? ''
                  : '$label: Tất cả',
            ),
            ...items.map((e) => _selectedRow(icon, '$label: ${itemLabel(e)}')),
          ],
          items: [
            DropdownMenuItem<T?>(
              value: null,
              child: Text(
                'Tất cả $label'.toLowerCase().replaceRange(0, 1, 'T'),
              ),
            ),
            ...items.map(
              (e) => DropdownMenuItem<T?>(value: e, child: Text(itemLabel(e))),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _selectedRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5B4BFF)),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
