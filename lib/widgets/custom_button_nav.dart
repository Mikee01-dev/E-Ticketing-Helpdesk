import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      elevation: 2,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[600],
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Tiket',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notif',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}