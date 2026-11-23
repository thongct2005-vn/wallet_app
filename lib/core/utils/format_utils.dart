import 'package:intl/intl.dart';

class FormatUtils {
  static String formatDisplayNumber(num amount) {
    if (amount == 0) return '0';

    String numberString = amount.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (int i = 0; i < numberString.length; i++) {
      buffer.write(numberString[i]);
      int nonZeroIndex = numberString.length - 1 - i;
      if (nonZeroIndex % 3 == 0 && nonZeroIndex != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  static num formatAmountToNum(String amount) {
    if (amount.isEmpty) return 0;
    final newAmount = amount.replaceAll('.', '').replaceAll('đ', '');
    num amountNum = num.tryParse(newAmount) ?? 0;
    return amountNum;
  }

  /// Chuẩn hóa chuỗi số tiền thô (`100000`, `100000.00`, `100.000`) sang dạng có dấu chấm (`100.000`).
  static String formatRawAmountDisplay(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final num parsed;
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      parsed = num.tryParse(trimmed) ?? 0;
    } else if (RegExp(r'^\d+\.\d{1,2}$').hasMatch(trimmed)) {
      parsed = (double.tryParse(trimmed) ?? 0).round();
    } else {
      parsed = formatAmountToNum(trimmed);
    }
    return parsed > 0 ? formatDisplayNumber(parsed) : trimmed;
  }

  static final DateFormat _dateTimeFmt = DateFormat('HH:mm - dd/MM/yyyy');

  static String formatDateTime(DateTime parsedDate) {
    final date = parsedDate.toUtc().add(const Duration(hours: 7));
    return _dateTimeFmt.format(date);
  }

  static String formatCustomDateTime(String timeString) {
    return formatDateTime(DateTime.parse(timeString));
  }

  static final RegExp _phoneRegex = RegExp(r'^(03|05|07|08|09)\d{8}$');

  /// Kiểm tra SĐT Việt Nam hợp lệ (10 chữ số, đầu 03, 05, 07, 08, 09).
  static bool isValidPhone(String phone) => _phoneRegex.hasMatch(phone);

  static String formatAvatar(String fullName) {
    if (fullName.trim().isEmpty) return '?';
    List<String> words = fullName.trim().split(RegExp(r'\s+'));
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[words.length - 2][0]}${words[words.length - 1][0]}'
        .toUpperCase();
  }
}
