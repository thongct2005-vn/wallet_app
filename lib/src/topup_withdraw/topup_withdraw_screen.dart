import 'package:app/src/topup_withdraw/confirm_topup_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:app/core/utils/currency_formatter.dart';
import 'package:app/core/utils/format_utils.dart';

class TopUpWithdrawScreen extends StatefulWidget {
  final String walletBalance;
  final bool isTopUpTab;
  final List<dynamic> bankLinkedList;
  const TopUpWithdrawScreen({super.key, required this.walletBalance, required this.isTopUpTab, required this.bankLinkedList});

  @override
  State<TopUpWithdrawScreen> createState() => _TopUpWithdrawScreenState();
}

class _TopUpWithdrawScreenState extends State<TopUpWithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isTopUpTab = true;
  bool _isLoading = false;

  final FocusNode _focusNode = FocusNode();
  String? _msg = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
    _isTopUpTab = widget.isTopUpTab;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleAmountChanged(String value) {
    num amountNum = FormatUtils.formatAmountToNum(value);
    final num minAmount = _isTopUpTab ? 1000 : 10000;
    if (amountNum == 0) {
      setState(() {
        _msg = _isTopUpTab
            ? 'Vui lòng nhập số tiền cần nạp'
            : 'Vui lòng nhập số tiền cần rút';
      });
    } else if (amountNum < minAmount) {
      setState(() {
        _msg =
            'Số tiền tối thiểu là ${FormatUtils.formatDisplayNumber(minAmount)}đ';
      });
    } else if (amountNum > 50000000) {
      setState(() {
        _msg = 'Số tiền tối đa là 50.000.000đ';
      });
    } else {
      setState(() {
        _msg = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnable = _amountController.text.isNotEmpty && _msg == '';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              height: 500,
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
                    padding: const EdgeInsets.fromLTRB(10, 5, 15, 10),
                    child: Row(
                      children: [
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Nạp/Rút",
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            icon: const Icon(Iconsax.home_2, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildTabBar(),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    15,
                                    15,
                                    15,
                                    10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isTopUpTab
                                            ? "Nạp tiền vào"
                                            : "Rút tiền từ",
                                        style: GoogleFonts.roboto(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.white,
                                          border: Border.all(
                                            width: 2,
                                            color: Colors.pink,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                10,
                                                10,
                                                0,
                                                10,
                                              ),
                                              child: Container(
                                                alignment: Alignment.center,
                                                width: 25,
                                                height: 25,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  color: Colors.pink,
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  child: Text(
                                                    'Mio',
                                                    style: GoogleFonts.roboto(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 8,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                10,
                                                10,
                                                10,
                                                5,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Ví Mio',
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 16,
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      height: 0.9,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${FormatUtils.formatDisplayNumber(FormatUtils.formatAmountToNum(widget.walletBalance))}đ',
                                                    style: GoogleFonts.roboto(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: 10,
                                              ),
                                              child: Container(
                                                alignment: Alignment.center,
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.pink,
                                                ),
                                                child: Container(
                                                  height: 7,
                                                  width: 7,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _isTopUpTab
                                            ? "Số tiền cần nạp"
                                            : "Số tiền cần rút",
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: _focusNode.hasFocus
                                              ? Border.all(
                                                  color: Colors.pink,
                                                  width: 1.5,
                                                )
                                              : Border.all(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                        ),
                                        child: TextField(
                                          controller: _amountController,
                                          focusNode: _focusNode,
                                          keyboardType: TextInputType.number,
                                          maxLength: 10,
                                          inputFormatters: [
                                            CurrencyFormatter(),
                                          ],
                                          onChanged: (val) {
                                            _handleAmountChanged(val);
                                          },
                                          style: GoogleFonts.roboto(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          cursorHeight: 30,
                                          cursorColor: Colors.pink,
                                          decoration: InputDecoration(
                                            counterText: '',
                                            border: InputBorder.none,
                                            hintText: '0đ',
                                            hintStyle: GoogleFonts.roboto(
                                              fontSize: 28,
                                              color: Colors.grey,
                                            ),
                                            suffixText:
                                                _amountController
                                                    .text
                                                    .isNotEmpty
                                                ? 'đ'
                                                : null,
                                            suffixStyle: GoogleFonts.roboto(
                                              fontSize: 20,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_msg != null && _msg != '') ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _msg!,
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 10),
                      child: GestureDetector(
                        onTap: isEnable
                            ? () async {
                                setState(() => _isLoading = true);
                                await Future.delayed(
                                  const Duration(seconds: 3),
                                );
                                setState(() => _isLoading = false);
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ConfirmTopUpScreen(
                                      amount: _amountController.text,
                                      linkedBanks: [],
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isEnable && !_isLoading
                                ? Colors.pinkAccent
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isTopUpTab ? "Nạp tiền" : "Rút tiền",
                                  style: GoogleFonts.roboto(
                                    color: isEnable
                                        ? Colors.white
                                        : Colors.grey.withValues(alpha: 0.5),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isTopUpTab = true;
                if (_amountController.text.isNotEmpty) {
                  _handleAmountChanged(_amountController.text);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _isTopUpTab
                    ? Colors.white
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.export_3,
                    size: 18,
                    color: _isTopUpTab ? Colors.pink : Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Nạp tiền",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isTopUpTab ? Colors.pink : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isTopUpTab = false;
                if (_amountController.text.isNotEmpty) {
                  _handleAmountChanged(_amountController.text);
                }
                
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: !_isTopUpTab
                    ? Colors.white
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.import_1,
                    size: 18,
                    color: !_isTopUpTab ? Colors.pink : Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Rút tiền",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: !_isTopUpTab ? Colors.pink : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
