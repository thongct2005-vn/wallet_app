import 'dart:async';
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
import 'package:app/src/postpaid/postpaid_unlock_sheet.dart';
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
import 'package:uuid/uuid.dart';

class PostpaidScreen extends StatefulWidget {
  const PostpaidScreen({super.key});

  @override
  State<PostpaidScreen> createState() => _PostpaidScreenState();
}

class _PostpaidScreenState extends State<PostpaidScreen> {
  final PostpaidService _postpaidService = PostpaidService();
  final WalletService _walletService = WalletService();
  final BankService _bankService = BankService();
  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  bool _isSilentRefreshing = false;
  bool _isActivating = false;
  bool _isProcessingLifecycle = false;
  bool _didScheduleInitialLoad = false;
  VoidCallback? _cancelDeferredLoad;
  Worker? _postpaidSocketWorker;
  String? _errorMsg;

  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _entries = [];
  bool _hasMoreEntries = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UserController>()) {
      final userController = Get.find<UserController>();
      _postpaidSocketWorker = ever<int>(
        userController.postpaidRefreshTick,
        (_) => _handlePostpaidSocketUpdate(userController),
      );
    }
  }

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
    _postpaidSocketWorker?.dispose();
    super.dispose();
  }

  void _handlePostpaidSocketUpdate(UserController userController) {
    if (!mounted) return;
    final currentWallet = _wallet;
    if (currentWallet != null) {
      final updatedWallet = Map<String, dynamic>.from(currentWallet);
      final nextUsed = userController.postpaidUsedAmount.value;
      final nextAvail = userController.postpaidAvailableLimit.value;
      final nextStatus = userController.postpaidStatus.value;
      if (nextUsed != null) updatedWallet['used_amount'] = nextUsed;
      if (nextAvail != null) updatedWallet['available_limit'] = nextAvail;
      if (nextStatus != null && nextStatus.isNotEmpty) {
        updatedWallet['status'] = nextStatus;
      }
      setState(() => _wallet = updatedWallet);
    }
    unawaited(_loadData(silent: true));
  }

  Future<void> _loadData({bool silent = false}) async {
    if (silent) {
      if (_isSilentRefreshing) return;
      _isSilentRefreshing = true;
    } else if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });
    }

    try {
      final walletRes = await _postpaidService.getWallet();
      if (!mounted) return;

      if (walletRes['is_success'] != true) {
        if (!silent) {
          setState(() {
            _isLoading = false;
            _errorMsg =
                walletRes['message'] ?? 'Không thể tải thông tin Ví trả sau';
          });
        }
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
    } finally {
      if (silent) {
        _isSilentRefreshing = false;
      }
    }
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

  Future<void> _openUnlockRequestSheet() async {
    final wallet = _wallet;
    if (wallet == null) return;
    final rawLatest = wallet['latest_unlock_request'];
    final previousRejected =
        rawLatest is Map && rawLatest['status']?.toString() == 'REJECTED'
        ? Map<String, dynamic>.from(rawLatest)
        : null;

    final result = await showSmoothPinBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (_) => PostpaidUnlockRequestSheet(
        service: _postpaidService,
        previousRejectedRequest: previousRejected,
      ),
    );

    if (result != null && result['is_success'] == true && mounted) {
      SnackbarUtils.success(
        context,
        result['message']?.toString() ??
            'Đã gửi yêu cầu mở khóa Ví trả sau kèm ảnh chứng minh thu nhập',
      );
      await _loadData(silent: true);
    }
  }

  Future<void> _refreshUnlockRequestStatus() async {
    final res = await _postpaidService.getLatestUnlockRequest();
    if (!mounted) return;
    await _loadData(silent: true);
    if (!mounted) return;
    if (res['is_success'] == true) {
      final reqData = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : null;
      final reqStatus = reqData?['status']?.toString();
      if (reqStatus == 'PENDING') {
        SnackbarUtils.info(
          context,
          'Yêu cầu mở khóa vẫn đang chờ Quản trị viên xét duyệt',
        );
      } else if (reqStatus == 'APPROVED') {
        SnackbarUtils.success(context, 'Ví trả sau của bạn đã được duyệt mở lại');
      } else if (reqStatus == 'REJECTED') {
        final adminNote = reqData?['admin_note']?.toString().trim();
        SnackbarUtils.failure(
          context,
          adminNote != null && adminNote.isNotEmpty
              ? 'Yêu cầu bị từ chối: $adminNote'
              : 'Yêu cầu mở khóa trước đó bị từ chối, bạn có thể gửi lại hồ sơ mới',
        );
      }
    }
  }

  void _openManageWalletSheet() {
    final wallet = _wallet;
    if (wallet == null || wallet['activated'] != true) return;

    final status = (wallet['status'] ?? 'ACTIVE').toString();
    final lockReason = wallet['lock_reason']?.toString();
    final usedAmount = _toInt(wallet['used_amount']);
    final overdueDebtTotal =
        _toInt(wallet['billed_amount']) +
        _toInt(wallet['service_fee_amount']) +
        _toInt(wallet['late_fee_amount']);
    final latestReq = wallet['latest_unlock_request'];
    final latestUnlockStatus = latestReq is Map
        ? latestReq['status']?.toString()
        : null;

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
        overdueDebtTotal: overdueDebtTotal,
        latestUnlockStatus: latestUnlockStatus,
        onFreezeTap: () {
          Navigator.pop(sheetCtx);
          _confirmFreezeWallet();
        },
        onUnfreezeTap: () {
          Navigator.pop(sheetCtx);
          _confirmUnfreezeWallet();
        },
        onUnlockRequestTap: () {
          Navigator.pop(sheetCtx);
          _openUnlockRequestSheet();
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
      builder: (dlgCtx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Iconsax.lock_1,
                  size: 26,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tạm khóa Ví trả sau?',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTfText,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kTfBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Trong thời gian tạm khóa, bạn sẽ không thể dùng Ví trả sau để thanh toán QR. Hạn mức và lịch sử sao kê vẫn được giữ nguyên, và bạn vẫn có thể trả dư nợ hoặc mở khóa bất cứ lúc nào.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    height: 1.45,
                    color: kTfMuted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dlgCtx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kTfPink,
                          side: const BorderSide(color: kTfPink, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Để sau',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dlgCtx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTfPink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Tạm khóa',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
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
      return const Center(
        child: CircularProgressIndicator(color: kTfPink),
      );
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
                  subtitle: isKyc ? 'Đã xác thực' : 'Chưa hoàn tất xác thực eKYC',
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
    final Color statusColor =
        met ? const Color(0xFF2E9E5B) : const Color(0xFFF57C00);
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
    final lockReason = wallet['lock_reason']?.toString();
    final rawLatestReq = wallet['latest_unlock_request'];
    final latestUnlockRequest = rawLatestReq is Map
        ? Map<String, dynamic>.from(rawLatestReq)
        : null;
    final overdueDebtTotal = billedAmount + serviceFeeAmount + lateFeeAmount;
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
                            ? (lockReason == 'OVERDUE_REPEAT'
                                  ? 'Khóa quá hạn lặp lại'
                                  : lockReason == 'ADMIN_FREEZE'
                                  ? 'Quản trị viên tạm khóa'
                                  : 'Đang tạm khóa')
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
          if (isFrozen) ...[
            const SizedBox(height: 12),
            _buildFrozenBanner(
              lockReason: lockReason,
              overdueDebtTotal: overdueDebtTotal,
              latestUnlockRequest: latestUnlockRequest,
            ),
          ],
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
                              ? (lockReason == 'OVERDUE_REPEAT'
                                    ? 'Khóa do quá hạn lặp lại • Xem chi tiết hoặc gửi hồ sơ'
                                    : lockReason == 'ADMIN_FREEZE'
                                    ? 'Ví đang bị Quản trị viên tạm khóa'
                                    : 'Ví đang tạm khóa chi tiêu • Nhấn để mở khóa hoặc hủy ví')
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

  Widget _buildFrozenStatusCard({
    required IconData icon,
    required Color accentColor,
    required Color iconBgColor,
    required String badgeText,
    required String title,
    required String body,
    String? extraHighlight,
    String? actionLabel,
    IconData? actionIcon,
    VoidCallback? onActionPressed,
    bool useOutlinedAction = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: kTfPink.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: accentColor),
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.roboto(
              fontSize: 13,
              height: 1.45,
              color: kTfMuted,
            ),
          ),
          if (extraHighlight != null && extraHighlight.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                extraHighlight,
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            ),
          ],
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: useOutlinedAction
                  ? OutlinedButton.icon(
                      onPressed: _isProcessingLifecycle ? null : onActionPressed,
                      icon: Icon(actionIcon ?? Icons.refresh_rounded, size: 18),
                      label: Text(
                        actionLabel,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTfPinkDark,
                        side: BorderSide(
                          color: kTfPink.withValues(alpha: 0.45),
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _isProcessingLifecycle ? null : onActionPressed,
                      icon: Icon(actionIcon ?? Iconsax.unlock, size: 18),
                      label: Text(
                        actionLabel,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildFrozenBanner({
    required String? lockReason,
    required int overdueDebtTotal,
    required Map<String, dynamic>? latestUnlockRequest,
  }) {
    final reqStatus = latestUnlockRequest?['status']?.toString();
    final proofCount = _toInt(latestUnlockRequest?['proof_count']);
    final userNote = latestUnlockRequest?['user_note']?.toString().trim();
    final adminNote = latestUnlockRequest?['admin_note']?.toString().trim();

    if (lockReason == 'OVERDUE_REPEAT') {
      final isPending = reqStatus == 'PENDING';
      final isRejected = reqStatus == 'REJECTED';
      final needsRepay = overdueDebtTotal > 0;

      if (needsRepay) {
        return _buildFrozenStatusCard(
          icon: Iconsax.lock_1,
          accentColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFEF3C7),
          badgeText: 'Khóa quá hạn lặp lại',
          title: 'Ví bị khóa do quá hạn từ lần thứ 2 trở lên',
          body:
              'Vui lòng thanh toán hết dư nợ kỳ quá hạn (${FormatUtils.formatDisplayNumber(overdueDebtTotal)}đ) trước khi gửi 1–3 ảnh chứng minh thu nhập cho Quản trị viên duyệt mở lại.',
          actionLabel: 'Thanh toán dư nợ ngay',
          actionIcon: Iconsax.wallet_check,
          onActionPressed: _openRepaySheet,
        );
      }

      if (isPending) {
        return _buildFrozenStatusCard(
          icon: Iconsax.document_text,
          accentColor: kTfPinkDark,
          iconBgColor: kTfPink.withValues(alpha: 0.1),
          badgeText: 'Đang chờ xét duyệt',
          title: 'Hồ sơ mở khóa đang chờ duyệt',
          body:
              'Bạn đã gửi $proofCount ảnh chứng minh thu nhập. Quản trị viên đang kiểm tra và sẽ phản hồi sớm.',
          extraHighlight: userNote != null && userNote.isNotEmpty
              ? 'Ghi chú của bạn: "$userNote"'
              : null,
          actionLabel: 'Kiểm tra trạng thái duyệt',
          actionIcon: Icons.refresh_rounded,
          onActionPressed: _refreshUnlockRequestStatus,
          useOutlinedAction: true,
        );
      }

      if (isRejected) {
        return _buildFrozenStatusCard(
          icon: Iconsax.warning_2,
          accentColor: kPostpaidExpense,
          iconBgColor: const Color(0xFFFEE2E2),
          badgeText: 'Hồ sơ bị từ chối',
          title: 'Yêu cầu mở khóa trước đó bị từ chối',
          body:
              'Bạn có thể chụp hoặc chọn 1–3 ảnh chứng minh thu nhập rõ ràng hơn để gửi lại yêu cầu mở khóa.',
          extraHighlight: adminNote != null && adminNote.isNotEmpty
              ? 'Lý do từ chối: $adminNote'
              : null,
          actionLabel: 'Gửi lại hồ sơ mở khóa',
          actionIcon: Iconsax.document_upload,
          onActionPressed: _openUnlockRequestSheet,
        );
      }

      return _buildFrozenStatusCard(
        icon: Iconsax.document_upload,
        accentColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
        badgeText: 'Cần xác minh thu nhập',
        title: 'Gửi ảnh chứng minh thu nhập để mở lại ví',
        body:
            'Bạn đã tất toán xong kỳ nợ quá hạn. Vui lòng gửi 1–3 ảnh chứng minh thu nhập (bảng lương, sao kê ngân hàng...) để Quản trị viên mở khóa lại Ví trả sau.',
        actionLabel: 'Gửi ảnh chứng minh thu nhập',
        actionIcon: Iconsax.document_upload,
        onActionPressed: _openUnlockRequestSheet,
      );
    }

    if (lockReason == 'ADMIN_FREEZE') {
      return _buildFrozenStatusCard(
        icon: Iconsax.shield_cross,
        accentColor: kPostpaidExpense,
        iconBgColor: const Color(0xFFFEE2E2),
        badgeText: 'Quản trị viên tạm khóa',
        title: 'Ví trả sau đang bị Quản trị viên tạm khóa',
        body:
            'Bạn không thể thanh toán QR hay tự mở khóa lúc này, nhưng vẫn có thể trả dư nợ hiện có. Vui lòng liên hệ bộ phận hỗ trợ nếu cần mở lại ví.',
      );
    }

    return _buildFrozenStatusCard(
      icon: Iconsax.lock_1,
      accentColor: const Color(0xFFD97706),
      iconBgColor: const Color(0xFFFEF3C7),
      badgeText: 'Bạn đã tạm khóa',
      title: 'Ví trả sau đang tạm khóa chi tiêu',
      body:
          'Bạn không thể thanh toán QR lúc này. Hạn mức và lịch sử sao kê vẫn được giữ nguyên, và bạn có thể mở khóa lại bất cứ lúc nào.',
      actionLabel: 'Mở khóa ví ngay',
      actionIcon: Iconsax.unlock,
      onActionPressed: _confirmUnfreezeWallet,
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
        _error = (res['message'] ?? 'Không thể tải thông tin Ví trả sau').toString();
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
                            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
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
    final billingDay = _toInt(statement['billing_day'] ?? config['billing_day']);
    final dueDay = _toInt(statement['due_day'] ?? config['due_day']);
    final rawTiers = feeRules['late_fee_tiers'];
    final tiers = rawTiers is List
        ? rawTiers.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const <Map<String, dynamic>>[];
    final minLateFee = _toInt(feeRules['min_late_fee'] ?? config['min_late_fee']);
    final lateFeePercent = (feeRules['late_fee_percent'] ?? config['late_fee_percent'] ?? 0).toString();
    final String lateFeeDisplay = tiers.isNotEmpty
        ? '${tiers.first['percent_text'] ?? tiers.first['percent']}% – ${tiers.last['percent_text'] ?? tiers.last['percent']}% (${tiers.length} bậc ngày)'
        : '$lateFeePercent% (tối thiểu ${FormatUtils.formatDisplayNumber(minLateFee)}đ)';
    final activationFee = _toInt(feeRules['activation_fee']);
    final qrPaymentFee = _toInt(feeRules['qr_payment_fee']);
    final repaymentFee = _toInt(feeRules['repayment_fee']);
    final monthlyServiceFee = _toInt(
      feeRules['monthly_service_fee'] ?? config['monthly_service_fee'],
    );
    final freeTxCount = _toInt(
      feeRules['free_service_fee_tx_count'] ??
          config['free_service_fee_tx_count'],
    );

    String formatFee(int amount) =>
        amount == 0 ? 'Miễn phí' : '${FormatUtils.formatDisplayNumber(amount)}đ';
    final serviceFeeLabel = monthlyServiceFee <= 0
        ? 'Miễn phí'
        : freeTxCount > 0
        ? '${FormatUtils.formatDisplayNumber(monthlyServiceFee)}đ/tháng (miễn $freeTxCount GD đầu)'
        : '${FormatUtils.formatDisplayNumber(monthlyServiceFee)}đ/tháng (kỳ có GD)';

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
              _buildMetricRow('Ngày chốt sao kê', 'Ngày $billingDay hàng tháng'),
              const SizedBox(height: 8),
              _buildMetricRow('Hạn thanh toán', 'Ngày $dueDay tháng kế tiếp'),
              const SizedBox(height: 8),
              _buildMetricRow('Phí dịch vụ tháng', serviceFeeLabel),
              const SizedBox(height: 8),
              _buildMetricRow(
                'Phí trễ hạn',
                lateFeeDisplay,
                valueColor: const Color(0xFFD32F2F),
              ),
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
            for (final tier in tiers)
              'Phí chậm trả bậc ${tier['tier']} (${tier['label']}): ${tier['percent_text'] ?? tier['percent']}% tổng dư nợ kỳ sao kê',
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

  const _RepaySelectionResult({
    required this.amount,
    required this.resolution,
  });
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
    final parsedAmount = FormatUtils.formatAmountToNum(_amountCtrl.text).round();
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
                        final hasError = errorMsg != null && errorMsg.isNotEmpty;
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
                                    color: hasError ? kPostpaidExpense : kTfPink,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            if (hasError)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  left: 4,
                                ),
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

class _ManagePostpaidWalletSheet extends StatelessWidget {
  final String status;
  final String? lockReason;
  final int usedAmount;
  final int overdueDebtTotal;
  final String? latestUnlockStatus;
  final VoidCallback onFreezeTap;
  final VoidCallback onUnfreezeTap;
  final VoidCallback onUnlockRequestTap;
  final VoidCallback onCloseTap;

  const _ManagePostpaidWalletSheet({
    required this.status,
    required this.lockReason,
    required this.usedAmount,
    required this.overdueDebtTotal,
    required this.latestUnlockStatus,
    required this.onFreezeTap,
    required this.onUnfreezeTap,
    required this.onUnlockRequestTap,
    required this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFrozen = status == 'FROZEN';
    final isPastDue = status == 'PAST_DUE';
    final isOverdueRepeatLock = isFrozen && lockReason == 'OVERDUE_REPEAT';
    final isAdminFreeze = isFrozen && lockReason == 'ADMIN_FREEZE';
    final hasDebt = usedAmount > 0;
    final hasOverdueDebt = overdueDebtTotal > 0;
    final isUnlockPending = latestUnlockStatus == 'PENDING';

    final Color statusBg;
    final Color statusFg;
    final String statusLabel;
    if (isPastDue) {
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFFB91C1C);
      statusLabel = 'Quá hạn';
    } else if (isFrozen) {
      statusBg = isAdminFreeze
          ? const Color(0xFFFEE2E2)
          : const Color(0xFFFEF3C7);
      statusFg = isAdminFreeze
          ? const Color(0xFFB91C1C)
          : const Color(0xFFB45309);
      statusLabel = 'Đang tạm khóa';
    } else {
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF15803D);
      statusLabel = 'Đang hoạt động';
    }

    final bool primaryActionEnabled =
        !isPastDue &&
        !isAdminFreeze &&
        (!isOverdueRepeatLock || (!hasOverdueDebt && !isUnlockPending));

    final String primaryTitle = isOverdueRepeatLock
        ? 'Gửi yêu cầu mở khóa ví'
        : isFrozen
        ? 'Mở khóa Ví trả sau'
        : 'Tạm khóa Ví trả sau';

    final String primarySubtitle = isPastDue
        ? 'Không thể tạm khóa khi ví đang có dư nợ quá hạn'
        : isAdminFreeze
        ? 'Ví đang bị Quản trị viên tạm khóa, không thể tự mở khóa'
        : isOverdueRepeatLock
        ? (hasOverdueDebt
              ? 'Cần thanh toán hết dư nợ quá hạn trước khi gửi ảnh chứng minh thu nhập'
              : isUnlockPending
              ? 'Hồ sơ mở khóa của bạn đang chờ Quản trị viên xét duyệt'
              : 'Gửi 1–3 ảnh chứng minh thu nhập để Quản trị viên xét duyệt mở lại')
        : isFrozen
        ? 'Khôi phục thanh toán QR bằng Ví trả sau'
        : 'Ngưng chi tiêu QR tạm thời; hạn mức và lịch sử được giữ nguyên';

    final bool canCloseWallet =
        !hasDebt && !isOverdueRepeatLock && !isAdminFreeze;

    return SafeArea(
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
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quản lý Ví trả sau',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTfText,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusFg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ManageActionTile(
              icon: isOverdueRepeatLock
                  ? Iconsax.document_upload
                  : isFrozen
                  ? Iconsax.unlock
                  : Iconsax.lock_1,
              iconColor: !primaryActionEnabled
                  ? kTfMuted
                  : isFrozen
                  ? const Color(0xFF15803D)
                  : const Color(0xFFD97706),
              iconBg: !primaryActionEnabled
                  ? Colors.grey.shade100
                  : isFrozen
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF3C7),
              title: primaryTitle,
              subtitle: primarySubtitle,
              enabled: primaryActionEnabled,
              onTap: isOverdueRepeatLock
                  ? onUnlockRequestTap
                  : isFrozen
                  ? onUnfreezeTap
                  : onFreezeTap,
            ),
            const SizedBox(height: 10),
            _ManageActionTile(
              icon: Iconsax.close_circle,
              iconColor: canCloseWallet ? kPostpaidExpense : kTfMuted,
              iconBg: canCloseWallet
                  ? kPostpaidExpense.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              title: 'Hủy Ví trả sau',
              subtitle: (isOverdueRepeatLock || isAdminFreeze)
                  ? 'Ví đang bị khóa bởi hệ thống/Quản trị viên, không thể tự hủy ví'
                  : hasDebt
                  ? 'Cần thanh toán hết dư nợ (${FormatUtils.formatDisplayNumber(usedAmount)}đ) trước khi hủy'
                  : 'Đóng dịch vụ Ví trả sau; vẫn có thể kích hoạt lại sau này',
              enabled: canCloseWallet,
              onTap: onCloseTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _ManageActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kTfBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: enabled ? kTfText : kTfMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
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

