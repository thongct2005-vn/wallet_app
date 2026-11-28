import 'dart:async';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/date_range_picker_sheet.dart';
import 'package:app/core/widgets/history_filter_widgets.dart';
import 'package:app/src/postpaid/postpaid_entry_widgets.dart';
import 'package:app/src/postpaid/postpaid_filter_screen.dart';
import 'package:app/src/services/postpaid_service.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>>? _preparedSource;
  List<MapEntry<String, List<Map<String, dynamic>>>> _groupedMonths = const [];

  String? _nextCursor;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isExporting = false;
  String? _errorMsg;
  String _searchKeyword = '';
  PostpaidFilterCriteria _filter = PostpaidFilterCriteria.empty;
  int _fetchGeneration = 0;

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
      _searchKeyword.isNotEmpty || !_filter.isEmpty;

  Future<void> _fetchMore({bool reset = false, bool clearCurrent = false}) async {
    if (!reset && _isLoading) return;
    if (reset) {
      _hasMore = true;
      _nextCursor = null;
    } else if (!_hasMore) {
      return;
    }

    final int generation = ++_fetchGeneration;
    setState(() {
      if (clearCurrent) {
        _allEntries.clear();
        _syncGroupedMonths();
      }
      _isLoading = true;
      _errorMsg = null;
    });

    final result = await _postpaidService.getEntries(
      cursorId: _nextCursor,
      limit: 20,
      keyword: _searchKeyword.isEmpty ? null : _searchKeyword,
      action: _filter.action,
      direction: _filter.deltaDirection,
      minAmount: _filter.minAmount,
      maxAmount: _filter.maxAmount,
      startDate: _filter.startDate,
      endDate: _filter.endDate,
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
        _syncGroupedMonths();
        _nextCursor = result['data']['next_cursor']?.toString();
        _hasMore = result['data']['next_cursor'] != null;
        _isLoading = false;
      });
    } else {
      setState(() {
        if (reset) {
          _allEntries.clear();
          _syncGroupedMonths();
        }
        _isLoading = false;
        _errorMsg =
            result['message']?.toString() ?? 'Không thể tải lịch sử biến động';
      });
    }
  }

  void _clearAllFilters() {
    _unfocusSearch();
    _searchController.clear();
    setState(() {
      _searchKeyword = '';
      _filter = PostpaidFilterCriteria.empty;
    });
    _fetchMore(reset: true, clearCurrent: true);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = value.trim().toLowerCase();
      if (_searchKeyword == trimmed) return;
      _searchKeyword = trimmed;
      _fetchMore(reset: true, clearCurrent: true);
    });
  }

  void _syncGroupedMonths() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final entry in _allEntries) {
      final vnDate = parsePostpaidVnDate(entry['created_at']?.toString());
      final key = vnDate != null
          ? 'Tháng ${vnDate.month}/${vnDate.year}'
          : 'Khác';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    _groupedMonths = grouped.entries.toList(growable: false);
    _preparedSource = _allEntries;
  }

  void _updateFilter(PostpaidFilterCriteria next) {
    _unfocusSearch();
    setState(() {
      _filter = next;
    });
    _fetchMore(reset: true, clearCurrent: true);
  }

  Future<void> _openFilterScreen() async {
    _unfocusSearch();
    final result = await Navigator.push<PostpaidFilterCriteria>(
      context,
      MaterialPageRoute(
        builder: (_) => PostpaidFilterScreen(initialCriteria: _filter),
      ),
    );

    if (result != null && mounted) {
      _updateFilter(result);
    }
  }

  // ===== Xuất Excel =====

  Future<void> _exportExcel() async {
    _unfocusSearch();
    if (_isExporting) return;

    final vnNow = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(vnNow.year, vnNow.month, vnNow.day);

    final range = await DateRangePickerSheet.show(
      context,
      title: 'Xuất lịch sử biến động',
      confirmText: 'Tiếp tục',
      firstDate: DateTime(vnNow.year - 1, vnNow.month, vnNow.day),
      lastDate: today,
      initialRange: _filter.hasDateRange
          ? DateTimeRange(start: _filter.startDate!, end: _filter.endDate!)
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
          'Bạn có muốn nhận file Excel lịch sử biến động Ví trả sau từ ngày ${fmt.format(range.start)} đến ngày ${fmt.format(range.end)} qua email đã liên kết không?',
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
          'Hệ thống sẽ gửi file Excel lịch sử biến động Ví trả sau qua email đã liên kết của bạn. Vui lòng kiểm tra hộp thư (bao gồm cả mục thư rác).',
    );

    unawaited(
      _postpaidService
          .exportEntriesToEmail(startDate: range.start, endDate: range.end)
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

  @override
  Widget build(BuildContext context) {
    if (!identical(_preparedSource, _allEntries)) {
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
                  tooltip: 'Bộ lọc biến động',
                  onPressed: _openFilterScreen,
                  badgeCount: _filter.activeCount,
                ),
                const SizedBox(width: 8),
                _appBarCircleButton(
                  icon: Icons.file_download_outlined,
                  tooltip: 'Xuất Excel',
                  onPressed: _exportExcel,
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
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
                    if (!_filter.isEmpty)
                      SliverToBoxAdapter(child: _buildActiveFilterChips()),
                    if (_errorMsg != null && _allEntries.isEmpty && !_isLoading)
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
                    else if (_allEntries.isEmpty && !_isLoading)
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

  Widget _buildActiveFilterChips() {
    final fmt = DateFormat('dd/MM/yyyy');
    final chips = <Widget>[];

    if (_filter.hasDateRange) {
      chips.add(
        HistoryActiveFilterChip(
          icon: Iconsax.calendar_1,
          label:
              '${fmt.format(_filter.startDate!)} - ${fmt.format(_filter.endDate!)}',
          onDeleted: () => _updateFilter(_filter.copyWith(clearDate: true)),
        ),
      );
    }

    if (_filter.hasAmountRange) {
      final fromText = _filter.minAmount != null
          ? '${FormatUtils.formatDisplayNumber(_filter.minAmount!)}đ'
          : '0đ';
      final toText = _filter.maxAmount != null
          ? '${FormatUtils.formatDisplayNumber(_filter.maxAmount!)}đ'
          : 'Không giới hạn';
      chips.add(
        HistoryActiveFilterChip(
          icon: Iconsax.money_2,
          label: '$fromText - $toText',
          onDeleted: () => _updateFilter(_filter.copyWith(clearAmount: true)),
        ),
      );
    }

    final dirLabel =
        PostpaidFilterScreen.labelForDirection(_filter.deltaDirection);
    if (dirLabel != null) {
      chips.add(
        HistoryActiveFilterChip(
          icon: Icons.swap_vert_rounded,
          label: dirLabel,
          onDeleted: () =>
              _updateFilter(_filter.copyWith(clearDeltaDirection: true)),
        ),
      );
    }

    final actionLabel = PostpaidFilterScreen.labelForAction(_filter.action);
    if (actionLabel != null) {
      chips.add(
        HistoryActiveFilterChip(
          icon: Iconsax.category_2,
          label: actionLabel,
          onDeleted: () => _updateFilter(_filter.copyWith(clearAction: true)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 6, children: chips),
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
    int badgeCount = 0,
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
            icon: Icon(
              icon,
              size: iconSize,
              color: badgeCount > 0 ? kPostpaidPinkDark : kPostpaidText,
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: kPostpaidPinkDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

