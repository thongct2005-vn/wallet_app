import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

const Color _kPromoPink = Color(0xFFEC407A);
const Color _kPromoPinkDark = Color(0xFFD81B60);
const Color _kPromoPinkSoft = Color(0xFFFCE4EC);
const Color _kPromoText = Color(0xFF1F1B24);
const Color _kPromoMuted = Color(0xFF8A8590);
const Color _kAgeRatingOrange = Color(0xFFEA580C);

/// Dữ liệu thẻ ưu đãi hoặc vé phim hiển thị dạng danh sách cuộn ngang.
class PromotionItemData {
  final String name;
  final String imagePath;
  final int discountPercent;
  final String originalPrice;
  final String discountedPrice;
  final String? rating;
  final String? ageRating;

  const PromotionItemData({
    required this.name,
    required this.imagePath,
    required this.discountPercent,
    required this.originalPrice,
    required this.discountedPrice,
    this.rating,
    this.ageRating,
  });
}

/// Danh sách thẻ cuộn ngang 3 cột trên một màn hình, dùng chung cho Trang chủ và Ưu đãi.
class PromoHorizontalList extends StatelessWidget {
  final List<PromotionItemData> items;
  final String buttonLabel;
  final VoidCallback onActionTap;

  const PromoHorizontalList({
    super.key,
    required this.items,
    required this.buttonLabel,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 8.0;
    final bool hasMovieMeta = items.any(
      (item) => item.rating != null || item.ageRating != null,
    );
    final double listHeight = hasMovieMeta ? 224.0 : 196.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Hiển thị tối đa đúng 3 thẻ trên khung nhìn, kéo ngang để xem thẻ tiếp theo
        final double cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return SizedBox(
          height: listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: spacing),
            itemBuilder: (context, index) {
              return SizedBox(
                width: cardWidth,
                child: _PromoItemCard(
                  item: items[index],
                  buttonLabel: buttonLabel,
                  onActionTap: onActionTap,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PromoItemCard extends StatelessWidget {
  final PromotionItemData item;
  final String buttonLabel;
  final VoidCallback onActionTap;

  const _PromoItemCard({
    required this.item,
    required this.buttonLabel,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _kPromoPink.withValues(alpha: 0.12),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    item.imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _kPromoPinkSoft,
                        alignment: Alignment.center,
                        child: const Icon(
                          Iconsax.image,
                          color: _kPromoPink,
                          size: 28,
                        ),
                      );
                    },
                  ),
                  if (item.ageRating != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _AgeRatingBadge(label: item.ageRating!),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.rating != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.rating!,
                        style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _kPromoText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kPromoText,
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
                                    color: _kPromoMuted,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: _kPromoMuted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kPromoPinkSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-${item.discountPercent}%',
                                    style: GoogleFonts.roboto(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: _kPromoPinkDark,
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
                                color: _kPromoPinkDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: _kPromoPink,
                      borderRadius: BorderRadius.circular(7),
                      child: InkWell(
                        onTap: onActionTap,
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
}

class _AgeRatingBadge extends StatelessWidget {
  final String label;

  const _AgeRatingBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kAgeRatingOrange,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}

