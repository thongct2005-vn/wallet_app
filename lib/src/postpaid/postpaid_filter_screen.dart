import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/widgets/date_range_picker_sheet.dart';
import 'package:app/core/widgets/history_filter_widgets.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

/// Tiêu chí lọc biến động Ví trả sau dùng chung giữa màn Biến động và Bộ lọc.
class PostpaidFilterCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minAmount;
  final int? maxAmount;
  final String? deltaDirection; // 'INCREASE' | 'DECREASE'
  final String? action; // 'PURCHASE' | 'REPAY' | 'REFUND' | 'SERVICE_FEE' | 'LATE_FEE' | 'STATEMENT_CLOSE' | 'LIMIT_ADJUST'

  const PostpaidFilterCriteria({
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.deltaDirection,
    this.action,
  });

  static const PostpaidFilterCriteria empty = PostpaidFilterCriteria();

  bool get hasDateRange => startDate != null && endDate != null;
  bool get hasAmountRange => minAmount != null || maxAmount != null;
  bool get hasDeltaDirection =>
      deltaDirection != null && deltaDirection!.isNotEmpty;
  bool get hasAction => action != null && action!.isNotEmpty;

  bool get isEmpty =>
      !hasDateRange &&
      !hasAmountRange &&
      !hasDeltaDirection &&
      !hasAction;

  int get activeCount =>
      (hasDateRange ? 1 : 0) +
      (hasAmountRange ? 1 : 0) +
      (hasDeltaDirection ? 1 : 0) +
      (hasAction ? 1 : 0);

  PostpaidFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool clearDate = false,
    int? minAmount,
    int? maxAmount,
    bool clearAmount = false,
    String? deltaDirection,
    bool clearDeltaDirection = false,
    String? action,
    bool clearAction = false,
  }) {
    return PostpaidFilterCriteria(
      startDate: clearDate ? null : (startDate ?? this.startDate),
      endDate: clearDate ? null : (endDate ?? this.endDate),
      minAmount: clearAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmount ? null : (maxAmount ?? this.maxAmount),
      deltaDirection: clearDeltaDirection
          ? null
          : (deltaDirection ?? this.deltaDirection),
      action: clearAction ? null : (action ?? this.action),
    );
  }
}

class _PostpaidActionOption {
  final String code;
  final String label;
  final IconData icon;
  final Color color;

  const _PostpaidActionOption({
    required this.code,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _PostpaidDirectionOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _PostpaidDirectionOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class PostpaidFilterScreen extends StatefulWidget {
  final PostpaidFilterCriteria initialCriteria;

  const PostpaidFilterScreen({
    super.key,
    required this.initialCriteria,
  });

  static const List<_PostpaidDirectionOption> _directionOptions = [
    _PostpaidDirectionOption(
      value: 'INCREASE',
      label: 'Tăng dư nợ',
      icon: Icons.arrow_upward_rounded,
      color: Color(0xFFE53935),
    ),
    _PostpaidDirectionOption(
      value: 'DECREASE',
      label: 'Giảm dư nợ',
      icon: Icons.arrow_downward_rounded,
      color: Color(0xFF2E9E5B),
    ),
  ];

  static const List<_PostpaidActionOption> _actionOptions = [
    _PostpaidActionOption(
      code: 'PURCHASE',
      label: 'Thanh toán',
      icon: Icons.credit_score_rounded,
      color: Color(0xFFEC407A),
    ),
    _PostpaidActionOption(
      code: 'REPAY',
      label: 'Trả nợ',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFD81B60),
    ),
    _PostpaidActionOption(
      code: 'REFUND',
      label: 'Hoàn tiền',
      icon: Iconsax.money_change5,
      color: Color(0xFF0D9488),
    ),
    _PostpaidActionOption(
      code: 'SERVICE_FEE',
      label: 'Phí dịch vụ',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFD97706),
    ),
    _PostpaidActionOption(
      code: 'LATE_FEE',
      label: 'Phí trễ hạn',
      icon: Icons.event_busy_rounded,
      color: Color(0xFFDC2626),
    ),
    _PostpaidActionOption(
      code: 'STATEMENT_CLOSE',
      label: 'Chốt sao kê',
      icon: Icons.event_note_rounded,
      color: Color(0xFF2563EB),
    ),
    _PostpaidActionOption(
      code: 'LIMIT_ADJUST',
      label: 'Điều chỉnh HM',
      icon: Icons.tune_rounded,
      color: Color(0xFF7C3AED),
    ),
  ];

  static String? labelForDirection(String? direction) {
    if (direction == null || direction.isEmpty) return null;
    for (final d in _directionOptions) {
      if (d.value == direction) return d.label;
    }
    return null;
  }

  static String? labelForAction(String? action) {
    if (action == null || action.isEmpty) return null;
    for (final a in _actionOptions) {
      if (a.code == action) return a.label;
    }
    return null;
  }

  @override
  State<PostpaidFilterScreen> createState() => _PostpaidFilterScreenState();
}

class _PostpaidFilterScreenState extends State<PostpaidFilterScreen> {
  static final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late int? _minAmount;
  late int? _maxAmount;
  late String? _deltaDirection;
  late String? _action;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCriteria;
    _startDate = c.startDate;
    _endDate = c.endDate;
    _minAmount = c.minAmount;
    _maxAmount = c.maxAmount;
    _deltaDirection = c.deltaDirection;
    _action = c.action;

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
      _deltaDirection != null ||
      _action != null;

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
    final vnNow = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(vnNow.year, vnNow.month, vnNow.day);
    final oneYearAgo = DateTime(vnNow.year - 1, vnNow.month, vnNow.day);

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
      _deltaDirection = null;
      _action = null;
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
      PostpaidFilterCriteria(
        startDate: _startDate,
        endDate: _endDate,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        deltaDirection: _deltaDirection,
        action: _action,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final vnNow = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(vnNow.year, vnNow.month, vnNow.day);
    final oneYearAgo = DateTime(vnNow.year - 1, vnNow.month, vnNow.day);

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
            'Bộ lọc biến động',
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
                                'Hỗ trợ tra cứu biến động trong 12 tháng gần nhất',
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
                          const HistoryFilterSectionTitle('Biến động dư nợ'),
                          const SizedBox(height: 8),
                          _buildDirectionSection(),
                          const SizedBox(height: 18),
                          const HistoryFilterSectionTitle('Loại biến động'),
                          const SizedBox(height: 8),
                          _buildActionsGrid(),
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

  Widget _buildDirectionSection() {
    const opts = PostpaidFilterScreen._directionOptions;
    return Row(
      children: [
        for (int i = 0; i < opts.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: HistoryFilterSelectablePill(
              label: opts[i].label,
              icon: opts[i].icon,
              accent: opts[i].color,
              selected: _deltaDirection == opts[i].value,
              onTap: () => setState(() {
                _deltaDirection =
                    _deltaDirection == opts[i].value ? null : opts[i].value;
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionsGrid() {
    const actions = PostpaidFilterScreen._actionOptions;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in actions)
              SizedBox(
                width: tileWidth,
                child: HistoryFilterGridTile(
                  label: item.label,
                  icon: item.icon,
                  color: item.color,
                  selected: _action == item.code,
                  onTap: () => setState(() {
                    _action = _action == item.code ? null : item.code;
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}

