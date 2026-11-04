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

const Color _kPink = Color(0xFFEC407A);
const Color _kPinkDark = Color(0xFFD81B60);
const Color _kPinkLight = Color(0xFFF48FB1);
const Color _kText = Color(0xFF1F1B24);
const Color _kMuted = Color(0xFF8A8590);

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(22),
  boxShadow: [
    BoxShadow(
      color: _kPink.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ],
);

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
  bool _isCheckingBank = false;
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
                height: 420,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kPink.withValues(alpha: 0.22),
                      _kPinkLight.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            IndexedStack(index: _selectedIndex, children: pages),
            if (_isCheckingBank)
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
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kPink.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () async {
              final status = await Permission.camera.request();
              if (status.isGranted) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QrMainScreen(),
                    ),
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
            elevation: 0,
            highlightElevation: 0,
            backgroundColor: _kPink,
            shape: const CircleBorder(),
            child: const Icon(
              Iconsax.scan_barcode,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          surfaceTintColor: Colors.transparent,
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
        color: _kPink,
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            _buildWalletBalanceContainer(context),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 22),
            _buildUtilList(context),
            const SizedBox(height: 22),
            _buildSectionTitle("Ưu đãi dành cho bạn"),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('assets/uu_dai.jpg', fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? action}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _kPink,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPink,
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_kPink, _kPinkLight]),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.network(
                  'https://orectic-noctilucent-ronan.ngrok-free.dev/images/avatar/default_avatar.png',
                  headers: const {'ngrok-skip-browser-warning': 'true'},
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 44,
                    height: 44,
                    color: _kPink.withValues(alpha: 0.12),
                    child: const Icon(Iconsax.user, color: _kPink),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Xin chào,",
                  style: GoogleFonts.roboto(color: _kMuted, fontSize: 13),
                ),
                Text(
                  _fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    color: _kText,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Iconsax.notification, color: _kText, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalanceContainer(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF06292), _kPinkDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPink.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: 50,
            bottom: -60,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 16,
            child: Icon(
              Iconsax.wallet_3,
              color: Colors.white.withValues(alpha: 0.25),
              size: 64,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 12, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      "Số dư ví",
                      style: GoogleFonts.roboto(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _isHidenWalletBalance = !_isHidenWalletBalance;
                          _balance =
                              '${FormatUtils.formatDisplayNumber(num.tryParse(_userController.balance.value) ?? 0)}đ';
                        });
                      },
                      icon: Icon(
                        _isHidenWalletBalance
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 22,
                      ),
                      color: Colors.white,
                    ),
                  ],
                ),

                Text(
                  _isHidenWalletBalance ? "• • • • • • • •" : _balance,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: _isHidenWalletBalance ? 2 : 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickAction(Iconsax.wallet_add, "Nạp tiền", () {
              if (!_hasPin) {
                _showCreatePinDialog(context);
                return;
              }
              _getBankLinkStatus(true);
            }),
          ),
          Expanded(
            child: _buildQuickAction(Iconsax.wallet_minus, "Rút tiền", () {
              if (!_hasPin) {
                _showCreatePinDialog(context);
                return;
              }
              _getBankLinkStatus(false);
            }),
          ),
          Expanded(
            child: _buildQuickAction(Iconsax.money_send, "Chuyển tiền", () {
              if (!_hasPin) {
                _showCreatePinDialog(context);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactListScreen()),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF06292), _kPinkDark],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _kPink.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: _kText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilList(BuildContext context) {
    final items = <MapEntry<IconData, String>>[
      const MapEntry(Iconsax.mobile, "Điện thoại"),
      const MapEntry(Iconsax.scan_barcode, "Thanh toán QR"),
      const MapEntry(Iconsax.flash, "Điện"),
      const MapEntry(Iconsax.card, "Thẻ cào"),
      const MapEntry(Icons.water_drop_outlined, "Nước"),
      const MapEntry(Iconsax.airplane, "Vé máy bay"),
      const MapEntry(Iconsax.wifi, "Internet"),
      const MapEntry(Iconsax.more_square, "Xem thêm"),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Tiện ích", action: "Xem tất cả"),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.85,
            children: [
              for (final e in items) _buildUtilIcon(context, e.key, e.value),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUtilIcon(BuildContext context, IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: _kPink.withValues(alpha: 0.09),
          ),
          child: Icon(icon, color: _kPink, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.roboto(fontSize: 12.5, color: _kText),
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
          Icon(icon, color: isSelected ? _kPink : Colors.grey),
          const SizedBox(height: 5),
          Text(
            lable,
            style: GoogleFonts.roboto(
              color: isSelected ? _kPink : Colors.grey,
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
    if (_isCheckingBank) return; // tránh bấm nhiều lần khi đang chờ
    setState(() => _isCheckingBank = true);
    try {
      final result = await _bankService.getBankLinkStatus();
      if (!mounted) return;
      if (result['data']['has_linked_account']) {
        Navigator.push(
          context,
          TopUpWithdrawScreen.route(
            walletBalance: _balance,
            isTopUpTab: isTopUpTab,
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
    } finally {
      if (mounted) setState(() => _isCheckingBank = false);
    }
  }
}
