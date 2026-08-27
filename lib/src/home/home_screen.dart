import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/create_pin_bottom_sheet.dart';
import 'package:app/src/history/history_screen.dart';
import 'package:app/src/link_bank/link_bank_screen.dart';
import 'package:app/src/profile/profile_screen.dart';
import 'package:app/src/qr/qr_main_screen.dart';
import 'package:app/src/services/app_data_service.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/topup_withdraw/topup_withdraw_screen.dart';
import 'package:app/src/transfer/contact_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/src/services/user_service.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final AppDataService _appDataService = AppDataService();
  final UserController _userController = Get.find<UserController>();
  final BankService _bankService = BankService();
  String _fullName = '';
  bool _isHidenWalletBalance = false;
  String _balance = '0';
  bool _hasPin = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      _fullName = _userController.fullName.value;
      _balance =
          '${FormatUtils.formatDisplayNumber(num.tryParse(_userController.balance.value) ?? 0)}đ';
      _hasPin = _userController.hasPin.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(context),
      const Center(child: Text("Ưu đãi")),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: _selectedIndex == 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: AppBar(
                  title: _buildAvatar(context),
                  automaticallyImplyLeading: false,
                  toolbarHeight: 80,
                ),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: AppBar(automaticallyImplyLeading: false),
              ),
        body: Stack(
          children: [
            if (_selectedIndex == 0)
              Container(
                width: double.infinity,
                height: 500,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.pink.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            IndexedStack(index: _selectedIndex, children: pages),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final status = await Permission.camera.request();
            if (status.isGranted) {
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QrMainScreen()),
                );
              }
            } else {
              if (context.mounted) {
                SnackbarUtils.info(
                  context,
                  "Cần quyền camara để sử dụng chức năng này",
                );
              }
            }
          },
          backgroundColor: Colors.pink.shade400,
          shape: const CircleBorder(),
          child: const Icon(
            Iconsax.scan_barcode,
            color: Colors.white,
            size: 30,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNavItem(Iconsax.home_2, "Trang chủ", 0),
                    _buildNavItem(Iconsax.discount_shape, "Ưu đãi", 1),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNavItem(Iconsax.receipt, "Giao dịch", 2),
                    _buildNavItem(Iconsax.profile_circle, "Tôi", 3),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: Colors.pink,
        onRefresh: _onRefresh,
        child: ListView(
          padding: EdgeInsetsGeometry.fromLTRB(5, 0, 5, 0),
          children: [
            _buildWalletBalanceContainer(context),
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(20, 45, 20, 0),
              child: Row(
                children: [
                  Text(
                    "Tiện ích",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 10),
                    child: Text(
                      "Xem tất cả",
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildUtilList(context),
            Padding(
              padding: EdgeInsetsGeometry.only(left: 15, right: 15),
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/u.jpg', fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(5, 10, 5, 5),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              'https://orectic-noctilucent-ronan.ngrok-free.dev/images/avatar/default_avatar.png',
              headers: const {'ngrok-skip-browser-warning': 'true'},
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                "Xin chào,",
                style: GoogleFonts.roboto(color: Colors.grey, fontSize: 15),
              ),
              Text(
                _fullName,
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsetsGeometry.only(top: 20),
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Iconsax.notification,
                color: Colors.black.withValues(alpha: 0.8),
                size: 30,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalanceContainer(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(15, 5, 15, 5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Colors.pink.shade300, Colors.pink.shade400],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 15,
                  top: -85,
                  bottom: 0,
                  child: Icon(
                    Icons.wallet,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 120,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(15, 10, 0, 0),
                      child: Row(
                        children: [
                          Text(
                            "Số dư ví",
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isHidenWalletBalance = !_isHidenWalletBalance;
                                _balance =
                                    '${FormatUtils.formatDisplayNumber(num.tryParse(_userController.balance.value) ?? 0)}đ';
                              });
                            },
                            icon: Icon(
                              _isHidenWalletBalance
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(15, 0, 0, 10),
                      child: Text(
                        _isHidenWalletBalance ? "* * * * * * * *" : _balance,
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -35,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsetsGeometry.fromLTRB(40, 18, 40, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (!_hasPin) {
                          _showCreatePinDialog(context);
                          return;
                        }
                        _getBankLinkStatus(true);
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade100.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: EdgeInsetsGeometry.all(10),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade400,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Iconsax.wallet_add,
                                  color: Colors.white,
                                  size: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Nạp tiền",
                            style: GoogleFonts.roboto(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!_hasPin) {
                          _showCreatePinDialog(context);
                          return;
                        }
                        _getBankLinkStatus(false);
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade100.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: EdgeInsetsGeometry.all(10),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade400,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Iconsax.wallet_minus,
                                  color: Colors.white,
                                  size: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Rút tiền",
                            style: GoogleFonts.roboto(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!_hasPin) {
                          _showCreatePinDialog(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactListScreen(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade100.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: EdgeInsetsGeometry.all(10),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade400,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Iconsax.money_send,
                                  color: Colors.white,
                                  size: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Chuyển tiền",
                            style: GoogleFonts.roboto(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilList(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(15, 10, 20, 15),
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildUtilIcon(context, Iconsax.mobile, "Điện thoại"),
                    _buildUtilIcon(
                      context,
                      Iconsax.scan_barcode,
                      "Thanh toán QR",
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildUtilIcon(context, Iconsax.flash, "Điện"),
                    _buildUtilIcon(context, Iconsax.card, "Thẻ cào"),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildUtilIcon(context, Icons.water_drop_outlined, "Nước"),
                    _buildUtilIcon(context, Iconsax.airplane, "Vé máy bay"),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildUtilIcon(context, Iconsax.wifi, "Internet"),
                    _buildUtilIcon(context, Iconsax.more_square, "Xem thêm"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilIcon(BuildContext context, IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.pink.shade100.withValues(alpha: 0.3),
          ),
          child: Icon(icon, color: Colors.pink, size: 30),
        ),
        SizedBox(height: 5),
        Text(
          text,
          style: GoogleFonts.roboto(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String lable, int index) {
    bool isSelected = _selectedIndex == index;
    return MaterialButton(
      minWidth: 80,
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.pink.shade400 : Colors.grey),
          const SizedBox(height: 5),
          Text(
            lable,
            style: GoogleFonts.roboto(
              color: isSelected ? Colors.pink.shade400 : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePinDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CreatePinBottomSheet(
          onCreatePin: (pin) async {
            return await _userService.createPin(pin);
          },
          onSuccess: () {
            setState(() {
              _hasPin = true;
            });
            SnackbarUtils.success(context, "Tạo mã pin thành công");
          },
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    try {
      final result = await _userService.getMe();
      final homeData = await _appDataService.fetchHomeData();

      _userController.setUserData(
        newId: result['user_id'],
        newPhone: result['phone'],
        newFullName: result['full_name'],
        newBalance: homeData['balance'],
        newHasPin: homeData['has_pin'],
      );

      setState(() {
        _fullName = _userController.fullName.value;
        _balance =
            '${FormatUtils.formatDisplayNumber(num.tryParse(_userController.balance.value) ?? 0)}đ';
        _hasPin = _userController.hasPin.value;
      });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.failure(
          context,
          "Không thể tải dữ liệu. Vui lòng thử lại",
        );
      }
    }
  }

  Future<void> _getBankLinkStatus(bool isTopUpTab) async {
    try {
      final result = await _bankService.getBankLinkStatus();
      if (!mounted) return;
      if (result['data']['has_linked_account']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopUpWithdrawScreen(
              walletBalance: _balance,
              isTopUpTab: isTopUpTab,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LinkBankScreen(bankList: result['data']['available_banks']),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.failure(
          context,
          "Hệ thống đang bảo trì. Vui lòng thử lại sau",
        );
      }
    }
  }
}
