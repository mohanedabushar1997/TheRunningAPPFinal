import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_provider.dart';
import '../models/user_model.dart';
import '../widgets/primary_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Prefer not to say';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  DateTime? _selectedBirthDate;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Create user model with form data
      final user = UserModel(
        deviceId: userProvider.deviceId ?? '',
        name: _nameController.text,
        gender: _selectedGender,
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        birthDate: _selectedBirthDate,
      );
      
      // Save profile
      userProvider.saveUserProfile(user).then((_) {
        // Navigate to home screen after successful save
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome to FitStride!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s set up your profile to personalize your experience.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Gender dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: _genderOptions.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Height field
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    hintText: 'Enter your height in centimeters',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final height = double.tryParse(value);
                      if (height == null) {
                        return 'Please enter a valid number';
                      }
                      if (height < 50 || height > 250) {
                        return 'Please enter a realistic height (50-250 cm)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Weight field
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Enter your weight in kilograms',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final weight = double.tryParse(value);
                      if (weight == null) {
                        return 'Please enter a valid number';
                      }
                      if (weight < 30 || weight > 300) {
                        return 'Please enter a realistic weight (30-300 kg)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Birth date picker
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Birth Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedBirthDate == null
                              ? 'Select your birth date'
                              : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                          style: TextStyle(
                            color: _selectedBirthDate == null
                                ? theme.hintColor
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Privacy note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.privacy_tip, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Privacy Note',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All your data is stored locally on your device only. FitStride does not collect or transmit your personal information to any external servers.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Save button
                PrimaryButton(
                  text: 'Save Profile',
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 16),
                
                // Skip button
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
