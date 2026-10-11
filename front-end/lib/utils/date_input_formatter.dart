import 'slot_input_formatter.dart';

/// Ô nhập ngày dạng ô cố định "__/__/____".
class DateInputFormatter extends SlotInputFormatter {
  static const String emptyMask = '__/__/____';

  @override
  String get mask => emptyMask;

  @override
  List<MaskSegment> get segments => const <MaskSegment>[
    MaskSegment(start: 0, length: 2, min: 1, max: 31), // ngày
    MaskSegment(start: 2, length: 2, min: 1, max: 12), // tháng
    MaskSegment(start: 4, length: 4, min: 1, max: 9999), // năm
  ];

  @override
  void correct(List<String?> slots, int from, int to) {
    super.correct(slots, from, to);

    // Đang gõ dở một phần thì chưa xét tới ngày cuối tháng.
    if (isMidSegment(to)) return;

    // Đủ ngày, tháng, năm thì cắt theo số ngày thật: 31/02/2025 -> 28/02/2025.
    final int? day = valueOf(slots, segments[0]);
    final int? month = valueOf(slots, segments[1]);
    final int? year = valueOf(slots, segments[2]);
    if (day == null || month == null || year == null) return;
    final int lastDay = DateTime(year, month + 1, 0).day;
    if (day > lastDay) setValue(slots, segments[0], lastDay);
  }
}
