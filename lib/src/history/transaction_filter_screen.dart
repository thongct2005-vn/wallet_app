import 'package:app/core/utils/currency_formatter.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/widgets/date_range_picker_sheet.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

/// Tiêu chí lọc giao dịch dùng chung giữa màn hình Lịch sử và Bộ lọc GD.
class TransactionFilterCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minAmount;
  final int? maxAmount;
  final String? fundingSource; // 'MIO' | 'POSTPAID'
  final String? transactionType; // 'TOPUP' | 'WITHDRAW' | 'TRANSFER' | 'PAYMENT'
  final String? direction; // 'IN' | 'OUT' (khi transactionType == 'TRANSFER')
  final String? status; // 'SUCCESS' | 'FAILED' | 'PENDING'

  const TransactionFilterCriteria({
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.fundingSource,
    this.transactionType,
    this.direction,
    this.status,
  });

  static const TransactionFilterCriteria empty = TransactionFilterCriteria();

  bool get hasDateRange => startDate != null && endDate != null;
  bool get hasAmountRange => minAmount != null || maxAmount != null;
  bool get hasFundingSource =>
      fundingSource != null && fundingSource!.isNotEmpty;
  bool get hasService =>
      transactionType != null && transactionType!.isNotEmpty;
  bool get hasStatus => status != null && status!.isNotEmpty;

  bool get isEmpty =>
      !hasDateRange &&
      !hasAmountRange &&
      !hasFundingSource &&
      !hasService &&
      !hasStatus;

  int get activeCount =>
      (hasDateRange ? 1 : 0) +
      (hasAmountRange ? 1 : 0) +
      (hasFundingSource ? 1 : 0) +
      (hasService ? 1 : 0) +
      (hasStatus ? 1 : 0);

  TransactionFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool clearDate = false,
    int? minAmount,
    int? maxAmount,
    bool clearAmount = false,
    String? fundingSource,
    bool clearFundingSource = false,
    String? transactionType,
    String? direction,
    bool clearService = false,
    String? status,
    bool clearStatus = false,
  }) {
    return TransactionFilterCriteria(
      startDate: clearDate ? null : (startDate ?? this.startDate),
      endDate: clearDate ? null : (endDate ?? this.endDate),
      minAmount: clearAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmount ? null : (maxAmount ?? this.maxAmount),
      fundingSource: clearFundingSource
          ? null
          : (fundingSource ?? this.fundingSource),
      transactionType: clearService
          ? null
          : (transactionType ?? this.transactionType),
      direction: clearService ? null : (direction ?? this.direction),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

class _FilterServiceOption {
  final String type;
  final String? direction;
  final String label;
  final IconData icon;
  final Color color;

  const _FilterServiceOption({
    required this.type,
    required this.direction,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _FilterPillOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _FilterPillOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class TransactionFilterScreen extends StatefulWidget {
  final TransactionFilterCriteria initialCriteria;

  const TransactionFilterScreen({
    super.key,
    required this.initialCriteria,
  });

  static const List<_FilterServiceOption> _serviceOptions = [
    _FilterServiceOption(
      type: 'TOPUP',
      direction: null,
      label: 'Nạp tiền',
      icon: Iconsax.direct_inbox5,
      color: Color(0xFF0284C7),
    ),
    _FilterServiceOption(
      type: 'WITHDRAW',
      direction: null,
      label: 'Rút tiền',
      icon: Iconsax.direct_send5,
      color: Color(0xFFEA580C),
    ),
    _FilterServiceOption(
      type: 'TRANSFER',
      direction: 'OUT',
      label: 'Chuyển tiền',
      icon: Iconsax.money_send5,
      color: Color(0xFFE11D48),
    ),
    _FilterServiceOption(
      type: 'TRANSFER',
      direction: 'IN',
      label: 'Nhận tiền',
      icon: Iconsax.money_recive5,
      color: Color(0xFF059669),
    ),
    _FilterServiceOption(
      type: 'PAYMENT',
      direction: null,
      label: 'Thanh toán',
      icon: Icons.storefront_rounded,
      color: Color(0xFF7C3AED),
    ),
  ];

  static const List<_FilterPillOption> _accountOptions = [
    _FilterPillOption(
      value: 'MIO',
      label: 'Ví Mio',
      icon: Iconsax.wallet_25,
      color: kTfPink,
    ),
    _FilterPillOption(
      value: 'POSTPAID',
      label: 'Ví Trả Sau',
      icon: Icons.credit_score_rounded,
      color: Color(0xFFC2185B),
    ),
  ];

  static const List<_FilterPillOption> _statusOptions = [
    _FilterPillOption(
      value: 'SUCCESS',
      label: 'Thành công',
      icon: Icons.check_circle_rounded,
      color: kTfSuccess,
    ),
    _FilterPillOption(
      value: 'FAILED',
      label: 'Thất bại',
      icon: Icons.cancel_rounded,
      color: Color(0xFFE53935),
    ),
    _FilterPillOption(
      value: 'PENDING',
      label: 'Đang xử lý',
      icon: Icons.schedule_rounded,
      color: Color(0xFFD97706),
    ),
  ];

  static String? labelForService(String? type, String? direction) {
    if (type == null || type.isEmpty) return null;
    for (final s in _serviceOptions) {
      if (s.type == type && s.direction == direction) return s.label;
    }
    return null;
  }

  static String? labelForAccount(String? fundingSource) {
    if (fundingSource == null || fundingSource.isEmpty) return null;
    for (final a in _accountOptions) {
      if (a.value == fundingSource) return a.label;
    }
    return null;
  }

  static String? labelForStatus(String? status) {
    if (status == null || status.isEmpty) return null;
    for (final s in _statusOptions) {
      if (s.value == status) return s.label;
    }
    return null;
  }

  @override
  State<TransactionFilterScreen> createState() =>
      _TransactionFilterScreenState();
}

class _TransactionFilterScreenState extends State<TransactionFilterScreen> {
  static final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late int? _minAmount;
  late int? _maxAmount;
  late String? _fundingSource;
  late String? _transactionType;
  late String? _direction;
  late String? _status;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCriteria;
    _startDate = c.startDate;
    _endDate = c.endDate;
    _minAmount = c.minAmount;
    _maxAmount = c.maxAmount;
    _fundingSource = c.fundingSource;
    _transactionType = c.transactionType;
    _direction = c.direction;
    _status = c.status;

    _minCtrl = TextEditingController(
      text: _minAmount != null ? FormatUtils.formatDisplayNumber(_minAmount!) : '',
    );
    _maxCtrl = TextEditingController(
      text: _maxAmount != null ? FormatUtils.formatDisplayNumber(_maxAmount!) : '',
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  bool get _hasAnyFilter =>
      (_startDate != null && _endDate != null) ||
      _minAmount != null ||
      _maxAmount != null ||
      _fundingSource != null ||
      _transactionType != null ||
      _status != null;

  int? _parseControllerAmount(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  void _onAmountChanged() {
    setState(() {
      _minAmount = _parseControllerAmount(_minCtrl.text);
      _maxAmount = _parseControllerAmount(_maxCtrl.text);
      if (_minAmount != null &&
          _maxAmount != null &&
          _minAmount! > _maxAmount!) {
        _amountError = 'Số tiền "Từ" phải nhỏ hơn hoặc bằng số tiền "Đến"';
      } else {
        _amountError = null;
      }
    });
  }

  Future<void> _pickDateRange() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    final result = await DateRangePickerSheet.show(
      context,
      title: 'Lọc theo ngày',
      confirmText: 'Áp dụng',
      firstDate: oneYearAgo,
      lastDate: today,
      initialRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (result != null && mounted) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }

  void _clearAll() {
    FocusManager.instance.primaryFocus?.unfocus();
    _minCtrl.clear();
    _maxCtrl.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
      _minAmount = null;
      _maxAmount = null;
      _fundingSource = null;
      _transactionType = null;
      _direction = null;
      _status = null;
      _amountError = null;
    });
  }

  void _apply() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_minAmount != null && _maxAmount != null && _minAmount! > _maxAmount!) {
      setState(() {
        _amountError = 'Số tiền "Từ" phải nhỏ hơn hoặc bằng số tiền "Đến"';
      });
      return;
    }

    Navigator.of(context).pop(
      TransactionFilterCriteria(
        startDate: _startDate,
        endDate: _endDate,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        fundingSource: _fundingSource,
        transactionType: _transactionType,
        direction: _direction,
        status: _status,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    final bool hasCustomDate = _startDate != null && _endDate != null;
    final String fromDateText = hasCustomDate
        ? _dateFmt.format(_startDate!)
        : _dateFmt.format(oneYearAgo);
    final String toDateText = hasCustomDate
        ? (_isSameDay(_endDate!, today)
              ? 'Hôm nay'
              : _dateFmt.format(_endDate!))
        : 'Hôm nay';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kTfBg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leadingWidth: 58,
          leading: TransferCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Bộ lọc giao dịch',
            style: GoogleFonts.roboto(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: kTfText,
            ),
          ),
          actions: [
            TransferCircleButton(
              icon: Iconsax.home_2,
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (r) => false,
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            const TransferHeaderGradient(),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Thời gian'),
                          const SizedBox(height: 8),
                          _buildTimeCard(
                            fromDateText: fromDateText,
                            toDateText: toDateText,
                            hasCustomDate: hasCustomDate,
                          ),
                          const SizedBox(height: 18),
                          _sectionTitle('Số tiền'),
                          const SizedBox(height: 8),
                          _buildAmountCard(),
                          const SizedBox(height: 18),
                          _sectionTitle('Tài khoản/thẻ'),
                          const SizedBox(height: 8),
                          _buildAccountSection(),
                          const SizedBox(height: 18),
                          _sectionTitle('Dịch vụ'),
                          const SizedBox(height: 8),
                          _buildServicesGrid(),
                          const SizedBox(height: 18),
                          _sectionTitle('Trạng thái'),
                          const SizedBox(height: 8),
                          _buildStatusSection(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: kTfText,
      ),
    );
  }

  Widget _buildTimeCard({
    required String fromDateText,
    required String toDateText,
    required bool hasCustomDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _dateSelectorBox(
                  label: 'Từ ngày',
                  valueText: fromDateText,
                  isActive: hasCustomDate,
                  onTap: _pickDateRange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateSelectorBox(
                  label: 'Đến ngày',
                  valueText: toDateText,
                  isActive: hasCustomDate,
                  onTap: _pickDateRange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Iconsax.info_circle, size: 14, color: kTfMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hỗ trợ tra cứu giao dịch trong 12 tháng gần nhất',
                  style: GoogleFonts.roboto(fontSize: 12, color: kTfMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateSelectorBox({
    required String label,
    required String valueText,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isActive ? const Color(0xFFFFF1F6) : const Color(0xFFFAF8FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? kTfPink : const Color(0xFFEAE2E7),
              width: isActive ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: isActive ? kTfPinkDark : kTfMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      valueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isActive ? kTfText : kTfMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: isActive ? kTfPinkDark : kTfMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _amountInputBox(
                  label: 'Từ',
                  hint: '0đ',
                  controller: _minCtrl,
                  isActive: _minAmount != null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _amountInputBox(
                  label: 'Đến',
                  hint: 'Không giới hạn',
                  controller: _maxCtrl,
                  isActive: _maxAmount != null,
                ),
              ),
            ],
          ),
          if (_amountError != null) ...[
            const SizedBox(height: 8),
            Text(
              _amountError!,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFE53935),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountInputBox({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFF1F6) : const Color(0xFFFAF8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _amountError != null
              ? const Color(0xFFE53935)
              : (isActive ? kTfPink : const Color(0xFFEAE2E7)),
          width: isActive || _amountError != null ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11.5,
              color: isActive ? kTfPinkDark : kTfMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                    CurrencyFormatter(),
                  ],
                  onChanged: (_) => _onAmountChanged(),
                  cursorColor: kTfPink,
                  style: GoogleFonts.roboto(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: kTfText,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kTfMuted,
                    ),
                    suffixText: controller.text.isNotEmpty ? 'đ' : null,
                    suffixStyle: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTfText,
                    ),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    _onAmountChanged();
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: kTfMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    const opts = TransactionFilterScreen._accountOptions;
    return Row(
      children: [
        for (int i = 0; i < opts.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _selectablePill(
              label: opts[i].label,
              icon: opts[i].icon,
              accent: opts[i].color,
              selected: _fundingSource == opts[i].value,
              onTap: () => setState(() {
                _fundingSource =
                    _fundingSource == opts[i].value ? null : opts[i].value;
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServicesGrid() {
    const services = TransactionFilterScreen._serviceOptions;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final s in services)
              SizedBox(
                width: tileWidth,
                child: _serviceTile(
                  option: s,
                  selected:
                      _transactionType == s.type && _direction == s.direction,
                  onTap: () => setState(() {
                    final alreadySelected =
                        _transactionType == s.type && _direction == s.direction;
                    if (alreadySelected) {
                      _transactionType = null;
                      _direction = null;
                    } else {
                      _transactionType = s.type;
                      _direction = s.direction;
                    }
                  }),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _serviceTile({
    required _FilterServiceOption option,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFFFF1F6) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? kTfPink : const Color(0xFFEDE2E8),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? kTfPink.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: selected ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: selected ? 0.16 : 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: option.color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? kTfPinkDark : kTfText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    const statuses = TransactionFilterScreen._statusOptions;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _selectablePill(
                label: statuses[0].label,
                icon: statuses[0].icon,
                accent: statuses[0].color,
                selected: _status == statuses[0].value,
                onTap: () => setState(() {
                  _status =
                      _status == statuses[0].value ? null : statuses[0].value;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _selectablePill(
                label: statuses[1].label,
                icon: statuses[1].icon,
                accent: statuses[1].color,
                selected: _status == statuses[1].value,
                onTap: () => setState(() {
                  _status =
                      _status == statuses[1].value ? null : statuses[1].value;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _selectablePill(
                label: statuses[2].label,
                icon: statuses[2].icon,
                accent: statuses[2].color,
                selected: _status == statuses[2].value,
                onTap: () => setState(() {
                  _status =
                      _status == statuses[2].value ? null : statuses[2].value;
                }),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _selectablePill({
    required String label,
    required IconData icon,
    required Color accent,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFFFF1F6) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kTfPink : const Color(0xFFEDE2E8),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? kTfPink.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.025),
                blurRadius: selected ? 8 : 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? kTfPinkDark : accent),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? kTfPinkDark : kTfText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEDE2E8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_hasAnyFilter) ...[
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _clearAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTfText,
                    side: const BorderSide(color: Color(0xFFDDD2D8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Xóa bộ lọc',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kTfPink, kTfPinkDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kTfPink.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Áp dụng',
                    style: GoogleFonts.roboto(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _whiteCardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFEDE2E8)),
    boxShadow: [
      BoxShadow(
        color: kTfPink.withValues(alpha: 0.06),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
