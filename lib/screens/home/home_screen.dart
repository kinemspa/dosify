import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/medication.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';
import '../../theme/theme_provider.dart';
import '../base_service_screen.dart';
import '../medications/add_medication/add_medication_type_screen.dart';
import '../medications/medication_list_screen.dart';
import '../medications/tools/reconstitution_calculator_screen.dart';
import '../medications/details/medication_detail_screen.dart';
import '../../widgets/upcoming_doses_widget.dart';

class HomeScreen extends BaseServiceScreen {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends BaseServiceScreenState<HomeScreen> {
  int _selectedIndex = 0;

  // Method to navigate to a specific tab
  void navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if we need to navigate to a specific tab based on route settings
    final settings = ModalRoute.of(context)?.settings;
    if (settings != null && settings.name != null) {
      switch (settings.name) {
        case '/medications':
          setState(() {
            _selectedIndex = 1;
          });
          break;
        case '/schedule':
          setState(() {
            _selectedIndex = 2;
          });
          break;
        case '/settings':
          setState(() {
            _selectedIndex = 3;
          });
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            _getScreenTitle(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        elevation: 0,
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkPrimary
                  : AppColors.lightPrimary,
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkPrimaryDark
                  : AppColors.lightPrimaryDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication),
              label: 'Medications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Medications';
      case 2:
        return 'Schedule';
      case 3:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }
  
  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardPage();
      case 1:
        return const MedicationListScreen();
      case 2:
        return const SchedulePage();
      case 3:
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }
  
  Widget? _buildFloatingActionButton() {
    if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicationTypeScreen(),
            ),
          );
        },
        backgroundColor: AppColors.actionButton,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
}

class DashboardPage extends BaseServiceScreen {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends BaseServiceScreenState<DashboardPage> {
  int _selectedStatIndex = 0;
  bool _isLoading = true;
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
    _initializeFirebase();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _showWelcome = prefs.getBool('first_launch') ?? true;
    if (_showWelcome) {
      await prefs.setBool('first_launch', false);
    }
    setState(() {});
  }

  Future<void> _initializeFirebase() async {
    try {
      await firebaseService.initialize();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Widget _buildMedicationListItem(BuildContext context, Medication medication) {
    IconData icon;
    Color color;

    switch (medication.type) {
      case MedicationType.tablet:
        icon = Icons.local_pharmacy;
        color = Colors.blue;
        break;
      case MedicationType.capsule:
        icon = Icons.medication;
        color = Colors.orange;
        break;
      case MedicationType.injection:
        icon = Icons.vaccines;
        color = Colors.teal;
        break;
      case MedicationType.preFilledSyringe:
        icon = Icons.vaccines;
        color = Colors.green;
        break;
      case MedicationType.vialPreMixed:
        icon = Icons.science;
        color = Colors.purple;
        break;
      case MedicationType.vialPowderedKnown:
        icon = Icons.science;
        color = Colors.deepPurple;
        break;
      case MedicationType.vialPowderedRecon:
        icon = Icons.science;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.medication;
        color = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          medication.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${medication.currentInventory.toInt()} ${medication.quantityUnit} in stock',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicationDetailScreen(
                medication: medication,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.screenBackground(context),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              if (_showWelcome) ...[
                Text(
                  'Welcome to Dosify',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your medication management assistant',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Upcoming Doses Section
              _buildSectionHeader(
                context,
                'Upcoming Doses',
                Icons.schedule,
                Colors.purple,
              ),
              const SizedBox(height: 8),
              Card(
                child: SizedBox(
                  height: 300, // Fixed height for the upcoming doses list
                  child: UpcomingDosesWidget(
                    daysToShow: 7, // Show doses for the next week
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Recent Medications Section
              _buildSectionHeader(
                context,
                'Your Medications',
                Icons.medication,
                AppColors.primary,
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Medication>>(
                stream: firebaseService.getMedications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading medications: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final medications = snapshot.data ?? [];

                  if (medications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.medication_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No medications added yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddMedicationTypeScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('ADD MEDICATION'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...medications
                          .take(5) // Show only the first 5 medications
                          .map((medication) => _buildMedicationListItem(context, medication))
                          .toList(),
                      if (medications.length > 5)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            onPressed: () {
                                                              // Navigate to medications tab
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                    settings: const RouteSettings(name: '/medications'),
                                  ),
                                );
                            },
                            child: const Text('VIEW ALL MEDICATIONS'),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Tools Section
              _buildSectionHeader(
                context,
                'Tools',
                Icons.build,
                Colors.teal,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calculate,
                          color: Colors.teal,
                          size: 24,
                        ),
                      ),
                      title: const Text('Reconstitution Calculator'),
                      subtitle: const Text('Calculate powder to liquid ratios'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReconstitutionCalculatorScreen(),
                          ),
                        );
                      },
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
  
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.screenBackground(context),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming Doses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No scheduled doses',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a medication and create a schedule to see it here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import '../settings/settings_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
