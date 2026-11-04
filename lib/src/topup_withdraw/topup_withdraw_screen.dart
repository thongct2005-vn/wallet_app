import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/topup_withdraw/confirm_topup_withdrawn_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:app/core/utils/currency_formatter.dart';
import 'package:app/core/utils/format_utils.dart';

const Color _kPink = Color(0xFFEC407A);
const Color _kPinkDark = Color(0xFFD81B60);
const Color _kPinkLight = Color(0xFFF48FB1);
const Color _kText = Color(0xFF1F1B24);
const Color _kMuted = Color(0xFF8A8590);
const Color _kBg = Color(0xFFFAF6F8);

class TopUpWithdrawScreen extends StatefulWidget {
  final String walletBalance;
  final bool isTopUpTab;
  const TopUpWithdrawScreen({
    super.key,
    required this.walletBalance,
    required this.isTopUpTab,
  });

  /// Route chuyển trang mượt (trượt nhẹ + mờ dần) dùng khi mở từ màn Home.
  static Route<T> route<T>({
    required String walletBalance,
    required bool isTopUpTab,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => TopUpWithdrawScreen(
        walletBalance: walletBalance,
        isTopUpTab: isTopUpTab,
      ),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TopUpWithdrawScreen> createState() => _TopUpWithdrawScreenState();
}

class _TopUpWithdrawScreenState extends State<TopUpWithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  final BankService _bankService = BankService();
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
    if (amountNum == 0) {
      setState(() {
        _msg = _isTopUpTab
            ? 'Vui lòng nhập số tiền cần nạp'
            : 'Vui lòng nhập số tiền cần rút';
      });
    } else if (amountNum < 10000) {
      setState(() {
        _msg =
            'Số tiền tối thiểu là 10.000đ';
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
        backgroundColor: _kBg,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kPink.withValues(alpha: 0.24),
                    _kPinkLight.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        _circleButton(
                          icon: Icons.arrow_back,
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => HomeScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Nạp/Rút",
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                        ),
                        const Spacer(),
                        _circleButton(
                          icon: Iconsax.home_2,
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => HomeScreen()),
                              (r) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTabBar(),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPink.withValues(alpha: 0.1),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isTopUpTab ? "Nạp tiền vào" : "Rút tiền từ",
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _kMuted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildWalletTile(),
                                const SizedBox(height: 22),
                                Text(
                                  _isTopUpTab
                                      ? "Số tiền cần nạp"
                                      : "Số tiền cần rút",
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _kMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: _focusNode.hasFocus
                                        ? _kPink.withValues(alpha: 0.04)
                                        : const Color(0xFFF7F5F8),
                                    border: Border.all(
                                      color: _focusNode.hasFocus
                                          ? _kPink
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: TextField(
                                    controller: _amountController,
                                    focusNode: _focusNode,
                                    keyboardType: TextInputType.number,
                                    maxLength: 10,
                                    inputFormatters: [CurrencyFormatter()],
                                    onChanged: (val) {
                                      _handleAmountChanged(val);
                                    },
                                    style: GoogleFonts.roboto(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: _kText,
                                    ),
                                    cursorHeight: 32,
                                    cursorColor: _kPink,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                      hintText: '0đ',
                                      hintStyle: GoogleFonts.roboto(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade400,
                                      ),
                                      suffixText:
                                          _amountController.text.isNotEmpty
                                          ? 'đ'
                                          : null,
                                      suffixStyle: GoogleFonts.roboto(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: _kText,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_msg != null && _msg != '')
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _msg!,
                                          style: GoogleFonts.roboto(
                                            fontSize: 13.5,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    'Tối thiểu 10.000đ - tối đa 50.000.000đ',
                                    style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      color: _kMuted,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final v in const [
                                      100000,
                                      200000,
                                      500000,
                                      1000000,
                                    ])
                                      _buildQuickAmountChip(v),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: GestureDetector(
                          onTap: isEnable
                              ? () async {
                                  setState(() => _isLoading = true);
                                  final result = await _getLinkedBanks();
                                  setState(() => _isLoading = false);
                                  if (!context.mounted) return;
                                  if (result['is_success']) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ConfirmTopUpWithdrawScreen(
                                              amount: _amountController.text,
                                              linkedBanks:
                                                  result['data']['linked_accounts'],
                                              isTopUpTab: _isTopUpTab,
                                            ),
                                      ),
                                    );
                                  } else {
                                    SnackbarUtils.failure(
                                      context,
                                      result['message'],
                                    );
                                  }
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 54,
                            alignment: Alignment.center,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: isEnable && !_isLoading
                                  ? const LinearGradient(
                                      colors: [Color(0xFFF06292), _kPinkDark],
                                    )
                                  : null,
                              color: isEnable && !_isLoading
                                  ? null
                                  : Colors.black.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isEnable && !_isLoading
                                  ? [
                                      BoxShadow(
                                        color: _kPink.withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
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
                                          : Colors.grey.withValues(alpha: 0.7),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
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

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _kPink.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 21, color: _kText),
      ),
    );
  }

  Widget _buildWalletTile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _kPink.withValues(alpha: 0.05),
        border: Border.all(width: 1.5, color: _kPink),
      ),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFF06292), _kPinkDark],
              ),
            ),
            child: Text(
              'Mio',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ví Mio',
                  style: GoogleFonts.roboto(fontSize: 14, color: _kMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  '${FormatUtils.formatDisplayNumber(FormatUtils.formatAmountToNum(widget.walletBalance))}đ',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: _kText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.center,
            height: 22,
            width: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _kPink,
            ),
            child: Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(int value) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        final text = FormatUtils.formatDisplayNumber(value);
        _amountController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _handleAmountChanged(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _kPink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          FormatUtils.formatDisplayNumber(value),
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kPinkDark,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    Widget tab(String label, IconData icon, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _kPink.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: selected ? _kPink : _kMuted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? _kPink : _kMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          tab("Nạp tiền", Iconsax.export_3, _isTopUpTab, () {
            setState(() {
              _isTopUpTab = true;
              if (_amountController.text.isNotEmpty) {
                _handleAmountChanged(_amountController.text);
              }
            });
          }),
          tab("Rút tiền", Iconsax.import_1, !_isTopUpTab, () {
            setState(() {
              _isTopUpTab = false;
              if (_amountController.text.isNotEmpty) {
                _handleAmountChanged(_amountController.text);
              }
            });
          }),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getLinkedBanks() async {
    try {
      final result = await _bankService.getBankLinkStatus();
      return result;
    } catch (e) {
      if (mounted) {
        SnackbarUtils.failure(
          context,
          "Hệ thống đang bảo trì. Vui lòng thử lại sau",
        );
      }
      return {};
    }
  }
}