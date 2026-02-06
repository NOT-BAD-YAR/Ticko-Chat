import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';

class OnlineUsersScreen extends StatelessWidget {
  const OnlineUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SocketService>(
      builder: (context, socketService, _) {
        final onlineUserIds = socketService.onlineUsers;
        
        // In a real app, you would fetch user details (name/avatar) based on these IDs
        // For now, we display the truncated ID or "User [ID]"
        
        if (onlineUserIds.isEmpty) {
            return const Center(child: Text('No users online'));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Online Users')), // Optional local AppBar
          body: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: onlineUserIds.length,
            itemBuilder: (context, index) {
              final userId = onlineUserIds[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.person),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    'User ID: ${userId.substring(0, 6)}...', // Placeholder for name
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Online',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      // TODO: Start chat with this user
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
