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

class _BottomNavBarWidgetState extends State<BottomNavBarWidget> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Navigation Bar
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  icon: Icons.emergency_rounded,
                  isSelected: widget.currentIndex == 0,
                  onTap: () => widget.onTap(0),
                ),
                _buildNavItem(
                  icon: Icons.groups_outlined,
                  isSelected: widget.currentIndex == 1,
                  onTap: () => widget.onTap(1),
                ),
                // Placeholder for FAB
                SizedBox(width: 60),
                _buildNavItem(
                  icon: Icons.route_outlined,
                  isSelected: widget.currentIndex == 3,
                  onTap: () => widget.onTap(3),
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  isSelected: widget.currentIndex == 4,
                  onTap: () => widget.onTap(4),
                ),
              ],
            ),
          ),
        ),
        // Floating Action Button
        Positioned(
          top: -5,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => widget.onTap(2),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emergency_share,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (_isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected
              ? (_isDarkMode ? Colors.white : Colors.black87)
              : (_isDarkMode ? Colors.white38 : Colors.black38),
        ),
      ),
    );
  }
}

// Add this to your constants.dart file:
/*
const primaryColor = Color(0xFF7E3EE8);
const secondaryColor = Color(0xFF1A1A1A);
*/