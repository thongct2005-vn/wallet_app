import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultTranferScreen extends StatefulWidget {
  final Map<String, dynamic>? result;
  const ResultTranferScreen({super.key, this.result});
  @override
  State<ResultTranferScreen> createState() => _ResultTranferScreenState();
}

class _ResultTranferScreenState extends State<ResultTranferScreen> {
  late dynamic data;
  late dynamic amount;
  late dynamic createdAt;
  @override
  void initState() {
    super.initState();
    setState(() {
      data = widget.result?['data'];
      amount = FormatUtils.formatDisplayNumber(data['amount']);
      createdAt = FormatUtils.formatCustomDateTime(data['createdAt']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            "Kết quả giao dịch",
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                icon: Icon(Icons.home_outlined, size: 24, color: Colors.black),
              ),
            ),
          ],
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
                    Colors.pink.shade200.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 25),
                            width: double.infinity,

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10, 40, 10, 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  Text(
                                    "Giao dịch thành công",
                                    style: GoogleFonts.roboto(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  Text(
                                    "$amountđ",
                                    style: GoogleFonts.roboto(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),

                                  Divider(
                                    height: 0.5,
                                    color: Colors.pink.withValues(alpha: 0.1),
                                  ),
                                  const SizedBox(height: 10),

                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100.withValues(
                                        alpha: 0.3,
                                      ),
                                      border: Border.all(
                                        width: 0.5,
                                        color: Colors.blue,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsGeometry.all(10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.blue,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "${data['destinationUserName']} đã nhận được tiền qua Mio",
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Giao dịch",
                                        style: GoogleFonts.roboto(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 20,
                                        ),
                                      ),

                                      Text(
                                        "${data['transactionId']}",
                                        style: GoogleFonts.roboto(
                                          color: Colors.pink,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Thời gian thanh toán",
                                        style: GoogleFonts.roboto(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 20,
                                        ),
                                      ),

                                      Text(
                                        createdAt,
                                        style: GoogleFonts.roboto(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        width: 0.5,
                                        color: Colors.pink,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                alignment: Alignment.center,
                                                width: 35,
                                                height: 35,
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
                                                      fontSize: 10,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                "Biên lại chuyển tiền",
                                                style: GoogleFonts.roboto(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 15),
                                          Divider(
                                            height: 0.5,
                                            color: Colors.pink.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                          SizedBox(height: 15),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors
                                                    .pink
                                                    .shade50
                                                    .withValues(alpha: 0.6),
                                                child: Text(
                                                  'VT',
                                                  style: GoogleFonts.roboto(
                                                    color: Colors.pink,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${data['sourceUserName']}",
                                                      style: GoogleFonts.roboto(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Container(
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey
                                                            .withValues(
                                                              alpha: 0.12,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsGeometry.symmetric(
                                                              horizontal: 6,
                                                              vertical: 3,
                                                            ),
                                                        child: Text(
                                                          "${data['description']}",
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              GoogleFonts.roboto(
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          Align(
                                            heightFactor: 0.4,
                                            alignment: Alignment.centerLeft,
                                            child: _buildDownArrow(
                                              15,
                                              Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                            ),
                                          ),
                                          Align(
                                            heightFactor: 0.4,
                                            alignment: Alignment.centerLeft,
                                            child: _buildDownArrow(
                                              16,
                                              Colors.black.withValues(
                                                alpha: 0.15,
                                              ),
                                            ),
                                          ),
                                          Align(
                                            heightFactor: 0.4,
                                            alignment: Alignment.centerLeft,
                                            child: _buildDownArrow(
                                              17,
                                              Colors.black.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          Align(
                                            heightFactor: 0.6,
                                            alignment: Alignment.centerLeft,
                                            child: _buildDownArrow(
                                              18,
                                              Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                            ),
                                          ),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors
                                                    .pink
                                                    .shade50
                                                    .withValues(alpha: 0.6),
                                                child: Text(
                                                  'VT',
                                                  style: GoogleFonts.roboto(
                                                    color: Colors.pink,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${data['destinationUserName']}",
                                                      style: GoogleFonts.roboto(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      "${data['destinationPhone']}",
                                                      style: GoogleFonts.roboto(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () {},
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                      border: Border.all(
                                                        width: 1,
                                                        color: Colors.pink,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsGeometry.symmetric(
                                                            vertical: 2,
                                                          ),
                                                      child: Text(
                                                        "Trò chuyện",
                                                        style:
                                                            GoogleFonts.roboto(
                                                              fontSize: 20,
                                                              color:
                                                                  Colors.pink,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AmountInputScreen(
                                                              receiverFullName:
                                                                  data['destinationUserName'],
                                                              receiverId:
                                                                  data['destinationId'],
                                                              receiverPhone:
                                                                  data['destinationPhone'],
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: Colors.pink,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                      border: Border.all(
                                                        width: 1,
                                                        color: Colors.pink,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsGeometry.symmetric(
                                                            vertical: 2,
                                                          ),
                                                      child: Text(
                                                        "Chuyển thêm",
                                                        style:
                                                            GoogleFonts.roboto(
                                                              fontSize: 20,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Positioned(
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 0.2,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.lightGreen.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.lightGreen,
                                    width: 5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.lightGreen,
                                  size: 35,
                                  fontWeight: FontWeight.w700,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownArrow(double size, Color color) {
    return SizedBox(
      width: 40,
      child: Center(
        child: Icon(Icons.keyboard_arrow_down, color: color, size: size),
      ),
    );
  }
}
