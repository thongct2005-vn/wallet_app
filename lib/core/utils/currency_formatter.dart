import 'package:flutter/services.dart';

class CurrencyFormatter extends TextInputFormatter {
  static final RegExp _nonDigitsRegex = RegExp(r'[^0-9]');
  static final RegExp _leadingZerosRegex = RegExp(r'^0+');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    final String numbericOnly = newValue.text
        .replaceAll(_nonDigitsRegex, '')
        .replaceFirst(_leadingZerosRegex, '');

    if (numbericOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    for (int i = 0; i < numbericOnly.length; i++) {
      buffer.write(numbericOnly[i]);
      final int nonZeroIndex = numbericOnly.length - 1 - i;
      if (nonZeroIndex % 3 == 0 && nonZeroIndex != 0) {
        buffer.write('.');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
