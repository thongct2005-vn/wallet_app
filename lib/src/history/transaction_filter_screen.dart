import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/widgets/date_range_picker_sheet.dart';
import 'package:app/core/widgets/history_filter_widgets.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

/// Tiêu chí lọc giao dịch dùng chung giữa màn hình Lịch sử và Bộ lọc GD.
class TransactionFilterCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minAmount;
  final int? maxAmount;
  final String? fundingSource; // 'LUMAPAY' | 'POSTPAID'
  final String? transactionType; // 'TOPUP' | 'WITHDRAW' | 'TRANSFER' | 'PAYMENT' | 'REFUND'
  final String? direction; // 'IN' | 'OUT' (khi transactionType == 'TRANSFER' hoặc 'REFUND')
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
    _FilterServiceOption(
      type: 'REFUND',
      direction: null,
      label: 'Hoàn tiền',
      icon: Iconsax.money_change5,
      color: Color(0xFF0D9488),
    ),
  ];

  static const List<_FilterPillOption> _accountOptions = [
    _FilterPillOption(
      value: 'LUMAPAY',
      label: 'Ví LumaPay',
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
                          const HistoryFilterSectionTitle('Thời gian'),
                          const SizedBox(height: 8),
                          HistoryFilterTimeCard(
                            fromDateText: fromDateText,
                            toDateText: toDateText,
                            hasCustomDate: hasCustomDate,
                            onPickDateRange: _pickDateRange,
                            infoText:
                                'Hỗ trợ tra cứu giao dịch trong 12 tháng gần nhất',
                          ),
                          const SizedBox(height: 18),
                          const HistoryFilterSectionTitle('Số tiền'),
                          const SizedBox(height: 8),
                          HistoryFilterAmountCard(
                            minCtrl: _minCtrl,
                            maxCtrl: _maxCtrl,
                            isMinActive: _minAmount != null,
                            isMaxActive: _maxAmount != null,
                            amountError: _amountError,
                            onAmountChanged: _onAmountChanged,
                          ),
                          const SizedBox(height: 18),
                          const HistoryFilterSectionTitle('Tài khoản/thẻ'),
                          const SizedBox(height: 8),
                          _buildAccountSection(),
                          const SizedBox(height: 18),
                          const HistoryFilterSectionTitle('Dịch vụ'),
                          const SizedBox(height: 8),
                          _buildServicesGrid(),
                          const SizedBox(height: 18),
                          const HistoryFilterSectionTitle('Trạng thái'),
                          const SizedBox(height: 8),
                          _buildStatusSection(),
                        ],
                      ),
                    ),
                  ),
                  HistoryFilterBottomBar(
                    hasAnyFilter: _hasAnyFilter,
                    onClearAll: _clearAll,
                    onApply: _apply,
                  ),
                ],
              ),
            ),
          ],
        ),
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
            child: HistoryFilterSelectablePill(
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
                child: HistoryFilterGridTile(
                  label: s.label,
                  icon: s.icon,
                  color: s.color,
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

  Widget _buildStatusSection() {
    const statuses = TransactionFilterScreen._statusOptions;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HistoryFilterSelectablePill(
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
              child: HistoryFilterSelectablePill(
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
              child: HistoryFilterSelectablePill(
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
}
