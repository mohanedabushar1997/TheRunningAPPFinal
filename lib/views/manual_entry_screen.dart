import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/workout_provider.dart';
import '../models/workout_model.dart'; // For WorkoutType enum
import '../widgets/primary_button.dart';
import '../widgets/custom_dialogs.dart'; // For confirmation
import '../widgets/custom_snackbar.dart'; // For feedback

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  WorkoutType _selectedType = WorkoutType.run; // Default type
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Duration _selectedDuration = const Duration(minutes: 30); // Default duration
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(
    text: '30',
  ); // Controller for duration input

  bool _isSaving = false;

  @override
  void dispose() {
    _distanceController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDuration(BuildContext context) async {
    // Simple dialog for duration input (HH:MM:SS or just minutes)
    // Or use a dedicated duration picker package if needed
    final result = await showDialog<Duration>(
      context: context,
      builder:
          (context) => DurationInputDialog(initialDuration: _selectedDuration),
    );

    if (result != null) {
      setState(() {
        _selectedDuration = result;
        // Update text controller if using one
        _durationController.text =
            result.inMinutes.toString(); // Example: show minutes
      });
    }
  }

  Future<void> _saveManualWorkout() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);

      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      final distanceKm = double.tryParse(_distanceController.text);
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      try {
        final success = await workoutProvider.createManualWorkout(
          type: _selectedType,
          date: combinedDateTime,
          duration: _selectedDuration,
          distance: distanceKm,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        if (mounted) {
          if (success) {
            showSuccessSnackBar(context, 'Manual workout saved successfully!');
            Navigator.of(context).pop(); // Go back after saving
          } else {
            showErrorSnackBar(context, 'Failed to save manual workout.');
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(context, 'Error saving workout: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Manual Workout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Workout Type
              Text('Workout Type', style: theme.textTheme.titleMedium),
              DropdownButtonFormField<WorkoutType>(
                value: _selectedType,
                items:
                    WorkoutType.values
                        .map((type) {
                          // All enum values are valid choices now
                          // if (type == WorkoutType.unknown) return null; // Removed check for non-existent enum
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.toShortString().capitalize(),
                            ), // Use existing extension
                          );
                        })
                        .whereType<DropdownMenuItem<WorkoutType>>()
                        .toList(), // Filter out nulls
                onChanged: (WorkoutType? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedType = newValue);
                  }
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Duration
              Text('Duration', style: theme.textTheme.titleMedium),
              InkWell(
                onTap: () => _selectDuration(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer),
                  ),
                  child: Text(
                    _formatDuration(_selectedDuration),
                  ), // Display formatted duration
                ),
              ),
              const SizedBox(height: 16),

              // Distance (Optional)
              Text('Distance (Optional)', style: theme.textTheme.titleMedium),
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  hintText: 'Enter distance in km',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                  suffixText: 'km',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final distance = double.tryParse(value);
                    if (distance == null) return 'Invalid number';
                    if (distance < 0) return 'Cannot be negative';
                  }
                  return null; // Optional field
                },
              ),
              const SizedBox(height: 16),

              // Notes (Optional)
              Text('Notes (Optional)', style: theme.textTheme.titleMedium),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'How did it go?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: _isSaving ? 'Saving...' : 'Save Workout',
                  onPressed: _isSaving ? null : _saveManualWorkout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to format duration (copied again)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) return "$hours:$minutes:$seconds";
    return "$minutes:$seconds";
  }
}

// --- Simple Duration Input Dialog ---
class DurationInputDialog extends StatefulWidget {
  final Duration initialDuration;

  const DurationInputDialog({super.key, required this.initialDuration});

  @override
  State<DurationInputDialog> createState() => _DurationInputDialogState();
}

class _DurationInputDialogState extends State<DurationInputDialog> {
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(
      text: widget.initialDuration.inHours.toString(),
    );
    _minutesController = TextEditingController(
      text: widget.initialDuration.inMinutes.remainder(60).toString(),
    );
    _secondsController = TextEditingController(
      text: widget.initialDuration.inSeconds.remainder(60).toString(),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Duration'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDurationInput(_hoursController, 'HH'),
          const Text(':'),
          _buildDurationInput(_minutesController, 'MM'),
          const Text(':'),
          _buildDurationInput(_secondsController, 'SS'),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            final hours = int.tryParse(_hoursController.text) ?? 0;
            final minutes = int.tryParse(_minutesController.text) ?? 0;
            final seconds = int.tryParse(_secondsController.text) ?? 0;
            final duration = Duration(
              hours: hours,
              minutes: minutes,
              seconds: seconds,
            );
            Navigator.of(context).pop(duration);
          },
        ),
      ],
    );
  }

  Widget _buildDurationInput(TextEditingController controller, String label) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

// Helper extension needed for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
