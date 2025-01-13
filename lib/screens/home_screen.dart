import 'package:flutter/material.dart';
import 'package:safety_app/screens/emergency_contacts_screen.dart';
import 'package:safety_app/screens/route_map.dart';
import '../routes/app_routes.dart';
import '../widgets/bottom_navbar_widget.dart';
import 'map_screen.dart';

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
       MapScreen(),
       EmergencyContactsScreen(),
       MapRouteScreen(),
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
                  Navigator.pushNamed(context, AppRoutes.settings); // Redirect to settings screen
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
