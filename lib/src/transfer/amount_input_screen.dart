import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class AmountInputScreen extends StatefulWidget {
  final String? phone;
  final String? fullName;
  final String? avatarName;
  const AmountInputScreen({
    super.key,
    this.phone,
    this.fullName,
    this.avatarName,
  });
  @override
  State<AmountInputScreen> createState() => _AmountInputScreenState();
}

class _AmountInputScreenState extends State<AmountInputScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.fromLTRB(10, 15, 0, 15),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),
          title: Text(
            "Chuyển tiền tới",
            style: GoogleFonts.roboto(fontSize: 20),
          ),
        ),
        body: Stack(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.pink.shade200.withValues(alpha: 0.75),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: _buildContainerReceiverInfo(context),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: _buildContainerAmountInput(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerReceiverInfo(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(width: 1, color: Colors.green),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.pink.shade50.withValues(alpha: 0.6),
              child: Text(
                widget.avatarName ?? "?",
                style: GoogleFonts.roboto(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.fullName ?? "Không rõ tên",
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  widget.phone ?? "***",
                  style: GoogleFonts.roboto(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerAmountInput(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(width: 1, color: Colors.white),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Center(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _amountController,
                builder: (context, value, child) {
                  return IntrinsicWidth(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          constraints: BoxConstraints(minWidth: 50),
                          child: Text(
                            value.text.isEmpty ? '0' : value.text,
                            style: GoogleFonts.roboto(
                              fontSize: 40,
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: TextField(
                            inputFormatters: [CurrencyFormatter()],
                            maxLength: 10,
                            keyboardType: TextInputType.number,
                            controller: _amountController,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(fontSize: 40),
                            cursorColor: Colors.pink,
                            cursorHeight: 50,

                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.only(bottom: 0),
                              counterText: '',
                              isDense: true,
                              hintText: '0',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 40,
                                color: Colors.grey,
                              ),

                              suffixIcon: Transform.translate(
                                offset: const Offset(-2, -4),
                                child: Text(
                                  'đ',
                                  style: GoogleFonts.roboto(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),

                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.pink,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    if (numbericOnly.isEmpty)
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
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
