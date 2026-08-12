import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/utils/currency_formatter.dart';

class CreateQRScreen extends StatefulWidget {
  const CreateQRScreen({super.key});
  @override
  State<CreateQRScreen> createState() => _CreateQRScreenState();
}

class _CreateQRScreenState extends State<CreateQRScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _desController = TextEditingController();
  final UserController _userController = Get.find<UserController>();
  final FocusNode _desFocusNode = FocusNode();
  String _qrData = "";
  String? _phone = '';
  String? _fullName = '';
  String? _avatar = '';
  int? _amount = 0;
  String? _description = '';
  String? _amountMsg = '';
  @override
  void initState() {
    super.initState();
    _phone = _userController.phone.value;
    _fullName = _userController.fullName.value;
    _avatar = FormatUtils.formatAvatar(_fullName ?? '?');
    _desFocusNode.addListener(_onDesFocusChange);
    _loadStaticQRToken();
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
    _amountController.dispose();
    _desController.dispose();
    _desFocusNode.dispose();
  }

  void _onDesFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.4),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
            ),
          ),
        ),
        title: Text('Nhận tiền', style: GoogleFonts.roboto()),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 500,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(2),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.pink.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 70,
                                            vertical: 20,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                  spreadRadius: 2,
                                                  blurRadius: 7,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                    0,
                                                    15,
                                                    0,
                                                    0,
                                                  ),
                                                  child: Text(
                                                    "Mio",
                                                    style: GoogleFonts.baloo2(
                                                      color: Colors.pink,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 25,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                    20,
                                                    5,
                                                    20,
                                                    0,
                                                  ),
                                                  child: _qrData.isEmpty
                                                      ? SizedBox(
                                                          width: 220,
                                                          height: 220,
                                                          child: Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                  color: Colors
                                                                      .pink,
                                                                ),
                                                          ),
                                                        )
                                                      : Stack(
                                                          alignment:
                                                              Alignment.center,
                                                          children: [
                                                            QrImageView(
                                                              data: _qrData,
                                                              version:
                                                                  QrVersions
                                                                      .auto,
                                                              size: 250.0,
                                                              backgroundColor:
                                                                  Colors.white,
                                                              errorCorrectionLevel:
                                                                  QrErrorCorrectLevel
                                                                      .H,
                                                            ),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    2,
                                                                  ),
                                                              decoration:
                                                                  const BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                              child: CircleAvatar(
                                                                radius: 22,
                                                                backgroundColor:
                                                                    Colors.pink
                                                                        .withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        ),
                                                                child: Text(
                                                                  _avatar ??
                                                                      '?',
                                                                  style: GoogleFonts.roboto(
                                                                    color: Colors
                                                                        .pink,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                ),
                                                SizedBox(height: 10),
                                                Divider(
                                                  height: 0.5,
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                ),
                                                Padding(
                                                  padding:
                                                      EdgeInsetsGeometry.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          _showAmountBottomSheet();
                                                        },
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              (_amount ==
                                                                          null ||
                                                                      _amount ==
                                                                          0)
                                                                  ? Icons.add
                                                                  : Icons
                                                                        .edit_outlined,
                                                              size: 16,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                            const SizedBox(
                                                              width: 5,
                                                            ),
                                                            Text(
                                                              (_amount ==
                                                                          null ||
                                                                      _amount ==
                                                                          0)
                                                                  ? "Thêm số tiền"
                                                                  : "${FormatUtils.formatDisplayNumber(_amount!)}đ",
                                                              style: GoogleFonts.roboto(
                                                                color:
                                                                    Colors.blue,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (_desController
                                                          .text
                                                          .isNotEmpty) ...[
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 15,
                                                              ),
                                                          child: Center(
                                                            child: Text(
                                                              _desController
                                                                  .text,
                                                              style: GoogleFonts.roboto(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 60),
                                        Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Padding(
                                              padding:
                                                  EdgeInsetsGeometry.symmetric(
                                                    horizontal: 10,
                                                    vertical: 15,
                                                  ),
                                              child: IntrinsicHeight(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .download_outlined,
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                            size: 15,
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text("Tải xuống"),
                                                        ],
                                                      ),
                                                    ),
                                                    VerticalDivider(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                                    Expanded(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .settings_outlined,
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                            size: 15,
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text("Tùy chỉnh"),
                                                        ],
                                                      ),
                                                    ),
                                                    VerticalDivider(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                                    Expanded(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .share_outlined,
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                            size: 15,
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text("Chia sẻ"),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
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
                            Padding(
                              padding: EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Tên người nhận",
                                        style: GoogleFonts.roboto(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 30),
                                      Expanded(
                                        child: Text(
                                          _fullName ?? "?",
                                          textAlign: TextAlign.right,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.roboto(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Ngân hàng",
                                        style: GoogleFonts.roboto(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 30),
                                      Expanded(
                                        child: Text(
                                          "Mio",
                                          textAlign: TextAlign.right,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.roboto(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Số tài khoản",
                                        style: GoogleFonts.roboto(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 30),
                                      Expanded(
                                        child: Text(
                                          _phone ?? "0xxxxxxxxx",
                                          textAlign: TextAlign.right,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.roboto(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  void _showAmountBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "Thêm số tiền",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                                  controller: _amountController,
                                  autofocus: true,
                                  inputFormatters: [CurrencyFormatter()],
                                  maxLength: 10,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: Colors.pink,
                                  cursorHeight: 50,
                                  onChanged: (val) {
                                    final amountNum =
                                        FormatUtils.formatAmountToNum(val);
                                    setSheetState(() {
                                      if (amountNum == 0) {
                                        _amountMsg = 'Vui lòng nhập số tiền';
                                      } else if (amountNum < 1000) {
                                        _amountMsg =
                                            'Số tiền tối thiểu là 1000đ';
                                      } else if (amountNum > 50000000) {
                                        _amountMsg =
                                            'Số tiền tối đa là 50.000.000đ';
                                      } else {
                                        _amountMsg = '';
                                      }
                                    });
                                  },
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
                  if (_amountMsg != null && _amountMsg != '') ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        _amountMsg!,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        width: 1,
                        color: _desFocusNode.hasFocus
                            ? Colors.pink
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextField(
                            focusNode: _desFocusNode,
                            controller: _desController,
                            maxLength: 50,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            onChanged: (val) {
                              setSheetState(() {});
                            },
                            style: GoogleFonts.roboto(fontSize: 18),
                            cursorColor: Colors.pink,
                            cursorHeight: 20,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.only(right: 30),
                              counterText: '',
                              isDense: true,
                              hintText: 'Thêm lời nhắn',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                          if (_desController.text.isNotEmpty)
                            Positioned(
                              right: -6,
                              child: IconButton(
                                constraints: BoxConstraints(),
                                padding: EdgeInsets.all(10),
                                onPressed: () {
                                  setSheetState(() {
                                    _desController.text = '';
                                  });
                                },
                                icon: Icon(
                                  Icons.cancel,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${_desController.text.length}/50",
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          (_amountMsg == '' &&
                              _amountController.text.isNotEmpty)
                          ? () {
                              final amountNum = FormatUtils.formatAmountToNum(
                                _amountController.text,
                              );
                              setState(() {
                                _amount = amountNum.toInt();
                                _description = _desController.text.trim();
                              });
                              Navigator.pop(context);
                              _loadDynamicQRToken(
                                amountNum.toInt(),
                                _description ?? '',
                              );
                            }
                          : null,
                      child: Text(
                        "Xác nhận",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadStaticQRToken() async {
    try {
      final result = await _paymentService.getStaticQRToken();
      final token = result['token'];
      if (mounted) {
        setState(() {
          _qrData = token ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrData = '';
        });
      }
    }
  }

  Future<void> _loadDynamicQRToken(int amount, String description) async {
    try {
      final result = await _paymentService.createDynamicQRToken(
        amount,
        description,
      );

      final token = result['token']['reference_code'];

      if (mounted) {
        setState(() {
          _amount = amount;
          _description = description;
          _qrData = token ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrData = '';
        });
      }
    }
  }
}
