import 'slot_input_formatter.dart';

/// Ô nhập tháng dạng ô cố định "__/____".
class MonthInputFormatter extends SlotInputFormatter {
  static const String emptyMask = '__/____';

  @override
  String get mask => emptyMask;

  @override
  List<MaskSegment> get segments => const <MaskSegment>[
    MaskSegment(start: 0, length: 2, min: 1, max: 12), // tháng
    MaskSegment(start: 2, length: 4, min: 1, max: 9999), // năm
  ];
}
