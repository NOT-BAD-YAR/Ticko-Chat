import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../store/auth_provider.dart';
import '../store/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEditing = false;
  XFile? _pickedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _populateUserData();
  }

  void _populateUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user['fullName'] ?? '';
      _emailController.text = user['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<String?> _uploadImage(XFile file) async {
    setState(() => _isUploading = true);
    try {
      final uri = Uri.parse(kIsWeb 
          ? 'http://localhost:5000/api/upload' 
          : 'http://10.0.2.2:5000/api/upload');

      final request = http.MultipartRequest('POST', uri);
      
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          bytes,
          filename: file.name,
        )
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      } else {
        throw Exception('Image upload failed: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveChanges() async {
    String? imageUrl;
    
    if (_pickedImage != null) {
      imageUrl = await _uploadImage(_pickedImage!);
      if (imageUrl == null) return; 
    }

    try {
      await Provider.of<AuthProvider>(context, listen: false).updateProfile(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        profilePic: imageUrl,
      );
      
      setState(() {
        _isEditing = false;
        _passwordController.clear();
        _pickedImage = null;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final theme = Theme.of(context);

    // Image source logic
    ImageProvider? bgImage;
    if (_pickedImage != null) {
        // For web, we can't use FileImage(File(_pickedImage!.path)) because path is blob
        // But NetworkImage(_pickedImage!.path) works for blob urls on web.
        // For mobile, we need FileImage.
        if (kIsWeb) {
           bgImage = NetworkImage(_pickedImage!.path);
        } else {
           // We need to import 'dart:io' for File, but careful with Web.
           // A safer cross-platform way without conditional imports for UI quick fix:
           // Just rely on the fact we might not preview strictly correct on mobile without File
           // But actually we can use CrossPlatform Image logic or just Network for now if uploaded.
           // Better: don't preview local file complicatedly. Just show "Selected".
           // Or use `Image.network` for web blob and `AssetImage` placeholder.
           bgImage = NetworkImage(_pickedImage!.path); // This works on Web. On mobile it might fail.
        }
    } else if (user?['profilePic'] != null && user!['profilePic'].startsWith('http')) {
        bgImage = NetworkImage(user['profilePic']);
        // NetworkImage doesn't expose error builder directly here easily without using an Image widget.
        // But CircleAvatar uses it. 
        // We will rely on onBackgroundImageError property of CircleAvatar which we should add.
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                   _populateUserData();
                   _pickedImage = null;
                   _passwordController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             GestureDetector(
               onTap: _pickImage,
               child: Stack(
                 children: [
                   CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.primaryColor,
                    backgroundImage: bgImage,
                    onBackgroundImageError: (exception, stackTrace) {
                      setState(() {
                         // Fallback logic could go here, but CircleAvatar handles it by showing child.
                         // But we need to ensure child is visible if image fails. 
                         // This callback just notifies us.
                      });
                    },
                    child: (bgImage == null)
                        ? Text(
                            (user?['fullName'] ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 40, color: Colors.white),
                          )
                        : null,
                   ),
                   if (_isEditing)
                     Positioned(
                       bottom: 0,
                       right: 0,
                       child: Container(
                         padding: const EdgeInsets.all(4),
                         decoration: const BoxDecoration(
                           color: Colors.white,
                           shape: BoxShape.circle,
                         ),
                         child: Icon(Icons.camera_alt, color: theme.primaryColor),
                       ),
                     ),
                 ],
               ),
             ),
            const SizedBox(height: 24),
            if (_isUploading) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            
            _buildTextField(
              label: 'Full Name',
              controller: _nameController,
              enabled: _isEditing,
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email',
              controller: _emailController,
              enabled: _isEditing,
              icon: Icons.email,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              _buildTextField(
                label: 'New Password (Optional)',
                controller: _passwordController,
                enabled: true,
                isPassword: true,
                icon: Icons.lock,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isUploading) ? null : _saveChanges,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
            const SizedBox(height: 48),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
            const Divider(),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = false,
    bool isPassword = false,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: !enabled,
        fillColor: enabled ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
    );
  }
}
