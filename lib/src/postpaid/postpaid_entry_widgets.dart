import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

const Color kPostpaidPink = Color(0xFFEC407A);
const Color kPostpaidPinkDark = Color(0xFFD81B60);
const Color kPostpaidPinkLight = Color(0xFFF48FB1);
const Color kPostpaidText = Color(0xFF1F1B24);
const Color kPostpaidMuted = Color(0xFF8A8590);
const Color kPostpaidIncome = Color(0xFF2E9E5B);
const Color kPostpaidExpense = Color(0xFFE53935);

int parsePostpaidInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  return num.tryParse(v?.toString() ?? '0')?.round() ?? 0;
}

DateTime? parsePostpaidVnDate(String? rawDate) {
  if (rawDate == null || rawDate.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(rawDate.trim());
  if (parsed == null) return null;
  return parsed.toUtc().add(const Duration(hours: 7));
}

String formatPostpaidEntryTime(String? rawDate) {
  if (rawDate == null || rawDate.trim().isEmpty) return '';
  final parsed = DateTime.tryParse(rawDate.trim());
  if (parsed == null) return rawDate;
  return FormatUtils.formatDateTime(parsed);
}

String formatPostpaidCycleMonth(String? rawCycle) {
  final raw = rawCycle?.trim() ?? '';
  if (raw.isEmpty) return '';
  final yyyyMm = RegExp(r'^(\d{4})[-/](\d{2})$').firstMatch(raw);
  if (yyyyMm != null) {
    return '${yyyyMm.group(2)}/${yyyyMm.group(1)}';
  }
  final mmYyyy = RegExp(r'^(\d{2})[-/](\d{4})$').firstMatch(raw);
  if (mmYyyy != null) {
    return '${mmYyyy.group(1)}/${mmYyyy.group(2)}';
  }
  return raw;
}

String formatPostpaidCycleNote(String? rawNote) {
  final raw = rawNote?.trim() ?? '';
  if (raw.isEmpty) return '';
  return raw
      .replaceAllMapped(
        RegExp(r'(kỳ\s+)(\d{4})-(\d{2})(?!-\d)\b', caseSensitive: false),
        (m) => '${m.group(1)}${m.group(3)}/${m.group(2)}',
      )
      .replaceAllMapped(
        RegExp(r'(kỳ\s+)(\d{2})-(\d{4})\b', caseSensitive: false),
        (m) => '${m.group(1)}${m.group(2)}/${m.group(3)}',
      );
}

String removePostpaidDiacritics(String str) {
  const withDia =
      'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ';
  const noDia =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
  var result = str;
  for (int i = 0; i < withDia.length; i++) {
    result = result.replaceAll(withDia[i], noDia[i]);
  }
  return result;
}

class PostpaidEntryVisualStyle {
  final IconData icon;
  final IconData? badgeIcon;
  final Color accentColor;
  final Color badgeColor;
  final Color tintColor;
  final LinearGradient gradient;
  final String shortLabel;

  const PostpaidEntryVisualStyle({
    required this.icon,
    required this.badgeIcon,
    required this.accentColor,
    required this.badgeColor,
    required this.tintColor,
    required this.gradient,
    required this.shortLabel,
  });

  factory PostpaidEntryVisualStyle.fromAction(String action) {
    switch (action) {
      case 'PURCHASE':
        return const PostpaidEntryVisualStyle(
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
      case 'REPAY_PRINCIPAL':
        return const PostpaidEntryVisualStyle(
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
      case 'REPAY_LATE_FEE':
        return const PostpaidEntryVisualStyle(
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
          shortLabel: 'Trả phí VTS',
        );
      case 'REFUND':
        return const PostpaidEntryVisualStyle(
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
      case 'LATE_FEE':
        return const PostpaidEntryVisualStyle(
          icon: Icons.event_busy_rounded,
          badgeIcon: Icons.percent_rounded,
          accentColor: Color(0xFFDC2626),
          badgeColor: Color(0xFFB91C1C),
          tintColor: Color(0xFFFEE2E2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFB7185), Color(0xFFDC2626)],
          ),
          shortLabel: 'Phí trễ hạn',
        );
      case 'STATEMENT_CLOSE':
        return const PostpaidEntryVisualStyle(
          icon: Icons.event_note_rounded,
          badgeIcon: Icons.receipt_long_rounded,
          accentColor: Color(0xFF2563EB),
          badgeColor: Color(0xFF1D4ED8),
          tintColor: Color(0xFFDBEAFE),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
          ),
          shortLabel: 'Chốt sao kê',
        );
      case 'LIMIT_ADJUST':
        return const PostpaidEntryVisualStyle(
          icon: Icons.tune_rounded,
          badgeIcon: Icons.swap_vert_rounded,
          accentColor: Color(0xFF7C3AED),
          badgeColor: Color(0xFF5B21B6),
          tintColor: Color(0xFFF3EEFF),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          ),
          shortLabel: 'Điều chỉnh HM',
        );
      default:
        return const PostpaidEntryVisualStyle(
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
          shortLabel: 'Biến động',
        );
    }
  }
}

