import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medication.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';
import '../medications/add_medication_type_screen.dart';
import '../medications/medication_list_screen.dart';
import '../medications/reconstitution_calculator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosify'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
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
        return const ProfilePage();
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseService _firebaseService = FirebaseService();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.gradientBackground,
      child: SafeArea(
        child: StreamBuilder<List<Medication>>(
          stream: _firebaseService.getMedications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            
            final medications = snapshot.data ?? [];
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  const Text(
                    'Welcome to Dosify',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track and manage your medications easily',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats cards
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        title: 'Total Medications',
                        value: medications.length.toString(),
                        icon: Icons.medication,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        title: 'Injections',
                        value: medications.where((m) => m.type == MedicationType.injection).length.toString(),
                        icon: Icons.vaccines,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        title: 'Tablets',
                        value: medications.where((m) => m.type == MedicationType.tablet).length.toString(),
                        icon: Icons.local_pharmacy,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        title: 'Capsules',
                        value: medications.where((m) => m.type == MedicationType.capsule).length.toString(),
                        icon: Icons.medication_liquid,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickActionButton(
                        context,
                        icon: Icons.add,
                        label: 'Add Medication',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddMedicationTypeScreen()),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        context,
                        icon: Icons.calculate,
                        label: 'Reconstitution Calculator',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReconstitutionCalculatorScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Recent medications
                  const Text(
                    'Recent Medications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recent medications list
                  if (medications.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No medications added yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: medications.length > 3 ? 3 : medications.length,
                        itemBuilder: (context, index) {
                          final medication = medications[index];
                          return ListTile(
                            leading: _getMedicationIcon(medication.type),
                            title: Text(
                              medication.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${medication.strength} ${medication.strengthUnit}',
                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                            ),
                            trailing: Text(
                              '${medication.currentInventory} ${medication.quantityUnit}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
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
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.secondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _getMedicationIcon(MedicationType type) {
    IconData icon;
    Color color;
    
    switch (type) {
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
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.gradientBackground,
      child: const Center(
        child: Text(
          'Schedule Feature Coming Soon',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _clearAllMedications() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing all medications...';
    });
    
    try {
      await _firebaseService.clearAllMedications();
      
      setState(() {
        _statusMessage = 'All medications cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing medications: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _resetFirestoreStatus() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Resetting Firestore status...';
    });
    
    try {
      await _firebaseService.resetFirestoreStatus();
      
      setState(() {
        _statusMessage = 'Firestore status reset successfully! The app will try to connect to Firestore on the next operation.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error resetting Firestore status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _checkDatabaseStatus() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking database status...';
    });
    
    try {
      bool exists = await _firebaseService.checkDatabaseExists();
      
      setState(() {
        if (exists) {
          _statusMessage = 'Firestore database exists and is accessible! You can use cloud storage.';
        } else {
          _statusMessage = 'Firestore database does not exist or is not accessible. The app will use local storage only.';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking database status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      decoration: AppDecorations.gradientBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Profile Header
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.cardBackground,
                child: Icon(
                  Icons.account_circle,
                  size: 80,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.email ?? "Not signed in",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // Logout Button
              ElevatedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionButton,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
              
              const SizedBox(height: 32),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),
              
              // Database Management Section
              const Text(
                'Database Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'If you are experiencing issues with the app, you can use these tools to manage the database.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              
              // Database Management Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _checkDatabaseStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isLoading && _statusMessage == 'Checking database status...'
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('CHECK DATABASE STATUS'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _clearAllMedications,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isLoading && _statusMessage == 'Clearing all medications...'
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('CLEAR ALL MEDICATIONS'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _resetFirestoreStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isLoading && _statusMessage == 'Resetting Firestore status...'
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('RESET FIRESTORE STATUS'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusMessage.contains('Error')
                        ? Colors.red.withOpacity(0.2)
                        : _statusMessage.contains('not exist')
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('Error')
                          ? Colors.red.shade100
                          : _statusMessage.contains('not exist')
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 