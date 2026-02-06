import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../store/auth_provider.dart';
import '../store/chat_provider.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),      // Index 0: Home (User List + Chat on Web)
    const ProfileScreen(),   // Index 1: Profile
    const SettingsScreen(),  // Index 2: Settings
  ];

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    if (auth.user != null && auth.user!['_id'] != null) {
      socketService.connect(auth.user!['_id']);
      socketService.addListener(() {
        if (mounted) {
           Provider.of<ChatProvider>(context, listen: false).setOnlineUsers(socketService.onlineUsers);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    // Responsive Web Layout
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          // Master-Detail Layout
          return Scaffold(
            body: Row(
              children: [
                // Left Panel: Navigation + User List
                Expanded(
                  flex: 4, // 40% width
                  child: Scaffold(
                     // We can reuse HomeScreen structure or wrap it. 
                     // Since HomeScreen has its own AppBar/Scaffold, we might need to handle it carefully.
                     // Assuming HomeScreen renders a list. 
                     // Ideally we refactor HomeScreen to be a widget without Scaffold for this use case, 
                     // but for now let's just use it.
                     body: _screens[chatProvider.currentTabIndex],
                     bottomNavigationBar: NavigationBar(
                      selectedIndex: chatProvider.currentTabIndex,
                      onDestinationSelected: (index) {
                        chatProvider.setTabIndex(index);
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.people_outline),
                          selectedIcon: Icon(Icons.people),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ),
                // Vertical Divider
                const VerticalDivider(width: 1),
                // Right Panel: Active Chat or Placeholder
                Expanded(
                  flex: 6, // 60% width
                  child: chatProvider.currentTabIndex == 0
                      ? const ChatScreen()
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 100,
                                color: Theme.of(context).disabledColor.withOpacity(0.2),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                chatProvider.currentTabIndex == 1
                                    ? 'Manage your Profile'
                                    : 'Adjust Settings',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout (Original)
        return Scaffold(
          body: IndexedStack(
            index: chatProvider.currentTabIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: chatProvider.currentTabIndex,
            onDestinationSelected: (index) {
              chatProvider.setTabIndex(index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
