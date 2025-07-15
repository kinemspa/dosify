import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../models/schedule.dart';
import '../services/firebase_service.dart';
import '../services/service_locator.dart';
import '../screens/medications/details/medication_detail_screen.dart';

class UpcomingDosesWidget extends StatefulWidget {
  final String? medicationId;
  final bool showMedicationName;
  final int daysToShow;
  final bool showEmptyMessage;
  final String emptyMessage;

  const UpcomingDosesWidget({
    super.key,
    this.medicationId,
    this.showMedicationName = true,
    this.daysToShow = 7,
    this.showEmptyMessage = true,
    this.emptyMessage = 'No upcoming doses scheduled',
  });

  @override
  State<UpcomingDosesWidget> createState() => _UpcomingDosesWidgetState();
}

class _UpcomingDosesWidgetState extends State<UpcomingDosesWidget> {
  final FirebaseService _firebaseService = serviceLocator<FirebaseService>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _upcomingDoses = [];

  @override
  void initState() {
    super.initState();
    _loadUpcomingDoses();
  }

  Future<void> _loadUpcomingDoses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all medications or just the specified one
      List<Medication> medications = [];
      if (widget.medicationId != null) {
        final medication = await _firebaseService.getMedication(widget.medicationId!);
        if (medication != null) {
          medications = [medication];
        }
      } else {
        // Get medications as a stream and convert to list
        final medicationsStream = await _firebaseService.getMedications();
        medications = await medicationsStream.first;
      }

      // Collect all upcoming doses
      final List<Map<String, dynamic>> allUpcomingDoses = [];
      
      for (final medication in medications) {
        // Get all doses for this medication
        final doses = await _firebaseService.getDosesForMedication(medication.id);
        
        for (final dose in doses) {
          // Get schedules for this dose
          final schedules = await _firebaseService.getMedicationSchedules(
            medication.id, 
            dose.id
          );
          
          for (final schedule in schedules) {
            // Only process active schedules
            if (!schedule.isActive) continue;
            
            // Calculate upcoming doses for the next X days
            final now = DateTime.now();
            final endDate = now.add(Duration(days: widget.daysToShow));
            
            final upcomingDoseTimes = schedule.getUpcomingDoses(
              from: now,
              to: endDate,
            );
            
            // Add each upcoming dose to our list
            for (final doseTime in upcomingDoseTimes) {
              allUpcomingDoses.add(
                {
                  'medication': medication,
                  'dose': dose,
                  'schedule': schedule,
                  'dateTime': doseTime,
                },
              );
            }
          }
        }
      }
      
      // Sort by date/time
      allUpcomingDoses.sort((a, b) => a['dateTime'].compareTo(b['dateTime']));
      
      setState(() {
        _upcomingDoses = allUpcomingDoses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading upcoming doses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_upcomingDoses.isEmpty && widget.showEmptyMessage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.emptyMessage,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _upcomingDoses.length,
      itemBuilder: (context, index) {
        final item = _upcomingDoses[index];
        return _buildDoseCard(context, item);
      },
    );
  }

  Widget _buildDoseCard(BuildContext context, Map<String, dynamic> item) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isToday = item['dateTime'].day == DateTime.now().day &&
        item['dateTime'].month == DateTime.now().month &&
        item['dateTime'].year == DateTime.now().year;
    
    // Format date and time
    final dateFormat = DateFormat('E, MMM d'); // e.g., "Mon, Jan 1"
    final timeFormat = DateFormat('h:mm a'); // e.g., "8:30 AM"
    
    final dateText = isToday ? 'Today' : dateFormat.format(item['dateTime']);
    final timeText = timeFormat.format(item['dateTime']);
    
    // Determine icon and color based on medication type
    IconData medicationIcon = Icons.medication;
    Color medicationColor = Colors.blue;
    
    switch (item['medication'].type) {
      case MedicationType.tablet:
        medicationIcon = Icons.local_pharmacy;
        medicationColor = Colors.blue;
        break;
      case MedicationType.capsule:
        medicationIcon = Icons.medication;
        medicationColor = Colors.orange;
        break;
      case MedicationType.injection:
        medicationIcon = Icons.vaccines;
        medicationColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () => _showDoseDetails(context, item),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: medicationColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  medicationIcon,
                  color: medicationColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['medication'].name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['dose'].name ?? '${item['dose'].amount} ${item['dose'].unit}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateText,
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday 
                          ? Theme.of(context).colorScheme.primary 
                          : (isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isToday 
                          ? Theme.of(context).colorScheme.primary 
                          : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoseDetails(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dose Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Medication', item['medication'].name),
              _buildDetailRow('Dose', 
                  item['dose'].name ?? '${item['dose'].amount} ${item['dose'].unit}'),
              _buildDetailRow('Time', 
                  DateFormat('EEEE, MMMM d, yyyy \'at\' h:mm a')
                      .format(item['dateTime'])),
              if (item['dose'].notes != null && item['dose'].notes!.isNotEmpty)
                _buildDetailRow('Notes', item['dose'].notes!),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _markDoseTaken(item);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('MARK AS TAKEN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _markDoseSkipped(item);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('SKIP'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _markDoseTaken(Map<String, dynamic> item) async {
    try {
      await _firebaseService.markDoseTaken(item['schedule'], item['dateTime']);
      
      // Refresh the list
      _loadUpcomingDoses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked ${item['medication'].name} dose as taken'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking dose as taken: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markDoseSkipped(Map<String, dynamic> item) async {
    try {
      // Use the DoseStatus from medication_schedule.dart
      final updatedSchedule = item['schedule'].markDoseStatus(
          item['dateTime'], DoseStatus.skipped);
      await _firebaseService.addMedicationSchedule(updatedSchedule);
      
      // Refresh the list
      _loadUpcomingDoses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked ${item['medication'].name} dose as skipped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking dose as skipped: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 