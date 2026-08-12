import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/services/transaction_service.dart';
import 'package:app/src/transfer/result_tranfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:uuid/uuid.dart';

class ConfirmTranferScreen extends StatefulWidget {
  final String? receiverId;
  final String? receiverName;
  final String? receiverPhone;
  final String? amount;
  final String? description;
  final String? walletBalance;
  final String? referenceCode;

  const ConfirmTranferScreen({
    super.key,
    this.receiverId,
    this.receiverName,
    this.receiverPhone,
    this.amount,
    this.description,
    this.walletBalance,
    this.referenceCode,
  });

  @override
  State<ConfirmTranferScreen> createState() => _ConfirmTranferScreenState();
}

class _ConfirmTranferScreenState extends State<ConfirmTranferScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  bool _isProcessingTransfer = false;
  final Uuid _uuid = const Uuid();
  late final String idempotencyKey;

  @override
  void initState() {
    super.initState();
    idempotencyKey = _uuid.v7();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessingTransfer,
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
            "Xác nhận thanh toán",
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
                  _buildContainerReceiverInfo(context),
                  _buildContainerVoucher(context),
                  _buildContainerWalletInfo(context),
                  const Spacer(),
                  _buildContainerConfirmButton(context),
                ],
              ),
            ),
            if (_isProcessingTransfer)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    bool isMultiLine = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              color: Colors.black.withValues(alpha: 0.5),
              fontSize: 20,
            ),
          ),
          SizedBox(width: 100),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: isMultiLine ? 3 : 1,
              overflow: isMultiLine
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
              style: GoogleFonts.roboto(
                color: valueColor,
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerReceiverInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.red),
                  SizedBox(width: 5),
                  Text(
                    "Chuyển tiền",
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Divider(
                height: 1.2,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
            _buildInfoRow(
              label: 'Số tiền',
              value: '${widget.amount}đ',
              valueColor: Colors.blue,
            ),
            _buildInfoRow(
              label: 'Người nhận',
              value: widget.receiverName ?? 'Không rõ tên',
              valueColor: Colors.blue,
            ),
            _buildInfoRow(
              label: 'Số điện thoại',
              value: widget.receiverPhone ?? '',
            ),
            if (widget.description!.isNotEmpty) ...[
              _buildInfoRow(
                label: 'Lời nhắn',
                value: widget.description ?? '',
                isMultiLine: true,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ],
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerVoucher(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15, 15, 15, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 15, 10, 15),
          child: Row(
            children: [
              Icon(Icons.local_offer, color: Colors.yellow),
              SizedBox(width: 5),
              Text(
                "Ưu đãi",
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      "Chọn hoặc nhập mã",
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContainerWalletInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15, 15, 15, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10, 15, 0, 0),
              child: Text(
                "Trả ngay",
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(width: 2, color: Colors.pink),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 10, 0, 10),
                      child: Container(
                        alignment: Alignment.center,
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.pink,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Text(
                            'Mio',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w900,
                              fontSize: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ví Mio',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.black.withValues(alpha: 0.7),
                              height: 0.9,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            '${FormatUtils.formatDisplayNumber(num.tryParse(widget.walletBalance!) ?? 0)}đ',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: 10),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerConfirmButton(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,

      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 15, 10, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Tổng tiền",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    color: Colors.black.withValues(alpha: 0.7),

                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  '${widget.amount ?? '0'}đ',
                  style: GoogleFonts.roboto(
                    fontSize: 35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _isProcessingTransfer
                  ? null
                  : () {
                      _showCheckPinDialog(context);
                    },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _isProcessingTransfer
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.pinkAccent,
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isProcessingTransfer
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                      const SizedBox(width: 10),
                      Text(
                        "Xác nhận",
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckPinDialog(BuildContext context) {
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
            await _handleTransfer();
          },
        );
      },
    );
  }

  Future<void> _handleTransfer() async {
    if (!mounted) return;
    setState(() => _isProcessingTransfer = true);
    final numAmount = FormatUtils.formatAmountToNum(
      widget.amount ?? '0',
    ).toString();
    try {
      final result = widget.referenceCode == null
          ? await _transactionService.transferMoney(
              widget.receiverId ?? "",
              numAmount,
              widget.description ?? "",
              idempotencyKey,
            )
          : await _transactionService.processQRPayment(
              widget.referenceCode!,
              idempotencyKey,
            );
      setState(() {
        _isProcessingTransfer = false;
      });
      if (!mounted) return;
      if (result['is_success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ResultTranferScreen(result: result),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        SnackbarUtils.failure(context, result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.failure(context, "Có lỗi xảy ra. Vui lòng thử lại");
    } finally {
      if (mounted) setState(() => _isProcessingTransfer = false);
    }
  }
}
