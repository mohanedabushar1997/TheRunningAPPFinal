import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/workout_provider.dart';
import '../models/workout_model.dart';
import '../utils/date_utils.dart';
import 'package:intl/intl.dart'; // For formatting

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Calendar state (keep for visual focus)
  DateTime _focusedDay = DateTime.now();
  // DateTime? _selectedDay; // Replaced by date range

  // Filter & Sort State
  DateTime _startDate = DateTimeUtils.startOfMonth(
    DateTime.now(),
  ); // Default: start of current month
  DateTime _endDate = DateTimeUtils.endOfMonth(
    DateTime.now(),
  ); // Default: end of current month
  WorkoutType? _selectedTypeFilter;
  String _sortBy = 'date'; // 'date', 'distance', 'duration'
  bool _sortAscending = false; // Default: newest/longest first

  // Data State
  List<WorkoutModel> _allLoadedWorkouts = []; // Store all workouts fetched
  List<WorkoutModel> _displayedWorkouts = []; // Filtered & sorted list for UI
  bool _isLoading = true; // Added loading state

  @override
  void initState() {
    super.initState();
    // _selectedDay = _focusedDay; // No longer selecting single day initially
    _loadAndFilterWorkouts(); // Initial load and filter
  }

  Future<void> _loadAndFilterWorkouts() async {
    setState(() => _isLoading = true);
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    try {
      // Load all workouts once
      _allLoadedWorkouts = await workoutProvider.getAllWorkouts();
      _applyFiltersAndSort(); // Apply current filters/sort
    } catch (e) {
      print("Error loading workouts: $e");
      // Handle error display if needed
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Removed _getWorkoutsForDay and _onDaySelected

  void _onTypeFilterChanged(WorkoutType? newType) {
    setState(() {
      _selectedTypeFilter = newType;
      _applyFiltersAndSort(); // Re-apply filters and sort
    });
  }

  void _onSortChanged(String? newSortBy) {
    if (newSortBy != null && newSortBy != _sortBy) {
      setState(() {
        _sortBy = newSortBy;
        // Keep direction or reset? Let's keep it for now.
        _applyFiltersAndSort();
      });
    }
  }

  void _toggleSortDirection() {
    setState(() {
      _sortAscending = !_sortAscending;
      _applyFiltersAndSort();
    });
  }

  // Apply current filters and sorting to the full list
  void _applyFiltersAndSort() {
    List<WorkoutModel> filtered = List.from(_allLoadedWorkouts);

    // 1. Filter by Date Range
    filtered =
        filtered.where((w) {
          final workoutDate = DateTimeUtils.dateOnly(w.date);
          return !workoutDate.isBefore(_startDate) &&
              !workoutDate.isAfter(_endDate);
        }).toList();

    // 2. Filter by Type
    if (_selectedTypeFilter != null) {
      filtered = filtered.where((w) => w.type == _selectedTypeFilter).toList();
    }

    // 3. Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'distance':
          comparison = (a.distance ?? 0).compareTo(b.distance ?? 0);
          break;
        case 'duration':
          comparison = a.duration.compareTo(b.duration);
          break;
        case 'date':
        default:
          comparison = a.date.compareTo(b.date);
          break;
      }
      return _sortAscending ? comparison : -comparison; // Apply direction
    });

    setState(() {
      _displayedWorkouts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: Column(
        children: [
          // Removed TableCalendar
          _buildDateRangeSelector(context), // Add Date Range Selector
          const Divider(height: 1),
          _buildFilterAndSortControls(context), // Combined Filter/Sort Controls
          const Divider(height: 1),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildWorkoutList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(DateFormat.yMd().format(_startDate)),
              onPressed: () => _selectDateRange(context, isStart: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceVariant,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('to'),
          ),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(DateFormat.yMd().format(_endDate)),
              onPressed: () => _selectDateRange(context, isStart: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceVariant,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(
    BuildContext context, {
    required bool isStart,
  }) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          // Ensure start date is not after end date
          _startDate = picked.isAfter(_endDate) ? _endDate : picked;
        } else {
          // Ensure end date is not before start date
          _endDate = picked.isBefore(_startDate) ? _startDate : picked;
        }
        _applyFiltersAndSort(); // Re-apply filters
      });
    }
  }

  Widget _buildFilterAndSortControls(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out controls
        children: [
          // Type Filter Dropdown
          Expanded(
            // Allow dropdown to take space
            child: DropdownButtonHideUnderline(
              child: DropdownButton<WorkoutType?>(
                value: _selectedTypeFilter,
                isDense: true, // Make it more compact
                hint: const Text('All Types'),
                items: [
                  const DropdownMenuItem<WorkoutType?>(
                    value: null, // Represents 'All'
                    child: Text('All Types'),
                  ),
                  ...WorkoutType.values.map((type) {
                    return DropdownMenuItem<WorkoutType>(
                      value: type,
                      child: Text(type.toShortString().capitalize()),
                    );
                  }).toList(),
                ],
                onChanged: _onTypeFilterChanged,
              ),
            ),
          ),
          const SizedBox(width: 16), // Spacing
          // Sort Dropdown
          Expanded(
            // Allow dropdown to take space
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'distance', child: Text('Distance')),
                  DropdownMenuItem(value: 'duration', child: Text('Duration')),
                ],
                onChanged: _onSortChanged,
              ),
            ),
          ),
          // Sort Direction Button
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 20,
            ),
            tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
            onPressed: _toggleSortDirection,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList(BuildContext context) {
    // Renamed function
    if (_displayedWorkouts.isEmpty) {
      // Use _displayedWorkouts
      return Center(
        child: Text(
          _selectedTypeFilter == null
              ? 'No workouts recorded for this day.'
              : 'No ${_selectedTypeFilter!.toShortString().capitalize()} workouts recorded for this day.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _displayedWorkouts.length, // Use _displayedWorkouts
      itemBuilder: (context, index) {
        final workout = _displayedWorkouts[index]; // Use _displayedWorkouts
        // TODO: Create a reusable WorkoutListTile widget
        return ListTile(
          title: Text('${workout.type.toShortString().capitalize()} Workout'),
          subtitle: Text(
            '${workout.distance?.toStringAsFixed(2) ?? '-'} km in ${_formatDuration(workout.duration)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/workout_summary',
              arguments: workout,
            );
          },
        );
      },
    );
  }

  // Helper to format duration (copied from summary screen for now)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }
}

// Placeholder for date utility - needs actual implementation
class DateTimeUtils {
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  // Added: Get the first moment of the month for a given date
  static DateTime startOfMonth(DateTime dt) {
    return DateTime(dt.year, dt.month, 1);
  }

  // Added: Get the last moment of the month for a given date
  static DateTime endOfMonth(DateTime dt) {
    // Go to the first day of the next month, then subtract a microsecond
    final nextMonth = DateTime(dt.year, dt.month + 1, 1);
    return nextMonth.subtract(const Duration(microseconds: 1));
  }
}

// Placeholder for capitalize extension - needs actual implementation or import
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
