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
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          actions: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Iconsax.search_normal_1,
                        size: 20,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          textAlignVertical: TextAlignVertical.center,
                          cursorColor: Colors.pink,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: "Tìm kiếm giao dịch",
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
              padding: const EdgeInsets.only(left: 8, right: 12),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              height: 500,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.pink.shade200.withValues(alpha: 0.75),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                color: Colors.pink,
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
                  slivers: [
                    SliverToBoxAdapter(child: _buildSummaryCard()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, bottom: 5),
                        child: Text(
                          "Giao dịch gần đây",
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    if (_startDate != null && _endDate != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: Row(
                            children: [
                              Chip(
                                label: Text(
                                  '${FormatUtils.formatCustomDateTime(_startDate.toString())} - ${FormatUtils.formatCustomDateTime(_endDate.toString())}',
                                  style: GoogleFonts.roboto(fontSize: 13),
                                ),
                                backgroundColor: Colors.pink.withValues(
                                  alpha: 0.1,
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: _clearDateFilter,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_filteredTransactions.isEmpty && !_isLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              _searchKeyword.isEmpty
                                  ? "Chưa có giao dịch nào"
                                  : "Không tìm thấy giao dịch phù hợp",
                              style: GoogleFonts.roboto(color: Colors.grey),
                            ),
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
                            child: CircularProgressIndicator(
                              color: Colors.pink,
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
      padding: const EdgeInsets.all(10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  "Tổng quan tháng ${DateTime.now().month}",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _summaryBox(
                      "Tổng thu",
                      '${FormatUtils.formatDisplayNumber(_totalIncome)}đ',
                      Colors.green,
                    ),
                  ),
                 
                  const SizedBox(width: 5),
                   Expanded(
                    child: _summaryBox(
                      "Tổng chi",
                      '${FormatUtils.formatDisplayNumber(_totalExpense)}đ',
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryBox(String label, String value, Color? textColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 0.5, color: Colors.grey),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String label) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(15, 8, 0, 8),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w500),
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
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          border: Border.all(
            width: 0.1,
            color: Colors.black.withValues(alpha: 0.5),
          ),
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
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

    return Material(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
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
            leading: CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.1),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
            subtitle: Text(
              FormatUtils.formatCustomDateTime(t.createdAt.toString()),
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${FormatUtils.formatDisplayNumber(t.amount)}đ',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Số dư ví: ${FormatUtils.formatDisplayNumber(isOut ? t.balanceBefore : t.balanceAfter)}đ',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(right: 25),
              child: Divider(
                height: 1,
                thickness: 0.5,
                indent: 72,
                color: Colors.grey.shade200,
              ),
            ),
        ],
      ),
    );
  }
}