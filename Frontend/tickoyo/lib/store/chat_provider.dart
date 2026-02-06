import 'package:flutter/foundation.dart';

class ChatProvider with ChangeNotifier {
  Map<String, dynamic>? _selectedUser;
  List<dynamic> _onlineUsers = [];
  int _currentTabIndex = 0;

  Map<String, dynamic>? get selectedUser => _selectedUser;
  List<dynamic> get onlineUsers => _onlineUsers;
  int get currentTabIndex => _currentTabIndex;

  void setSelectedUser(Map<String, dynamic>? user) {
    _selectedUser = user;
    if (user != null) {
      _currentTabIndex = 0; // Switch to Home tab (where Chat is visible)
    }
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void setOnlineUsers(List<dynamic> users) {
    _onlineUsers = users;
    notifyListeners();
  }
}
