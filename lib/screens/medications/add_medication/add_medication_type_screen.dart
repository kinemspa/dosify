import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/help_card.dart';
import 'add_tablet_medication_screen.dart';
import 'add_capsule_medication_screen.dart';
import 'add_injection_medication_screen.dart';
import 'injection_type_selection_screen.dart';

class AddMedicationTypeScreen extends StatelessWidget {
  const AddMedicationTypeScreen({super.key});

  void _navigateToMedicationScreen(BuildContext context, MedicationType type) async {
    Widget screen;
    
    switch (type) {
      case MedicationType.tablet:
        screen = const AddTabletMedicationScreen();
        break;
      case MedicationType.capsule:
        screen = const AddCapsuleMedicationScreen();
        break;
      case MedicationType.injection:
        screen = const InjectionTypeSelectionScreen();
        break;
      case MedicationType.preFilledSyringe:
      case MedicationType.vialPreMixed:
      case MedicationType.vialPowderedKnown:
      case MedicationType.vialPowderedRecon:
        // These are handled within the InjectionTypeSelectionScreen
        screen = const InjectionTypeSelectionScreen();
        break;
      default:
        // Default to injection type selection for any new medication types
        screen = const InjectionTypeSelectionScreen();
        break;
    }
    
    // Navigate to the appropriate screen and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    
    // If a medication was added, pass the result back to refresh the list
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildTypeCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required MedicationType type,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToMedicationScreen(context, type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dosify'),
            Text(
              'Add Medication',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        centerTitle: false,
        titleSpacing: 16,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        decoration: AppDecorations.screenBackground(context),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Medication Type',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Choose the type of medication you want to add',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Add help card for medication type selection - using extension method
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CompactHelpCard(
                  title: 'Choosing the Right Type',
                  content: 'Select the appropriate medication type for accurate tracking:',
                  icon: Icons.help_outline,
                  steps: [
                    'Tablets: For solid pills that you swallow whole',
                    'Capsules: For gelatin capsules with powder/liquid inside',
                    'Injections: For medications administered via needle',
                  ],
                ).makeCollapsible(initiallyExpanded: false),
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // Tablet option
                    _buildTypeCard(
                      context,
                      title: 'Tablet',
                      description: 'Pills, tablets, or other solid oral medications',
                      icon: Icons.local_pharmacy,
                      color: Colors.blue,
                      type: MedicationType.tablet,
                    ),
                    
                    // Capsule option
                    _buildTypeCard(
                      context,
                      title: 'Capsule',
                      description: 'Gelatin capsules containing medicine',
                      icon: Icons.medication,
                      color: Colors.orange,
                      type: MedicationType.capsule,
                    ),
                    
                    // Injection option (merged)
                    _buildTypeCard(
                      context,
                      title: 'Injection',
                      description: 'Vials, ampoules, or pre-filled syringes',
                      icon: Icons.vaccines,
                      color: Colors.teal,
                      type: MedicationType.injection,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 