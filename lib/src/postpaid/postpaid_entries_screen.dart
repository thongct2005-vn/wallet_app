import 'dart:async';
import 'package:app/core/widgets/date_range_picker_sheet.dart';
import 'package:app/src/postpaid/postpaid_entry_widgets.dart';
import 'package:app/src/services/postpaid_service.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class PostpaidEntriesScreen extends StatefulWidget {
  const PostpaidEntriesScreen({super.key});

  @override
  State<PostpaidEntriesScreen> createState() => _PostpaidEntriesScreenState();
}

class _PostpaidEntriesScreenState extends State<PostpaidEntriesScreen> {
  final PostpaidService _postpaidService = PostpaidService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  final List<Map<String, dynamic>> _allEntries = [];
  List<Map<String, dynamic>> _filteredEntries = [];
  List<Map<String, dynamic>>? _preparedSource;
  List<MapEntry<String, List<Map<String, dynamic>>>> _groupedMonths = const [];

  String? _nextCursor;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMsg;
  String _searchKeyword = '';
  String? _selectedAction;
  DateTime? _startDate;
  DateTime? _endDate;
  int _fetchGeneration = 0;

  static const List<_EntryActionFilter> _actionFilters = [
    _EntryActionFilter(
      action: null,
      label: 'Tất cả',
      icon: Iconsax.receipt_item5,
    ),
    _EntryActionFilter(
      action: 'PURCHASE',
      label: 'Thanh toán',
      icon: Icons.credit_score_rounded,
    ),
    _EntryActionFilter(
      action: 'REPAY',
      label: 'Trả nợ',
      icon: Icons.account_balance_wallet_rounded,
    ),
    _EntryActionFilter(
      action: 'REFUND',
      label: 'Hoàn tiền',
      icon: Iconsax.money_recive5,
    ),
    _EntryActionFilter(
      action: 'SERVICE_FEE',
      label: 'Phí dịch vụ',
      icon: Icons.receipt_long_rounded,
    ),
    _EntryActionFilter(
      action: 'LATE_FEE',
      label: 'Phí trễ hạn',
      icon: Icons.event_busy_rounded,
    ),
    _EntryActionFilter(
      action: 'STATEMENT_CLOSE',
      label: 'Chốt sao kê',
      icon: Icons.event_note_rounded,
    ),
    _EntryActionFilter(
      action: 'LIMIT_ADJUST',
      label: 'Điều chỉnh HM',
      icon: Icons.tune_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMore();
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
      _selectedAction != null ||
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
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final result = await _postpaidService.getEntries(
      cursorId: _nextCursor,
      limit: 20,
      keyword: _searchKeyword.isEmpty ? null : _searchKeyword,
      action: _selectedAction,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (!mounted || generation != _fetchGeneration) return;

    if (result['is_success'] == true && result['data'] is Map) {
      final rawList = (result['data']['entries'] as List?) ?? const [];
      final newItems = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        if (reset) {
          _allEntries.clear();
        }
        _allEntries.addAll(newItems);
        _applyFilter();
        _nextCursor = result['data']['next_cursor']?.toString();
        _hasMore = result['data']['next_cursor'] != null;
        _isLoading = false;
      });
    } else {
      setState(() {
        if (reset) {
          _allEntries.clear();
          _applyFilter();
        }
        _isLoading = false;
        _errorMsg =
            result['message']?.toString() ?? 'Không thể tải lịch sử biến động';
      });
    }
  }

  void _selectActionFilter(_EntryActionFilter filter) {
    _unfocusSearch();
    if (_selectedAction == filter.action) return;
    setState(() {
      _selectedAction = filter.action;
      _applyFilter();
    });
    _fetchMore(reset: true);
  }

