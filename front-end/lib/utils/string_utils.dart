// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const String DATE_TIME_FORMAT = "dd/MM/yyyy HH:mm:ss";
const String DATE_FORMAT = "dd/MM/yyyy";
const String TIME_FORMAT = "HH:mm:ss";
const String DATE_TIME_TZ_FORMAT = "yyyy-MM-dd'T'HH:mm:ssZZ";

final String CHARFORM_NOHORN =
    "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiii"
    "ooooooooooooooooouuuuuuuuuuuyyyyyd"
    "AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIO"
    "OOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD"
    "AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz"; //extra

final String CHARFORM_UNICODE =
    "àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩị"
    "òóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ"
    "ÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒ"
    "ÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ"
    "ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž";

String removeVietnameseAccents(String text) {
  final Map<String, String> vietnameseMap = {
    'á': 'a',
    'à': 'a',
    'ả': 'a',
    'ã': 'a',
    'ạ': 'a',
    'ă': 'a',
    'ắ': 'a',
    'ằ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'ặ': 'a',
    'â': 'a',
    'ấ': 'a',
    'ầ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ậ': 'a',
    'é': 'e',
    'è': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ẹ': 'e',
    'ê': 'e',
    'ế': 'e',
    'ề': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ệ': 'e',
    'í': 'i',
    'ì': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ị': 'i',
    'ó': 'o',
    'ò': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ọ': 'o',
    'ô': 'o',
    'ố': 'o',
    'ồ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ộ': 'o',
    'ơ': 'o',
    'ớ': 'o',
    'ờ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ợ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ụ': 'u',
    'ư': 'u',
    'ứ': 'u',
    'ừ': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ự': 'u',
    'ý': 'y',
    'ỳ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'ỵ': 'y',
    'đ': 'd',
    'Đ': 'D',
  };

  return text.split('').map((char) => vietnameseMap[char] ?? char).join('');
}

