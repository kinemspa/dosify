import 'package:flutter/material.dart';
import '../../../models/dose.dart';
import '../../../models/medication.dart';
import '../../../models/medication_schedule.dart';
import '../../../services/firebase_service.dart';
import '../../../theme/app_colors.dart';
import 'schedule_dose_screen.dart';

class ViewSchedulesScreen extends StatefulWidget {
  final Medication medication;
  final Dose dose;

  const ViewSchedulesScreen({
    super.key,
    required this.medication,
    required this.dose,
  });

  @override
  State<ViewSchedulesScreen> createState() => _ViewSchedulesScreenState();
}

class _ViewSchedulesScreenState extends State<ViewSchedulesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<MedicationSchedule> _schedules = [];
  
  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }
  
  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final schedules = await _firebaseService.getMedicationSchedules(
        widget.medication.id,
        widget.dose.id,
      );
      
      if (mounted) {
        setState(() {
          _schedules = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedules: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _markDoseTaken(MedicationSchedule schedule, DateTime doseDateTime) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firebaseService.markDoseTaken(schedule, doseDateTime);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dose marked as taken'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload schedules to get updated status
        await _loadSchedules();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking dose as taken: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _navigateToScheduleScreen({MedicationSchedule? existingSchedule}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleDoseScreen(
          medication: widget.medication,
          dose: widget.dose,
          existingSchedule: existingSchedule,
        ),
      ),
    );
    
    if (result == true) {
      // Schedule was created/updated, reload schedules
      await _loadSchedules();
    }
  }
  
  Widget _buildScheduleCard(MedicationSchedule schedule) {
    final now = DateTime.now();
    final upcomingDoses = schedule.getUpcomingDoses(
      from: now,
      to: now.add(const Duration(days: 7)),
    );
    
    // Format frequency text
    String frequencyText;
    switch (schedule.frequency) {
      case ScheduleFrequency.once:
        frequencyText = 'Once only';
        break;
      case ScheduleFrequency.daily:
        frequencyText = 'Daily';
        break;
      case ScheduleFrequency.certainDays:
        frequencyText = 'Specific days of week';
        break;
      case ScheduleFrequency.daysOnOff:
        frequencyText = '${schedule.daysOn} days on, ${schedule.daysOff} days off';
        break;
      case ScheduleFrequency.weekly:
        frequencyText = 'Weekly';
        break;
      case ScheduleFrequency.weeksOnOff:
        frequencyText = '${schedule.weeksOn} weeks on, ${schedule.weeksOff} weeks off';
        break;
      case ScheduleFrequency.monthly:
        frequencyText = 'Monthly';
        break;
      default:
        frequencyText = schedule.frequency.toString().split('.').last;
    }
    
    // Format times
    final timeStrings = schedule.times.map((time) => 
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}').toList();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    schedule.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToScheduleScreen(existingSchedule: schedule),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Frequency
            Row(
              children: [
                const Icon(Icons.repeat, size: 16),
                const SizedBox(width: 8),
                Text(frequencyText),
              ],
            ),
            const SizedBox(height: 4),
            
            // Times
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(timeStrings.join(', ')),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Date range
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'From ${_formatDate(schedule.startDate)}${schedule.endDate != null ? ' to ${_formatDate(schedule.endDate!)}' : ''}',
                ),
              ],
            ),
            
            // Inventory deduction
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  size: 16,
                  color: schedule.deductFromInventory ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  schedule.deductFromInventory
                      ? 'Deducts from inventory'
                      : 'Does not affect inventory',
                  style: TextStyle(
                    color: schedule.deductFromInventory ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Upcoming doses
            Text(
              'Upcoming Doses',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            if (upcomingDoses.isEmpty)
              const Text('No upcoming doses in the next 7 days')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingDoses.length.clamp(0, 5), // Show max 5 upcoming doses
                itemBuilder: (context, index) {
                  final doseDateTime = upcomingDoses[index];
                  final doseStatus = schedule.doseStatuses[doseDateTime];
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      doseStatus == DoseStatus.taken
                          ? Icons.check_circle
                          : Icons.access_time,
                      color: doseStatus == DoseStatus.taken
                          ? Colors.green
                          : doseStatus == DoseStatus.missed
                              ? Colors.red
                              : null,
                    ),
                    title: Text(_formatDateTime(doseDateTime)),
                    trailing: doseStatus != DoseStatus.taken
                        ? ElevatedButton(
                            onPressed: () => _markDoseTaken(schedule, doseDateTime),
                            child: const Text('Take'),
                          )
                        : const Text('Taken', style: TextStyle(color: Colors.green)),
                  );
                },
              ),
            
            if (upcomingDoses.length > 5)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to a detailed schedule view
                  },
                  child: Text('+ ${upcomingDoses.length - 5} more'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.dose.getDisplayName()} Schedules'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: _schedules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No schedules yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button to create a schedule',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => _navigateToScheduleScreen(),
                            child: const Text('Create Schedule'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
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
                                  'Schedules for:',
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
                        
                        // Schedules list
                        ..._schedules.map(_buildScheduleCard).toList(),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToScheduleScreen(),
        child: const Icon(Icons.add),
      ),
    );
  }
} 