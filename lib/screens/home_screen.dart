import 'package:flutter/material.dart';
import 'package:safety_app/screens/emergency_contacts_screen.dart';
import 'package:safety_app/screens/heart_rate_monitor_screen.dart';
import 'package:safety_app/screens/user_profile.dart';
import '../routes/app_routes.dart';
import '../widgets/hero_banner_widget.dart';
import '../widgets/menu_options_widget.dart';
import '../widgets/bottom_navbar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeContentScreen(),
       EmergencyContactsScreen(),
       HeartRateMonitorScreen(),
       UserProfile()
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('We\'ll help you\nIn any way we can'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.settings); // Redirect to onboarding screen
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomeContentScreen extends StatelessWidget {
  const HomeContentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          HeroBannerWidget(),
          MenuOptionsWidget(),
        ],
      ),
    );
  }
}
