import 'dart:io';
import 'dart:math' as math;

import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/route_transition_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/create_pin_bottom_sheet.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/kyc/kyc_guide_screen.dart';
import 'package:app/src/link_bank/manage_linked_banks_screen.dart';
import 'package:app/src/postpaid/confirm_postpaid_repay_screen.dart';
import 'package:app/src/postpaid/postpaid_entries_screen.dart';
import 'package:app/src/postpaid/postpaid_entry_widgets.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/services/postpaid_service.dart';
import 'package:app/src/services/user_service.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:app/src/transfer/transfer_funding_helper.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class PostpaidScreen extends StatefulWidget {
  const PostpaidScreen({
    super.key,
    this.postpaidService,
    this.walletService,
    this.bankService,
  });

  final PostpaidService? postpaidService;
  final WalletService? walletService;
  final BankService? bankService;

  @override
  State<PostpaidScreen> createState() => _PostpaidScreenState();
}

class _PostpaidScreenState extends State<PostpaidScreen> {
  late final PostpaidService _postpaidService =
      widget.postpaidService ?? PostpaidService();
  late final WalletService _walletService =
      widget.walletService ?? WalletService();
  late final BankService _bankService = widget.bankService ?? BankService();
  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  bool _isActivating = false;
  bool _isProcessingLifecycle = false;
  bool _didScheduleInitialLoad = false;
  VoidCallback? _cancelDeferredLoad;
  String? _errorMsg;

  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _entries = [];
  bool _hasMoreEntries = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didScheduleInitialLoad) {
      _didScheduleInitialLoad = true;
      // Đợi hiệu ứng mở màn hình hoàn tất rồi mới tải API Ví trả sau.
      _cancelDeferredLoad = runAfterRouteTransition(context, _loadData);
    }
  }

  @override
  void dispose() {
    _cancelDeferredLoad?.call();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });
    }

    final walletRes = await _postpaidService.getWallet();
    if (!mounted) return;

    if (walletRes['is_success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMsg =
            walletRes['message'] ?? 'Không thể tải thông tin Ví trả sau';
      });
      return;
    }

    final walletData = Map<String, dynamic>.from(walletRes['data'] as Map);
    List<Map<String, dynamic>> entries = [];
    bool hasMoreEntries = false;

    if (walletData['activated'] == true) {
      final entriesRes = await _postpaidService.getEntries(limit: 5);
      if (!mounted) return;
      if (entriesRes['is_success'] == true && entriesRes['data'] is Map) {
        final rawList = (entriesRes['data']['entries'] as List?) ?? const [];
        entries = rawList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        hasMoreEntries = entriesRes['data']['next_cursor'] != null;
      }
    }

    if (!mounted) return;
    setState(() {
      _wallet = walletData;
      _entries = entries;
      _hasMoreEntries = hasMoreEntries;
      _isLoading = false;
    });
  }

  void _openEntriesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostpaidEntriesScreen()),
    );
  }

  bool _ensurePinReady(VoidCallback onPinCreated) {
    if (Get.isRegistered<UserController>() &&
        !Get.find<UserController>().hasPin.value) {
      showSmoothPinBottomSheet(
        context: context,
        builder: (sheetCtx) => CreatePinBottomSheet(
          onCreatePin: (pin) => UserService().createPin(pin),
          onSuccess: () {
            if (Get.isRegistered<UserController>()) {
              Get.find<UserController>().hasPin.value = true;
            }
            if (!mounted) return;
            SnackbarUtils.success(context, 'Tạo mã PIN thành công');
            onPinCreated();
          },
        ),
      );
      return false;
    }
    return true;
  }

  void _runPinVerifiedAction({
    required String checkTitle,
    required String action,
    Map<String, dynamic> params = const <String, dynamic>{},
    required Future<Map<String, dynamic>> Function(
      String idempotencyKey,
      String pinToken,
    )
    request,
    required String Function(Map<String, dynamic> res) successMessage,
    required String defaultErrorMessage,
    void Function(Map<String, dynamic> res)? onSuccessResult,
    bool Function()? isBusy,
    ValueChanged<bool>? setBusy,
  }) {
    if (isBusy?.call() == true || _isProcessingLifecycle) return;
    if (!_ensurePinReady(() {
      _runPinVerifiedAction(
        checkTitle: checkTitle,
        action: action,
        params: params,
        request: request,
        successMessage: successMessage,
        defaultErrorMessage: defaultErrorMessage,
        onSuccessResult: onSuccessResult,
        isBusy: isBusy,
        setBusy: setBusy,
      );
    })) {
      return;
    }

    final idempotencyKey = _uuid.v7();

    showCheckPinDialog(
      context: context,
      customTitle: checkTitle,
      onCheckPin: (pin) => _walletService.checkPin(
        pin,
        idempotencyKey,
        action: action,
        params: params,
      ),
      onSuccess: (pinToken) async {
        if (!mounted || isBusy?.call() == true || _isProcessingLifecycle) {
          return;
        }
        setState(() {
          _isProcessingLifecycle = true;
          setBusy?.call(true);
        });
        try {
          final res = await request(idempotencyKey, pinToken);
          if (!mounted) return;
          if (res['is_success'] == true) {
            onSuccessResult?.call(res);
            SnackbarUtils.success(context, successMessage(res));
            await _loadData();
          } else {
            SnackbarUtils.failure(
              context,
              res['message'] ?? defaultErrorMessage,
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isProcessingLifecycle = false;
              setBusy?.call(false);
            });
          }
        }
      },
    );
  }

  Future<void> _handleActivate() async {
    _runPinVerifiedAction(
      checkTitle: 'Xác thực kích hoạt Ví trả sau',
      action: 'POSTPAID_ACTIVATE',
      isBusy: () => _isActivating,
      setBusy: (busy) => _isActivating = busy,
      request: (idempotencyKey, pinToken) => _postpaidService.activate(
        idempotencyKey: idempotencyKey,
        pinToken: pinToken,
      ),
      successMessage: (_) => 'Kích hoạt Ví trả sau thành công!',
      defaultErrorMessage: 'Không thể kích hoạt Ví trả sau',
    );
  }

  void _openManageWalletSheet() {
    final wallet = _wallet;
    if (wallet == null || wallet['activated'] != true) return;

    final status = (wallet['status'] ?? 'ACTIVE').toString();
    final lockReason = (wallet['lock_reason'] ?? '').toString();
    final usedAmount = _toInt(wallet['used_amount']);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _ManagePostpaidWalletSheet(
        status: status,
        lockReason: lockReason,
        usedAmount: usedAmount,
        onFreezeTap: () {
          Navigator.pop(sheetCtx);
          _confirmFreezeWallet();
        },
        onUnfreezeTap: () {
          Navigator.pop(sheetCtx);
          _confirmUnfreezeWallet();
        },
        onCloseTap: () {
          Navigator.pop(sheetCtx);
          if (usedAmount > 0) {
            SnackbarUtils.info(
              context,
              'Vui lòng thanh toán hết dư nợ trước khi hủy Ví trả sau',
            );
            return;
          }
          _openCloseWalletFlow();
        },
      ),
    );
  }

  Future<void> _confirmFreezeWallet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Tạm khóa Ví trả sau?',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kTfText,
          ),
        ),
        content: Text(
          'Trong thời gian tạm khóa, bạn sẽ không thể dùng Ví trả sau để thanh toán QR. Hạn mức và lịch sử sao kê vẫn được giữ nguyên, và bạn vẫn có thể thanh toán dư nợ hoặc mở khóa bất cứ lúc nào.',
          style: GoogleFonts.roboto(
            fontSize: 14,
            height: 1.45,
            color: kTfMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                color: kTfMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kTfPink,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Tiếp tục',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    _runPinVerifiedAction(
      checkTitle: 'Xác thực tạm khóa Ví trả sau',
      action: 'POSTPAID_FREEZE',
      request: (idempotencyKey, pinToken) => _postpaidService.freezeWallet(
        idempotencyKey: idempotencyKey,
        pinToken: pinToken,
      ),
      successMessage: (res) =>
          res['message']?.toString() ?? 'Đã tạm khóa Ví trả sau',
      defaultErrorMessage: 'Không thể tạm khóa Ví trả sau',
    );
  }

  void _confirmUnfreezeWallet() {
    _runPinVerifiedAction(
      checkTitle: 'Xác thực mở khóa Ví trả sau',
      action: 'POSTPAID_UNFREEZE',
      request: (idempotencyKey, pinToken) => _postpaidService.unfreezeWallet(
        idempotencyKey: idempotencyKey,
        pinToken: pinToken,
      ),
      successMessage: (res) =>
          res['message']?.toString() ?? 'Đã mở khóa Ví trả sau',
      defaultErrorMessage: 'Không thể mở khóa Ví trả sau',
    );
  }

  Future<void> _openCloseWalletFlow() async {
    final usedAmount = _toInt(_wallet?['used_amount']);
    if (usedAmount > 0) {
      SnackbarUtils.info(
        context,
        'Vui lòng thanh toán hết dư nợ trước khi hủy Ví trả sau',
      );
      return;
    }

    final reason = await showSmoothPinBottomSheet<String>(
      context: context,
      builder: (_) => const _ClosePostpaidWalletSheet(),
    );

    if (reason == null || !mounted) return;
    _runPinVerifiedAction(
      checkTitle: 'Xác thực hủy Ví trả sau',
      action: 'POSTPAID_CLOSE',
      request: (idempotencyKey, pinToken) => _postpaidService.closeWallet(
        idempotencyKey: idempotencyKey,
        pinToken: pinToken,
        reason: reason,
      ),
      successMessage: (res) =>
          res['message']?.toString() ?? 'Đã hủy kích hoạt Ví trả sau',
      defaultErrorMessage: 'Không thể hủy Ví trả sau',
    );
  }

  int _toInt(dynamic v) {
    if (v is num) return v.round();
    return num.tryParse(v?.toString() ?? '0')?.round() ?? 0;
  }

  String _formatDateOnly(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '--/--/----';
    final datePart = rawDate.trim().split('T').first;
    final parts = datePart.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return rawDate;
  }

  void _openInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _PostpaidInfoSheet(service: _postpaidService),
    );
  }

  Future<void> _openRepaySheet() async {
    final wallet = _wallet;
    if (wallet == null) return;

    final usedAmount = _toInt(wallet['used_amount']);
    if (usedAmount <= 0) {
      SnackbarUtils.info(context, 'Bạn hiện không có dư nợ cần thanh toán');
      return;
    }

    if (!_ensurePinReady(_openRepaySheet)) return;

    final billedAmount = _toInt(wallet['billed_amount']);
    final serviceFeeAmount = _toInt(wallet['service_fee_amount']);
    final lateFeeAmount = _toInt(wallet['late_fee_amount']);
    final mainBalance = _toInt(wallet['main_balance']);
    final dueTotal = billedAmount + serviceFeeAmount + lateFeeAmount;
    final defaultAmount = dueTotal > 0 ? dueTotal : usedAmount;
    final unbilledAmount = math.max(0, usedAmount - dueTotal);

    final selection = await showSmoothPinBottomSheet<_RepaySelectionResult>(
      context: context,
      builder: (_) => _RepayPostpaidSheet(
        usedAmount: usedAmount,
        dueTotal: dueTotal,
        mainBalance: mainBalance,
        defaultAmount: defaultAmount,
        bankService: _bankService,
      ),
    );

    if (selection == null || !mounted) return;

    final isServiceFeeOnly =
        serviceFeeAmount > 0 &&
        lateFeeAmount == 0 &&
        billedAmount == 0 &&
        unbilledAmount == 0 &&
        selection.amount <= serviceFeeAmount;

    final repayRes = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmPostpaidRepayScreen(
          amount: selection.amount,
          mainBalance: mainBalance,
          isServiceFeeOnly: isServiceFeeOnly,
          initialFundingSource: selection.resolution.initialFundingSource,
          initialLinkedBankAccountId:
              selection.resolution.initialLinkedBankAccountId,
          initialLinkedBanks: selection.resolution.linkedBanks,
        ),
      ),
    );

    if (repayRes != null && repayRes['is_success'] == true && mounted) {
      SnackbarUtils.success(
        context,
        isServiceFeeOnly
            ? 'Đã thanh toán ${FormatUtils.formatDisplayNumber(selection.amount)}đ phí dịch vụ Ví trả sau'
            : 'Đã thanh toán ${FormatUtils.formatDisplayNumber(selection.amount)}đ dư nợ Ví trả sau',
      );
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FreezeKeyboardMediaQuery(
      child: Scaffold(
        backgroundColor: kTfBg,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: kTfBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTfText),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Ví trả sau',
            style: GoogleFonts.roboto(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: kTfText,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Thông tin Ví trả sau',
              icon: const Icon(Iconsax.info_circle, color: kTfText, size: 22),
              onPressed: _openInfoSheet,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kTfPink));
    }

    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 48, color: kTfPink),
              const SizedBox(height: 12),
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 15, color: kTfText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTfPink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final wallet = _wallet!;
    if (wallet['activated'] != true) {
      return _buildOnboardingView(wallet);
    }
    return _buildActiveDashboard(wallet);
  }

  Widget _buildOnboardingView(Map<String, dynamic> wallet) {
    final config = (wallet['config'] is Map)
        ? Map<String, dynamic>.from(wallet['config'] as Map)
        : <String, dynamic>{};
    final defaultLimit = _toInt(
      config['default_credit_limit'] ?? wallet['credit_limit'] ?? 2000000,
    );
    final billingDay = _toInt(config['billing_day'] ?? 20);
    final dueDay = _toInt(config['due_day'] ?? 5);
    final isKyc = wallet['is_kyc'] == true;
    final hasLinkedBank = wallet['has_linked_bank'] == true;
    final isAgeEligible = wallet['is_account_age_eligible'] != false;
    final ageHours = _toInt(wallet['account_age_hours'] ?? 0);
    final minHours = _toInt(wallet['min_account_hours'] ?? 24);
    final eligible = wallet['eligible_to_activate'] == true;
    final reason = wallet['ineligible_reason']?.toString();

    return RefreshIndicator(
      color: kTfPink,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF06292), kTfPinkDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: kTfPink.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.credit_score_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LumaPay PayLater',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Hạn mức cấp sẵn lên đến',
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${FormatUtils.formatDisplayNumber(defaultLimit)}đ',
                  style: GoogleFonts.roboto(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chi tiêu QR trước, thanh toán lại vào kỳ sao kê hàng tháng với 0đ phí mở ví.',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: transferCardDeco(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quy tắc sử dụng',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTfText,
                  ),
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  Iconsax.scan_barcode,
                  'Thanh toán QR tiện lợi',
                  'Dùng hạn mức Ví trả sau khi quét mã QR thanh toán đơn hàng.',
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Iconsax.calendar_tick,
                  'Chu kỳ sao kê minh bạch',
                  'Chốt sao kê ngày $billingDay hàng tháng, hạn thanh toán ngày $dueDay tháng sau.',
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Iconsax.shield_tick,
                  'Bảo vệ ví chính',
                  'Hạn mức tín dụng không chuyển P2P hay rút về ví chính để đảm bảo an toàn.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: transferCardDeco(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Điều kiện mở ví',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTfText,
                  ),
                ),
                const SizedBox(height: 12),
                _buildConditionRow(
                  met: isKyc,
                  title: 'Xác thực danh tính (eKYC)',
                  subtitle: isKyc
                      ? 'Đã xác thực'
                      : 'Chưa hoàn tất xác thực eKYC',
                ),
                const SizedBox(height: 10),
                _buildConditionRow(
                  met: hasLinkedBank,
                  title: 'Liên kết ít nhất 1 tài khoản ngân hàng',
                  subtitle: hasLinkedBank
                      ? 'Đã liên kết ngân hàng'
                      : 'Chưa có tài khoản ngân hàng liên kết',
                ),
                const SizedBox(height: 10),
                _buildConditionRow(
                  met: isAgeEligible,
                  title: 'Tài khoản hoạt động tối thiểu $minHours giờ',
                  subtitle: isAgeEligible
                      ? 'Đã đủ thời gian hoạt động'
                      : 'Tài khoản mới tạo $ageHours/$minHours giờ',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!isKyc)
            ..._buildOnboardingActionPrompt(
              icon: Iconsax.personalcard,
              message:
                  'Bạn cần hoàn tất xác thực danh tính (eKYC) để kích hoạt Ví trả sau.',
              buttonLabel: 'Xác thực eKYC ngay',
              destinationBuilder: () => const KycGuideScreen(),
            )
          else if (!hasLinkedBank)
            ..._buildOnboardingActionPrompt(
              icon: Iconsax.bank,
              message:
                  'Bạn cần liên kết ít nhất 1 tài khoản ngân hàng để kích hoạt Ví trả sau.',
              buttonLabel: 'Liên kết ngân hàng ngay',
              destinationBuilder: () => const ManageLinkedBanksScreen(),
            )
          else if (eligible) ...[
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isActivating ? null : _handleActivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTfPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isActivating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(
                        'Kích hoạt Ví trả sau ngay',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                reason ?? 'Tài khoản hiện chưa đủ điều kiện mở Ví trả sau',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: kTfMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildOnboardingActionPrompt({
    required IconData icon,
    required String message,
    required String buttonLabel,
    required Widget Function() destinationBuilder,
  }) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF57C00), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  color: const Color(0xFF795548),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destinationBuilder()),
            ).then((_) => _loadData());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kTfPink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            buttonLabel,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildConditionRow({
    required bool met,
    required String title,
    required String subtitle,
  }) {
    final Color statusColor = met
        ? const Color(0xFF2E9E5B)
        : const Color(0xFFF57C00);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.schedule_rounded,
          color: statusColor,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTfText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  color: met ? const Color(0xFF2E9E5B) : kTfMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: kTfPink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kTfPink, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: kTfText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: kTfMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDashboard(Map<String, dynamic> wallet) {
    final status = (wallet['status'] ?? 'ACTIVE').toString();
    final isPastDue = status == 'PAST_DUE';
    final isFrozen = status == 'FROZEN';

    final creditLimit = _toInt(wallet['credit_limit']);
    final usedAmount = _toInt(wallet['used_amount']);
    final availableLimit = _toInt(wallet['available_limit']);
    final billedAmount = _toInt(wallet['billed_amount']);
    final serviceFeeAmount = _toInt(wallet['service_fee_amount']);
    final lateFeeAmount = _toInt(wallet['late_fee_amount']);
    final unbilledAmount = _toInt(wallet['unbilled_amount']);
    final dueDateStr = _formatDateOnly(wallet['due_date']?.toString());
    final cycleMonth = wallet['current_cycle_month']?.toString();
    final progress = creditLimit > 0
        ? (usedAmount / creditLimit).clamp(0.0, 1.0)
        : 0.0;

    return RefreshIndicator(
      color: kTfPink,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPastDue
                    ? [const Color(0xFFEF5350), const Color(0xFFC62828)]
                    : isFrozen
                    ? [const Color(0xFF64748B), const Color(0xFF475569)]
                    : [const Color(0xFFF06292), kTfPinkDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color:
                      (isPastDue
                              ? Colors.red
                              : isFrozen
                              ? const Color(0xFF475569)
                              : kTfPink)
                          .withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hạn mức khả dụng',
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPastDue
                            ? 'Quá hạn thanh toán'
                            : isFrozen
                            ? 'Đang tạm khóa'
                            : 'Đang hoạt động',
                        style: GoogleFonts.roboto(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${FormatUtils.formatDisplayNumber(availableLimit)}đ',
                  style: GoogleFonts.roboto(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.28),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã dùng: ${FormatUtils.formatDisplayNumber(usedAmount)}đ',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    Text(
                      'Tổng hạn mức: ${FormatUtils.formatDisplayNumber(creditLimit)}đ',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: transferCardDeco(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết dư nợ',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTfText,
                      ),
                    ),
                    if (cycleMonth != null &&
                        (billedAmount + serviceFeeAmount) > 0)
                      Text(
                        'Kỳ ${formatPostpaidCycleMonth(cycleMonth)} • Hạn $dueDateStr',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: isPastDue ? Colors.red.shade700 : kTfMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDebtRow(
                  'Dư nợ đã chốt sao kê',
                  '${FormatUtils.formatDisplayNumber(billedAmount)}đ',
                ),
                if (serviceFeeAmount > 0) ...[
                  const SizedBox(height: 10),
                  _buildDebtRow(
                    'Phí dịch vụ tháng',
                    '${FormatUtils.formatDisplayNumber(serviceFeeAmount)}đ',
                    valueColor: const Color(0xFFD97706),
                  ),
                ],
                if (lateFeeAmount > 0) ...[
                  const SizedBox(height: 10),
                  _buildDebtRow(
                    'Phí trễ hạn',
                    '${FormatUtils.formatDisplayNumber(lateFeeAmount)}đ',
                    valueColor: Colors.red.shade700,
                  ),
                ],
                const SizedBox(height: 10),
                _buildDebtRow(
                  'Chi tiêu chưa chốt kỳ',
                  '${FormatUtils.formatDisplayNumber(unbilledAmount)}đ',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildDebtRow(
                  'Tổng dư nợ hiện tại',
                  '${FormatUtils.formatDisplayNumber(usedAmount)}đ',
                  isBold: true,
                  valueColor: usedAmount > 0 ? kTfPinkDark : kTfSuccess,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: usedAmount > 0 ? _openRepaySheet : null,
                    icon: const Icon(Iconsax.wallet_check, size: 20),
                    label: Text(
                      usedAmount > 0
                          ? 'Thanh toán dư nợ'
                          : 'Không có dư nợ cần trả',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTfPink,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFreezeUnlockSection(),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isProcessingLifecycle ? null : _openManageWalletSheet,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: transferCardDeco(radius: 18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kTfPink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.setting_2,
                      color: kTfPinkDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản lý Ví trả sau',
                          style: GoogleFonts.roboto(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: kTfText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFrozen
                              ? ((wallet['lock_reason'] ?? '')
                                              .toString()
                                              .toUpperCase() ==
                                          'ADMIN_FREEZE' ||
                                      (wallet['lock_reason'] ?? '')
                                              .toString()
                                              .toUpperCase() ==
                                          'OVERDUE_REPEAT')
                                  ? 'Ví đang khóa chi tiêu • Xem thông tin trạng thái'
                                  : 'Ví đang tạm khóa chi tiêu • Nhấn để mở khóa hoặc hủy ví'
                              : 'Tạm khóa chi tiêu hoặc hủy dịch vụ Ví trả sau',
                          style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            color: kTfMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: kTfMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch sử biến động hạn mức',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTfText,
                  ),
                ),
              ),
              TextButton(
                onPressed: _openEntriesScreen,
                style: TextButton.styleFrom(
                  foregroundColor: kTfPinkDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem tất cả',
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: transferCardDeco(radius: 18),
              child: Center(
                child: Text(
                  'Chưa có giao dịch hoặc biến động nào.',
                  style: GoogleFonts.roboto(fontSize: 14, color: kTfMuted),
                ),
              ),
            )
          else ...[
            ..._entries.map((entry) => PostpaidEntryTile(entry: entry)),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton.icon(
                onPressed: _openEntriesScreen,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTfPinkDark,
                  side: BorderSide(color: kTfPink.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Iconsax.search_normal_1, size: 17),
                label: Text(
                  _hasMoreEntries
                      ? 'Tìm kiếm, lọc & xem thêm biến động'
                      : 'Tìm kiếm & lọc lịch sử biến động',
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebtRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: isBold ? 14.5 : 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? kTfText : kTfMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? kTfText,
          ),
        ),
      ],
    );
  }

  Widget _buildFreezeUnlockSection() {
    final wallet = _wallet;
    if (wallet == null) return const SizedBox.shrink();

    final status = (wallet['status'] ?? 'ACTIVE').toString().toUpperCase();
    final lockReason = (wallet['lock_reason'] ?? '').toString().toUpperCase();
    final overdueCount = _toInt(wallet['overdue_count']);
    final overdueDebt =
        _toInt(wallet['billed_amount']) +
        _toInt(wallet['service_fee_amount']) +
        _toInt(wallet['late_fee_amount']);
    final rawLatest = wallet['latest_unlock_request'];
    final latestReq = rawLatest is Map
        ? Map<String, dynamic>.from(rawLatest)
        : null;

    if (status != 'FROZEN' && latestReq == null) {
      return const SizedBox.shrink();
    }

    final reqStatus = (latestReq?['status'] ?? '').toString().toUpperCase();
    final adminNote = (latestReq?['admin_note'] ?? '').toString().trim();
    final userNote = (latestReq?['user_note'] ?? '').toString().trim();
    final proofCount = _toInt(latestReq?['proof_count']);
    final isRepeatLock = status == 'FROZEN' && lockReason == 'OVERDUE_REPEAT';
    final isUserFreeze =
        status == 'FROZEN' && (lockReason.isEmpty || lockReason == 'USER_FREEZE');
    final canSubmitUnlock =
        isRepeatLock && reqStatus != 'PENDING' && overdueDebt == 0;

    String titleText = 'Trạng thái Ví trả sau';
    String descText = '';
    Color accentColor = Colors.orange.shade800;
    Color bgColor = const Color(0xFFFFF8E1);
    Color borderColor = const Color(0xFFFFE082);

    if (status == 'FROZEN') {
      if (isRepeatLock) {
        titleText = 'Ví bị khóa do quá hạn lặp lại (Lần $overdueCount)';
        descText =
            'Để bảo vệ hạn mức tín dụng, hệ thống tạm khóa tính năng thanh toán QR từ lần quá hạn thứ 2 trở đi. Sau khi trả hết dư nợ quá hạn, hãy gửi 1–3 ảnh chứng minh thu nhập để Quản trị viên xét duyệt mở lại.';
        accentColor = Colors.red.shade800;
        bgColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFFFCDD2);
      } else if (lockReason == 'ADMIN_FREEZE') {
        titleText = 'Ví đã bị Quản trị viên tạm khóa';
        descText =
            'Tính năng chi tiêu QR đang tạm khóa theo quyết định quản trị. Bạn vẫn có thể thanh toán dư nợ bình thường.';
      } else {
        titleText = 'Ví trả sau đang tạm khóa';
        descText = 'Bạn vẫn có thể thanh toán dư nợ hiện tại bình thường.';
      }
    } else if (latestReq != null) {
      titleText = 'Hồ sơ xét duyệt mở lại Ví trả sau';
      descText = 'Trạng thái hồ sơ gần nhất của bạn:';
      accentColor = kTfPinkDark;
      bgColor = const Color(0xFFFDF2F8);
      borderColor = const Color(0xFFFBCFE8);
    }

    String reqLabel(String st) {
      switch (st) {
        case 'PENDING':
          return 'Đang chờ Quản trị viên duyệt';
        case 'APPROVED':
          return 'Đã duyệt mở lại ví';
        case 'REJECTED':
          return 'Đã từ chối — Cần bổ sung hồ sơ';
        default:
          return st;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status == 'FROZEN' ? Iconsax.lock_1 : Iconsax.document_text,
                  size: 20,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titleText,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            if (descText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                descText,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  height: 1.45,
                  color: kTfText,
                ),
              ),
            ],
            if (latestReq != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor.withValues(alpha: 0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hồ sơ gần nhất: ${reqLabel(reqStatus)} ($proofCount ảnh)',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: reqStatus == 'REJECTED'
                            ? Colors.red.shade700
                            : reqStatus == 'APPROVED'
                            ? kTfSuccess
                            : Colors.orange.shade800,
                      ),
                    ),
                    if (userNote.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ghi chú của bạn: $userNote',
                        style: GoogleFonts.roboto(
                          fontSize: 12.5,
                          color: kTfMuted,
                        ),
                      ),
                    ],
                    if (adminNote.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Phản hồi Admin: $adminNote',
                        style: GoogleFonts.roboto(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: kTfText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (isRepeatLock) ...[
              const SizedBox(height: 12),
              if (overdueDebt > 0)
                Text(
                  'Còn ${FormatUtils.formatDisplayNumber(overdueDebt)}đ dư nợ quá hạn cần tất toán trước khi gửi ảnh chứng minh thu nhập.',
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                  ),
                )
              else if (reqStatus == 'PENDING')
                Text(
                  'Hồ sơ chứng minh thu nhập đang được Quản trị viên kiểm tra. Vui lòng chờ kết quả.',
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: canSubmitUnlock ? _openUnlockRequestSheet : null,
                    icon: const Icon(Iconsax.gallery_add, size: 18),
                    label: Text(
                      reqStatus == 'REJECTED'
                          ? 'Gửi lại ảnh chứng minh thu nhập'
                          : 'Gửi yêu cầu mở khóa & chứng minh thu nhập',
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTfPink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
            if (isUserFreeze) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  key: const Key('btn-postpaid-quick-unfreeze'),
                  onPressed: _isProcessingLifecycle
                      ? null
                      : _confirmUnfreezeWallet,
                  icon: const Icon(Iconsax.unlock, size: 15),
                  label: Text(
                    'Mở khóa ví',
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openUnlockRequestSheet() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PostpaidUnlockRequestSheet(service: _postpaidService),
    );
    if (submitted == true && mounted) {
      await _loadData();
    }
  }
}

class _PostpaidInfoSheet extends StatefulWidget {
  final PostpaidService service;

  const _PostpaidInfoSheet({required this.service});

  @override
  State<_PostpaidInfoSheet> createState() => _PostpaidInfoSheetState();
}

class _PostpaidInfoSheetState extends State<_PostpaidInfoSheet> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _info;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.service.getWalletInfo();
    if (!mounted) return;
    if (res['is_success'] == true && res['data'] is Map) {
      setState(() {
        _info = Map<String, dynamic>.from(res['data'] as Map);
        _loading = false;
      });
    } else {
      setState(() {
        _error = (res['message'] ?? 'Không thể tải thông tin Ví trả sau')
            .toString();
        _loading = false;
      });
    }
  }

  int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _asMap(dynamic val) {
    if (val is Map) return Map<String, dynamic>.from(val);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.86;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: kTfPink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.info_circle,
                      color: kTfPink,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin & quy định Ví trả sau',
                          style: GoogleFonts.roboto(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kTfText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Biểu phí, lịch chốt sổ và quy tắc thanh toán',
                          style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            color: kTfMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: kTfPink),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 13.5,
                            color: kTfMuted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _fetchInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kTfPink,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            'Thử lại',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildInfoContent(_info ?? const {}),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoContent(Map<String, dynamic> info) {
    final config = _asMap(info['config']);
    final statement = _asMap(info['statement_cycle']);
    final feeRules = _asMap(info['fee_rules']);
    final feeExample = _asMap(feeRules['example']);
    final repayment = _asMap(info['repayment_rules']);
    final activation = _asMap(info['activation_rules']);

    final creditLimit = _toInt(config['default_credit_limit']);
    final billingDay = _toInt(
      statement['billing_day'] ?? config['billing_day'],
    );
    final dueDay = _toInt(statement['due_day'] ?? config['due_day']);
    final minLateFee = _toInt(
      feeRules['min_late_fee'] ?? config['min_late_fee'],
    );
    final lateFeePercent =
        (feeRules['late_fee_percent'] ?? config['late_fee_percent'] ?? 0)
            .toString();
    final rawTiers = feeRules['late_fee_tiers'];
    final lateFeeTiers = rawTiers is List
        ? rawTiers
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : const <Map<String, dynamic>>[];
    final serviceFeeRuleText = (feeRules['service_fee_rule'] ?? '').toString();
    final activationFee = _toInt(feeRules['activation_fee']);
    final qrPaymentFee = _toInt(feeRules['qr_payment_fee']);
    final repaymentFee = _toInt(feeRules['repayment_fee']);

    String formatFee(int amount) => amount == 0
        ? 'Miễn phí'
        : '${FormatUtils.formatDisplayNumber(amount)}đ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kTfBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildMetricRow(
                'Hạn mức mặc định',
                '${FormatUtils.formatDisplayNumber(creditLimit)}đ',
              ),
              const SizedBox(height: 8),
              _buildMetricRow(
                'Ngày chốt sao kê',
                'Ngày $billingDay hàng tháng',
              ),
              const SizedBox(height: 8),
              _buildMetricRow('Hạn thanh toán', 'Ngày $dueDay tháng kế tiếp'),
              const SizedBox(height: 8),
              if (lateFeeTiers.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Biểu phí chậm trả (4 bậc ngày quá hạn)',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: kTfMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ...lateFeeTiers.map((tier) {
                  final label = (tier['label'] ?? 'Bậc ${tier['tier']}')
                      .toString();
                  final pct = (tier['percent_text'] ?? tier['percent'] ?? 0)
                      .toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildMetricRow(
                      '  • $label',
                      '$pct% dư nợ quá hạn',
                      valueColor: const Color(0xFFD32F2F),
                    ),
                  );
                }),
              ] else
                _buildMetricRow(
                  'Phí trễ hạn',
                  minLateFee > 0
                      ? '$lateFeePercent% (tối thiểu ${FormatUtils.formatDisplayNumber(minLateFee)}đ)'
                      : '$lateFeePercent%',
                  valueColor: const Color(0xFFD32F2F),
                ),
              if (serviceFeeRuleText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    serviceFeeRuleText,
                    style: GoogleFonts.roboto(fontSize: 12.5, color: kTfMuted),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          icon: Icons.event_note_rounded,
          title: 'Quy tắc chốt sổ & hạn thanh toán',
          bullets: [
            if ((statement['summary'] ?? '').toString().isNotEmpty)
              statement['summary'].toString(),
            if ((statement['due_rule'] ?? '').toString().isNotEmpty)
              statement['due_rule'].toString(),
            if ((statement['overdue_rule'] ?? '').toString().isNotEmpty)
              statement['overdue_rule'].toString(),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          icon: Icons.percent_rounded,
          title: 'Cách tính phí',
          bullets: [
            'Phí kích hoạt ví: ${formatFee(activationFee)}',
            'Phí thanh toán QR bằng Ví trả sau: ${formatFee(qrPaymentFee)}',
            'Phí thanh toán dư nợ: ${formatFee(repaymentFee)}',
            if ((feeRules['summary'] ?? '').toString().isNotEmpty)
              feeRules['summary'].toString(),
          ],
          highlightText: (feeExample['description'] ?? '').toString(),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Thứ tự trả nợ & điều kiện sử dụng',
          bullets: [
            if ((repayment['summary'] ?? '').toString().isNotEmpty)
              repayment['summary'].toString(),
            if ((repayment['unlock_rule'] ?? '').toString().isNotEmpty)
              repayment['unlock_rule'].toString(),
            if ((activation['summary'] ?? '').toString().isNotEmpty)
              activation['summary'].toString(),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            color: kTfMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.roboto(
              fontSize: 13.5,
              color: valueColor ?? kTfText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<String> bullets,
    String? highlightText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kTfPink, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: kTfText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in bullets) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTfPink,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: kTfText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (highlightText != null && highlightText.trim().isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kTfPink.withValues(alpha: 0.25)),
              ),
              child: Text(
                highlightText,
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  color: kTfText,
                  height: 1.38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RepaySelectionResult {
  final int amount;
  final TransferFundingResolution resolution;

  const _RepaySelectionResult({required this.amount, required this.resolution});
}

class _RepayPostpaidSheet extends StatefulWidget {
  final int usedAmount;
  final int dueTotal;
  final int mainBalance;
  final int defaultAmount;
  final BankService? bankService;

  const _RepayPostpaidSheet({
    required this.usedAmount,
    required this.dueTotal,
    required this.mainBalance,
    required this.defaultAmount,
    this.bankService,
  });

  @override
  State<_RepayPostpaidSheet> createState() => _RepayPostpaidSheetState();
}

class _RepayPostpaidSheetState extends State<_RepayPostpaidSheet> {
  static final TextStyle _titleStyle = GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: kTfText,
  );
  static final TextStyle _subtitleStyle = GoogleFonts.roboto(
    fontSize: 13.5,
    color: kTfMuted,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle _chipStyle = GoogleFonts.roboto(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: kTfPinkDark,
  );
  static final TextStyle _inputStyle = GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: kTfText,
  );
  static final TextStyle _labelStyle = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: kTfMuted,
  );
  static final TextStyle _suffixStyle = GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: kTfText,
  );
  static final TextStyle _errorStyle = GoogleFonts.roboto(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: kPostpaidExpense,
  );
  static final TextStyle _submitStyle = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  late final TextEditingController _amountCtrl;
  final FocusNode _amountFocusNode = FocusNode();
  final ValueNotifier<String?> _inlineErrorNotifier = ValueNotifier<String?>(
    null,
  );
  late final BankService _bankService = widget.bankService ?? BankService();
  late final Future<List<Map<String, dynamic>>> _linkedBanksFuture;
  bool _isCheckingFunding = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: FormatUtils.formatDisplayNumber(widget.defaultAmount),
    );
    _linkedBanksFuture = _fetchLinkedBanks();
  }

  Future<List<Map<String, dynamic>>> _fetchLinkedBanks() async {
    final res = await _bankService.getBankLinkStatus();
    if (res['is_success'] == true && res['data'] is Map) {
      final accounts = (res['data'] as Map)['linked_accounts'];
      if (accounts is List) {
        return accounts
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocusNode.dispose();
    _inlineErrorNotifier.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_inlineErrorNotifier.value != null) {
      _inlineErrorNotifier.value = null;
    }
  }

  void _setPreset(int val) {
    final formatted = FormatUtils.formatDisplayNumber(val);
    _amountCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _clearError();
  }

  void _handleAmountChanged(String raw) {
    final parsed = int.tryParse(raw) ?? 0;
    final formatted = parsed > 0 ? FormatUtils.formatDisplayNumber(parsed) : '';
    if (formatted != raw) {
      _amountCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _clearError();
  }

  Future<void> _submit() async {
    if (_isCheckingFunding) return;
    final parsedAmount = FormatUtils.formatAmountToNum(
      _amountCtrl.text,
    ).round();
    if (parsedAmount <= 0) {
      _inlineErrorNotifier.value = 'Số tiền phải lớn hơn 0';
      return;
    }
    if (parsedAmount > widget.usedAmount) {
      _inlineErrorNotifier.value =
          'Không vượt quá tổng dư nợ (${FormatUtils.formatDisplayNumber(widget.usedAmount)}đ)';
      return;
    }
    setState(() => _isCheckingFunding = true);
    final linkedBanks = await _linkedBanksFuture;
    if (!mounted) return;
    setState(() => _isCheckingFunding = false);

    final resolution = resolveTransferFundingOption(
      walletEligible: widget.mainBalance >= parsedAmount,
      walletBalance: widget.mainBalance.toString(),
      neededAmount: parsedAmount,
      linkedBanks: linkedBanks,
      postpaidEligible: false,
    );
    if (!resolution.canProceed) {
      _inlineErrorNotifier.value =
          resolution.errorMessage ?? 'Số dư trong ví không đủ';
      return;
    }
    Navigator.pop(
      context,
      _RepaySelectionResult(amount: parsedAmount, resolution: resolution),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: kTfPink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kTfPink.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: _chipStyle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = math.max(
      240.0,
      media.size.height - media.viewPadding.top - 24,
    );

    return SmoothKeyboardSheet(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Thanh toán dư nợ Ví trả sau', style: _titleStyle),
                  const SizedBox(height: 6),
                  Text(
                    'Số dư ví chính: ${FormatUtils.formatDisplayNumber(widget.mainBalance)}đ',
                    style: _subtitleStyle,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.dueTotal > 0 &&
                          widget.dueTotal < widget.usedAmount)
                        _buildPresetChip(
                          'Trả kỳ sao kê (${FormatUtils.formatDisplayNumber(widget.dueTotal)}đ)',
                          () => _setPreset(widget.dueTotal),
                        ),
                      _buildPresetChip(
                        'Tất toán (${FormatUtils.formatDisplayNumber(widget.usedAmount)}đ)',
                        () => _setPreset(widget.usedAmount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  RepaintBoundary(
                    child: ValueListenableBuilder<String?>(
                      valueListenable: _inlineErrorNotifier,
                      builder: (context, errorMsg, _) {
                        final hasError =
                            errorMsg != null && errorMsg.isNotEmpty;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _amountCtrl,
                              focusNode: _amountFocusNode,
                              onTap: () =>
                                  requestKeyboardFocus(_amountFocusNode),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: false,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              enableSuggestions: false,
                              autocorrect: false,
                              enableIMEPersonalizedLearning: false,
                              cursorColor: kTfPink,
                              onChanged: _handleAmountChanged,
                              style: _inputStyle,
                              decoration: InputDecoration(
                                labelText: 'Số tiền thanh toán',
                                labelStyle: _labelStyle,
                                floatingLabelStyle: _labelStyle.copyWith(
                                  color: hasError ? kPostpaidExpense : kTfPink,
                                ),
                                suffixText: 'đ',
                                suffixStyle: _suffixStyle,
                                filled: true,
                                fillColor: kTfBg,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: hasError
                                      ? const BorderSide(
                                          color: kPostpaidExpense,
                                          width: 1.2,
                                        )
                                      : BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: hasError
                                        ? kPostpaidExpense
                                        : kTfPink,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            if (hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 15,
                                      color: kPostpaidExpense,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(errorMsg, style: _errorStyle),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isCheckingFunding ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTfPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isCheckingFunding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Tiếp tục', style: _submitStyle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostpaidUnlockRequestSheet extends StatefulWidget {
  const _PostpaidUnlockRequestSheet({required this.service});

  final PostpaidService service;

  @override
  State<_PostpaidUnlockRequestSheet> createState() =>
      _PostpaidUnlockRequestSheetState();
}

class _PostpaidUnlockRequestSheetState
    extends State<_PostpaidUnlockRequestSheet> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _noteCtrl = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final remaining = 3 - _selectedImages.length;
    if (remaining <= 0) {
      setState(() => _errorText = 'Tối đa 3 ảnh chứng minh thu nhập');
      return;
    }
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _errorText = null;
        _selectedImages.addAll(picked.take(remaining));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Không thể truy cập Thư viện ảnh');
    }
  }

  Future<void> _pickFromCamera() async {
    if (_selectedImages.length >= 3) {
      setState(() => _errorText = 'Tối đa 3 ảnh chứng minh thu nhập');
      return;
    }
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null || !mounted) return;
      setState(() {
        _errorText = null;
        _selectedImages.add(photo);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Không thể mở Camera để chụp ảnh');
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_selectedImages.isEmpty) {
      setState(
        () => _errorText =
            'Vui lòng chọn ít nhất 1 ảnh chứng minh thu nhập (tối đa 3 ảnh)',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final res = await widget.service.submitUnlockRequest(
      filePaths: _selectedImages.map((e) => e.path).toList(),
      userNote: _noteCtrl.text,
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (res['is_success'] == true) {
      SnackbarUtils.success(
        context,
        res['message']?.toString() ??
            'Đã gửi yêu cầu mở khóa Ví trả sau thành công!',
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorText =
            res['message']?.toString() ?? 'Không thể gửi yêu cầu mở khóa';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mở lại Ví trả sau',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kTfText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, color: kTfMuted),
                  ),
                ],
              ),
              Text(
                'Tải lên 1–3 ảnh (JPEG/PNG) sao kê nhận lương hoặc ảnh chứng minh thu nhập để Quản trị viên xét duyệt. Lưu ý: hạn mức sau khi mở lại vẫn giữ mức hiện tại.',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  height: 1.45,
                  color: kTfMuted,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickFromGallery,
                      icon: const Icon(Iconsax.gallery, size: 18),
                      label: Text(
                        'Thư viện ảnh',
                        style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTfPinkDark,
                        side: BorderSide(
                          color: kTfPink.withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickFromCamera,
                      icon: const Icon(Iconsax.camera, size: 18),
                      label: Text(
                        'Chụp Camera',
                        style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTfPinkDark,
                        side: BorderSide(
                          color: kTfPink.withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Ảnh đã chọn (${_selectedImages.length}/3):',
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: kTfText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_selectedImages.length, (i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImages[i].path),
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: _isSubmitting
                                ? null
                                : () => setState(
                                    () => _selectedImages.removeAt(i),
                                  ),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _noteCtrl,
                enabled: !_isSubmitting,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Ghi chú bổ sung (không bắt buộc)',
                  hintText:
                      'Ví dụ: Sao kê lương tháng 11 nhận qua ngân hàng...',
                  filled: true,
                  fillColor: kTfBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTfPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Gửi hồ sơ xét duyệt',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagePostpaidWalletSheet extends StatelessWidget {
  const _ManagePostpaidWalletSheet({
    required this.status,
    required this.lockReason,
    required this.usedAmount,
    required this.onFreezeTap,
    required this.onUnfreezeTap,
    required this.onCloseTap,
  });

  final String status;
  final String lockReason;
  final int usedAmount;
  final VoidCallback onFreezeTap;
  final VoidCallback onUnfreezeTap;
  final VoidCallback onCloseTap;

  @override
  Widget build(BuildContext context) {
    final normStatus = status.trim().toUpperCase();
    final normReason = lockReason.trim().toUpperCase();
    final isFrozen = normStatus == 'FROZEN';
    final isPastDue = normStatus == 'PAST_DUE';
    final isSystemOrAdminLocked =
        isFrozen &&
        (normReason == 'ADMIN_FREEZE' || normReason == 'OVERDUE_REPEAT');
    final canUnfreeze = isFrozen && !isSystemOrAdminLocked;
    final canFreeze = !isFrozen && !isPastDue;
    final canClose = !isSystemOrAdminLocked;

    return SafeArea(
      key: const Key('sheet-manage-postpaid-wallet'),
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quản lý Ví trả sau',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kTfText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tùy chọn tạm khóa chi tiêu tạm thời, mở khóa hoặc hủy dịch vụ Ví trả sau.',
              style: GoogleFonts.roboto(
                fontSize: 13,
                height: 1.4,
                color: kTfMuted,
              ),
            ),
            if (isSystemOrAdminLocked) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Text(
                  normReason == 'OVERDUE_REPEAT'
                      ? 'Ví đang khóa do quá hạn lặp lại. Bạn cần tất toán dư nợ (nếu còn) và gửi ảnh chứng minh thu nhập để Quản trị viên duyệt mở lại; không thể tự mở khóa hoặc tự hủy ví.'
                      : 'Ví đang bị Quản trị viên tạm khóa; bạn không thể tự mở khóa hoặc tự hủy ví.',
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    height: 1.4,
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!isFrozen)
              _buildActionTile(
                key: const Key('btn-manage-freeze'),
                icon: Iconsax.lock_1,
                iconColor: const Color(0xFFD97706),
                title: 'Tạm khóa Ví trả sau',
                subtitle: isPastDue
                    ? 'Vui lòng tất toán kỳ quá hạn trước khi tạm khóa'
                    : 'Chặn thanh toán QR tạm thời, giữ nguyên hạn mức & lịch sử',
                enabled: canFreeze,
                onTap: canFreeze ? onFreezeTap : null,
              )
            else
              _buildActionTile(
                key: const Key('btn-manage-unfreeze'),
                icon: Iconsax.unlock,
                iconColor: kTfSuccess,
                title: 'Mở khóa Ví trả sau',
                subtitle: isSystemOrAdminLocked
                    ? (normReason == 'OVERDUE_REPEAT'
                          ? 'Cần xét duyệt ảnh chứng minh thu nhập'
                          : 'Do Quản trị viên quản lý mở khóa')
                    : 'Kích hoạt lại tính năng thanh toán QR bằng Ví trả sau',
                enabled: canUnfreeze,
                onTap: canUnfreeze ? onUnfreezeTap : null,
              ),
            const SizedBox(height: 10),
            _buildActionTile(
              key: const Key('btn-manage-close'),
              icon: Iconsax.close_circle,
              iconColor: kPostpaidExpense,
              title: 'Hủy dịch vụ Ví trả sau',
              subtitle: isSystemOrAdminLocked
                  ? 'Không thể tự hủy khi ví đang bị khóa hệ thống / Quản trị viên'
                  : usedAmount > 0
                  ? 'Cần tất toán hết ${FormatUtils.formatDisplayNumber(usedAmount)}đ dư nợ trước khi hủy'
                  : 'Đóng Ví trả sau sau khi xác thực mã PIN',
              enabled: canClose,
              onTap: canClose ? onCloseTap : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    final effectiveIconColor = enabled ? iconColor : Colors.grey.shade400;
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kTfBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: kTfText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        height: 1.35,
                        color: kTfMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: kTfMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosePostpaidWalletSheet extends StatefulWidget {
  const _ClosePostpaidWalletSheet();

  @override
  State<_ClosePostpaidWalletSheet> createState() =>
      _ClosePostpaidWalletSheetState();
}

class _ClosePostpaidWalletSheetState extends State<_ClosePostpaidWalletSheet> {
  static const List<String> _presetReasons = [
    'Ít sử dụng dịch vụ',
    'Muốn kiểm soát chi tiêu',
    'Đã có phương thức khác',
    'Lý do khác',
  ];

  final TextEditingController _reasonCtrl = TextEditingController();
  String? _selectedPreset;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final custom = _reasonCtrl.text.trim();
    final effective = custom.isNotEmpty
        ? custom
        : (_selectedPreset != null && _selectedPreset != 'Lý do khác'
              ? _selectedPreset!
              : '');
    Navigator.pop(context, effective);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = math.max(
      240.0,
      media.size.height - media.viewPadding.top - 24,
    );

    return SmoothKeyboardSheet(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hủy Ví trả sau',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTfText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Iconsax.warning_2,
                            size: 18,
                            color: kPostpaidExpense,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sau khi hủy, Ví trả sau sẽ ngừng hoạt động. Lịch sử biến động hạn mức vẫn được lưu giữ để đối soát và bạn có thể kích hoạt lại sau này nếu đủ điều kiện.',
                            style: GoogleFonts.roboto(
                              fontSize: 12.5,
                              height: 1.4,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lý do hủy ví (không bắt buộc)',
                    style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: kTfText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetReasons.map((reason) {
                      final isSelected = _selectedPreset == reason;
                      return ChoiceChip(
                        label: Text(
                          reason,
                          style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? kTfPinkDark : kTfText,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: kTfPink.withValues(alpha: 0.14),
                        backgroundColor: kTfBg,
                        side: BorderSide(
                          color: isSelected ? kTfPink : Colors.grey.shade300,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedPreset = selected ? reason : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonCtrl,
                    maxLength: 200,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập thêm lý do hoặc góp ý của bạn...',
                      hintStyle: GoogleFonts.roboto(
                        fontSize: 13.5,
                        color: kTfMuted,
                      ),
                      filled: true,
                      fillColor: kTfBg,
                      counterStyle: GoogleFonts.roboto(
                        fontSize: 11,
                        color: kTfMuted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: kTfPink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kTfText,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Giữ lại ví',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _confirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPostpaidExpense,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Xác nhận hủy ví',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}
