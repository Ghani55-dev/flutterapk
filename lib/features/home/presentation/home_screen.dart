import 'package:flutter/material.dart';
import 'feed_screen.dart';
import '../../search/presentation/search_screen.dart';
// polls providers are not directly used here; navigation handles tabs
import '../../reels/presentation/reels_screen.dart';
import '../../polls/presentation/polls_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  final List<Widget Function()> _pageFactories = [
    () => const FeedScreen(),
    () => const SearchScreen(),
    () => const ReelsScreen(),
    () => const PollsScreen(),
  ];
  final Map<int, Widget> _pageCache = {};

  Widget _buildPage(int index) {
    return _pageCache[index] ??= _pageFactories[index]();
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onTap(int idx) {
    setState(() => _selectedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: List.generate(_pageFactories.length, (i) => _buildPage(i))),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.video_collection), label: 'Reels'),
            BottomNavigationBarItem(icon: Icon(Icons.poll), label: 'Polls'),
          ],
        ),
      ),
    );
  }
}
