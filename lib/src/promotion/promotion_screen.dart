import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/utils/snackbar_utils.dart';
import '../transfer/transfer_ui.dart';

class PromotionItemData {
  final String name;
  final String imagePath;
  final int discountPercent;
  final String originalPrice;
  final String discountedPrice;

  const PromotionItemData({
    required this.name,
    required this.imagePath,
    required this.discountPercent,
    required this.originalPrice,
    required this.discountedPrice,
  });
}

class TelecomPackageData {
  final String name;
  final String description;
  final int discountPercent;
  final String originalPrice;
  final String discountedPrice;

  const TelecomPackageData({
    required this.name,
    required this.description,
    required this.discountPercent,
    required this.originalPrice,
    required this.discountedPrice,
  });
}

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  static const Color _kPink = Color(0xFFEC407A);
  static const Color _kPinkDark = Color(0xFFD81B60);
  static const Color _kPinkLight = Color(0xFFF48FB1);
  static const Color _kPinkSoft = Color(0xFFFCE4EC);
  static const Color _kBg = Color(0xFFFAF6F8);
  static const Color _kText = Color(0xFF1F1B24);
  static const Color _kMuted = Color(0xFF8A8590);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static const List<PromotionItemData> _movieTickets = [
    PromotionItemData(
      name: 'Thám Tử Conan',
      imagePath: 'assets/conan-movie.jpg',
      discountPercent: 5,
      originalPrice: '100.000đ',
      discountedPrice: '95.000đ',
    ),
    PromotionItemData(
      name: 'Doraemon',
      imagePath: 'assets/doraemon-movie.jpg',
      discountPercent: 7,
      originalPrice: '100.000đ',
      discountedPrice: '93.000đ',
    ),
    PromotionItemData(
      name: 'Dragon Ball',
      imagePath: 'assets/dragon-ball-movie.jpg',
      discountPercent: 10,
      originalPrice: '100.000đ',
      discountedPrice: '90.000đ',
    ),
    PromotionItemData(
      name: 'One Piece',
      imagePath: 'assets/once-piece-movie.jpg',
      discountPercent: 15,
      originalPrice: '100.000đ',
      discountedPrice: '85.000đ',
    ),
  ];

  static const List<PromotionItemData> _drinkItems = [
    PromotionItemData(
      name: 'Matcha Latte',
      imagePath: 'assets/matcha-latte.jpg',
      discountPercent: 5,
      originalPrice: '60.000đ',
      discountedPrice: '57.000đ',
    ),
    PromotionItemData(
      name: 'Trà Đào',
      imagePath: 'assets/tra-dao.jpg',
      discountPercent: 7,
      originalPrice: '60.000đ',
      discountedPrice: '55.800đ',
    ),
    PromotionItemData(
      name: 'Trà Sữa Khoai Môn',
      imagePath: 'assets/tra-sua-khoai-mon.jpg',
      discountPercent: 10,
      originalPrice: '60.000đ',
      discountedPrice: '54.000đ',
    ),
    PromotionItemData(
      name: 'Trà Sữa Trân Châu',
      imagePath: 'assets/tra-sua-tran-chau.jpg',
      discountPercent: 15,
      originalPrice: '60.000đ',
      discountedPrice: '51.000đ',
    ),
  ];

  static const List<TelecomPackageData> _telecomPackages = [
    TelecomPackageData(
      name: 'DT70',
      description: '10GB • 30 ngày',
      discountPercent: 5,
      originalPrice: '70.000đ',
      discountedPrice: '66.500đ',
    ),
    TelecomPackageData(
      name: 'BIG90',
      description: '1GB/ngày • 30 ngày',
      discountPercent: 7,
      originalPrice: '90.000đ',
      discountedPrice: '83.700đ',
    ),
    TelecomPackageData(
      name: 'YOLO100M',
      description: '1GB/ngày + MXH • 30 ngày',
      discountPercent: 10,
      originalPrice: '100.000đ',
      discountedPrice: '90.000đ',
    ),
    TelecomPackageData(
      name: 'VD120M',
      description: '1GB/ngày + Thoại • 30 ngày',
      discountPercent: 15,
      originalPrice: '120.000đ',
      discountedPrice: '102.000đ',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _unfocusSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _showDevelopingNotification() {
    _unfocusSearch();
    SnackbarUtils.developing(
      context,
      message: 'Tính năng đang phát triển',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _unfocusSearch,
        child: Scaffold(
          backgroundColor: _kBg,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: _buildSearchBar(),
                ),
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
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Đặt vé'),
                      const SizedBox(height: 10),
                      _buildHorizontalPromoList(
                        items: _movieTickets,
                        buttonLabel: 'Đặt vé',
                      ),
                      const SizedBox(height: 22),
                      _buildSectionTitle('Ăn uống'),
                      const SizedBox(height: 10),
                      _buildHorizontalPromoList(
                        items: _drinkItems,
                        buttonLabel: 'Mua ngay',
                      ),
                      const SizedBox(height: 22),
                      _buildSectionTitle('Nạp gói cước'),
                      const SizedBox(height: 10),
                      _buildTelecomGrid(),
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

  Widget _buildSearchBar() {
    return TextFieldTapRegion(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => requestKeyboardFocus(_searchFocusNode),
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
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) {
              return Row(
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
                      onTap: () => requestKeyboardFocus(_searchFocusNode),
                      onTapOutside: (_) => _unfocusSearch(),
                      onSubmitted: (_) => _unfocusSearch(),
                      textInputAction: TextInputAction.search,
                      textAlignVertical: TextAlignVertical.center,
                      cursorColor: _kPink,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: _kText,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Tìm kiếm ưu đãi',
                        hintStyle: GoogleFonts.roboto(
                          fontSize: 15,
                          color: _kMuted,
                        ),
                      ),
                    ),
                  ),
                  if (value.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        requestKeyboardFocus(_searchFocusNode);
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
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
          title,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalPromoList({
    required List<PromotionItemData> items,
    required String buttonLabel,
  }) {
    const double spacing = 8.0;
    const double listHeight = 196.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Hiển thị tối đa đúng 3 thẻ trên khung nhìn, kéo ngang để xem thẻ thứ 4
        final double cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return SizedBox(
          height: listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: spacing),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: cardWidth,
                child: _buildPromoCard(
                  item: item,
                  buttonLabel: buttonLabel,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPromoCard({
    required PromotionItemData item,
    required String buttonLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _kPink.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
              child: Image.asset(
                item.imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: _kPinkSoft,
                    alignment: Alignment.center,
                    child: const Icon(
                      Iconsax.image,
                      color: _kPink,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.originalPrice,
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: _kMuted,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: _kMuted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kPinkSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-${item.discountPercent}%',
                                    style: GoogleFonts.roboto(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: _kPinkDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.discountedPrice,
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kPinkDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: _kPink,
                      borderRadius: BorderRadius.circular(7),
                      child: InkWell(
                        onTap: _showDevelopingNotification,
                        borderRadius: BorderRadius.circular(7),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: Text(
                            buttonLabel,
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelecomGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTelecomCard(_telecomPackages[0]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTelecomCard(_telecomPackages[1]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTelecomCard(_telecomPackages[2]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTelecomCard(_telecomPackages[3]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelecomCard(TelecomPackageData pkg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _kPink.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pkg.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _kPinkSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${pkg.discountPercent}%',
                  style: GoogleFonts.roboto(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _kPinkDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pkg.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: _kMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pkg.originalPrice,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: _kMuted,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: _kMuted,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      pkg.discountedPrice,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPinkDark,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: _kPink,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _showDevelopingNotification,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Text(
                      'Nạp',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
