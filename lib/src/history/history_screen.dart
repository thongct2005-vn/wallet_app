import 'dart:async';
import 'package:app/src/history/transaction_detail_screen.dart';
import 'package:app/src/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/history/transaction_model.dart';
import 'package:iconsax/iconsax.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchMore();
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
    );
    final List<dynamic> rawList = result['data']['transaction_list'];
    final newItems = rawList.map((e) => TransactionModel.fromJson(e)).toList();

    setState(() {
      _allTransactions.addAll(newItems);
      _nextCursor = result['data']['next_cursor']?.toString();
      _hasMore = result['data']['next_cursor'] != null;
      _applyFilter();
    });

    if (mounted) setState(() => _isLoading = false);
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
    if (_searchKeyword.isEmpty) {
      _filteredTransactions = List.from(_allTransactions);
      return;
    }
    _filteredTransactions = _allTransactions.where((t) {
      final desc = (t.description ?? '').toLowerCase();
      final name = t.counterpartyName.toLowerCase();
      return desc.contains(_searchKeyword) || name.contains(_searchKeyword);
    }).toList();
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
                        Icons.search,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
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
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list_outlined, size: 20),
                ),
              ),
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
                  await _fetchMore();
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
                  style: GoogleFonts.roboto(fontSize: 20),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _summaryBox("Tổng chi", "500.000đ")),
                  const SizedBox(width: 5),
                  Expanded(child: _summaryBox("Tổng thu", "500.000đ")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryBox(String label, String value) {
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
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 5),
            Text(value, style: GoogleFonts.roboto(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String label) {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50.withValues(alpha: 0.8),
      padding: const EdgeInsets.fromLTRB(15, 8, 0, 8),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel t, {bool isLast = false}) {
    final isOut = t.direction == 'OUT';
    final amountColor = isOut ? Colors.red : Colors.green;
    final amountPrefix = isOut ? '-' : '+';

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
                    title: isOut ? 'Chuyển tiền' : 'Nhận tiền',
                    amount:
                        '$amountPrefix${FormatUtils.formatDisplayNumber(t.amount)}đ',
                    status: 'Thành công',
                    time: FormatUtils.formatCustomDateTime(
                      t.createdAt.toString(),
                    ),
                    transactionCode: t.id.toString(),
                    walletName: 'Ví Mio',
                    feeText: t.fee > 0
                        ? '${FormatUtils.formatDisplayNumber(t.fee)}đ'
                        : 'Miễn phí',
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: (isOut ? Colors.red : Colors.green).withValues(
                alpha: 0.1,
              ),
              child: Icon(
                isOut ? Iconsax.money_send : Iconsax.money_recive,
                color: amountColor,
                size: 18,
              ),
            ),
            title: Text(
              isOut
                  ? 'Chuyển đến ${t.counterpartyName}'
                  : 'Nhận từ ${t.counterpartyName}',
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
                    color: isOut
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.green,
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
              padding: EdgeInsets.only(right: 25),
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
