import 'slot_input_formatter.dart';

/// Ô nhập giờ dạng ô cố định "__:__:__".
class TimeInputFormatter extends SlotInputFormatter {
  static const String emptyMask = '__:__:__';

  @override
  String get mask => emptyMask;

  @override
  List<MaskSegment> get segments => const <MaskSegment>[
    MaskSegment(start: 0, length: 2, min: 0, max: 23), // giờ
    MaskSegment(start: 2, length: 2, min: 0, max: 59), // phút
    MaskSegment(start: 4, length: 2, min: 0, max: 59), // giây
  ];
}