  void _clearAllFilters() {
    _unfocusSearch();
    _searchController.clear();
    setState(() {
      _searchKeyword = '';
      _selectedAction = null;
      _startDate = null;
      _endDate = null;
      _applyFilter();
    });
    _fetchMore(reset: true);
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

  static String _formatDateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static bool _isSameCalendarDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _matchesActionFilter(String entryAction) {
    if (_selectedAction == null || _selectedAction!.isEmpty) return true;
    if (_selectedAction == 'REPAY') {
      return entryAction == 'REPAY_PRINCIPAL' ||
          entryAction == 'REPAY_SERVICE_FEE' ||
          entryAction == 'REPAY_LATE_FEE';
    }
    return entryAction == _selectedAction;
  }

  void _applyFilter() {
    Iterable<Map<String, dynamic>> items = _allEntries;

    if (_selectedAction != null && _selectedAction!.isNotEmpty) {
      items = items.where(
        (e) => _matchesActionFilter((e['action'] ?? '').toString()),
      );
    }

    if (_searchKeyword.isNotEmpty) {
      final cleanKeyword = removePostpaidDiacritics(_searchKeyword);
      final isTimeOrCycleQuery =
          _searchKeyword.contains('/') ||
          _searchKeyword.contains(':') ||
          _searchKeyword.contains('-');
      items = items.where((e) {
        final action = (e['action'] ?? '').toString().toLowerCase();
        final actionLabel = (e['action_label'] ?? '').toString().toLowerCase();
        final note = (e['note'] ?? '').toString().toLowerCase();
        final counterparty =
            (e['counterparty_name'] ?? '').toString().toLowerCase();
        final txId = (e['tx_id'] ?? '').toString().toLowerCase();
        final refTxId = (e['ref_tx_id'] ?? '').toString().toLowerCase();
        final orderId = (e['order_id'] ?? '').toString().toLowerCase();
        final cycleMonth = (e['cycle_month'] ?? '').toString().toLowerCase();
        final cycleDisplay = formatPostpaidCycleMonth(cycleMonth);
        final cycleDash = cycleDisplay.replaceAll('/', '-');
        final amountStr = (e['amount'] ?? '').toString();
        final title = buildPostpaidEntryTitle(e).toLowerCase();
        final timeStr = isTimeOrCycleQuery
            ? formatPostpaidEntryTime(e['created_at']?.toString()).toLowerCase()
            : '';

        final combined =
            '$action $actionLabel $note $counterparty $txId $refTxId $orderId $cycleMonth $cycleDisplay $cycleDash $amountStr $title $timeStr';
        final combinedClean = removePostpaidDiacritics(combined);
        return combined.contains(_searchKeyword) ||
            combinedClean.contains(cleanKeyword);
      });
    }

    if (_startDate != null && _endDate != null) {
      // Compare in UTC wall-clock domain to match parsePostpaidVnDate (UTC+7).
      final start = DateTime.utc(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      final endExclusive = DateTime.utc(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day + 1,
      );
      items = items.where((e) {
        final vnDate = parsePostpaidVnDate(e['created_at']?.toString());
        if (vnDate == null) return false;
        return !vnDate.isBefore(start) && vnDate.isBefore(endExclusive);
      });
    }

    _filteredEntries = items.toList();
    _syncGroupedMonths();
  }

  void _syncGroupedMonths() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final entry in _filteredEntries) {
      final vnDate = parsePostpaidVnDate(entry['created_at']?.toString());
      final key = vnDate != null
          ? 'Tháng ${vnDate.month}/${vnDate.year}'
          : 'Khác';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    _groupedMonths = grouped.entries.toList(growable: false);
    _preparedSource = _filteredEntries;
  }

  Future<void> _showDateFilterDialog() async {
    _unfocusSearch();
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

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
        _applyFilter();
      });
      _fetchMore(reset: true);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _applyFilter();
    });
    _fetchMore(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!identical(_preparedSource, _filteredEntries)) {
      _syncGroupedMonths();
    }
    final groupedMonths = _groupedMonths;

    return FreezeKeyboardMediaQuery(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _unfocusSearch,
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF6F8),
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                _appBarCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.pop(context),
                  iconSize: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFieldTapRegion(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: kPostpaidPink.withValues(alpha: 0.12),
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
                            size: 19,
                            color: kPostpaidPink,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onTap: () =>
                                  requestKeyboardFocus(_searchFocusNode),
                              onChanged: _onSearchChanged,
                              onTapOutside: (_) => _unfocusSearch(),
                              onSubmitted: (_) => _unfocusSearch(),
                              textInputAction: TextInputAction.search,
                              textAlignVertical: TextAlignVertical.center,
                              cursorColor: kPostpaidPink,
                              style: GoogleFonts.roboto(fontSize: 14.5),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Tìm kiếm biến động hạn mức',
                                hintStyle: GoogleFonts.roboto(
                                  fontSize: 14.5,
                                  color: kPostpaidMuted,
                                ),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                setState(() {});
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
                const SizedBox(width: 10),
                _appBarCircleButton(
                  icon: Iconsax.filter,
                  tooltip: 'Lọc theo ngày',
                  onPressed: _showDateFilterDialog,
                  hasBadge: _startDate != null && _endDate != null,
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            RepaintBoundary(
              child: Container(
                height: 360,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kPostpaidPink.withValues(alpha: 0.20),
                      kPostpaidPinkLight.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                color: kPostpaidPink,
                onRefresh: () => _fetchMore(reset: true),
                child: CustomScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 12),
                        child: _buildActionFilterBar(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 2, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: kPostpaidPink,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Biến động hạn mức',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: kPostpaidText,
                                ),
                              ),
                            ),
                            if (_hasActiveFilters)
                              TextButton.icon(
                                onPressed: _clearAllFilters,
                                style: TextButton.styleFrom(
                                  foregroundColor: kPostpaidPinkDark,
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
                              Flexible(
                                child: Chip(
                                  avatar: const Icon(
                                    Iconsax.calendar_1,
                                    size: 16,
                                    color: kPostpaidPink,
                                  ),
                                  label: Text(
                                    _isSameCalendarDate(_startDate!, _endDate!)
                                        ? _formatDateLabel(_startDate!)
                                        : '${_formatDateLabel(_startDate!)} - ${_formatDateLabel(_endDate!)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      color: kPostpaidPinkDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor:
                                      kPostpaidPink.withValues(alpha: 0.1),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: kPostpaidPinkDark,
                                  ),
                                  onDeleted: _clearDateFilter,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_errorMsg != null && _filteredEntries.isEmpty && !_isLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 40,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 44,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _errorMsg!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  color: kPostpaidMuted,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () => _fetchMore(reset: true),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kPostpaidPinkDark,
                                  side: BorderSide(
                                    color: kPostpaidPink.withValues(alpha: 0.4),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 17),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_filteredEntries.isEmpty && !_isLoading)
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
                                      kPostpaidPink.withValues(alpha: 0.16),
                                      kPostpaidPinkLight.withValues(alpha: 0.10),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Iconsax.receipt_search,
                                  color: kPostpaidPink,
                                  size: 38,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                !_hasActiveFilters
                                    ? 'Chưa có biến động hạn mức nào'
                                    : 'Không tìm thấy biến động phù hợp',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  color: kPostpaidMuted,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_hasActiveFilters) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _clearAllFilters,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kPostpaidPinkDark,
                                    side: BorderSide(
                                      color: kPostpaidPink.withValues(alpha: 0.35),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 17),
                                  label: Text(
                                    'Xem tất cả biến động',
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
                              (context, index) => PostpaidEntryTile(
                                entry: monthEntry.value[index],
                                isLast: index == monthEntry.value.length - 1,
                                margin: EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  index == monthEntry.value.length - 1
                                      ? 14
                                      : 10,
                                ),
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
                            child: CircularProgressIndicator(
                              color: kPostpaidPink,
                            ),
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

  Widget _buildActionFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _actionFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _actionFilters[index];
          final isSelected = _selectedAction == item.action;
          final visual = item.action == null
              ? null
              : PostpaidEntryVisualStyle.fromAction(
                  item.action == 'REPAY' ? 'REPAY_PRINCIPAL' : item.action!,
                );
          final Color accent = visual?.accentColor ?? kPostpaidPinkDark;
          final Gradient? gradient = isSelected
              ? (visual?.gradient ??
                    const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF06292), kPostpaidPinkDark],
                    ))
              : null;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectActionFilter(item),
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
                        : const Color(0xFFEDE2E8),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
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
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : kPostpaidText,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: const Color(0xFFFAF6F8).withValues(alpha: 0.94),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: kPostpaidPink.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Iconsax.calendar_1,
                  size: 14,
                  color: kPostpaidPinkDark,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: kPostpaidPinkDark,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$count biến động',
            style: GoogleFonts.roboto(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: kPostpaidMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBarCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    double iconSize = 21,
    bool hasBadge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kPostpaidPink.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, size: iconSize, color: kPostpaidText),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: kPostpaidPinkDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _EntryActionFilter {
  final String? action;
  final String label;
  final IconData icon;

  const _EntryActionFilter({
    required this.action,
    required this.label,
    required this.icon,
  });
}

