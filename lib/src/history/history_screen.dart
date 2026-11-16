import 'dart:async';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/date_range_picker_sheet.dart';
import 'package:app/src/history/transaction_detail_screen.dart';
import 'package:app/src/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/history/transaction_model.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

const Color _kPink = Color(0xFFEC407A);
const Color _kPinkDark = Color(0xFFD81B60);
const Color _kPinkLight = Color(0xFFF48FB1);
const Color _kText = Color(0xFF1F1B24);
const Color _kMuted = Color(0xFF8A8590);
const Color _kIncome = Color(0xFF2E9E5B);
const Color _kExpense = Color(0xFFE53935);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TransactionService _transactionService = TransactionService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  final List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  List<TransactionModel>? _preparedSource;
  List<MapEntry<String, List<_PreparedTransaction>>> _groupedMonths = const [];
  String? _nextCursor;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchKeyword = '';
  String? _selectedType;
  String? _selectedDirection;

  static final TextStyle _tileTitleStyle = GoogleFonts.roboto(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: _kText,
  );
  static final TextStyle _tileBadgeBaseStyle = GoogleFonts.roboto(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle _tileTimeStyle = GoogleFonts.roboto(
    fontSize: 12,
    color: _kMuted,
  );
  static final TextStyle _tileIncomeAmountStyle = GoogleFonts.roboto(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: _kIncome,
  );
  static final TextStyle _tileExpenseAmountStyle = GoogleFonts.roboto(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: _kText,
  );
  static final TextStyle _tileBalanceStyle = GoogleFonts.roboto(
    fontSize: 11.5,
    color: _kMuted,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle _monthLabelStyle = GoogleFonts.roboto(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: _kPinkDark,
  );
  static final TextStyle _monthCountStyle = GoogleFonts.roboto(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: _kMuted,
  );
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isExporting = false;
  int _fetchGeneration = 0;

  static const List<_TransactionTypeFilter> _typeFilters = [
    _TransactionTypeFilter(
      type: null,
      direction: null,
      label: 'Tất cả',
      icon: Iconsax.receipt_item5,
    ),
    _TransactionTypeFilter(
      type: 'TOPUP',
      direction: null,
      label: 'Nạp tiền',
      icon: Iconsax.direct_inbox5,
    ),
    _TransactionTypeFilter(
      type: 'WITHDRAW',
      direction: null,
      label: 'Rút tiền',
      icon: Iconsax.direct_send5,
    ),
    _TransactionTypeFilter(
      type: 'TRANSFER',
      direction: 'OUT',
      label: 'Chuyển tiền',
      icon: Iconsax.money_send5,
    ),
    _TransactionTypeFilter(
      type: 'TRANSFER',
      direction: 'IN',
      label: 'Nhận tiền',
      icon: Iconsax.money_recive5,
    ),
    _TransactionTypeFilter(
      type: 'PAYMENT',
      direction: null,
      label: 'Thanh toán',
      icon: Icons.storefront_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMore();
    _fetchSummary();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _unfocusSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  bool get _hasActiveFilters =>
      _selectedType != null ||
      _selectedDirection != null ||
      _searchKeyword.isNotEmpty ||
      (_startDate != null && _endDate != null);

  Future<void> _fetchMore({bool reset = false}) async {
    if (!reset && _isLoading) return;
    if (reset) {
      _hasMore = true;
      _nextCursor = null;
    } else if (!_hasMore) {
      return;
    }

    final int generation = ++_fetchGeneration;
    setState(() => _isLoading = true);

    final result = await _transactionService.getTransferHistory(
      _nextCursor,
      20,
      keyword: _searchKeyword.isEmpty ? null : _searchKeyword,
      transactionType: _selectedType,
      direction: _selectedDirection,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (!mounted || generation != _fetchGeneration) return;

    if (result['is_success'] == true) {
      final List<dynamic> rawList = result['data']['transaction_list'];
      final newItems = rawList
          .map((e) => TransactionModel.fromJson(e))
          .toList();

      setState(() {
        if (reset) {
          _allTransactions.clear();
        }
        _allTransactions.addAll(newItems);
        _applyFilter();
        _nextCursor = result['data']['next_cursor']?.toString();
        _hasMore = result['data']['next_cursor'] != null;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _selectTypeFilter(_TransactionTypeFilter filter) {
    _unfocusSearch();
    if (_selectedType == filter.type &&
        _selectedDirection == filter.direction) {
      return;
    }
    setState(() {
      _selectedType = filter.type;
      _selectedDirection = filter.direction;
      _applyFilter();
    });
    _fetchMore(reset: true);
  }

  void _clearAllFilters() {
    _unfocusSearch();
    _searchController.clear();
    setState(() {
      _searchKeyword = '';
      _selectedType = null;
      _selectedDirection = null;
      _startDate = null;
      _endDate = null;
      _applyFilter();
    });
    _fetchMore(reset: true);
  }

  Future<void> _fetchSummary() async {
    final result = await _transactionService.getCurrentMonthSummary();
    if (result['is_success'] == true) {
      setState(() {
        _totalIncome = (result['data']['total_income'] as num).toDouble();
        _totalExpense = (result['data']['total_expense'] as num).toDouble();
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = value.trim().toLowerCase();
      if (_searchKeyword == trimmed) return;
      _searchKeyword = trimmed;
      _applyFilter();
      _fetchMore(reset: true);
    });
  }

  static String _removeDiacritics(String str) {
    var withDia = 'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ';
    var noDia   = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], noDia[i]);
    }
    return result;
  }

  void _applyFilter() {
    Iterable<TransactionModel> items = _allTransactions;

    if (_selectedType != null && _selectedType!.isNotEmpty) {
      items = items.where((t) => t.type == _selectedType);
    }

    if (_selectedDirection != null && _selectedDirection!.isNotEmpty) {
      items = items.where((t) => t.direction == _selectedDirection);
    }

    if (_searchKeyword.isNotEmpty) {
      final cleanKeyword = _removeDiacritics(_searchKeyword);
      items = items.where((t) {
        final desc = (t.description ?? '').toLowerCase();
        final name = t.counterpartyName.toLowerCase();
        final bank = t.bankName.toLowerCase();
        final phone = t.counterpartyPhone.toLowerCase();
        final idStr = t.id.toString();
        final orderId = (t.orderId ?? '').toLowerCase();

        String typeDisplay = '';
        if (t.type == 'TOPUP') {
          typeDisplay =
              'nạp tiền nạp tiền vào ví nạp từ $bank nạp tiền từ $bank topup';
        } else if (t.type == 'WITHDRAW') {
          typeDisplay =
              'rút tiền rút tiền từ ví rút về $bank rút tiền về $bank withdraw';
        } else if (t.type == 'TRANSFER') {
          typeDisplay = t.direction == 'OUT'
              ? 'chuyển tiền chuyển đến $name transfer'
              : 'nhận tiền nhận từ $name transfer';
        } else if (t.type == 'PAYMENT') {
          typeDisplay = 'thanh toán $name payment';
        }

        final combined = '$desc $name $bank $phone $idStr $orderId $typeDisplay';
        final combinedClean = _removeDiacritics(combined);

        return combined.contains(_searchKeyword) ||
            combinedClean.contains(cleanKeyword);
      });
    }

    if (_startDate != null && _endDate != null) {
      final start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      final end = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      items = items.where(
        (t) =>
            t.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.createdAt.isBefore(end.add(const Duration(seconds: 1))),
      );
    }

    _filteredTransactions = items.toList();
    _syncGroupedMonths();
  }

  void _syncGroupedMonths() {
    final Map<String, List<_PreparedTransaction>> grouped = {};
    for (final t in _filteredTransactions) {
      final key = 'Tháng ${t.createdAt.month}/${t.createdAt.year}';
      grouped
          .putIfAbsent(key, () => [])
          .add(_PreparedTransaction.fromModel(t, _tileBadgeBaseStyle));
    }
    _groupedMonths = grouped.entries.toList(growable: false);
    _preparedSource = _filteredTransactions;
  }

  @override
  Widget build(BuildContext context) {
    if (!identical(_preparedSource, _filteredTransactions)) {
      _syncGroupedMonths();
    }
    final groupedMonths = _groupedMonths;

    return PopScope(
      canPop: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _unfocusSearch,
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF6F8),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            actions: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
                  child: TextFieldTapRegion(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: _kPink.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            Iconsax.search_normal_1,
                            size: 20,
                            color: _kPink,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchChanged,
                              onTapOutside: (_) => _unfocusSearch(),
                              onSubmitted: (_) => _unfocusSearch(),
                              textInputAction: TextInputAction.search,
                              textAlignVertical: TextAlignVertical.center,
                              cursorColor: _kPink,
                              style: GoogleFonts.roboto(fontSize: 15),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: "Tìm kiếm giao dịch",
                                hintStyle: GoogleFonts.roboto(
                                  fontSize: 15,
                                  color: _kMuted,
                                ),
                              ),
                            ),
                          ),
                          if (_searchKeyword.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _appBarCircleButton(
                icon: Iconsax.filter,
                tooltip: 'Lọc theo ngày',
                onPressed: _showDateFilterDialog,
                padding: const EdgeInsets.only(left: 12),
              ),
              _appBarCircleButton(
                icon: Icons.file_download_outlined,
                tooltip: 'Xuất Excel',
                onPressed: _exportExcel,
                padding: const EdgeInsets.only(left: 8, right: 16),
              ),
            ],
          ),
        body: Stack(
          children: [
            RepaintBoundary(
              child: Container(
                height: 420,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kPink.withValues(alpha: 0.22),
                      _kPinkLight.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                color: _kPink,
                onRefresh: () async {
                  await Future.wait([_fetchMore(reset: true), _fetchSummary()]);
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  scrollCacheExtent: const ScrollCacheExtent.pixels(700),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildSummaryCard()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTypeFilterBar(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                        child: Row(
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
                            Expanded(
                              child: Text(
                                "Giao dịch gần đây",
                                style: GoogleFonts.roboto(
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w700,
                                  color: _kText,
                                ),
                              ),
                            ),
                            if (_hasActiveFilters)
                              TextButton.icon(
                                onPressed: _clearAllFilters,
                                style: TextButton.styleFrom(
                                  foregroundColor: _kPinkDark,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.close_rounded, size: 15),
                                label: Text(
                                  'Đặt lại',
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_startDate != null && _endDate != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Chip(
                                avatar: const Icon(
                                  Iconsax.calendar_1,
                                  size: 16,
                                  color: _kPink,
                                ),
                                label: Text(
                                  '${FormatUtils.formatCustomDateTime(_startDate.toString())} - ${FormatUtils.formatCustomDateTime(_endDate.toString())}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: _kPinkDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: _kPink.withValues(alpha: 0.1),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: _kPinkDark,
                                ),
                                onDeleted: _clearDateFilter,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_filteredTransactions.isEmpty && !_isLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 48,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _kPink.withValues(alpha: 0.16),
                                      _kPinkLight.withValues(alpha: 0.10),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Iconsax.receipt_search,
                                  color: _kPink,
                                  size: 38,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                !_hasActiveFilters
                                    ? "Chưa có giao dịch nào"
                                    : "Không tìm thấy giao dịch phù hợp",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  color: _kMuted,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_hasActiveFilters) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _clearAllFilters,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _kPinkDark,
                                    side: BorderSide(
                                      color: _kPink.withValues(alpha: 0.35),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 17,
                                  ),
                                  label: Text(
                                    'Xem tất cả giao dịch',
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      for (final monthEntry in groupedMonths)
                        SliverStickyHeader(
                          header: _buildMonthHeader(
                            monthEntry.key,
                            monthEntry.value.length,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildTransactionTile(
                                monthEntry.value[index],
                                isLast: index == monthEntry.value.length - 1,
                              ),
                              childCount: monthEntry.value.length,
                              addAutomaticKeepAlives: false,
                            ),
                          ),
                        ),
                    if (_isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: _kPink),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.calendar_1, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Tổng quan tháng ${DateTime.now().month}",
                  style: GoogleFonts.roboto(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _summaryBox(
                    "Tổng thu",
                    '${FormatUtils.formatDisplayNumber(_totalIncome)}đ',
                    _kIncome,
                    Iconsax.arrow_down_2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryBox(
                    "Tổng chi",
                    '${FormatUtils.formatDisplayNumber(_totalExpense)}đ',
                    _kExpense,
                    Iconsax.arrow_up_3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(
    String label,
    String value,
    Color? textColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: textColor?.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: textColor, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.roboto(fontSize: 14, color: _kMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _typeFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _typeFilters[index];
          final isSelected =
              _selectedType == item.type &&
              _selectedDirection == item.direction;
          final bool styleIsOut = item.direction != null
              ? item.direction == 'OUT'
              : item.type != 'TOPUP';
          final Color accent = item.type == null
              ? _kPinkDark
              : _TransactionVisualStyle.fromType(
                  item.type!,
                  isOut: styleIsOut,
                ).accentColor;
          final Gradient? gradient = isSelected
              ? (item.type == null
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF06292), _kPinkDark],
                      )
                    : _TransactionVisualStyle.fromType(
                        item.type!,
                        isOut: styleIsOut,
                      ).gradient)
              : null;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectTypeFilter(item),
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFEEDDE5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? accent.withValues(alpha: 0.28)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 16,
                      color: isSelected ? Colors.white : accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : _kText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader(String label, int count) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFAF6F8),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kPink.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Iconsax.calendar_1,
                  size: 14,
                  color: _kPinkDark,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: _monthLabelStyle,
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$count giao dịch',
            style: _monthCountStyle,
          ),
        ],
      ),
    );
  }

  Widget _appBarCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required EdgeInsetsGeometry padding,
  }) {
    return Padding(
      padding: padding,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kPink.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 21, color: _kText),
        ),
      ),
    );
  }

  Future<void> _showDateFilterDialog() async {
    _unfocusSearch();
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

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
      _fetchMore(reset: true);
    }
  }

  // ===== Xuất Excel =====

  Future<void> _exportExcel() async {
    _unfocusSearch();
    if (_isExporting) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final range = await DateRangePickerSheet.show(
      context,
      title: 'Xuất lịch sử giao dịch',
      confirmText: 'Tiếp tục',
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: today,
      initialRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime(today.year, today.month, 1),
              end: today,
            ),
    );
    if (range == null || !mounted) return;

    final fmt = DateFormat('dd/MM/yyyy');
    await DialogUtils.showConfirmation(
      context,
      title: 'Xuất file Excel',
      message:
          'Bạn có muốn nhận file Excel lịch sử giao dịch từ ngày ${fmt.format(range.start)} đến ngày ${fmt.format(range.end)} qua email đã liên kết không?',
      confirmText: 'Gửi file',
      onConfirm: () => _sendExportEmail(range),
    );
  }

  void _sendExportEmail(DateTimeRange range) {
    if (!mounted || _isExporting) return;
    _isExporting = true;

    DialogUtils.showNotification(
      context,
      title: 'Đã tiếp nhận yêu cầu',
      message:
          'Hệ thống sẽ gửi file Excel lịch sử giao dịch qua email đã liên kết của bạn. Vui lòng kiểm tra hộp thư (bao gồm cả mục thư rác).',
    );

    unawaited(
      _transactionService
          .exportHistoryToEmail(startDate: range.start, endDate: range.end)
          .then((result) {
            if (!mounted) return;
            if (result['is_success'] != true) {
              SnackbarUtils.failure(
                context,
                result['message']?.toString() ??
                    'Không gửi được file, vui lòng thử lại',
              );
            }
          })
          .whenComplete(() {
            _isExporting = false;
          }),
    );
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchMore(reset: true);
  }

  Widget _buildTransactionIcon(_TransactionVisualStyle style) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: style.gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                style.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          if (style.badgeIcon != null)
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: style.badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.8),
                ),
                child: Center(
                  child: Icon(
                    style.badgeIcon,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(_PreparedTransaction item, {bool isLast = false}) {
    final t = item.raw;
    final style = item.style;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, isLast ? 14 : 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: Color(0xFFEDE2E8),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            _unfocusSearch();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(
                  transactionModel: t,
                  title: item.titleDetail,
                  amount: item.signedAmount,
                  status: 'Thành công',
                  time: item.formattedTime,
                  transactionCode: t.id.toString(),
                  walletName: item.walletName,
                  feeText: item.formattedFee,
                  bankName: t.bankName,
                  icon: style.icon,
                  iconColor: style.accentColor,
                  textBtn: item.textBtn,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTransactionIcon(style),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _tileTitleStyle,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: style.tintColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              style.shortLabel,
                              style: item.badgeTextStyle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.formattedTime,
                              style: _tileTimeStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.signedAmount,
                      style: item.isIncome
                          ? _tileIncomeAmountStyle
                          : _tileExpenseAmountStyle,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.formattedBalance,
                      style: _tileBalanceStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreparedTransaction {
  final TransactionModel raw;
  final _TransactionVisualStyle style;
  final bool isIncome;
  final String title;
  final String titleDetail;
  final String textBtn;
  final String walletName;
  final String formattedTime;
  final String signedAmount;
  final String formattedFee;
  final String formattedBalance;
  final TextStyle badgeTextStyle;

  _PreparedTransaction({
    required this.raw,
    required this.style,
    required this.isIncome,
    required this.title,
    required this.titleDetail,
    required this.textBtn,
    required this.walletName,
    required this.formattedTime,
    required this.signedAmount,
    required this.formattedFee,
    required this.formattedBalance,
    required this.badgeTextStyle,
  });

  factory _PreparedTransaction.fromModel(
    TransactionModel t,
    TextStyle badgeBaseStyle,
  ) {
    final isOut = t.direction == 'OUT';
    final isIncome = !isOut || t.type == "TOPUP";
    final isMerchantPayment = t.type == "PAYMENT";
    final isTransfer = t.type == "TRANSFER";
    final isPostpaid = t.fundingSource == 'POSTPAID';
    final postpaidAction = t.postpaidAction;
    final isPostpaidPurchase = isPostpaid && postpaidAction == 'PURCHASE';
    final isPostpaidRefund = isPostpaid && postpaidAction == 'REFUND';
    final isPostpaidRepay =
        isPostpaid &&
        (postpaidAction == 'REPAY_PRINCIPAL' ||
            postpaidAction == 'REPAY_LATE_FEE');
    final isPostpaidCreditEvent = isPostpaidPurchase || isPostpaidRefund;

    final style = _TransactionVisualStyle.fromType(
      t.type,
      isOut: isOut,
      isPostpaidPurchase: isPostpaidPurchase,
      isPostpaidRefund: isPostpaidRefund,
      isPostpaidRepay: isPostpaidRepay,
    );

    final amountPrefix = isIncome ? '+' : '-';
    final bankLabel = t.bankName.trim().isNotEmpty
        ? t.bankName.trim()
        : 'ngân hàng';
    final counterpartyLabel = t.counterpartyName.trim().isNotEmpty
        ? t.counterpartyName.trim()
        : (isMerchantPayment ? 'đối tác' : 'người dùng');

    final title = isPostpaidRepay
        ? "Thanh toán dư nợ Ví trả sau"
        : isPostpaidRefund
        ? "Hoàn tiền từ $counterpartyLabel"
        : t.type == "TOPUP"
        ? "Nạp tiền từ $bankLabel"
        : t.type == "WITHDRAW"
        ? "Rút về $bankLabel"
        : isTransfer
        ? isOut
              ? 'Chuyển đến $counterpartyLabel'
              : 'Nhận từ $counterpartyLabel'
        : isMerchantPayment
        ? 'Thanh toán $counterpartyLabel'
        : "Giao dịch không xác định";

    final titleDetail = isPostpaidRepay
        ? "Thanh toán dư nợ Ví trả sau"
        : isPostpaidRefund
        ? "Hoàn tiền Ví trả sau"
        : isPostpaidPurchase
        ? "Thanh toán qua Ví trả sau"
        : isMerchantPayment
        ? 'Thanh toán $counterpartyLabel'
        : t.type == "TOPUP"
        ? "Nạp tiền vào ví"
        : t.type == "WITHDRAW"
        ? "Rút tiền"
        : isTransfer
        ? isOut
              ? 'Chuyển tiền'
              : 'Nhận tiền'
        : "Giao dịch không xác định";

    final textBtn = (isPostpaidRepay || isPostpaidRefund)
        ? "Quản lý ví"
        : isMerchantPayment
        ? "Chia tiền"
        : t.type == "TOPUP"
        ? "Nạp thêm"
        : t.type == "WITHDRAW"
        ? "Rút thêm"
        : isTransfer
        ? (t.counterpartyPhone.trim().isEmpty
              ? ''
              : (isOut ? 'Chuyển thêm' : 'Chuyển lại'))
        : "Giao dịch không xác định";

    return _PreparedTransaction(
      raw: t,
      style: style,
      isIncome: isIncome,
      title: title,
      titleDetail: titleDetail,
      textBtn: textBtn,
      walletName: isPostpaidCreditEvent
          ? 'Ví trả sau'
          : (t.type != 'TRANSFER' && !isPostpaidRepay ? bankLabel : 'Ví Mio'),
      formattedTime: FormatUtils.formatDateTime(t.createdAt),
      signedAmount: '$amountPrefix${FormatUtils.formatDisplayNumber(t.amount)}đ',
      formattedFee: t.fee > 0
          ? '${FormatUtils.formatDisplayNumber(t.fee)}đ'
          : 'Miễn phí',
      formattedBalance: isPostpaidCreditEvent
          ? 'Hạn mức còn: ${FormatUtils.formatDisplayNumber(t.balanceAfter)}đ'
          : 'Số dư: ${FormatUtils.formatDisplayNumber(t.balanceAfter)}đ',
      badgeTextStyle: badgeBaseStyle.copyWith(color: style.accentColor),
    );
  }
}

class _TransactionTypeFilter {
  final String? type;
  final String? direction;
  final String label;
  final IconData icon;

  const _TransactionTypeFilter({
    required this.type,
    required this.direction,
    required this.label,
    required this.icon,
  });
}

class _TransactionVisualStyle {
  final IconData icon;
  final IconData? badgeIcon;
  final Color accentColor;
  final Color badgeColor;
  final Color tintColor;
  final LinearGradient gradient;
  final String shortLabel;

  const _TransactionVisualStyle({
    required this.icon,
    required this.badgeIcon,
    required this.accentColor,
    required this.badgeColor,
    required this.tintColor,
    required this.gradient,
    required this.shortLabel,
  });

  factory _TransactionVisualStyle.fromType(
    String type, {
    required bool isOut,
    bool isPostpaidPurchase = false,
    bool isPostpaidRefund = false,
    bool isPostpaidRepay = false,
  }) {
    if (isPostpaidPurchase) {
      return const _TransactionVisualStyle(
        icon: Icons.credit_score_rounded,
        badgeIcon: Icons.credit_score_rounded,
        accentColor: Color(0xFFEC407A),
        badgeColor: Color(0xFFD81B60),
        tintColor: Color(0xFFFCE7F3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
        ),
        shortLabel: 'Ví trả sau',
      );
    }
    if (isPostpaidRefund) {
      return const _TransactionVisualStyle(
        icon: Iconsax.money_recive5,
        badgeIcon: Icons.south_west_rounded,
        accentColor: Color(0xFF059669),
        badgeColor: Color(0xFF047857),
        tintColor: Color(0xFFD1FAE5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34D399), Color(0xFF059669)],
        ),
        shortLabel: 'Hoàn trả sau',
      );
    }
    if (isPostpaidRepay) {
      return const _TransactionVisualStyle(
        icon: Icons.account_balance_wallet_rounded,
        badgeIcon: Icons.north_east_rounded,
        accentColor: Color(0xFFDB2777),
        badgeColor: Color(0xFFBE185D),
        tintColor: Color(0xFFFCE7F3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEC407A), Color(0xFFD81B60)],
        ),
        shortLabel: 'Trả nợ VTS',
      );
    }
    switch (type) {
      case 'PAYMENT':
        return const _TransactionVisualStyle(
          icon: Icons.storefront_rounded,
          badgeIcon: Icons.shopping_bag_rounded,
          accentColor: Color(0xFF7C3AED),
          badgeColor: Color(0xFF5B21B6),
          tintColor: Color(0xFFF3EEFF),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          ),
          shortLabel: 'Thanh toán',
        );
      case 'TOPUP':
        return const _TransactionVisualStyle(
          icon: Iconsax.direct_inbox5,
          badgeIcon: Icons.south_west_rounded,
          accentColor: Color(0xFF0284C7),
          badgeColor: Color(0xFF10B981),
          tintColor: Color(0xFFE0F2FE),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
          ),
          shortLabel: 'Nạp tiền',
        );
      case 'WITHDRAW':
        return const _TransactionVisualStyle(
          icon: Iconsax.direct_send5,
          badgeIcon: Icons.north_east_rounded,
          accentColor: Color(0xFFEA580C),
          badgeColor: Color(0xFFC2410C),
          tintColor: Color(0xFFFFEDD5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
          ),
          shortLabel: 'Rút tiền',
        );
      case 'TRANSFER':
        if (isOut) {
          return const _TransactionVisualStyle(
            icon: Iconsax.money_send5,
            badgeIcon: Icons.north_east_rounded,
            accentColor: Color(0xFFE11D48),
            badgeColor: Color(0xFFBE123C),
            tintColor: Color(0xFFFFE4E6),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
            ),
            shortLabel: 'Chuyển tiền',
          );
        }
        return const _TransactionVisualStyle(
          icon: Iconsax.money_recive5,
          badgeIcon: Icons.south_west_rounded,
          accentColor: Color(0xFF059669),
          badgeColor: Color(0xFF047857),
          tintColor: Color(0xFFD1FAE5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF34D399), Color(0xFF059669)],
          ),
          shortLabel: 'Nhận tiền',
        );
      default:
        return const _TransactionVisualStyle(
          icon: Iconsax.info_circle,
          badgeIcon: null,
          accentColor: Color(0xFF64748B),
          badgeColor: Color(0xFF475569),
          tintColor: Color(0xFFF1F5F9),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
          ),
          shortLabel: 'Giao dịch',
        );
    }
  }
}