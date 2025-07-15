import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/dose.dart';
import '../../../models/medication.dart';
import '../../../models/medication_schedule.dart';
import '../../../models/notification_settings.dart';
import '../../../services/firebase_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/help_card.dart';
import '../../../widgets/confirmation_dialog.dart';

class ScheduleDoseScreen extends StatefulWidget {
  final Medication medication;
  final Dose dose;
  final MedicationSchedule? existingSchedule;

  const ScheduleDoseScreen({
    super.key,
    required this.medication,
    required this.dose,
    this.existingSchedule,
  });

  @override
  State<ScheduleDoseScreen> createState() => _ScheduleDoseScreenState();
}

class _ScheduleDoseScreenState extends State<ScheduleDoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  
  bool _isLoading = false;
  bool _isEditing = false;
  
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
  bool _deductFromInventory = true;
  
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
      _isEditing = true;
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
      _deductFromInventory = schedule.deductFromInventory;
      
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
      _nameController.text = '${widget.medication.name} - ${widget.dose.getDisplayName()} Schedule';
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
        id: _isEditing ? widget.existingSchedule!.notificationSettings.id : const Uuid().v4(),
        ringType: _ringType,
        vibrateType: _vibrateType,
        minutesBeforeDose: _minutesBeforeDose,
        repeatedAlerts: _repeatedAlerts,
        repeatIntervalMinutes: _repeatIntervalMinutes,
        maxRepeats: _maxRepeats,
        snoozeMinutes: _snoozeMinutes,
        showDoseDetails: _showDoseDetails,
        notificationColor: _notificationColor,
      );
      
      // Create schedule
      final schedule = MedicationSchedule(
        id: _isEditing ? widget.existingSchedule!.id : const Uuid().v4(),
        medicationId: widget.medication.id,
        doseId: widget.dose.id,
        name: _nameController.text,
        frequency: _frequency,
        startDate: _startDate,
        endDate: _endDate,
        times: _times,
        daysOfWeek: _daysOfWeek,
        daysOfMonth: _daysOfMonth,
        daysOn: _daysOn,
        daysOff: _daysOff,
        weeksOn: _weeksOn,
        weeksOff: _weeksOff,
        doseStatuses: _isEditing 
            ? widget.existingSchedule!.doseStatuses 
            : <DateTime, DoseStatus>{},
        notificationSettings: notificationSettings,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        deductFromInventory: _deductFromInventory,
      );
      
      // Save to Firebase
      await _firebaseService.addMedicationSchedule(schedule);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Schedule updated successfully' : 'Schedule added successfully'),
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

  Future<void> _deleteSchedule() async {
    if (!_isEditing) return;
    
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Schedule',
      message: 'Are you sure you want to delete this schedule? This action cannot be undone.',
      confirmText: 'DELETE',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firebaseService.deleteMedicationSchedule(
        widget.existingSchedule!.id,
        widget.medication.id,
        widget.dose.id,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting schedule: $e'),
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
            labelText: 'Frequency',
          ),
          items: ScheduleFrequency.values.map((freq) {
            String displayName;
            switch (freq) {
              case ScheduleFrequency.once:
                displayName = 'Once only';
                break;
              case ScheduleFrequency.daily:
                displayName = 'Every day';
                break;
              case ScheduleFrequency.certainDays:
                displayName = 'Specific days of the week';
                break;
              case ScheduleFrequency.daysOnOff:
                displayName = 'Days on / days off cycle';
                break;
              case ScheduleFrequency.weekly:
                displayName = 'Weekly';
                break;
              case ScheduleFrequency.certainWeeks:
                displayName = 'Specific weeks';
                break;
              case ScheduleFrequency.weeksOnOff:
                displayName = 'Weeks on / weeks off cycle';
                break;
              case ScheduleFrequency.monthly:
                displayName = 'Monthly';
                break;
              case ScheduleFrequency.certainMonths:
                displayName = 'Specific months';
                break;
              case ScheduleFrequency.custom:
                displayName = 'Custom schedule';
                break;
            }
            return DropdownMenuItem(
              value: freq,
              child: Text(displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _frequency = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Show additional fields based on frequency
        if (_frequency == ScheduleFrequency.certainDays)
          _buildDaysOfWeekSelector(),
        if (_frequency == ScheduleFrequency.daysOnOff)
          _buildDaysOnOffSelector(),
        if (_frequency == ScheduleFrequency.weeksOnOff)
          _buildWeeksOnOffSelector(),
        if (_frequency == ScheduleFrequency.certainMonths)
          _buildMonthsSelector(),
      ],
    );
  }

  Widget _buildDaysOfWeekSelector() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select days of the week:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final dayIndex = index + 1; // 1 = Monday, 7 = Sunday
            final isSelected = _daysOfWeek.contains(dayIndex);
            
            return FilterChip(
              label: Text(days[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _daysOfWeek.add(dayIndex);
                  } else {
                    _daysOfWeek.remove(dayIndex);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDaysOnOffSelector() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: _daysOn?.toString() ?? '7',
            decoration: AppDecorations.inputField(
              labelText: 'Days ON',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'Must be > 0';
              }
              return null;
            },
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _daysOn = int.tryParse(value);
                });
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            initialValue: _daysOff?.toString() ?? '7',
            decoration: AppDecorations.inputField(
              labelText: 'Days OFF',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'Must be > 0';
              }
              return null;
            },
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _daysOff = int.tryParse(value);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeksOnOffSelector() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: _weeksOn?.toString() ?? '1',
            decoration: AppDecorations.inputField(
              labelText: 'Weeks ON',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'Must be > 0';
              }
              return null;
            },
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _weeksOn = int.tryParse(value);
                });
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            initialValue: _weeksOff?.toString() ?? '1',
            decoration: AppDecorations.inputField(
              labelText: 'Weeks OFF',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'Must be > 0';
              }
              return null;
            },
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _weeksOff = int.tryParse(value);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthsSelector() {
    // Not implemented yet - would show month selector
    return const Text('Month selection coming soon');
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Date Range',
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
                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartDate,
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('End Date'),
                subtitle: _endDate != null
                    ? Text('${_endDate!.day}/${_endDate!.month}/${_endDate!.year}')
                    : const Text('No end date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndDate,
              ),
            ),
          ],
        ),
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
          const Center(
            child: Text('No times added yet. Add at least one time.'),
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
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (picked != null) {
                    setState(() {
                      _times[index] = picked;
                      // Resort times
                      _times.sort((a, b) {
                        final aMinutes = a.hour * 60 + a.minute;
                        final bMinutes = b.hour * 60 + b.minute;
                        return aMinutes.compareTo(bMinutes);
                      });
                    });
                  }
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildInventorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Deduct from inventory when taken'),
          subtitle: Text(
            'When you mark a dose as taken, it will automatically deduct from your ${widget.medication.name} inventory',
          ),
          value: _deductFromInventory,
          onChanged: (value) {
            setState(() {
              _deductFromInventory = value;
            });
          },
        ),
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
        
        // Reminder time
        TextFormField(
          initialValue: _minutesBeforeDose.toString(),
          decoration: AppDecorations.inputField(
            labelText: 'Minutes before dose to notify',
            hintText: 'e.g., 15',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            if (int.tryParse(value) == null || int.parse(value) < 0) {
              return 'Must be >= 0';
            }
            return null;
          },
          onChanged: (value) {
            if (value.isNotEmpty && int.tryParse(value) != null) {
              setState(() {
                _minutesBeforeDose = int.parse(value);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Repeated alerts
        SwitchListTile(
          title: const Text('Repeated alerts'),
          subtitle: const Text('Send multiple notifications until dose is taken'),
          value: _repeatedAlerts,
          onChanged: (value) {
            setState(() {
              _repeatedAlerts = value;
            });
          },
        ),
        
        if (_repeatedAlerts) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _repeatIntervalMinutes.toString(),
                  decoration: AppDecorations.inputField(
                    labelText: 'Repeat interval (minutes)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Must be > 0';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty && int.tryParse(value) != null) {
                      setState(() {
                        _repeatIntervalMinutes = int.parse(value);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _maxRepeats.toString(),
                  decoration: AppDecorations.inputField(
                    labelText: 'Max repeats',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Must be > 0';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty && int.tryParse(value) != null) {
                      setState(() {
                        _maxRepeats = int.parse(value);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Show dose details
        SwitchListTile(
          title: const Text('Show dose details in notification'),
          subtitle: const Text('Include medication name and dose amount'),
          value: _showDoseDetails,
          onChanged: (value) {
            setState(() {
              _showDoseDetails = value;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Schedule' : 'New Schedule'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSchedule,
            ),
          TextButton(
            onPressed: _isLoading ? null : _saveSchedule,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Medication and dose info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduling for:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.medication.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.dose.getDisplayName()} dose',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Schedule name
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
                  
                  // Frequency section
                  _buildScheduleFrequencySection(),
                  const SizedBox(height: 24),
                  
                  // Date range section
                  _buildDateRangeSection(),
                  const SizedBox(height: 24),
                  
                  // Times section
                  _buildTimesSection(),
                  const SizedBox(height: 24),
                  
                  // Inventory section
                  _buildInventorySection(),
                  const SizedBox(height: 24),
                  
                  // Notification section
                  _buildNotificationSection(),
                  const SizedBox(height: 24),
                  
                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: AppDecorations.inputField(
                      labelText: 'Notes (optional)',
                      hintText: 'Add any additional notes about this schedule',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  
                  // Save button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSchedule,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_isEditing ? 'Update Schedule' : 'Create Schedule'),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _deleteSchedule,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete Schedule'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
} 