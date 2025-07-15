import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/schedule.dart';
import '../../../models/notification_settings.dart';
import '../../../services/firebase_service.dart';
import '../../../services/service_locator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_decorations.dart';
import '../../../constants/schedules_variables.dart';
import '../../base_service_screen.dart';
import '../../../widgets/help_card.dart';

class AddScheduleScreen extends BaseServiceScreen {
  final String doseId;
  final String doseName;
  final String? medicationId;
  final Schedule? existingSchedule;

  const AddScheduleScreen({
    super.key,
    required this.doseId,
    required this.doseName,
    this.medicationId,
    this.existingSchedule,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends BaseServiceScreenState<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEdit = false;
  
  // Schedule settings
  ScheduleFrequency _frequency = ScheduleFrequency.daily;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  List<int> _daysOfWeek = [];
  List<int> _daysOfMonth = [];
  int? _daysOn;
  int? _daysOff;
  int? _weeksOn;
  int? _weeksOff;
  
  // Notification settings
  RingType _ringType = RingType.medium;
  VibrateType _vibrateType = VibrateType.normal;
  int _minutesBeforeDose = 15;
  bool _repeatedAlerts = false;
  int _repeatIntervalMinutes = 5;
  int _maxRepeats = 3;
  int _snoozeMinutes = 10;
  bool _showDoseDetails = true;
  Color _notificationColor = Colors.blue;
  
  @override
  void initState() {
    super.initState();
    
    // If editing an existing schedule, populate the fields
    if (widget.existingSchedule != null) {
      _isEdit = true;
      final schedule = widget.existingSchedule!;
      
      _nameController.text = schedule.name;
      _frequency = schedule.frequency;
      _startDate = schedule.startDate;
      _endDate = schedule.endDate;
      _times = List<TimeOfDay>.from(schedule.times);
      _daysOfWeek = List<int>.from(schedule.daysOfWeek);
      _daysOfMonth = List<int>.from(schedule.daysOfMonth);
      _daysOn = schedule.daysOn;
      _daysOff = schedule.daysOff;
      _weeksOn = schedule.weeksOn;
      _weeksOff = schedule.weeksOff;
      
      if (schedule.notes != null) {
        _notesController.text = schedule.notes!;
      }
      
      // Notification settings
      final notifications = schedule.notificationSettings;
      _ringType = notifications.ringType;
      _vibrateType = notifications.vibrateType;
      _minutesBeforeDose = notifications.minutesBeforeDose;
      _repeatedAlerts = notifications.repeatedAlerts;
      _repeatIntervalMinutes = notifications.repeatIntervalMinutes;
      _maxRepeats = notifications.maxRepeats;
      _snoozeMinutes = notifications.snoozeMinutes;
      _showDoseDetails = notifications.showDoseDetails;
      _notificationColor = notifications.notificationColor;
    } else {
      // Default name for new schedule
      _nameController.text = '${widget.doseName} Schedule';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Create notification settings
      final notificationSettings = NotificationSettings(
        id: _isEdit ? widget.existingSchedule!.notificationSettings.id : const Uuid().v4(),
        ringType: RingType.medium,
        vibrateType: VibrateType.normal,
      );
      
      // Create schedule
      final schedule = Schedule(
        id: _isEdit ? widget.existingSchedule!.id : const Uuid().v4(),
        doseId: widget.doseId,
        medicationId: widget.medicationId,
        name: _nameController.text,
        frequency: ScheduleFrequency.daily,
        startDate: DateTime.now(),
        endDate: null,
        times: [const TimeOfDay(hour: 8, minute: 0)],
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        daysOfMonth: [],
        daysOn: null,
        daysOff: null,
        weeksOn: null,
        weeksOff: null,
        doseStatuses: _isEdit 
            ? widget.existingSchedule!.doseStatuses 
            : <DateTime, DoseStatus>{},
        notificationSettings: notificationSettings,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      // Save to Firebase
      await firebaseService.addSchedule(schedule);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Schedule updated successfully' : 'Schedule added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return to previous screen with success result
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, clear it
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _addTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _times.add(picked);
        // Sort times
        _times.sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });
      });
    }
  }

  void _removeTime(int index) {
    setState(() {
      _times.removeAt(index);
    });
  }

  Widget _buildScheduleFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Frequency',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ScheduleFrequency>(
          value: _frequency,
          decoration: AppDecorations.inputField(
            hintText: 'Select frequency',
          ),
          items: [
            DropdownMenuItem(
              value: ScheduleFrequency.once,
              child: Text(SchedulesVariables.variables['scheduleType']?['behavior'].toString().split(', ')[0] ?? 'Once'),
            ),
            DropdownMenuItem(
              value: ScheduleFrequency.daily,
              child: Text(SchedulesVariables.DAILY),
            ),
            DropdownMenuItem(
              value: ScheduleFrequency.certainDays,
              child: Text(SchedulesVariables.CERTAIN_DAYS),
            ),
            DropdownMenuItem(
              value: ScheduleFrequency.daysOnOff,
              child: Text(SchedulesVariables.DAYS_ON_OFF),
            ),
            DropdownMenuItem(
              value: ScheduleFrequency.weekly,
              child: Text('Weekly'),
            ),
            DropdownMenuItem(
              value: ScheduleFrequency.monthly,
              child: Text('Monthly'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _frequency = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Start Date'),
                subtitle: Text(
                  '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartDate,
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('End Date (Optional)'),
                subtitle: _endDate == null
                    ? const Text('No end date')
                    : Text(
                        '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
                      ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dose Times',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Time'),
              onPressed: _addTime,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_times.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No times added yet. Tap "Add Time" to add a time.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _times.length,
            itemBuilder: (context, index) {
              final time = _times[index];
              return ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeTime(index),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFrequencyDetailsSection() {
    // Show different options based on frequency
    switch (_frequency) {
      case ScheduleFrequency.certainDays:
        return _buildDaysOfWeekSelector();
      case ScheduleFrequency.daysOnOff:
        return _buildDaysOnOffSelector();
      case ScheduleFrequency.weeksOnOff:
        return _buildWeeksOnOffSelector();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDaysOfWeekSelector() {
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days of Week',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1; // 1 = Monday, 7 = Sunday
            final isSelected = _daysOfWeek.contains(day);
            
            return FilterChip(
              label: Text(daysOfWeek[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _daysOfWeek.add(day);
                  } else {
                    _daysOfWeek.remove(day);
                  }
                });
              },
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDaysOnOffSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days On/Off Pattern',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: AppDecorations.inputField(
                  labelText: 'Days On',
                  hintText: 'e.g., 5',
                ),
                keyboardType: TextInputType.number,
                initialValue: _daysOn?.toString() ?? '',
                onChanged: (value) {
                  setState(() {
                    _daysOn = int.tryParse(value);
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: AppDecorations.inputField(
                  labelText: 'Days Off',
                  hintText: 'e.g., 2',
                ),
                keyboardType: TextInputType.number,
                initialValue: _daysOff?.toString() ?? '',
                onChanged: (value) {
                  setState(() {
                    _daysOff = int.tryParse(value);
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWeeksOnOffSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weeks On/Off Pattern',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: AppDecorations.inputField(
                  labelText: 'Weeks On',
                  hintText: 'e.g., 3',
                ),
                keyboardType: TextInputType.number,
                initialValue: _weeksOn?.toString() ?? '',
                onChanged: (value) {
                  setState(() {
                    _weeksOn = int.tryParse(value);
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: AppDecorations.inputField(
                  labelText: 'Weeks Off',
                  hintText: 'e.g., 1',
                ),
                keyboardType: TextInputType.number,
                initialValue: _weeksOff?.toString() ?? '',
                onChanged: (value) {
                  setState(() {
                    _weeksOff = int.tryParse(value);
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        
        // Ring Type
        DropdownButtonFormField<RingType>(
          value: _ringType,
          decoration: AppDecorations.inputField(
            labelText: 'Ring Type',
          ),
          items: RingType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.name.capitalize()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _ringType = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Vibrate Type
        DropdownButtonFormField<VibrateType>(
          value: _vibrateType,
          decoration: AppDecorations.inputField(
            labelText: 'Vibration',
          ),
          items: VibrateType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.name.capitalize()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _vibrateType = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Minutes Before Dose
        TextFormField(
          decoration: AppDecorations.inputField(
            labelText: 'Minutes Before Dose',
            hintText: 'e.g., 15',
          ),
          keyboardType: TextInputType.number,
          initialValue: _minutesBeforeDose.toString(),
          onChanged: (value) {
            setState(() {
              _minutesBeforeDose = int.tryParse(value) ?? 15;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Repeated Alerts
        SwitchListTile(
          title: const Text('Repeat Alerts'),
          subtitle: const Text('Send multiple notifications if not acknowledged'),
          value: _repeatedAlerts,
          onChanged: (value) {
            setState(() {
              _repeatedAlerts = value;
            });
          },
        ),
        
        if (_repeatedAlerts) ...[
          // Repeat Interval
          TextFormField(
            decoration: AppDecorations.inputField(
              labelText: 'Repeat Interval (minutes)',
              hintText: 'e.g., 5',
            ),
            keyboardType: TextInputType.number,
            initialValue: _repeatIntervalMinutes.toString(),
            onChanged: (value) {
              setState(() {
                _repeatIntervalMinutes = int.tryParse(value) ?? 5;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Max Repeats
          TextFormField(
            decoration: AppDecorations.inputField(
              labelText: 'Maximum Repeats',
              hintText: 'e.g., 3',
            ),
            keyboardType: TextInputType.number,
            initialValue: _maxRepeats.toString(),
            onChanged: (value) {
              setState(() {
                _maxRepeats = int.tryParse(value) ?? 3;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
        
        // Snooze Minutes
        TextFormField(
          decoration: AppDecorations.inputField(
            labelText: 'Snooze Duration (minutes)',
            hintText: 'e.g., 10',
          ),
          keyboardType: TextInputType.number,
          initialValue: _snoozeMinutes.toString(),
          onChanged: (value) {
            setState(() {
              _snoozeMinutes = int.tryParse(value) ?? 10;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Show Dose Details
        SwitchListTile(
          title: const Text('Show Dose Details'),
          subtitle: const Text('Include dose information in notification'),
          value: _showDoseDetails,
          onChanged: (value) {
            setState(() {
              _showDoseDetails = value;
            });
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Schedule' : 'Add Schedule'),
        centerTitle: false,
        titleSpacing: 16,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        decoration: AppDecorations.screenBackground(context),
        height: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dose Info Card
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medication_liquid,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dose',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  widget.doseName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Help Card
                  CompactHelpCard(
                    title: 'About Schedules',
                    content: 'Schedules define when you need to take your doses:',
                    icon: Icons.calendar_today,
                    steps: [
                      'Remember to schedule your doses for reminders and tracking',
                      'Set up notification preferences to never miss a dose',
                      'Choose a frequency pattern that matches your prescription',
                      'Add multiple times if you need to take the same dose at different times'
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Schedule Name
                  TextFormField(
                    controller: _nameController,
                    decoration: AppDecorations.inputField(
                      labelText: 'Schedule Name',
                      hintText: 'Enter a name for this schedule',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a schedule name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Schedule Frequency
                  _buildScheduleFrequencySection(),
                  
                  // Date Range
                  _buildDateRangeSection(),
                  
                  // Frequency-specific options
                  _buildFrequencyDetailsSection(),
                  
                  // Times
                  _buildTimesSection(),
                  
                  // Notification Settings
                  _buildNotificationSection(),
                  
                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: AppDecorations.inputField(
                      labelText: 'Notes (Optional)',
                      hintText: 'Add any additional notes',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSchedule,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEdit ? 'UPDATE SCHEDULE' : 'SAVE SCHEDULE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 