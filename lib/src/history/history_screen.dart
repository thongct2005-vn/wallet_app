import 'dart:async';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/loading_util.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/date_range_picker_sheet.dart';
import 'package:app/src/history/transaction_detail_screen.dart';
import 'package:app/src/services/transaction_service.dart';
import 'package:flutter/material.dart';
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
  Timer? _debounce;

  final List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  String? _nextCursor;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchKeyword = '';
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isExporting = false;
  static const int _exportMaxDays = 31; // khớp EXPORT.MAX_DAYS ở backend

  @override
  void initState() {
    super.initState();
    _fetchMore();
    _fetchSummary();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore &&
          _searchKeyword.isEmpty) {
        _fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final result = await _transactionService.getTransferHistory(
      _nextCursor,
      20,
      keyword: _searchKeyword.isEmpty ? null : _searchKeyword,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (result['is_success'] == true) {
      final List<dynamic> rawList = result['data']['transaction_list'];
      final newItems = rawList
          .map((e) => TransactionModel.fromJson(e))
          .toList();

      setState(() {
        _allTransactions.addAll(newItems);
        _filteredTransactions = List.from(_allTransactions);
        _nextCursor = result['data']['next_cursor']?.toString();
        _hasMore = result['data']['next_cursor'] != null;
      });
    }

    if (mounted) setState(() => _isLoading = false);
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchKeyword = value.trim().toLowerCase();
        _applyFilter();
      });
    });
  }

  void _applyFilter() {
    Iterable<TransactionModel> items = _allTransactions;

    if (_searchKeyword.isNotEmpty) {
      items = items.where((t) {
        final desc = (t.description ?? '').toLowerCase();
        final name = t.counterpartyName.toLowerCase();
        return desc.contains(_searchKeyword) || name.contains(_searchKeyword);
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
  }

  Map<String, List<TransactionModel>> _groupByMonth(
    List<TransactionModel> items,
  ) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in items) {
      final key = 'Tháng ${t.createdAt.month}/${t.createdAt.year}';
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByMonth(_filteredTransactions);
    final monthKeys = grouped.keys.toList();

    return PopScope(
      canPop: false,
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
                          onChanged: _onSearchChanged,
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
            Container(
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
            SafeArea(
              child: RefreshIndicator(
                color: _kPink,
                onRefresh: () async {
                  setState(() {
                    _allTransactions.clear();
                    _nextCursor = null;
                    _hasMore = true;
                  });
                  await Future.wait([_fetchMore(), _fetchSummary()]);
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildSummaryCard()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
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
                            Text(
                              "Giao dịch gần đây",
                              style: GoogleFonts.roboto(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: _kText,
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
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kPink.withValues(alpha: 0.08),
                                ),
                                child: const Icon(
                                  Iconsax.receipt_search,
                                  color: _kPink,
                                  size: 38,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _searchKeyword.isEmpty
                                    ? "Chưa có giao dịch nào"
                                    : "Không tìm thấy giao dịch phù hợp",
                                style: GoogleFonts.roboto(
                                  color: _kMuted,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      for (final monthKey in monthKeys)
                        SliverStickyHeader(
                          header: _buildMonthHeader(monthKey),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildTransactionTile(
                                grouped[monthKey]![index],
                                isLast: index == grouped[monthKey]!.length - 1,
                              ),
                              childCount: grouped[monthKey]!.length,
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

  Widget _buildMonthHeader(String label) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFAF6F8),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _kPink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: _kPinkDark,
          ),
        ),
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
        _applyFilter();
      });
    }
  }

  // ===== Xuất Excel =====

  Future<void> _exportExcel() async {
    if (_isExporting) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final range = await DateRangePickerSheet.show(
      context,
      title: 'Xuất lịch sử giao dịch',
      confirmText: 'Tiếp tục',
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: today,
      maxDays: _exportMaxDays,
      initialRange: DateTimeRange(
        start: DateTime(today.year, today.month, today.day - 29),
        end: today,
      ),
    );
    if (range == null || !mounted) return;

    final fmt = DateFormat('dd/MM/yyyy');
    await DialogUtils.showConfirmation(
      context,
      title: 'Xuất file Excel',
      message:
          'Bạn có muốn gửi file Excel lịch sử giao dịch từ ngày ${fmt.format(range.start)} đến ngày ${fmt.format(range.end)} đến email đã đăng ký của bạn không?',
      confirmText: 'Gửi file',
      onConfirm: () => _sendExportEmail(range),
    );
  }

  Future<void> _sendExportEmail(DateTimeRange range) async {
    if (!mounted || _isExporting) return;
    _isExporting = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: FireworkStarSpinner()),
      ),
    );

    try {
      final result = await _transactionService.exportHistoryToEmail(
        startDate: range.start,
        endDate: range.end,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // đóng loading

      if (result['is_success'] == true) {
        final email = result['data']?['email']?.toString();
        await DialogUtils.showNotification(
          context,
          title: 'Đã gửi file Excel',
          message: email != null && email.isNotEmpty
              ? 'File lịch sử giao dịch đã được gửi đến email $email. Vui lòng kiểm tra hộp thư (kể cả mục thư rác).'
              : 'File lịch sử giao dịch đã được gửi đến email đã đăng ký của bạn.',
        );
      } else {
        SnackbarUtils.failure(
          context,
          result['message']?.toString() ??
              'Không gửi được file, vui lòng thử lại',
        );
      }
    } finally {
      _isExporting = false;
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _applyFilter();
    });
  }

  Widget _buildTransactionTile(TransactionModel t, {bool isLast = false}) {
    final isOut = t.direction == 'OUT';
    final isMerchantPayment = t.type == "PAYMENT";
    final isTransfer = t.type == "TRANSFER";

    final amountColor = !isOut || t.type == "TOPUP"
        ? Colors.green
        : Colors.black;

    final iconColor = isMerchantPayment
        ? Colors.purple
        : t.type == "TOPUP"
        ? Colors.blue
        : t.type == "WITHDRAW"
        ? Colors.yellow
        : isTransfer
        ? isOut
              ? Colors.red
              : Colors.green
        : Colors.grey;

    final amountPrefix = !isOut || t.type == "TOPUP" ? '+' : '-';

    final title = t.type == "TOPUP"
        ? "Nạp tiền vào ví từ ${t.bankName}"
        : t.type == "WITHDRAW"
        ? "Rút tiền từ ví về ${t.bankName}"
        : isTransfer
        ? isOut
              ? 'Chuyển đến ${t.counterpartyName}'
              : 'Nhận từ ${t.counterpartyName}'
        : isMerchantPayment
        ? 'Thanh toán ${t.counterpartyName}'
        : "Giao dịch không xác định";

    final titleDetail = isMerchantPayment
        ? 'Thanh toán ${t.counterpartyName}'
        : t.type == "TOPUP"
        ? "Nạp tiền vào ví"
        : t.type == "WITHDRAW"
        ? "Rút tiền"
        : isTransfer
        ? isOut
              ? 'Chuyển tiền'
              : 'Nhận tiền'
        : "Giao dịch không xác định";

    final IconData icon = isMerchantPayment
        ? Iconsax.shop
        : t.type == "TOPUP"
        ? Iconsax.wallet_add
        : t.type == "WITHDRAW"
        ? Iconsax.export_1
        : isTransfer
        ? isOut
              ? Iconsax.money_send
              : Iconsax.money_recive
        : Iconsax.info_circle;

    final textBtn = isMerchantPayment
        ? "Chia tiền"
        : t.type == "TOPUP"
        ? "Nạp thêm"
        : t.type == "WITHDRAW"
        ? "Rút thêm"
        : isTransfer
        ? isOut
              ? 'Chuyển thêm'
              : 'Chuyển lại'
        : "Giao dịch không xác định";

    final displayColor = iconColor == Colors.yellow
        ? Colors.amber.shade700
        : iconColor;

    return Material(
      color: Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(
                    transactionModel: t,
                    title: titleDetail,
                    amount:
                        '$amountPrefix${FormatUtils.formatDisplayNumber(t.amount)}đ',
                    status: 'Thành công',
                    time: FormatUtils.formatCustomDateTime(
                      t.createdAt.toString(),
                    ),
                    transactionCode: t.id.toString(),
                    walletName: t.type != 'TRANSFER' ? t.bankName : 'Ví Mio',
                    feeText: t.fee > 0
                        ? '${FormatUtils.formatDisplayNumber(t.fee)}đ'
                        : 'Miễn phí',
                    bankName: t.bankName,
                    icon: icon,
                    iconColor: iconColor,
                    textBtn: textBtn,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: displayColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: displayColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          FormatUtils.formatCustomDateTime(
                            t.createdAt.toString(),
                          ),
                          style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            color: _kMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        '$amountPrefix${FormatUtils.formatDisplayNumber(t.amount)}đ',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: amountColor == Colors.green
                              ? _kIncome
                              : _kText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Số dư: ${FormatUtils.formatDisplayNumber(isOut ? t.balanceBefore : t.balanceAfter)}đ',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: _kMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 0.6,
              indent: 74,
              endIndent: 16,
              color: Colors.grey.shade200,
            ),
        ],
      ),
    );
  }
}