String buildPostpaidEntryTitle(Map<String, dynamic> entry) {
  final action = (entry['action'] ?? '').toString();
  final counterparty = entry['counterparty_name']?.toString().trim();
  final note = entry['note']?.toString().trim();
  final cycleMonth = entry['cycle_month']?.toString().trim();

  switch (action) {
    case 'PURCHASE':
      if (counterparty != null && counterparty.isNotEmpty) {
        return 'Thanh toán $counterparty';
      }
      return (note != null && note.isNotEmpty)
          ? note
          : 'Thanh toán QR bằng Ví trả sau';
    case 'REPAY_PRINCIPAL':
      return 'Trả nợ gốc Ví trả sau';
    case 'REPAY_LATE_FEE':
      return 'Thanh toán phí trễ hạn';
    case 'LATE_FEE':
      if (note != null && note.isNotEmpty) {
        return formatPostpaidCycleNote(note);
      }
      if (cycleMonth != null && cycleMonth.isNotEmpty) {
        return 'Phí trễ hạn kỳ ${formatPostpaidCycleMonth(cycleMonth)}';
      }
      return 'Phí trễ hạn kỳ sao kê';
    case 'REFUND':
      if (counterparty != null && counterparty.isNotEmpty) {
        return 'Hoàn tiền từ $counterparty';
      }
      return 'Hoàn tiền Ví trả sau';
    case 'STATEMENT_CLOSE':
      if (note != null && note.isNotEmpty) {
        return formatPostpaidCycleNote(note);
      }
      if (cycleMonth != null && cycleMonth.isNotEmpty) {
        return 'Chốt sao kê kỳ ${formatPostpaidCycleMonth(cycleMonth)}';
      }
      return 'Chốt sao kê kỳ';
    default:
      return (note != null && note.isNotEmpty) ? note : 'Điều chỉnh hạn mức';
  }
}

Widget buildPostpaidEntryIcon(PostpaidEntryVisualStyle style) {
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
            child: Icon(style.icon, color: Colors.white, size: 22),
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
                child: Icon(style.badgeIcon, color: Colors.white, size: 10),
              ),
            ),
          ),
      ],
    ),
  );
}

class PostpaidEntryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isLast;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const PostpaidEntryTile({
    super.key,
    required this.entry,
    this.isLast = false,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final action = (entry['action'] ?? '').toString();
    final style = PostpaidEntryVisualStyle.fromAction(action);
    final title = buildPostpaidEntryTitle(entry);
    final formattedTime = formatPostpaidEntryTime(
      entry['created_at']?.toString(),
    );

    final amount = parsePostpaidInt(entry['amount']);
    final deltaUsed = parsePostpaidInt(entry['delta_used']);
    final usedAfter = parsePostpaidInt(entry['used_after']);

    final signedText = deltaUsed == 0
        ? '${FormatUtils.formatDisplayNumber(amount.abs())}đ'
        : deltaUsed > 0
            ? '+${FormatUtils.formatDisplayNumber(deltaUsed)}đ'
            : '-${FormatUtils.formatDisplayNumber(deltaUsed.abs())}đ';

    final amountColor = deltaUsed > 0
        ? kPostpaidExpense
        : deltaUsed < 0
            ? kPostpaidIncome
            : const Color(0xFF2563EB);

    return Padding(
      padding: margin ?? EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFEDE2E8), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap ?? () => showPostpaidEntryDetailSheet(context, entry),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                buildPostpaidEntryIcon(style),
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: kPostpaidText,
                        ),
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
                              style: GoogleFonts.roboto(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: style.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              formattedTime,
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: kPostpaidMuted,
                              ),
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
                      signedText,
                      style: GoogleFonts.roboto(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Nợ sau: ${FormatUtils.formatDisplayNumber(usedAfter)}đ',
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: kPostpaidMuted,
                        fontWeight: FontWeight.w400,
                      ),
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

Future<void> showPostpaidEntryDetailSheet(
  BuildContext context,
  Map<String, dynamic> entry,
) {
  final action = (entry['action'] ?? '').toString();
  final style = PostpaidEntryVisualStyle.fromAction(action);
  final title = buildPostpaidEntryTitle(entry);
  final actionLabel = (entry['action_label'] ?? style.shortLabel).toString();
  final formattedTime = formatPostpaidEntryTime(entry['created_at']?.toString());

  final amount = parsePostpaidInt(entry['amount']);
  final deltaUsed = parsePostpaidInt(entry['delta_used']);
  final usedBefore = parsePostpaidInt(entry['used_before']);
  final usedAfter = parsePostpaidInt(entry['used_after']);

  final txId = entry['tx_id']?.toString().trim();
  final refTxId = entry['ref_tx_id']?.toString().trim();
  final orderId = entry['order_id']?.toString().trim();
  final cycleMonth = entry['cycle_month']?.toString().trim();
  final counterparty = entry['counterparty_name']?.toString().trim();
  final note = entry['note']?.toString().trim();

  final signedDelta = deltaUsed == 0
      ? '${FormatUtils.formatDisplayNumber(amount.abs())}đ'
      : deltaUsed > 0
          ? '+${FormatUtils.formatDisplayNumber(deltaUsed)}đ dư nợ'
          : '-${FormatUtils.formatDisplayNumber(deltaUsed.abs())}đ dư nợ';

  final deltaColor = deltaUsed > 0
      ? kPostpaidExpense
      : deltaUsed < 0
          ? kPostpaidIncome
          : const Color(0xFF2563EB);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      Widget detailRow(
        String label,
        String value, {
        bool copyable = false,
        Color? valueColor,
      }) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 128,
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: kPostpaidMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.roboto(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: valueColor ?? kPostpaidText,
                        ),
                      ),
                    ),
                    if (copyable) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: value));
                          SnackbarUtils.success(sheetCtx, 'Đã sao chép');
                        },
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: kPostpaidPinkDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              buildPostpaidEntryIcon(style),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: kPostpaidText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                signedDelta,
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: deltaColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF6F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE2E8)),
                ),
                child: Column(
                  children: [
                    detailRow('Loại biến động', actionLabel),
                    if (formattedTime.isNotEmpty)
                      detailRow('Thời gian', formattedTime),
                    if (counterparty != null && counterparty.isNotEmpty)
                      detailRow('Đối tác', counterparty),
                    if (cycleMonth != null && cycleMonth.isNotEmpty)
                      detailRow(
                        'Kỳ sao kê',
                        formatPostpaidCycleMonth(cycleMonth),
                      ),
                    detailRow(
                      'Dư nợ trước',
                      '${FormatUtils.formatDisplayNumber(usedBefore)}đ',
                    ),
                    detailRow(
                      'Dư nợ sau',
                      '${FormatUtils.formatDisplayNumber(usedAfter)}đ',
                      valueColor: kPostpaidPinkDark,
                    ),
                    if (txId != null && txId.isNotEmpty)
                      detailRow('Mã giao dịch', txId, copyable: true),
                    if (refTxId != null && refTxId.isNotEmpty)
                      detailRow('Giao dịch gốc', refTxId, copyable: true),
                    if (orderId != null && orderId.isNotEmpty)
                      detailRow('Mã đơn hàng', orderId, copyable: true),
                    if (note != null && note.isNotEmpty)
                      detailRow('Ghi chú', formatPostpaidCycleNote(note)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

