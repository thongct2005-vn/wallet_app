import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet chọn khoảng ngày (thay cho showDateRangePicker mặc định).
///
/// - Chọn nhanh: 7 ngày qua, 30 ngày qua, Tháng này, Tháng trước.
/// - [maxDays]: giới hạn số ngày tối đa của khoảng chọn (null = không giới hạn).
/// - Trả về [DateTimeRange] (chỉ có ngày, giờ = 00:00) hoặc null nếu người dùng đóng sheet.
class DateRangePickerSheet extends StatefulWidget {
  final String title;
  final String confirmText;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialRange;
  final int? maxDays;

  const DateRangePickerSheet({
    super.key,
    required this.title,
    required this.firstDate,
    required this.lastDate,
    this.initialRange,
    this.maxDays,
    this.confirmText = 'Áp dụng',
  });

  static Future<DateTimeRange?> show(
    BuildContext context, {
    required String title,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTimeRange? initialRange,
    int? maxDays,
    String confirmText = 'Áp dụng',
  }) {
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DateRangePickerSheet(
        title: title,
        firstDate: firstDate,
        lastDate: lastDate,
        initialRange: initialRange,
        maxDays: maxDays,
        confirmText: confirmText,
      ),
    );
  }

  @override
  State<DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _Preset {
  final String label;
  final DateTime start;
  final DateTime end;
  const _Preset(this.label, this.start, this.end);
}

