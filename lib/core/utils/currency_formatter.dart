import 'package:flutter/services.dart';

class CurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    String numbericOnly = newValue.text
        .replaceAll(RegExp(r'[^0-9]'), '')
        .replaceFirst(RegExp(r'^0+'), '');
        
    if (numbericOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < numbericOnly.length; i++) {
      buffer.write(numbericOnly[i]);
      int nonZeroIndex = numbericOnly.length - 1 - i;
      if (nonZeroIndex % 3 == 0 && nonZeroIndex != 0) {
        buffer.write('.');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}