import 'package:flutter/material.dart';
import 'screens/explore_screen.dart';
import 'screens/putons_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'screens/brand_of_week_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'config/supabase_config.dart';
import 'screens/onboarding_screen.dart';
import 'screens/account_type_selection_screen.dart';
import 'screens/brand_onboarding_screen.dart';
import 'screens/brand_dashboard_screen.dart';

// Global key to access MainScreen state from anywhere
final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(const PutOnApp());
}

class PutOnApp extends StatelessWidget {
  const PutOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PutOn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2D5F4C),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5F4C),
          primary: const Color(0xFF2D5F4C),
        ),
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D5F4C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(), // Changed to check auth state
    );
  }
}

// Auth wrapper to check if user is logged in
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseConfig.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D5F4C),
              ),
            ),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return FutureBuilder(
            future: _checkIfNeedsOnboarding(session.user.id),
            builder: (context, onboardingSnapshot) {
              if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2D5F4C),
                    ),
                  ),
                );
              }

              final data = onboardingSnapshot.data;
              final needsOnboarding = data?['needsOnboarding'] ?? false;
              final accountType = data?['accountType'] ?? 'creator';

              if (needsOnboarding) {
                if (accountType == 'brand') {
                  return const BrandOnboardingScreen();
                } else {
                  return const OnboardingScreen();
                }
              } else {
                return MainScreen(key: mainScreenKey);
              }
            },
          );
        } else {
          return const AccountTypeSelectionScreen();
        }
      },
    );
  }

  Future<Map<String, dynamic>> _checkIfNeedsOnboarding(String userId) async {
    try {
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('onboarding_completed, account_type')
          .eq('id', userId)
          .maybeSingle();

      return {
        'needsOnboarding': profile == null || profile['onboarding_completed'] != true,
        'accountType': profile?['account_type'] ?? 'creator',
      };
    } catch (e) {
      print('Error checking onboarding: $e');
      return {
        'needsOnboarding': false,
        'accountType': 'creator',
      };
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isBrandAccount = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccountType();
  }

  Future<void> _checkAccountType() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await SupabaseConfig.client
            .from('profiles')
            .select('account_type')
            .eq('id', userId)
            .single();

        if (mounted) {
          setState(() {
            _isBrandAccount = profile['account_type'] == 'brand';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error checking account type: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Widget> get _screens {
    if (_isBrandAccount) {
      return [
        const ExploreScreen(),
        const PutOnsScreen(),
        const WardrobeScreen(),
        const BrandOfWeekScreen(),
        const BrandDashboardScreen(), // Brand dashboard instead of profile
      ];
    } else {
      return [
        const ExploreScreen(),
        const PutOnsScreen(),
        const WardrobeScreen(),
        const BrandOfWeekScreen(),
        const ProfileScreen(),
      ];
    }
  }

  void navigateToPutOns() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2D5F4C),
          ),
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _isBrandAccount 
            ? const Color(0xFFFF6B35) 
            : const Color(0xFF2D5F4C),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Put Ons',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            activeIcon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            activeIcon: Icon(Icons.star),
            label: 'Brand of Week',
          ),
          BottomNavigationBarItem(
            icon: Icon(_isBrandAccount ? Icons.dashboard_outlined : Icons.person_outline),
            activeIcon: Icon(_isBrandAccount ? Icons.dashboard : Icons.person),
            label: _isBrandAccount ? 'Dashboard' : 'Profile',
          ),
        ],
      ),
    );
  }
}