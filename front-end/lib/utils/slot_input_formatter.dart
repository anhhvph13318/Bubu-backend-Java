import 'package:flutter/services.dart';

/// Một phần của mặt nạ nhập liệu, ví dụ phần ngày, phần tháng hay phần giờ.
class MaskSegment {
  /// Ô đầu tiên của phần này.
  final int start;

  /// Số ô của phần này.
  final int length;

  /// Khoảng giá trị hợp lệ.
  final int min;
  final int max;

  const MaskSegment({
    required this.start,
    required this.length,
    required this.min,
    required this.max,
  });

  int get end => start + length;

  bool contains(int slot) => slot >= start && slot < end;
}

/// Nền chung cho các ô nhập theo mặt nạ ô cố định như "__/__/____" hay
/// "__:__:__".
///
/// Mỗi chữ số được ghi đè đúng vào ô con trỏ đang đứng nên có thể sửa riêng
/// từng phần mà không phải xoá hết rồi gõ lại từ đầu.
abstract class SlotInputFormatter extends TextInputFormatter {
  static const String placeholder = '_';

  /// Mặt nạ lúc chưa nhập gì, ví dụ "__/__/____".
  String get mask;

  /// Các phần của mặt nạ, xếp từ trái sang phải.
  List<MaskSegment> get segments;

  /// Vị trí của từng ô số trong mặt nạ.
  late final List<int> offsets = <int>[
    for (int i = 0; i < mask.length; i++)
      if (mask[i] == placeholder) i,
  ];

  int get slotCount => offsets.length;

  /// Chuỗi đã nhập đủ mọi ô hay chưa.
  bool isFilled(String text) =>
      text.length == mask.length && !text.contains(placeholder);

  /// Đưa [text] về đúng dạng mặt nạ, trả về chuỗi rỗng nếu không có chữ số nào.
  String format(String text) => hasDigit(text) ? _rebuild(text).text : '';

  static bool hasDigit(String text) {
    for (int i = 0; i < text.length; i++) {
      if (_isDigit(text, i)) return true;
    }
    return false;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String oldText = oldValue.text;
    final String newText = newValue.text;
    final int start = oldValue.selection.start;
    final int end = oldValue.selection.end;
    final int insertedLength = newText.length - oldText.length + (end - start);

    // Không xác định được thao tác (dán vào ô rỗng, gõ tiếng Việt, tự động
    // điền...) thì dựng lại mặt nạ từ các chữ số đang có.
    if (oldText.length != mask.length ||
        start < 0 ||
        end < start ||
        end > oldText.length ||
        (insertedLength < 0 && start != end) ||
        start + insertedLength > newText.length) {
      return _rebuild(newText);
    }

    final List<String?> slots = _slotsOf(oldText);
    // insertedLength âm nghĩa là vừa xoá bằng phím Backspace hoặc Delete.
    final String typed = insertedLength <= 0
        ? ''
        : _digitsOf(newText.substring(start, start + insertedLength));
    int caret;

    if (typed.isEmpty) {
      // Backspace thì con trỏ mới lùi về trước vị trí cũ, Delete thì đứng yên.
      final bool backward = newValue.selection.start < start;
      int from = start;
      int to = end;
      if (end == start) {
        final int removed = oldText.length - newText.length;
        if (removed <= 0) {
          return _value(slots, _caretSlot(start));
        }
        from = backward ? start - removed : start;
        to = backward ? start : start + removed;
      }
      if (_clear(slots, from, to) > 0) {
        caret = _caretSlot(from);
      } else {
        // Chỉ xoá dấu ngăn cách thì xoá ô số nằm sát bên.
        final int? slot = backward ? _slotBefore(from) : _slotIn(to);
        if (slot != null) slots[slot] = null;
        caret = slot ?? _caretSlot(from);
      }
    } else {
      if (end > start) _clear(slots, start, end);
      final int from = _caretSlot(start);
      caret = _write(slots, from, typed);
      correct(slots, from, caret);
    }

    return _value(slots, caret);
  }

  /// Đưa từng phần về khoảng hợp lệ sau khi vừa ghi các ô [from, to).
  void correct(List<String?> slots, int from, int to) {
    for (final MaskSegment segment in segments) {
      final int? value = valueOf(slots, segment);
      if (value == null || (value >= segment.min && value <= segment.max)) {
        continue;
      }
      final int last = segment.end - 1;
      if (from <= last && to > last) {
        // Vừa gõ xong cả phần này nhưng vượt khoảng cho phép.
        setValue(slots, segment, value.clamp(segment.min, segment.max));
      } else if (from < segment.end && to > segment.start) {
        // Mới sửa số đầu, xoá các số còn lại để người dùng gõ tiếp.
        for (int i = to; i < segment.end; i++) {
          slots[i] = null;
        }
      }
    }
  }

