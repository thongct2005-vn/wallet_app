import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/currency_formatter.dart';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/create_pin_bottom_sheet.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/services/user_service.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

class TransactionLimitsScreen extends StatefulWidget {
  const TransactionLimitsScreen({super.key});

  @override
  State<TransactionLimitsScreen> createState() =>
      _TransactionLimitsScreenState();
}

class _TransactionLimitsScreenState extends State<TransactionLimitsScreen> {
  final UserService _userService = UserService();
  final WalletService _walletService = WalletService();
  final UserController _userController = Get.find<UserController>();
  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  Map<String, dynamic>? _walletCapacity;
  List<Map<String, dynamic>> _limits = [];

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  void _applyLimitsPayload(Map data) {
    final rawList = (data['limits'] as List?) ?? [];
    final rawCap = data['wallet_capacity'];
    setState(() {
      _walletCapacity = rawCap is Map
          ? Map<String, dynamic>.from(rawCap)
          : null;
      _limits = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _loadLimits() async {
    setState(() => _isLoading = true);
    final res = await _userService.getTransactionLimits();
    if (!mounted) return;
    if (res['is_success'] == true && res['data'] is Map) {
      _applyLimitsPayload(res['data'] as Map);
    } else {
      setState(() => _isLoading = false);
      SnackbarUtils.failure(
        context,
        res['message']?.toString() ?? 'Không thể tải thông tin hạn mức',
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

  Map<String, dynamic> _metaForType(String type) {
    switch (type) {
      case 'TRANSFER':
        return {
          'title': 'Chuyển tiền & Thanh toán',
          'subtitle': 'Áp dụng cho chuyển tiền ví LumaPay và quét mã QR',
          'icon': Iconsax.send_2,
          'color': kAuthPinkDark,
        };
      case 'WITHDRAW':
        return {
          'title': 'Rút tiền về ngân hàng',
          'subtitle': 'Áp dụng khi rút tiền từ ví về ngân hàng liên kết',
          'icon': Iconsax.import_1,
          'color': const Color(0xFF1565C0),
        };
      case 'TOPUP':
      default:
        return {
          'title': 'Nạp tiền vào ví',
          'subtitle': 'Áp dụng khi nạp tiền từ ngân hàng liên kết vào ví',
          'icon': Iconsax.export_3,
          'color': const Color(0xFF2E7D32),
        };
    }
  }

  Future<void> _onTapEditLimit(Map<String, dynamic> item) async {
    final hasPin = await _ensureHasPin();
    if (!hasPin || !mounted) return;

    final draft = await showModalBottomSheet<Map<String, num>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditLimitBottomSheet(
        item: item,
        meta: _metaForType(item['transaction_type']?.toString() ?? ''),
      ),
    );

    if (draft == null || !mounted) return;

    final String type = item['transaction_type']?.toString() ?? '';
    final num newMax = draft['max_amount']!;
    final num newDaily = draft['daily_limit']!;
    final String idempotencyKey = _uuid.v7();

    await showCheckPinDialog(
      context: context,
      customTitle: 'Nhập mã PIN để lưu hạn mức',
      onCheckPin: (pin) async {
        try {
          return await _walletService.checkPin(
            pin,
            idempotencyKey,
            action: 'UPDATE_LIMIT',
            params: {
              'transaction_type': type,
              'max_amount': newMax.toString(),
              'daily_limit': newDaily.toString(),
            },
          );
        } catch (_) {
          return {'is_success': false};
        }
      },
      onSuccess: (pinToken) async {
        final res = await _userService.updateTransactionLimit(
          transactionType: type,
          maxAmount: newMax,
          dailyLimit: newDaily,
          idempotencyKey: idempotencyKey,
          pinToken: pinToken,
        );
        if (!mounted) return;
        if (res['is_success'] == true && res['data'] is Map) {
          _applyLimitsPayload(res['data'] as Map);
          SnackbarUtils.success(
            context,
            res['message']?.toString() ?? 'Cập nhật hạn mức thành công',
          );
        } else {
          SnackbarUtils.failure(
            context,
            res['message']?.toString() ?? 'Không thể cập nhật hạn mức',
          );
        }
      },
    );
  }

  Future<void> _onTapEditWalletCapacity(Map<String, dynamic> cap) async {
    final hasPin = await _ensureHasPin();
    if (!hasPin || !mounted) return;

    final newCapacity = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCapacityBottomSheet(cap: cap),
    );

    if (newCapacity == null || !mounted) return;

    final String idempotencyKey = _uuid.v7();

    await showCheckPinDialog(
      context: context,
      customTitle: 'Nhập mã PIN để lưu sức chứa ví',
      onCheckPin: (pin) async {
        try {
          return await _walletService.checkPin(
            pin,
            idempotencyKey,
            action: 'UPDATE_LIMIT',
            params: {
              'transaction_type': 'WALLET_CAPACITY',
              'max_amount': newCapacity.toString(),
              'daily_limit': newCapacity.toString(),
            },
          );
        } catch (_) {
          return {'is_success': false};
        }
      },
      onSuccess: (pinToken) async {
        final res = await _userService.updateTransactionLimit(
          transactionType: 'WALLET_CAPACITY',
          maxAmount: newCapacity,
          dailyLimit: newCapacity,
          idempotencyKey: idempotencyKey,
          pinToken: pinToken,
        );
        if (!mounted) return;
        if (res['is_success'] == true && res['data'] is Map) {
          _applyLimitsPayload(res['data'] as Map);
          SnackbarUtils.success(
            context,
            'Cập nhật sức chứa ví thành công',
          );
        } else {
          SnackbarUtils.failure(
            context,
            res['message']?.toString() ?? 'Không thể cập nhật sức chứa ví',
          );
        }
      },
    );
  }

  Future<void> _onTapResetWalletCapacity() async {
    bool confirmed = false;
    await DialogUtils.showConfirmation(
      context,
      title: 'Khôi phục sức chứa mặc định',
      message:
          'Bạn có muốn đưa sức chứa ví về mức mặc định (100.000.000đ) không?',
      cancelText: 'Hủy',
      confirmText: 'Khôi phục',
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
      customTitle: 'Nhập mã PIN để khôi phục',
      onCheckPin: (pin) async {
        try {
          return await _walletService.checkPin(
            pin,
            idempotencyKey,
            action: 'RESET_LIMIT',
            params: {'transaction_type': 'WALLET_CAPACITY'},
          );
        } catch (_) {
          return {'is_success': false};
        }
      },
      onSuccess: (pinToken) async {
        final res = await _userService.resetTransactionLimit(
          transactionType: 'WALLET_CAPACITY',
          idempotencyKey: idempotencyKey,
          pinToken: pinToken,
        );
        if (!mounted) return;
        if (res['is_success'] == true && res['data'] is Map) {
          _applyLimitsPayload(res['data'] as Map);
          SnackbarUtils.success(
            context,
            'Đã khôi phục sức chứa ví mặc định',
          );
        } else {
          SnackbarUtils.failure(
            context,
            res['message']?.toString() ?? 'Không thể khôi phục sức chứa ví',
          );
        }
      },
    );
  }

  Future<void> _onTapResetLimit(Map<String, dynamic> item) async {
    final String type = item['transaction_type']?.toString() ?? '';
    final meta = _metaForType(type);

    bool confirmed = false;
    await DialogUtils.showConfirmation(
      context,
      title: 'Khôi phục hạn mức mặc định',
      message:
          'Bạn có muốn đưa hạn mức "${meta['title']}" về mức tối đa mặc định của hệ thống không?',
      cancelText: 'Hủy',
      confirmText: 'Khôi phục',
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
      customTitle: 'Nhập mã PIN để khôi phục',
      onCheckPin: (pin) async {
        try {
          return await _walletService.checkPin(
            pin,
            idempotencyKey,
            action: 'RESET_LIMIT',
            params: {'transaction_type': type},
          );
        } catch (_) {
          return {'is_success': false};
        }
      },
      onSuccess: (pinToken) async {
        final res = await _userService.resetTransactionLimit(
          transactionType: type,
          idempotencyKey: idempotencyKey,
          pinToken: pinToken,
        );
        if (!mounted) return;
        if (res['is_success'] == true && res['data'] is Map) {
          _applyLimitsPayload(res['data'] as Map);
          SnackbarUtils.success(
            context,
            res['message']?.toString() ?? 'Đã khôi phục hạn mức mặc định',
          );
        } else {
          SnackbarUtils.failure(
            context,
            res['message']?.toString() ?? 'Không thể khôi phục hạn mức',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FreezePinMediaQuery(
      child: AuthScaffold(
        appBarTitle: 'Hạn mức giao dịch',
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
                    icon: Iconsax.chart_2,
                    badgeText: 'Kiểm soát chi tiêu',
                    title: 'Hạn mức & Sức chứa ví',
                    subtitle:
                        'Theo dõi sức chứa tối đa của ví LumaPay và chủ động đặt giới hạn cho từng loại giao dịch.',
                  ),
                  const SizedBox(height: 20),
                  if (_walletCapacity != null) ...[
                    _buildWalletCapacityCard(_walletCapacity!),
                    const SizedBox(height: 14),
                  ],
                  for (final item in _limits) ...[
                    _buildLimitCard(item),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildWalletCapacityCard(Map<String, dynamic> cap) {
    final num currentBalance = (cap['current_balance'] as num?) ?? 0;
    final num effectiveCapacity = (cap['effective_capacity'] as num?) ?? 100000000;
    final num defaultCapacity = (cap['default_capacity'] as num?) ?? 100000000;
    final num maxCapacity = (cap['max_capacity'] as num?) ?? 200000000;
    final num remainingCapacity =
        (cap['remaining_capacity'] as num?) ??
        (effectiveCapacity > currentBalance
            ? effectiveCapacity - currentBalance
            : 0);
    final bool isCustom = cap['is_custom'] == true;

    final double progress = effectiveCapacity > 0
        ? (currentBalance / effectiveCapacity).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: authCardDeco(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF06292), kAuthPinkDark],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Iconsax.wallet_2,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sức chứa ví LumaPay',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kAuthText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Số dư tối đa được phép giữ trong ví',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        color: kAuthMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCustom
                      ? kAuthPink.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCustom ? 'Tùy chỉnh' : 'Mặc định',
                  style: GoogleFonts.roboto(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isCustom ? kAuthPinkDark : kAuthMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: kAuthPink.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Số dư hiện tại / Sức chứa',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        color: kAuthMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${FormatUtils.formatDisplayNumber(currentBalance)}đ / ${FormatUtils.formatDisplayNumber(effectiveCapacity)}đ',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kAuthText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.black.withValues(alpha: 0.07),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      kAuthPinkDark,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Có thể nạp / nhận thêm',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: kAuthMuted,
                      ),
                    ),
                    Text(
                      '${FormatUtils.formatDisplayNumber(remainingCapacity)}đ',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: kAuthSuccess,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  label: 'Sức chứa đang áp dụng',
                  value:
                      '${FormatUtils.formatDisplayNumber(effectiveCapacity)}đ',
                  note:
                      'Mặc định: ${FormatUtils.formatDisplayNumber(defaultCapacity)}đ',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricBox(
                  label: 'Tối đa cho phép',
                  value: '${FormatUtils.formatDisplayNumber(maxCapacity)}đ',
                  note: 'Trần tối đa có thể nâng',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => _onTapEditWalletCapacity(cap),
                    icon: const Icon(
                      Iconsax.setting_4,
                      size: 16,
                      color: kAuthPinkDark,
                    ),
                    label: Text(
                      'Điều chỉnh sức chứa',
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kAuthPinkDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kAuthPink.withValues(alpha: 0.5)),
                      backgroundColor: kAuthPink.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
              ),
              if (isCustom) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: _onTapResetWalletCapacity,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      side: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: Text(
                      'Mặc định',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kAuthMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard(Map<String, dynamic> item) {
    final String type = item['transaction_type']?.toString() ?? '';
    final meta = _metaForType(type);
    final Color accentColor = meta['color'] as Color;
    final IconData icon = meta['icon'] as IconData;

    final num maxAmount = (item['max_amount'] as num?) ?? 0;
    final num dailyLimit = (item['daily_limit'] as num?) ?? 0;
    final num sysMax = (item['system_max_amount'] as num?) ?? maxAmount;
    final num sysDaily = (item['system_daily_limit'] as num?) ?? dailyLimit;
    final num dailyUsed = (item['daily_used'] as num?) ?? 0;
    final num dailyRemaining =
        (item['daily_remaining'] as num?) ??
        (dailyLimit > dailyUsed ? dailyLimit - dailyUsed : 0);
    final bool isCustom = item['is_custom'] == true;

    final double progress = dailyLimit > 0
        ? (dailyUsed / dailyLimit).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: authCardDeco(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta['title'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kAuthText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta['subtitle'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        color: kAuthMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCustom
                      ? kAuthPink.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCustom ? 'Tùy chỉnh' : 'Mặc định',
                  style: GoogleFonts.roboto(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isCustom ? kAuthPinkDark : kAuthMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã dùng hôm nay',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        color: kAuthMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${FormatUtils.formatDisplayNumber(dailyUsed)}đ / ${FormatUtils.formatDisplayNumber(dailyLimit)}đ',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kAuthText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.black.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hạn mức còn lại hôm nay',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: kAuthMuted,
                      ),
                    ),
                    Text(
                      '${FormatUtils.formatDisplayNumber(dailyRemaining)}đ',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: kAuthSuccess,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  label: 'Tối đa / lần',
                  value: '${FormatUtils.formatDisplayNumber(maxAmount)}đ',
                  note: 'Trần HT: ${FormatUtils.formatDisplayNumber(sysMax)}đ',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricBox(
                  label: 'Tối đa / ngày',
                  value: '${FormatUtils.formatDisplayNumber(dailyLimit)}đ',
                  note:
                      'Trần HT: ${FormatUtils.formatDisplayNumber(sysDaily)}đ',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => _onTapEditLimit(item),
                    icon: const Icon(
                      Iconsax.setting_4,
                      size: 16,
                      color: kAuthPinkDark,
                    ),
                    label: Text(
                      'Điều chỉnh hạn mức',
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kAuthPinkDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kAuthPink.withValues(alpha: 0.5)),
                      backgroundColor: kAuthPink.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
              ),
              if (isCustom) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => _onTapResetLimit(item),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      side: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: Text(
                      'Mặc định',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kAuthMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required String note,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: kAuthMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: kAuthText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: kAuthMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditLimitBottomSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> meta;

  const _EditLimitBottomSheet({
    required this.item,
    required this.meta,
  });

  @override
  State<_EditLimitBottomSheet> createState() => _EditLimitBottomSheetState();
}

class _EditLimitBottomSheetState extends State<_EditLimitBottomSheet> {
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _dailyController = TextEditingController();
  String _errorMsg = '';

  late final num _sysMin;
  late final num _sysMax;
  late final num _sysDaily;

  @override
  void initState() {
    super.initState();
    _sysMin = (widget.item['min_amount'] as num?) ?? 10000;
    _sysMax = (widget.item['system_max_amount'] as num?) ?? 50000000;
    _sysDaily = (widget.item['system_daily_limit'] as num?) ?? _sysMax;

    final curMax = (widget.item['max_amount'] as num?) ?? _sysMax;
    final curDaily = (widget.item['daily_limit'] as num?) ?? _sysDaily;

    _maxController.text = FormatUtils.formatDisplayNumber(curMax);
    _dailyController.text = FormatUtils.formatDisplayNumber(curDaily);
  }

  @override
  void dispose() {
    _maxController.dispose();
    _dailyController.dispose();
    super.dispose();
  }

  void _setAmount(TextEditingController ctrl, num val) {
    final text = FormatUtils.formatDisplayNumber(val);
    ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (_errorMsg.isNotEmpty) {
      setState(() => _errorMsg = '');
    }
  }

  void _onSave() {
    final maxNum = FormatUtils.formatAmountToNum(_maxController.text);
    final dailyNum = FormatUtils.formatAmountToNum(_dailyController.text);

    if (maxNum < _sysMin || maxNum > _sysMax) {
      setState(() {
        _errorMsg =
            'Hạn mức mỗi lần phải từ ${FormatUtils.formatDisplayNumber(_sysMin)}đ đến ${FormatUtils.formatDisplayNumber(_sysMax)}đ';
      });
      return;
    }
    if (dailyNum < _sysMin || dailyNum > _sysDaily) {
      setState(() {
        _errorMsg =
            'Hạn mức mỗi ngày phải từ ${FormatUtils.formatDisplayNumber(_sysMin)}đ đến ${FormatUtils.formatDisplayNumber(_sysDaily)}đ';
      });
      return;
    }
    if (maxNum > dailyNum) {
      setState(() {
        _errorMsg = 'Hạn mức mỗi lần không được lớn hơn hạn mức mỗi ngày';
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, {
      'max_amount': maxNum,
      'daily_limit': dailyNum,
    });
  }

  List<num> _presetAmounts(num ceiling) {
    final candidates = <num>[2000000, 5000000, 10000000, 20000000, ceiling];
    final unique = <num>{};
    for (final c in candidates) {
      if (c >= _sysMin && c <= ceiling) {
        unique.add(c);
      }
    }
    return unique.toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Điều chỉnh: ${widget.meta['title']}',
                        style: GoogleFonts.roboto(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: kAuthText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Hạn mức tối đa mỗi lần giao dịch',
                  style: kAuthSectionLabelStyle,
                ),
                const SizedBox(height: 8),
                _buildCurrencyField(
                  controller: _maxController,
                  hint:
                      'Từ ${FormatUtils.formatDisplayNumber(_sysMin)}đ - ${FormatUtils.formatDisplayNumber(_sysMax)}đ',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final v in _presetAmounts(_sysMax))
                      _buildPresetChip(
                        label: v == _sysMax
                            ? 'Tối đa (${FormatUtils.formatDisplayNumber(v)}đ)'
                            : '${FormatUtils.formatDisplayNumber(v)}đ',
                        onTap: () => _setAmount(_maxController, v),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Hạn mức tối đa mỗi ngày',
                  style: kAuthSectionLabelStyle,
                ),
                const SizedBox(height: 8),
                _buildCurrencyField(
                  controller: _dailyController,
                  hint:
                      'Từ ${FormatUtils.formatDisplayNumber(_sysMin)}đ - ${FormatUtils.formatDisplayNumber(_sysDaily)}đ',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final v in _presetAmounts(_sysDaily))
                      _buildPresetChip(
                        label: v == _sysDaily
                            ? 'Tối đa (${FormatUtils.formatDisplayNumber(v)}đ)'
                            : '${FormatUtils.formatDisplayNumber(v)}đ',
                        onTap: () => _setAmount(_dailyController, v),
                      ),
                  ],
                ),
                if (_errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  AuthErrorBanner(message: _errorMsg),
                ],
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: 'Xác nhận lưu hạn mức',
                  loading: false,
                  onTap: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              inputFormatters: [CurrencyFormatter()],
              onChanged: (_) {
                if (_errorMsg.isNotEmpty) {
                  setState(() => _errorMsg = '');
                }
              },
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kAuthText,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.roboto(
                  fontSize: 14,
                  color: kAuthMuted,
                ),
              ),
            ),
          ),
          Text(
            'đ',
            style: GoogleFonts.roboto(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kAuthPinkDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: kAuthPink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: kAuthPink.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: kAuthPinkDark,
          ),
        ),
      ),
    );
  }
}

class _EditCapacityBottomSheet extends StatefulWidget {
  final Map<String, dynamic> cap;

  const _EditCapacityBottomSheet({required this.cap});

  @override
  State<_EditCapacityBottomSheet> createState() =>
      _EditCapacityBottomSheetState();
}

class _EditCapacityBottomSheetState extends State<_EditCapacityBottomSheet> {
  final TextEditingController _capacityController = TextEditingController();
  String _errorMsg = '';

  late final num _minCap;
  late final num _defaultCap;
  late final num _maxCap;

  @override
  void initState() {
    super.initState();
    _minCap = (widget.cap['min_capacity'] as num?) ?? 10000000;
    _defaultCap = (widget.cap['default_capacity'] as num?) ?? 100000000;
    _maxCap = (widget.cap['max_capacity'] as num?) ?? 200000000;

    final curCap = (widget.cap['effective_capacity'] as num?) ?? _defaultCap;
    _capacityController.text = FormatUtils.formatDisplayNumber(curCap);
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  void _setAmount(num val) {
    final text = FormatUtils.formatDisplayNumber(val);
    _capacityController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (_errorMsg.isNotEmpty) {
      setState(() => _errorMsg = '');
    }
  }

  void _onSave() {
    final capNum = FormatUtils.formatAmountToNum(_capacityController.text);
    if (capNum < _minCap || capNum > _maxCap) {
      setState(() {
        _errorMsg =
            'Sức chứa ví phải từ ${FormatUtils.formatDisplayNumber(_minCap)}đ đến ${FormatUtils.formatDisplayNumber(_maxCap)}đ';
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, capNum);
  }

  List<num> _presetCapacities() {
    final candidates = <num>[
      50000000,
      _defaultCap,
      150000000,
      _maxCap,
    ];
    final unique = <num>{};
    for (final c in candidates) {
      if (c >= _minCap && c <= _maxCap) {
        unique.add(c);
      }
    }
    return unique.toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Điều chỉnh sức chứa ví LumaPay',
                        style: GoogleFonts.roboto(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: kAuthText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sức chứa tối đa của ví',
                  style: kAuthSectionLabelStyle,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _capacityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: false,
                          ),
                          inputFormatters: [CurrencyFormatter()],
                          onChanged: (_) {
                            if (_errorMsg.isNotEmpty) {
                              setState(() => _errorMsg = '');
                            }
                          },
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kAuthText,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText:
                                'Từ ${FormatUtils.formatDisplayNumber(_minCap)}đ - ${FormatUtils.formatDisplayNumber(_maxCap)}đ',
                            hintStyle: GoogleFonts.roboto(
                              fontSize: 14,
                              color: kAuthMuted,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'đ',
                        style: GoogleFonts.roboto(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kAuthPinkDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final v in _presetCapacities())
                      InkWell(
                        onTap: () => _setAmount(v),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kAuthPink.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: kAuthPink.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Text(
                            v == _defaultCap
                                ? 'Mặc định (${FormatUtils.formatDisplayNumber(v)}đ)'
                                : v == _maxCap
                                ? 'Tối đa (${FormatUtils.formatDisplayNumber(v)}đ)'
                                : '${FormatUtils.formatDisplayNumber(v)}đ',
                            style: GoogleFonts.roboto(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: kAuthPinkDark,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  AuthErrorBanner(message: _errorMsg),
                ],
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: 'Xác nhận lưu sức chứa',
                  loading: false,
                  onTap: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

