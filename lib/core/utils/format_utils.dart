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

  static String formatCustomDateTime(String timeString) {
    DateTime parsedDate = DateTime.parse(timeString);

    DateTime date = parsedDate.toUtc().add(const Duration(hours: 7));
    String formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(date);

    return formattedDate;
  }

  static String formatAvatar(String fullName) {
    if (fullName.trim().isEmpty) return '?';
    List<String> words = fullName.trim().split(RegExp(r'\s+'));
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[words.length - 2][0]}${words[words.length - 1][0]}'
        .toUpperCase();
  }
}