  /// Con trỏ đang đứng giữa chừng một phần (chưa gõ xong phần đó).
  bool isMidSegment(int slot) {
    for (final MaskSegment segment in segments) {
      if (segment.contains(slot) && slot > segment.start) return true;
    }
    return false;
  }

  int? valueOf(List<String?> slots, MaskSegment segment) {
    final StringBuffer buffer = StringBuffer();
    for (int i = segment.start; i < segment.end; i++) {
      if (slots[i] == null) return null;
      buffer.write(slots[i]);
    }
    return int.parse(buffer.toString());
  }

  void setValue(List<String?> slots, MaskSegment segment, int value) {
    final String text = value.toString().padLeft(segment.length, '0');
    for (int i = 0; i < segment.length; i++) {
      slots[segment.start + i] = text[i];
    }
  }

  /// Dựng lại toàn bộ mặt nạ từ các chữ số có trong [text].
  TextEditingValue _rebuild(String text) {
    final List<String?> slots = List<String?>.filled(slotCount, null);
    final String digits = _digitsOf(text);
    final int caret = _write(slots, 0, digits);
    if (digits.isNotEmpty) correct(slots, 0, caret);
    return _value(slots, caret);
  }

  /// Ghi [digits] từ ô [slot] trở đi, trả về ô kế tiếp của con trỏ.
  int _write(List<String?> slots, int slot, String digits) {
    if (digits.length == 1 && slot < slotCount) {
      final MaskSegment? segment = _segmentAt(slot);
      // Gõ 1 số không thể đứng đầu phần này thì tự thêm 0 rồi nhảy sang phần
      // kế bên: giờ "5" -> "05", tháng "3" -> "03".
      if (segment != null &&
          segment.length == 2 &&
          segment.start == slot &&
          int.parse(digits) > segment.max ~/ 10) {
        slots[slot] = '0';
        slots[slot + 1] = digits;
        return slot + 2;
      }
    }
    for (int i = 0; i < digits.length && slot < slotCount; i++) {
      slots[slot] = digits[i];
      slot++;
    }
    return slot;
  }

  /// Xoá các ô số nằm trong đoạn [from, to), trả về số ô đã đi qua.
  int _clear(List<String?> slots, int from, int to) {
    int count = 0;
    for (int i = 0; i < slotCount; i++) {
      if (offsets[i] >= from && offsets[i] < to) {
        slots[i] = null;
        count++;
      }
    }
    return count;
  }

  List<String?> _slotsOf(String text) {
    return List<String?>.generate(slotCount, (int i) {
      final int offset = offsets[i];
      return _isDigit(text, offset) ? text[offset] : null;
    });
  }

  TextEditingValue _value(List<String?> slots, int slot) {
    final StringBuffer buffer = StringBuffer();
    int index = 0;
    for (int i = 0; i < mask.length; i++) {
      final String char = mask[i];
      buffer.write(char == placeholder ? slots[index++] ?? placeholder : char);
    }
    final int offset = slot < slotCount ? offsets[slot] : mask.length;
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }

  MaskSegment? _segmentAt(int slot) {
    for (final MaskSegment segment in segments) {
      if (segment.contains(slot)) return segment;
    }
    return null;
  }

  /// Ô số đầu tiên tính từ [offset] trở đi, [slotCount] nếu đã hết ô.
  int _caretSlot(int offset) {
    for (int i = 0; i < slotCount; i++) {
      if (offsets[i] >= offset) return i;
    }
    return slotCount;
  }

  /// Ô số nằm ngay tại [offset].
  int? _slotIn(int offset) {
    for (int i = 0; i < slotCount; i++) {
      if (offsets[i] == offset) return i;
    }
    return null;
  }

  /// Ô số cuối cùng nằm trước [offset].
  int? _slotBefore(int offset) {
    for (int i = slotCount - 1; i >= 0; i--) {
      if (offsets[i] < offset) return i;
    }
    return null;
  }

  String _digitsOf(String text) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (_isDigit(text, i)) buffer.write(text[i]);
    }
    return buffer.toString();
  }

  static bool _isDigit(String text, int index) {
    if (index < 0 || index >= text.length) return false;
    final int code = text.codeUnitAt(index);
    return code >= 0x30 && code <= 0x39;
  }
}
