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
}