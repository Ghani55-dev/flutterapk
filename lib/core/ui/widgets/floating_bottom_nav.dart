import 'package:flutter/material.dart';

typedef OnTab = void Function(int index);

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final OnTab onTap;

  const FloatingBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: PhysicalModel(
          elevation: 6,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: theme.cardColor.withAlpha((0.9 * 255).round()),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(icon: Icons.home_filled, label: 'Home', index: 0),
                _navItem(icon: Icons.article, label: 'News', index: 1),
                _navItem(icon: Icons.grid_view, label: 'Categories', index: 2),
                _navItem(icon: Icons.play_circle_fill, label: 'Reels', index: 3),
                _navItem(icon: Icons.menu_book, label: 'Epaper', index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final bool active = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: active ? 26 : 22, color: active ? Colors.white : Colors.white70),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.white : Colors.white70)),
          ],
        ),
      ),
    );
  }
}
