import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/utils/formatters.dart';
import '../providers/history_providers.dart';

const List<String> _monthsEs = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

const List<String> _weekdayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

class HistoryCalendar extends ConsumerStatefulWidget {
  const HistoryCalendar({super.key});

  @override
  ConsumerState<HistoryCalendar> createState() => _HistoryCalendarState();
}

class _HistoryCalendarState extends ConsumerState<HistoryCalendar> {
  late DateTime _viewedMonth;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _viewedMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month + 1);
    });
  }

  void _toggleDay(DateTime day) {
    final current = ref.read(selectedDayProvider);
    ref.read(selectedDayProvider.notifier).state =
        current == day ? null : day;
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final today = startOfDay(now);
    final workoutDays =
        ref.watch(workoutDaysProvider).valueOrNull ?? const <DateTime>{};
    final selected = ref.watch(selectedDayProvider);
    final scheme = Theme.of(context).colorScheme;

    final firstOfMonth = _viewedMonth;
    final daysInMonth =
        DateTime(_viewedMonth.year, _viewedMonth.month + 1, 0).day;
    final leadingBlanks = (firstOfMonth.weekday - DateTime.monday + 7) % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final cellCount = rows * 7;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
        child: Column(
          children: [
            // ── Month navigation ──
            Row(
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                  style: IconButton.styleFrom(
                    foregroundColor: scheme.primary,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_monthsEs[_viewedMonth.month - 1]} ${_viewedMonth.year}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                  style: IconButton.styleFrom(
                    foregroundColor: scheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Weekday headers ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  for (final letter in _weekdayLetters)
                    Expanded(
                      child: Center(
                        child: Text(
                          letter,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                                letterSpacing: 0.5,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Day grid ──
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - leadingBlanks + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(
                  _viewedMonth.year,
                  _viewedMonth.month,
                  dayNumber,
                );
                return _DayCell(
                  date: date,
                  isToday: date == today,
                  isSelected: selected == date,
                  hasWorkout: workoutDays.contains(date),
                  onTap: () => _toggleDay(date),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.hasWorkout,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool hasWorkout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bg = isSelected
        ? scheme.primary
        : (hasWorkout
            ? scheme.primary.withValues(alpha: 0.15)
            : Colors.transparent);
    final fg = isSelected
        ? scheme.onPrimary
        : (isToday ? scheme.primary : null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: scheme.primary, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
            ),
            if (hasWorkout)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.onPrimary : scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
