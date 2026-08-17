import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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

  @override
  void initState() {
    super.initState();
    _bankList = List.from(widget.bankList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        "Liên kết ngân hàng",
                        style: GoogleFonts.roboto(
                          fontSize: 20,
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
                          icon: const Icon(Iconsax.home_2, size: 18),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Iconsax.support),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50.withValues(
                                    alpha: 0.6,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.pink.shade100,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "Liên kết ngân hàng của bạn để thanh toán/chuyển tiền qua Mio.",
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    color: Colors.black87,
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
                          String bankName = bank['name']?.toString() ?? 'Ngân hàng';
                          String bankLogo = bank['logo_url']?.toString() ?? "";
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
              ],
            ),
          ),
        ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CheckPinBottomSheet(
          onCheckPin: (pin) async {
            try {
              final res = await _walletService.checkPin(pin);
              return res;
            } catch (e) {
              return {};
            }
          },
          onSuccess: () async {
            try {
              await _bankService.linkBankAccount(bankId);
              if (!mounted) return;
              setState(() {
                final index = _bankList.indexWhere(
                  (bank) => bank['id'].toString() == bankId,
                );
                if (index != -1) {
                  _bankList[index]['is_linked'] = true;
                }
              });
            } catch (e) {
              return;
            }
          },
        );
      },
    );
  }
}