import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/help_card.dart';
import 'ampule_medication_screen.dart';
import 'cartridge_medication_screen.dart';
import 'liquid_vial_medication_screen.dart';
import 'powder_vial_medication_screen.dart';
import 'prefilled_pen_medication_screen.dart';
import 'prefilled_syringe_medication_screen.dart';

class InjectionTypeSelectionScreen extends StatelessWidget {
  const InjectionTypeSelectionScreen({super.key});

  void _navigateToInjectionScreen(BuildContext context, Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    
    // If a medication was added, pass the result back to refresh the list
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildInjectionTypeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToInjectionScreen(context, screen),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
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
              'Select Injection Type',
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
                  'Choose Injection Type',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              
              // Help card for injection type selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CompactHelpCard(
                  title: 'Selecting the Right Type',
                  content: 'Choose the appropriate injection type for accurate tracking:',
                  icon: Icons.help_outline,
                  steps: [
                    'Solution Vials: Liquid medication in vials',
                    'Powdered Vials: Need reconstitution before use',
                    'Pre-filled Syringes: Ready-to-use single syringes',
                    'Pre-filled Pens: Pen devices with pre-loaded medication',
                    'Cartridges: For reusable pen devices',
                    'Ampules: Single-use glass containers'
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // Section: Vials
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        'Vials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    
                    // Solution Vial option
                    _buildInjectionTypeCard(
                      context: context,
                      title: 'Solution Vial',
                      description: 'Ready-to-use liquid medication in a vial',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                      screen: const LiquidVialMedicationScreen(),
                    ),
                    
                    // Powder Vial option
                    _buildInjectionTypeCard(
                      context: context,
                      title: 'Powdered Vial',
                      description: 'Medication that needs reconstitution',
                      icon: Icons.science,
                      color: Colors.purple,
                      screen: const PowderVialMedicationScreen(),
                    ),
                    
                    // Section: Pre-filled Devices
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(
                        'Pre-filled Devices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    
                    // Pre-filled Syringe option
                    _buildInjectionTypeCard(
                      context: context,
                      title: 'Pre-filled Syringe',
                      description: 'Ready-to-use medication in a syringe',
                      icon: Icons.vaccines,
                      color: Colors.teal,
                      screen: const PrefilledSyringeMedicationScreen(),
                    ),
                    
                    // Pre-filled Pen option
                    _buildInjectionTypeCard(
                      context: context,
                      title: 'Pre-filled Pen',
                      description: 'Ready-to-use medication in a pen device',
                      icon: Icons.edit,
                      color: Colors.green,
                      screen: const PrefilledPenMedicationScreen(),
                    ),
                    
                    // Section: Other Formats
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(
                        'Other Formats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    
                    // Cartridge option
                    _buildInjectionTypeCard(
                      context: context,
                      title: 'Cartridge',
                      description: 'For reusable pen devices',
                      icon: Icons.battery_std,
                      color: Colors.amber,
                      screen: const CartridgeMedicationScreen(),
                    ),
                    
                    // Ampule option
                    _buildInjectionTypeCard(
                      context: context,
                      title: 'Ampule',
                      description: 'Single-use glass container',
                      icon: Icons.water_drop,
                      color: Colors.cyan,
                      screen: const AmpuleMedicationScreen(),
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