class _DateRangePickerSheetState extends State<DateRangePickerSheet> {
  static const List<String> _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  late final DateTime _first;
  late final DateTime _last;
  late DateTime _month; // ngày 1 của tháng đang hiển thị
  DateTime? _start;
  DateTime? _end;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _same(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays +
      1;

  @override
  void initState() {
    super.initState();
    _first = _dateOnly(widget.firstDate);
    _last = _dateOnly(widget.lastDate);

    final init = widget.initialRange;
    if (init != null) {
      final s = _dateOnly(init.start);
      final e = _dateOnly(init.end);
      if (!s.isBefore(_first) && !e.isAfter(_last) && !e.isBefore(s)) {
        _start = s;
        _end = e;
      }
    }
    final anchor = _end ?? _last;
    _month = DateTime(anchor.year, anchor.month);
  }

  bool get _canPrev =>
      _month.isAfter(DateTime(_first.year, _first.month));

  bool get _canNext => _month.isBefore(DateTime(_last.year, _last.month));

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  bool _isSelectable(DateTime day) {
    if (day.isBefore(_first) || day.isAfter(_last)) return false;

    final max = widget.maxDays;
    // Đang chọn ngày kết thúc: chặn các ngày vượt quá số ngày tối đa
    if (max != null && _start != null && _end == null) {
      final limit = DateTime(_start!.year, _start!.month, _start!.day + max - 1);
      if (day.isAfter(limit)) return false;
    }
    return true;
  }

  void _onTapDay(DateTime day) {
    if (!_isSelectable(day)) return;
    setState(() {
      if (_start == null || _end != null) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  void _applyPreset(_Preset p) {
    setState(() {
      _start = p.start;
      _end = p.end;
      _month = DateTime(p.end.year, p.end.month);
    });
  }

  List<_Preset> _buildPresets() {
    var today = _dateOnly(DateTime.now());
    if (today.isAfter(_last)) today = _last;

    final raw = <_Preset>[
      _Preset('7 ngày qua', DateTime(today.year, today.month, today.day - 6), today),
      _Preset('30 ngày qua', DateTime(today.year, today.month, today.day - 29), today),
      _Preset('Tháng này', DateTime(today.year, today.month, 1), today),
      _Preset(
        'Tháng trước',
        DateTime(today.year, today.month - 1, 1),
        DateTime(today.year, today.month, 0),
      ),
    ];

    final result = <_Preset>[];
    for (final p in raw) {
      final start = p.start.isBefore(_first) ? _first : p.start;
      final end = p.end.isAfter(_last) ? _last : p.end;
      if (end.isBefore(start)) continue;
      if (widget.maxDays != null && _daysBetween(start, end) > widget.maxDays!) {
        continue;
      }
      result.add(_Preset(p.label, start, end));
    }
    return result;
  }

  void _apply() {
    if (_start == null) return;
    Navigator.of(context).pop(
      DateTimeRange(start: _start!, end: _end ?? _start!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final end = _end ?? _start;
    final selectedDays =
        (_start != null && end != null) ? _daysBetween(_start!, end) : 0;
    // Hộp "Từ ngày" sáng khi bước tiếp theo là chọn ngày bắt đầu, ngược lại sáng hộp "Đến ngày"
    final pickingStart = _start == null || _end != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _dateBox('Từ ngày', _start, pickingStart),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  _dateBox('Đến ngày', end, !pickingStart),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final p in _buildPresets()) _presetChip(p),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: _canPrev ? () => _shiftMonth(-1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    splashRadius: 20,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Tháng ${_month.month}, ${_month.year}',
                        style: GoogleFonts.roboto(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _canNext ? () => _shiftMonth(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    splashRadius: 20,
                  ),
                ],
              ),
              Row(
                children: [
                  for (final w in _weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              ..._buildWeeks(),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  selectedDays > 0
                      ? 'Đã chọn $selectedDays ngày'
                      : (widget.maxDays != null
                            ? 'Chọn tối đa ${widget.maxDays} ngày'
                            : 'Chạm vào ngày để chọn khoảng thời gian'),
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _start == null ? null : _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.pink,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    widget.confirmText,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateBox(String label, DateTime? value, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.pink.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? Colors.pink : Colors.grey.shade300,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value == null ? '--/--/----' : _fmt(value),
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: value == null ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(_Preset p) {
    final selected = _same(_start, p.start) && _same(_end ?? _start, p.end);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _applyPreset(p),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.pink : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.pink : Colors.grey.shade300,
            ),
          ),
          child: Text(
            p.label,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWeeks() {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = DateTime(_month.year, _month.month, 1).weekday - 1; // T2 = 0
    final cells = <Widget>[];

    for (var i = 0; i < lead; i++) {
      cells.add(const SizedBox(height: 44));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_buildDay(DateTime(_month.year, _month.month, d)));
    }
    // Luôn đủ 6 hàng để chiều cao sheet không nhảy khi đổi tháng
    while (cells.length < 42) {
      cells.add(const SizedBox(height: 44));
    }

    return [
      for (var i = 0; i < 42; i += 7)
        Row(
          children: [
            for (final c in cells.sublist(i, i + 7)) Expanded(child: c),
          ],
        ),
    ];
  }

  Widget _buildDay(DateTime day) {
    final selectable = _isSelectable(day);
    final end = _end ?? _start;
    final isStart = _same(day, _start);
    final isEnd = _same(day, end);
    final isEdge = isStart || isEnd;
    final hasRange = _start != null && end != null && end.isAfter(_start!);
    final inBand =
        hasRange && !day.isBefore(_start!) && !day.isAfter(end!);
    final leftBand = inBand && !isStart;
    final rightBand = inBand && !isEnd;
    final isToday = _same(day, DateTime.now());

    final Color textColor = isEdge
        ? Colors.white
        : (selectable ? Colors.black87 : Colors.grey.shade400);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selectable ? () => _onTapDay(day) : null,
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    color: leftBand ? Colors.pink.shade50 : Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 36,
                    color: rightBand ? Colors.pink.shade50 : Colors.transparent,
                  ),
                ),
              ],
            ),
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isEdge ? Colors.pink : null,
                shape: BoxShape.circle,
                border: (isToday && !isEdge)
                    ? Border.all(color: Colors.pink, width: 1)
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: isEdge ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}