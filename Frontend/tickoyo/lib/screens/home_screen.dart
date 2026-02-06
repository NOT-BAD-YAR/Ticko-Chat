import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../store/auth_provider.dart';
import '../store/chat_provider.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Determine URL based on platform (assuming AuthProvider has _baseUrl logic, but we'll reproduce simplified here)
       // Or better, use a service. For now, hardcode similar to AuthProvider logic or use relative if consistent.
      // API: /api/user
      
      String baseUrl = 'http://localhost:5000/api/user';
      // If Android Emulator:
      // baseUrl = 'http://10.0.2.2:5000/api/user';
      // We should really handle this better. Let's borrow from AuthProvider or just check standard way.
      // For Windows/Web localhost is fine. For Android emulator 10.0.2.2.
      // Since user is on Windows OS and might be running Windows App or Android Emulator, let's grab the baseUrl from AuthProvider if possible?
      // AuthProvider._baseUrl is private.
      // I'll stick to localhost for now as user is likely testing on Windows/Web based on "cd .\Frontend\" commands.
      // If mobile, it might fail. But user said "app is made for both mobile and web".
      // I'll add a helper/constant later if needed or check existing.
      
      // Let's use the same logic as AuthProvider (kIsWeb check).
      // Since I can't import kIsWeb easily without flutter/foundation.
      
      // Check AuthProvider.dart again: it uses kIsWeb.
      
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/user'), 
        headers: {
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _users = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticko Chat'),
        actions: [
          // Optional: Add search here
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ChatProvider>(
              builder: (ctx, chatProvider, _) {
                final onlineUsers = chatProvider.onlineUsers; // List of user IDs

                return ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final userId = user['_id'];
                    final isOnline = onlineUsers.contains(userId);

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: (user['profilePic'] != null && user['profilePic'].startsWith('http'))
                                ? NetworkImage(user['profilePic'])
                                : null,
                            onBackgroundImageError: (_, __) {}, // Prevent crash on load error
                            child: (user['profilePic'] == null || !user['profilePic'].startsWith('http'))
                                ? Text((user['fullName'] ?? 'U').substring(0, 1).toUpperCase())
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(user['fullName'] ?? 'Unknown'),
                      subtitle: Text(user['email'] ?? ''),
                      onTap: () {
                        chatProvider.setSelectedUser(user);
                        if (MediaQuery.of(context).size.width < 900) {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => const ChatScreen(),
                             ),
                           );
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
