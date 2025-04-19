import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/weight_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_snackbar.dart'; // For feedback

class WeightEntryScreen extends StatefulWidget {
  const WeightEntryScreen({super.key});

  @override
  State<WeightEntryScreen> createState() => _WeightEntryScreenState();
}

class _WeightEntryScreenState extends State<WeightEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
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

  Future<void> _saveWeightEntry() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);
      final weightProvider = Provider.of<WeightProvider>(
        context,
        listen: false,
      );
      final weight = double.tryParse(_weightController.text);

      if (weight == null) {
        showErrorSnackBar(context, 'Invalid weight entered.');
        setState(() => _isSaving = false);
        return;
      }

      try {
        final success = await weightProvider.addWeightRecord(
          weight,
          date: _selectedDate,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        if (mounted) {
          if (success) {
            showSuccessSnackBar(context, 'Weight record saved successfully!');
            Navigator.of(context).pop(); // Go back after saving
          } else {
            showErrorSnackBar(context, 'Failed to save weight record.');
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(context, 'Error saving weight record: $e');
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
      appBar: AppBar(title: const Text('Log Weight')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Picker
              Text('Date', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat.yMMMd().format(_selectedDate),
                  ), // Format date
                ),
              ),
              const SizedBox(height: 16),

              // Weight Input
              Text(
                'Weight (kg)',
                style: theme.textTheme.titleMedium,
              ), // Assuming kg for now
              const SizedBox(height: 8),
              CustomTextField(
                controller: _weightController,
                hintText: 'Enter your weight in kilograms',
                prefixIcon: Icons.monitor_weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null) {
                    return 'Please enter a valid number';
                  }
                  if (weight <= 0 || weight > 500) {
                    // Basic validation
                    return 'Please enter a realistic weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes Input (Optional)
              Text('Notes (Optional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _notesController,
                hintText: 'Any notes about this weigh-in?',
                maxLines: 3,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: _isSaving ? 'Saving...' : 'Save Record',
                  onPressed: _isSaving ? null : _saveWeightEntry,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
