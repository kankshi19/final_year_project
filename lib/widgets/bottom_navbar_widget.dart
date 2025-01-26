import 'package:flutter/material.dart';
import 'package:safety_app/utils/constants.dart';

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

class _BottomNavBarWidgetState extends State<BottomNavBarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedIcon(IconData icon, bool isSelected) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected 
            ? 1 + _animationController.value * 0.3 
            : 1.0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected 
                ? primaryColor.withOpacity(0.2) 
                : Colors.transparent,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: primaryColor,
              size: isSelected ? 28 : 24,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          currentIndex: widget.currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            _animationController.reset();
            _animationController.forward();
            widget.onTap(index);
          },
          items: [
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.home, widget.currentIndex == 0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.find_in_page, widget.currentIndex == 1),
              label: 'Support',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.map, widget.currentIndex == 2),
              label: 'SafeRoute',
            ),
          ],
        ),
      ),
    );
  }
}