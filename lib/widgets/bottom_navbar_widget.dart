import 'package:flutter/material.dart';
import 'package:safety_app/screens/emergency_contacts_screen.dart';
import 'package:safety_app/screens/route_map.dart';

class BottomNavBarWidget extends StatefulWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const BottomNavBarWidget({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  _BottomNavBarWidgetState createState() => _BottomNavBarWidgetState();
}

class _BottomNavBarWidgetState extends State<BottomNavBarWidget> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap, // This is where you handle the navigation
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.phone),
          label: 'Emergency',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.map),
          label: 'SafeRoute',
        ),
      ],
    );
  }
}
