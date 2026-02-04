import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme/app_theme.dart';
import 'package:intl/intl.dart';

class WorkoutCalendarScreen extends StatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  State<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends State<WorkoutCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Datos de ejemplo
  final Map<DateTime, List<WorkoutEvent>> _workoutEvents = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadWorkoutEvents();
  }

  void _loadWorkoutEvents() {
    final now = DateTime.now();

    // Datos de ejemplo - conectar con WorkoutSessionProvider para datos reales
    _workoutEvents[DateTime(now.year, now.month, now.day)] = [
      WorkoutEvent('Entrenamiento Completo', true, 45),
    ];
    _workoutEvents[DateTime(now.year, now.month, now.day - 1)] = [
      WorkoutEvent('Piernas y Glúteos', true, 50),
    ];
    _workoutEvents[DateTime(now.year, now.month, now.day - 2)] = [
      WorkoutEvent('Tren Superior', true, 42),
    ];
    _workoutEvents[DateTime(now.year, now.month, now.day - 4)] = [
      WorkoutEvent('Cardio Intenso', true, 30),
    ];
    _workoutEvents[DateTime(now.year, now.month, now.day + 1)] = [
      WorkoutEvent('Entrenamiento Completo', false, 0),
    ];
  }

  List<WorkoutEvent> _getEventsForDay(DateTime day) {
    return _workoutEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Calendario de Entrenamientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendario
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar<WorkoutEvent>(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2026, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'es_ES',
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle:
                    const TextStyle(color: AppColors.textSecondary),
                defaultTextStyle: const TextStyle(color: Colors.white),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppColors.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),

          // Estadísticas del mes
          _buildMonthStats(),

          // Eventos del día seleccionado
          Expanded(
            child: _buildSelectedDayEvents(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStats() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final completedDays = _workoutEvents.entries
        .where((entry) =>
            entry.key.month == now.month &&
            entry.value.any((event) => event.isCompleted))
        .length;

    final totalMinutes = _workoutEvents.entries
        .where((entry) => entry.key.month == now.month)
        .expand((entry) => entry.value)
        .where((event) => event.isCompleted)
        .fold<int>(0, (sum, event) => sum + event.durationMinutes);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMonthStatItem(
            Icons.calendar_month,
            '$completedDays/$daysInMonth',
            'Días activos',
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: AppColors.background),
          _buildMonthStatItem(
            Icons.access_time,
            '${(totalMinutes / 60).toStringAsFixed(1)}h',
            'Tiempo total',
            Colors.orange,
          ),
          Container(width: 1, height: 40, color: AppColors.background),
          _buildMonthStatItem(
            Icons.local_fire_department,
            '${((completedDays / daysInMonth) * 100).toStringAsFixed(0)}%',
            'Cumplimiento',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayEvents() {
    if (_selectedDay == null) {
      return const SizedBox();
    }

    final events = _getEventsForDay(_selectedDay!);
    final dateStr = DateFormat('EEEE, d MMMM', 'es').format(_selectedDay!);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 60,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin entrenamientos programados',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventCard(event);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(WorkoutEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: event.isCompleted
            ? Border.all(color: Colors.green.withOpacity(0.5))
            : Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: event.isCompleted
                  ? Colors.green.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              event.isCompleted ? Icons.check_circle : Icons.schedule,
              color: event.isCompleted ? Colors.green : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (event.isCompleted)
                  Text(
                    '${event.durationMinutes} minutos completados',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const Text(
                    'Programado',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (event.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✓ Hecho',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WorkoutEvent {
  final String name;
  final bool isCompleted;
  final int durationMinutes;

  WorkoutEvent(this.name, this.isCompleted, this.durationMinutes);
}
