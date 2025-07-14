import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_decorations.dart';
import 'add_tablet_medication_screen.dart';
import 'add_capsule_medication_screen.dart';
import 'add_injection_medication_screen.dart';

class AddMedicationTypeScreen extends StatelessWidget {
  const AddMedicationTypeScreen({super.key});

  void _navigateToMedicationForm(BuildContext context, MedicationType type) {
    Widget screen;
    switch (type) {
      case MedicationType.tablet:
        screen = const AddTabletMedicationScreen();
        break;
      case MedicationType.capsule:
        screen = const AddCapsuleMedicationScreen();
        break;
      case MedicationType.injection:
        screen = const AddInjectionMedicationScreen();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
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
        onTap: () => _navigateToMedicationForm(context, type),
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
        title: const Text('Add Medication'),
      ),
      body: Container(
        decoration: AppDecorations.gradientBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Medication Type',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Choose the type of medication you want to add',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
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
        ),
      ),
    );
  }
} 