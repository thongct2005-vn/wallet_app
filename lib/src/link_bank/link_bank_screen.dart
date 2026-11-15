import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

const Color _kPink = Color(0xFFEC407A);
const Color _kPinkLight = Color(0xFFF48FB1);
const Color _kText = Color(0xFF1F1B24);
const Color _kBg = Color(0xFFFAF6F8);

class LinkBankScreen extends StatefulWidget {
  final List<dynamic> bankList;
  const LinkBankScreen({super.key, required this.bankList});
  @override
  State<LinkBankScreen> createState() => _LinkBankScreenState();
}

class _LinkBankScreenState extends State<LinkBankScreen> {
  List<dynamic> _bankList = [];
  final WalletService _walletService = WalletService();
  final BankService _bankService = BankService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _bankList = List.from(widget.bankList);
  }

  @override
  Widget build(BuildContext context) {
    return FreezePinMediaQuery(
      child: Scaffold(
        backgroundColor: _kBg,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            RepaintBoundary(
              child: Container(
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
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        _circleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            "Liên kết ngân hàng",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: _kText,
                            ),
                          ),
                        ),
                        _circleButton(
                          icon: Iconsax.home_2,
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              );
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                                (r) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RepaintBoundary(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.pink.shade100,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kPink.withValues(alpha: 0.18),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Iconsax.support,
                                    color: Color(0xFFD81B60),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.pink.shade100,
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kPink.withValues(alpha: 0.14),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "Liên kết ngân hàng của bạn để thanh toán/chuyển tiền qua Mio.",
                                      style: GoogleFonts.roboto(
                                        fontSize: 15,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                        color: _kText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ..._bankList.map((bank) {
                              String bankId = bank['id']?.toString() ?? '';
                              String bankCode = bank['code']?.toString() ?? '';
                              String bankName =
                                  bank['name']?.toString() ?? 'Ngân hàng';
                              String bankLogo =
                                  bank['logo_url']?.toString() ?? "";
                              bool isLinked = bank['is_linked'] as bool;

                              List<Color> gradientColors = [
                                Colors.grey.shade600,
                                Colors.grey.shade400,
                              ];

                              if (bankCode == 'MBBANK') {
                                gradientColors = [
                                  Colors.blue.shade600,
                                  Colors.blue.shade400,
                                ];
                              } else if (bankCode == 'VIETCOMBANK') {
                                gradientColors = [
                                  Colors.green.shade600,
                                  Colors.green.shade400,
                                ];
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildBankTile(
                                  name: bankName,
                                  gradientColors: gradientColors,
                                  isLinked: isLinked,
                                  logoUrl: bankLogo,
                                  onTap: () {
                                    _showCheckPinDialog(context, bankId);
                                  },
                                ),
                              );
                            }),
                          ],
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

  Widget _buildBankTile({
    required String name,
    required List<Color> gradientColors,
    required String logoUrl,
    required bool isLinked,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  logoUrl,
                  headers: const {'ngrok-skip-browser-warning': 'true'},
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Icon(Iconsax.bank, size: 22),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (!isLinked) ...[
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Liên kết",
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: gradientColors.first,
                    ),
                  ),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Đã liên kết",
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCheckPinDialog(BuildContext context, String bankId) {
    // checkPin cần idempotency key để cấp pin_token; mỗi lần mở hộp thoại dùng một key mới
    final String idempotencyKey = _uuid.v7();

    showSmoothPinBottomSheet(
      context: context,
      builder: (context) {
        return CheckPinBottomSheet(
          onCheckPin: (pin) async {
            try {
              final res = await _walletService.checkPin(
                pin,
                idempotencyKey,
                action: 'BANK_LINK',
                params: {'bank_id': bankId},
              );
              return res;
            } catch (e) {
              return {'is_success': false};
            }
          },
          onSuccess: (pinToken) async {
            final result = await _bankService.linkBankAccount(
              bankId,
              idempotencyKey,
              pinToken,
            );
            if (!mounted) return;
            if (result['is_success'] != true) {
              SnackbarUtils.failure(
                this.context,
                result['message']?.toString() ?? 'Liên kết ngân hàng thất bại',
              );
              return;
            }
            setState(() {
              final index = _bankList.indexWhere(
                (bank) => bank['id'].toString() == bankId,
              );
              if (index != -1) {
                _bankList[index]['is_linked'] = true;
              }
            });
            SnackbarUtils.success(
              this.context,
              result['message']?.toString() ?? 'Liên kết ngân hàng thành công',
            );
          },
        );
      },
    );
  }
}