String generateCheckSum(String input) {
  int crc = 0xFFFF; // initial value
  int polynomial = 0x1021; // 0001 0000 0010 0001  (0, 5, 12)
  List<int> bytes = input.codeUnits;
  for (int b in bytes) {
    for (int i = 0; i < 8; i++) {
      bool bit = ((b >> (7 - i) & 1) == 1);
      bool c15 = ((crc >> 15 & 1) == 1);
      crc <<= 1;
      if (c15 ^ bit) crc ^= polynomial;
    }
  }
  crc &= 0xffff;
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

String generatePaymentQRCode(
  String bin,
  String bankAccountNo,
  int amount,
  String message,
) {
  String paymentAmount = amount.toString();

  String bankAccountBuilder =
      "00${bin.length.toString().padLeft(2, '0')}${bin}01${bankAccountNo.length.toString().padLeft(2, '0')}$bankAccountNo";

  String stringGUIDBuilder =
      "0010A00000072701${bankAccountBuilder.length.toString().padLeft(2, '0')}${bankAccountBuilder}0208QRIBFTTA";

  String informationBuilder =
      "38${stringGUIDBuilder.length.toString().padLeft(2, '0')}$stringGUIDBuilder";

  String part21Builder =
      "08${message.length.toString().padLeft(2, '0')}$message";

  String amountQRString =
      "530370454${paymentAmount.length.toString().padLeft(2, '0')}${paymentAmount}5802VN62${part21Builder.length.toString().padLeft(2, '0')}$part21Builder";

  String builder = "000201010212$informationBuilder${amountQRString}6304";

  String qrcodeContent = builder + generateCheckSum(builder).toUpperCase();

  return qrcodeContent;
}

String nvl(String? input) {
  //return input == null ? "" : input;
  return input ?? "";
}

int nvlInt(dynamic input) {
  return input ?? 0;
}

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

String obfuscate(String input, String hideChar, int keepChars) {
  if (input.length > keepChars) {
    String val =
        createRepeatChars(hideChar, input.length - keepChars) +
        input.substring(input.length - keepChars);

    return val;
  }

  return input;
}

/// check if the string contains only numbers
bool isNumeric(String? str) {
  if (str == null) {
    return false;
  }

  RegExp numeric = RegExp(r'^-?[0-9]+$');
  return numeric.hasMatch(str);
}

String createRepeatChars(String char, int n) {
  String val = "";
  for (int i = 0; i < n; i++) {
    val += char;
  }

  return val;
}

extension RemoveAccentsOnString on String {
  String get removeAccents => splitMapJoin(
    '',
    onNonMatch: (char) => char.isNotEmpty && CHARFORM_UNICODE.contains(char)
        ? CHARFORM_NOHORN[CHARFORM_UNICODE.indexOf(char)]
        : char,
  );
}

extension KeepDigitsLetters on String {
  String get keepDigitsLetters => replaceAll("[^a-zA-Z0-9- ]", "");
}

extension KeepOnlyDigits on String {
  String get keepOnlyDigits => replaceAll(RegExp(r'[^0-9]'), '');
  //return input.replaceAll(RegExp(r'[^0-9]'), '');
}

extension RemoveSpecialCharacters on String {
  String get removeSpecialCharacters =>
      replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  //return input.replaceAll(RegExp(r'[^0-9]'), '');
}

extension StringExtension on String {
  String keepOnlyNumbersAndDots() {
    return replaceAll(RegExp(r'[^0-9.]'), '');
  }
}

extension KeepLetters on String {
  String get keepLetters =>
      replaceAll("-", "").replaceAll(".", "").replaceAll("_", "");
}

extension SearchText on String {
  String get searchText => replaceAll(
    "-",
    "",
  ).replaceAll(".", "").replaceAll("_", "").removeAccents.toLowerCase();
}

extension ParseTZ on String {
  DateTime? get parseTz => nvl(this).isEmpty
      ? null
      : DateFormat(DATE_TIME_TZ_FORMAT).parse("${this}Z");
}

extension ParseDateTime on String {
  DateTime? get parseDateTime =>
      nvl(this).isEmpty ? null : DateFormat(DATE_TIME_FORMAT).parse(this);
}

extension ParseInt on String {
  int get parseInt => nvl(this).isEmpty ? 0 : int.parse(this);
}

extension ParseDate on String {
  DateTime? get parseDate =>
      nvl(this).isEmpty ? null : DateFormat(DATE_FORMAT).parse(this);
}

extension ParseMonth on String {
  DateTime? get parseMonth =>
      nvl(this).isEmpty ? null : DateFormat("MM/yyyy").parse(this);
}

extension FormatDouble on double {
  String formatDouble() {
    var f = NumberFormat("#,##0.0#", "en_US");
    return f.format(this);
  }
}

extension DoubleExtension on double {
  double roundToDecimalPlaces(int num) {
    return double.parse((this).toStringAsFixed(num));
  }
}

extension FormatDistance on double {
  String formatDistance() {
    var f = NumberFormat("#,##0.00", "en_US");
    return f.format(this);
  }
}

extension FormatPercent on double {
  String formatPercent() {
    if (truncateToDouble() == this) {
      return toInt().toString();
    }
    return toStringAsFixed(2);
  }
}

extension FormatCurrency on int {
  String formatCurrency() {
    var f = NumberFormat("#,##0", "en_US");
    String val = f.format(this);
    val = val.replaceAll(",", ".");
    return val;
  }
}

extension FormatThousand on int {
  String formatThousand() {
    var f = NumberFormat("#,##0", "en_US");
    String val = f.format(this);
    return val;
  }
}

extension Format on int {
  String format(String format) {
    var f = NumberFormat(format, "en_US");
    String val = f.format(this);
    return val;
  }
}

bool isValidTime(String value) {
  final reg = RegExp(r'^(\d{2}):(\d{2}):(\d{2})$');

  if (!reg.hasMatch(value)) return false;

  final match = reg.firstMatch(value)!;

  final h = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  final s = int.parse(match.group(3)!);

  return h < 24 && m < 60 && s < 60;
}

TextEditingValue validateInteger(
  TextEditingValue oldValue,
  TextEditingValue newValue,
) {
  final String text = newValue.text;
  if (text.length > 1) {
    if (text.startsWith("0")) {
      int tmp = int.tryParse(text) ?? 0;
      String tmpString = tmp.toString();
      TextEditingValue value = TextEditingValue(
        text: tmpString,
        selection: TextSelection(
          baseOffset: tmpString.length,
          extentOffset: tmpString.length,
        ),
      );
      return value;
    } else {
      int.parse(text);
    }
  }

  return newValue;
}
