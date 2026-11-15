import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/create_pin_bottom_sheet.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/link_bank/link_bank_screen.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/services/user_service.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

class ManageLinkedBanksScreen extends StatefulWidget {
  const ManageLinkedBanksScreen({super.key});

  @override
  State<ManageLinkedBanksScreen> createState() =>
      _ManageLinkedBanksScreenState();
}

class _ManageLinkedBanksScreenState extends State<ManageLinkedBanksScreen> {
  final BankService _bankService = BankService();
  final WalletService _walletService = WalletService();
  final UserService _userService = UserService();
  final UserController _userController = Get.find<UserController>();
  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  final Set<String> _hidingBalanceIds = <String>{};
  List<Map<String, dynamic>> _linkedAccounts = [];
  List<dynamic> _availableBanks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final res = await _bankService.getBankLinkStatus();
    if (!mounted) return;
    if (res['is_success'] == true && res['data'] is Map) {
      final data = res['data'] as Map;
      final rawLinked = (data['linked_accounts'] as List?) ?? [];
      final rawAvailable = (data['available_banks'] as List?) ?? [];
      setState(() {
        _linkedAccounts = rawLinked
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _availableBanks = List<dynamic>.from(rawAvailable);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      SnackbarUtils.failure(
        context,
        res['message']?.toString() ?? 'Không thể tải danh sách ngân hàng',
      );
    }
  }

  Future<bool> _ensureHasPin() async {
    if (_userController.hasPin.value) return true;
    final hasPin = await _userService.checkPinStatus();
    if (hasPin) {
      _userController.hasPin.value = true;
      return true;
    }
    if (!mounted) return false;
    bool created = false;
    await showCreatePinDialog(
      context: context,
      onCreatePin: (pin) => _userService.createPin(pin),
      onSuccess: () {
        created = true;
        _userController.hasPin.value = true;
      },
    );
    return created;
  }

  Future<void> _onTapShowBalance(Map<String, dynamic> account) async {
    final String linkedAccountId = account['id']?.toString() ?? '';
    if (linkedAccountId.isEmpty) return;

    final hasPin = await _ensureHasPin();
    if (!hasPin || !mounted) return;

    final String idempotencyKey = _uuid.v7();

    await showCheckPinDialog(
      context: context,
      customTitle: 'Nhập mã PIN để xem số dư',
      onCheckPin: (pin) async {
        try {
          return await _walletService.checkPin(
            pin,
            idempotencyKey,
            action: 'BANK_SHOW_BALANCE',
            params: {'linked_bank_account_id': linkedAccountId},
          );
        } catch (_) {
          return {'is_success': false};
        }
      },
      onSuccess: (pinToken) async {
        final result = await _bankService.enableShowBalance(
          linkedAccountId,
          idempotencyKey,
          pinToken,
        );
        if (!mounted) return;
        if (result['is_success'] == true) {
          final updatedData = result['data'] as Map?;
          setState(() {
            final idx = _linkedAccounts.indexWhere(
              (item) => item['id']?.toString() == linkedAccountId,
            );
            if (idx != -1) {
              _linkedAccounts[idx]['is_show_balance'] = true;
              if (updatedData != null && updatedData['balance'] != null) {
                _linkedAccounts[idx]['balance'] = updatedData['balance'];
              }
            }
          });
          SnackbarUtils.success(
            context,
            result['message']?.toString() ?? 'Đã bật hiển thị số dư ngân hàng',
          );
        } else {
          SnackbarUtils.failure(
            context,
            result['message']?.toString() ?? 'Không thể bật hiển thị số dư',
          );
        }
      },
    );
  }

  Future<void> _onTapHideBalance(Map<String, dynamic> account) async {
    final String linkedAccountId = account['id']?.toString() ?? '';
    if (linkedAccountId.isEmpty ||
        _hidingBalanceIds.contains(linkedAccountId)) {
      return;
    }

    setState(() {
      _hidingBalanceIds.add(linkedAccountId);
    });

    final result = await _bankService.hideBalance(linkedAccountId);
    if (!mounted) return;

    setState(() {
      _hidingBalanceIds.remove(linkedAccountId);
      if (result['is_success'] == true) {
        final idx = _linkedAccounts.indexWhere(
          (item) => item['id']?.toString() == linkedAccountId,
        );
        if (idx != -1) {
          _linkedAccounts[idx]['is_show_balance'] = false;
          _linkedAccounts[idx]['balance'] = null;
        }
      }
    });

    if (result['is_success'] == true) {
      SnackbarUtils.success(
        context,
        result['message']?.toString() ?? 'Đã ẩn số dư ngân hàng',
      );
    } else {
      SnackbarUtils.failure(
        context,
        result['message']?.toString() ?? 'Không thể ẩn số dư ngân hàng',
      );
    }
  }

  Future<void> _onTapUnlinkBank(Map<String, dynamic> account) async {
    final String linkedAccountId = account['id']?.toString() ?? '';
    final String bankName =
        account['bank_name']?.toString() ?? 'ngân hàng này';
    if (linkedAccountId.isEmpty) return;

    bool confirmed = false;
    await DialogUtils.showConfirmation(
      context,
      title: 'Hủy liên kết ngân hàng',
      message: 'Bạn có chắc chắn muốn hủy liên kết $bankName khỏi Ví Mio không?',
      cancelText: 'Đóng',
      confirmText: 'Hủy liên kết',
      onConfirm: () {
        confirmed = true;
      },
    );

    if (!confirmed || !mounted) return;

    final hasPin = await _ensureHasPin();
    if (!hasPin || !mounted) return;

    final String idempotencyKey = _uuid.v7();

    await showCheckPinDialog(
      context: context,
      customTitle: 'Nhập mã PIN để hủy liên kết',
      onCheckPin: (pin) async {
        try {
          return await _walletService.checkPin(
            pin,
            idempotencyKey,
            action: 'BANK_UNLINK',
            params: {'linked_bank_account_id': linkedAccountId},
          );
        } catch (_) {
          return {'is_success': false};
        }
      },
      onSuccess: (pinToken) async {
        final result = await _bankService.unlinkBankAccount(
          linkedAccountId,
          idempotencyKey,
          pinToken,
        );
        if (!mounted) return;
        if (result['is_success'] == true) {
          SnackbarUtils.success(
            context,
            result['message']?.toString() ??
                'Đã hủy liên kết ngân hàng thành công',
          );
          await _loadData();
        } else {
          SnackbarUtils.failure(
            context,
            result['message']?.toString() ?? 'Hủy liên kết ngân hàng thất bại',
          );
        }
      },
    );
  }

  Future<void> _onTapAddBank() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LinkBankScreen(bankList: _availableBanks),
      ),
    );
    if (mounted) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FreezePinMediaQuery(
      child: AuthScaffold(
        appBarTitle: 'Ngân hàng liên kết',
        onBack: () => Navigator.pop(context),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(color: kAuthPink),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 6),
                  const AuthHeroBanner(
                    icon: Iconsax.bank,
                    badgeText: 'Quản lý nguồn tiền',
                    title: 'Ngân hàng đã liên kết',
                    subtitle:
                        'Bật xem số dư để hiển thị số dư ngân hàng khi nạp/rút hoặc thêm mới, hủy liên kết ngân hàng.',
                  ),
                  const SizedBox(height: 20),
                  if (_linkedAccounts.isEmpty)
                    _buildEmptyState()
                  else
                    for (final acc in _linkedAccounts) ...[
                      _buildLinkedBankCard(acc),
                      const SizedBox(height: 14),
                    ],
                  const SizedBox(height: 6),
                  _buildAddBankButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: authCardDeco(radius: 22),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kAuthPink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.bank,
              color: kAuthPinkDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có ngân hàng liên kết',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kAuthText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhấn nút bên dưới để chọn và liên kết ngân hàng với Ví Mio của bạn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 13.5,
              color: kAuthMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedBankCard(Map<String, dynamic> acc) {
    final String linkedAccountId = acc['id']?.toString() ?? '';
    final String bankName = acc['bank_name']?.toString() ?? 'Ngân hàng';
    final String bankCode = acc['bank_code']?.toString() ?? '';
    final String logoUrl = acc['logo_url']?.toString() ?? '';
    final String accountNumber = acc['account_number']?.toString() ?? '';
    final String holderName = acc['account_holder_name']?.toString() ?? '';
    final bool isShowBalance = acc['is_show_balance'] == true;
    final bool isHiding = _hidingBalanceIds.contains(linkedAccountId);
    final dynamic rawBalance = acc['balance'];
    final num balanceNum = rawBalance != null
        ? FormatUtils.formatAmountToNum(rawBalance.toString())
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: authCardDeco(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.network(
                    logoUrl,
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Iconsax.bank,
                      color: kAuthPinkDark,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bankName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: kAuthText,
                            ),
                          ),
                        ),
                        if (bankCode.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kAuthPink.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bankCode,
                              style: GoogleFonts.roboto(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: kAuthPinkDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$accountNumber • $holderName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: kAuthMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isShowBalance
                  ? const Color(0xFFE9F9EE)
                  : const Color(0xFFF6F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số dư ngân hàng',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kAuthMuted,
                  ),
                ),
                Text(
                  isShowBalance
                      ? '${FormatUtils.formatDisplayNumber(balanceNum)}đ'
                      : '••••••••',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isShowBalance
                        ? const Color(0xFF1B7A3D)
                        : kAuthMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: isShowBalance
                        ? (isHiding ? null : () => _onTapHideBalance(acc))
                        : () => _onTapShowBalance(acc),
                    icon: Icon(
                      isShowBalance ? Iconsax.eye_slash : Iconsax.eye,
                      size: 16,
                      color: isShowBalance ? kAuthText : kAuthPinkDark,
                    ),
                    label: Text(
                      isShowBalance
                          ? (isHiding ? 'Đang ẩn...' : 'Ẩn số dư')
                          : 'Xem số dư',
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isShowBalance ? kAuthText : kAuthPinkDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: BorderSide(
                        color: isShowBalance
                            ? Colors.grey.shade300
                            : kAuthPink.withValues(alpha: 0.5),
                      ),
                      backgroundColor: isShowBalance
                          ? Colors.grey.shade100
                          : kAuthPink.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => _onTapUnlinkBank(acc),
                    icon: const Icon(
                      Iconsax.trash,
                      size: 16,
                      color: Color(0xFFD32F2F),
                    ),
                    label: Text(
                      'Hủy liên kết',
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: BorderSide(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
                      ),
                      backgroundColor:
                          const Color(0xFFD32F2F).withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddBankButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onTapAddBank,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: kAuthPink.withValues(alpha: 0.45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: kAuthPink.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kAuthPink.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.add,
                  color: kAuthPinkDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Thêm ngân hàng liên kết',
                style: GoogleFonts.roboto(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: kAuthPinkDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

