import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/home_tab_body.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  final String location;

  const HomeScreen({super.key, required this.child, required this.location});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tabs = ['/home', '/quotes', '/jobs', '/support', '/profile'];

  int get _currentIndex {
    for (int i = 0; i < _tabs.length; i++) {
      if (widget.location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  void _onTap(int index) {
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // The shell child for /home is a placeholder — we render HomeTabBody directly
    final body = widget.location.startsWith('/home')
        ? const HomeTabBody()
        : widget.child;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Home tab — always show HomeTabBody
          const HomeTabBody(),
          // Other tabs — rendered by shell child when active
          if (_currentIndex == 1) widget.child else const _BlankTab(),
          if (_currentIndex == 2) widget.child else const _BlankTab(),
          if (_currentIndex == 3) widget.child else const _BlankTab(),
          if (_currentIndex == 4) widget.child else const _BlankTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote),
            label: 'Quotes',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'My Move',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Support',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _BlankTab extends StatelessWidget {
  const _BlankTab();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
