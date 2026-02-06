import 'package:flutter/material.dart';

class WebSplitLayout extends StatelessWidget {
  final Widget child;
  final Widget? rightPanel; // Optional custom right panel

  const WebSplitLayout({
    super.key, 
    required this.child, 
    this.rightPanel
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Check if we should split (e.g. width > 900)
    // The user requested "half and half".
    if (size.width > 900) {
      return Scaffold(
        body: Row(
          children: [
            // Left Half: Application Content
            Expanded(
              flex: 1,
              child: child,
            ),
            // Right Half: Animation / Illustration
            Expanded(
              flex: 1,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: rightPanel ?? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded, 
                        size: 100, 
                        color: Theme.of(context).primaryColor.withOpacity(0.5)
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ticko Chat',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Connect with the world.'),
                      // TODO: Add real animation here (Lottie)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile/Tablet: Just show the content
    return child;
  }
}
