import 'package:app/core/utils/currency_formatter.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Khung thẻ trắng chuẩn cho các màn hình Bộ lọc (Lịch sử giao dịch & Ví trả sau).
BoxDecoration buildHistoryFilterCardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0xFFEDE2E8)),
  boxShadow: [
    BoxShadow(
      color: kTfPink.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ],
);

class HistoryFilterSectionTitle extends StatelessWidget {
  final String text;

  const HistoryFilterSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: kTfText,
      ),
    );
  }
}

class HistoryFilterTimeCard extends StatelessWidget {
  final String fromDateText;
  final String toDateText;
  final bool hasCustomDate;
  final VoidCallback onPickDateRange;
  final String infoText;

  const HistoryFilterTimeCard({
    super.key,
    required this.fromDateText,
    required this.toDateText,
    required this.hasCustomDate,
    required this.onPickDateRange,
    required this.infoText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: buildHistoryFilterCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DateSelectorBox(
                  label: 'Từ ngày',
                  valueText: fromDateText,
                  isActive: hasCustomDate,
                  onTap: onPickDateRange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateSelectorBox(
                  label: 'Đến ngày',
                  valueText: toDateText,
                  isActive: hasCustomDate,
                  onTap: onPickDateRange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Iconsax.info_circle, size: 14, color: kTfMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  infoText,
                  style: GoogleFonts.roboto(fontSize: 12, color: kTfMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateSelectorBox extends StatelessWidget {
  final String label;
  final String valueText;
  final bool isActive;
  final VoidCallback onTap;

  const _DateSelectorBox({
    required this.label,
    required this.valueText,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? const Color(0xFFFFF1F6) : const Color(0xFFFAF8FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? kTfPink : const Color(0xFFEAE2E7),
              width: isActive ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: isActive ? kTfPinkDark : kTfMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      valueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isActive ? kTfText : kTfMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: isActive ? kTfPinkDark : kTfMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryFilterAmountCard extends StatelessWidget {
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final bool isMinActive;
  final bool isMaxActive;
  final String? amountError;
  final VoidCallback onAmountChanged;

  const HistoryFilterAmountCard({
    super.key,
    required this.minCtrl,
    required this.maxCtrl,
    required this.isMinActive,
    required this.isMaxActive,
    required this.amountError,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: buildHistoryFilterCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _AmountInputBox(
                  label: 'Từ',
                  hint: '0đ',
                  controller: minCtrl,
                  isActive: isMinActive,
                  hasError: amountError != null,
                  onAmountChanged: onAmountChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AmountInputBox(
                  label: 'Đến',
                  hint: 'Không giới hạn',
                  controller: maxCtrl,
                  isActive: isMaxActive,
                  hasError: amountError != null,
                  onAmountChanged: onAmountChanged,
                ),
              ),
            ],
          ),
          if (amountError != null) ...[
            const SizedBox(height: 8),
            Text(
              amountError!,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFE53935),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountInputBox extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isActive;
  final bool hasError;
  final VoidCallback onAmountChanged;

  const _AmountInputBox({
    required this.label,
    required this.hint,
    required this.controller,
    required this.isActive,
    required this.hasError,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFF1F6) : const Color(0xFFFAF8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? const Color(0xFFE53935)
              : (isActive ? kTfPink : const Color(0xFFEAE2E7)),
          width: isActive || hasError ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11.5,
              color: isActive ? kTfPinkDark : kTfMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                    CurrencyFormatter(),
                  ],
                  onChanged: (_) => onAmountChanged(),
                  cursorColor: kTfPink,
                  style: GoogleFonts.roboto(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: kTfText,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kTfMuted,
                    ),
                    suffixText: controller.text.isNotEmpty ? 'đ' : null,
                    suffixStyle: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTfText,
                    ),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onAmountChanged();
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: kTfMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryFilterSelectablePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const HistoryFilterSelectablePill({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF1F6) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kTfPink : const Color(0xFFEDE2E8),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? kTfPink.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.025),
                blurRadius: selected ? 8 : 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? kTfPinkDark : accent),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? kTfPinkDark : kTfText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryFilterGridTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const HistoryFilterGridTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF1F6) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? kTfPink : const Color(0xFFEDE2E8),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? kTfPink.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: selected ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 0.16 : 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? kTfPinkDark : kTfText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryFilterBottomBar extends StatelessWidget {
  final bool hasAnyFilter;
  final VoidCallback onClearAll;
  final VoidCallback onApply;

  const HistoryFilterBottomBar({
    super.key,
    required this.hasAnyFilter,
    required this.onClearAll,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEDE2E8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (hasAnyFilter) ...[
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: onClearAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTfText,
                    side: const BorderSide(color: Color(0xFFDDD2D8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Xóa bộ lọc',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kTfPink, kTfPinkDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kTfPink.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Áp dụng',
                    style: GoogleFonts.roboto(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryActiveFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onDeleted;

  const HistoryActiveFilterChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 15, color: kTfPink),
      label: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 12.5,
          color: kTfPinkDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: kTfPink.withValues(alpha: 0.1),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      deleteIcon: const Icon(Icons.close, size: 15, color: kTfPinkDark),
      onDeleted: onDeleted,
    );
  }
}

