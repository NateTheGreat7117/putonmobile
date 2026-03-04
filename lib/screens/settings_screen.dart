import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Toggle states
  bool privateProfile = false;
  bool hideSaved = false;
  bool showFollowing = true;
  bool showFollowers = true;
  bool darkMode = false;
  bool pushNotifications = false;
  bool emailUpdates = false;
  bool showRecommendations = false;

  // Dropdown values
  String shirtSize = 'Select size';
  String shoeSize = 'Select size';
  String preferredStyle = 'All Styles';
  String language = 'en';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _profileService.getCurrentUserProfile();
      
      if (profile != null) {
        _displayNameController.text = profile['full_name'] ?? '';
        _usernameController.text = profile['username'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _locationController.text = profile['location'] ?? '';
        
        setState(() {
          shirtSize = profile['shirt_size'] ?? 'Select size';
          shoeSize = profile['shoe_size'] ?? 'Select size';
          privateProfile = profile['private_profile'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      final success = await _profileService.updateProfile({
        'full_name': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'shirt_size': shirtSize,
        'shoe_size': shoeSize,
        'private_profile': privateProfile,
      });
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Color(0xFF2D5F4C),
          ),
        );
        Navigator.pop(context, true); // Return true to trigger profile reload
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2D5F4C),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5F4C),
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5F4C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account and preferences',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Account Settings
              _buildSection(
                'Account Settings',
                Column(
                  children: [
                    _buildTextField('Display Name', _displayNameController),
                    _buildTextField('Username', _usernameController),
                    _buildTextField('Email Address', _emailController,
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField('Bio', _bioController,
                        maxLines: 3, hint: 'Tell us about yourself...'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Location', _locationController,
                              hint: 'City, Country'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField('Birthday'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Clothing Measurements
              _buildSection(
                'Clothing Measurements',
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Shirt Size',
                            shirtSize,
                            ['Select size', 'XS', 'S', 'M', 'L', 'XL', 'XXL'],
                            (value) => setState(() => shirtSize = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'Shoe Size (US)',
                            shoeSize,
                            ['Select size', '7', '8', '9', '10', '11', '12'],
                            (value) => setState(() => shoeSize = value!),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField('Waist (inches)', 'inches'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField('Inseam (inches)', 'inches'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField('Chest (inches)', 'inches'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField('Height (cm)', 'cm'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Privacy & Display
              _buildSection(
                'Privacy & Display',
                Column(
                  children: [
                    _buildToggle(
                      'Private Profile',
                      'Only followers can see your posts',
                      privateProfile,
                      (value) => setState(() => privateProfile = value),
                    ),
                    _buildToggle(
                      'Hide Saved Content',
                      'Keep your saved posts private from your profile',
                      hideSaved,
                      (value) => setState(() => hideSaved = value),
                    ),
                    _buildToggle(
                      'Show Following List',
                      'Let others see who you follow',
                      showFollowing,
                      (value) => setState(() => showFollowing = value),
                    ),
                    _buildToggle(
                      'Show Followers List',
                      'Let others see your followers',
                      showFollowers,
                      (value) => setState(() => showFollowers = value),
                    ),
                  ],
                ),
              ),

              // App Preferences
              _buildSection(
                'App Preferences',
                Column(
                  children: [
                    _buildToggle(
                      'Dark Mode',
                      'Switch between light and dark theme',
                      darkMode,
                      (value) => setState(() => darkMode = value),
                    ),
                    _buildToggle(
                      'Push Notifications',
                      'Receive notifications about new posts and followers',
                      pushNotifications,
                      (value) => setState(() => pushNotifications = value),
                    ),
                    _buildToggle(
                      'Email Updates',
                      'Get weekly updates about new styles and trends',
                      emailUpdates,
                      (value) => setState(() => emailUpdates = value),
                    ),
                    _buildToggle(
                      'Show Size Recommendations',
                      'Get personalized size suggestions when shopping',
                      showRecommendations,
                      (value) => setState(() => showRecommendations = value),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      'Preferred Style',
                      preferredStyle,
                      ['All Styles', 'Streetwear', 'Formal', 'Casual', 'Athletic', 'Vintage'],
                      (value) => setState(() => preferredStyle = value!),
                    ),
                    _buildDropdown(
                      'Language',
                      language,
                      ['en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh'],
                      (value) => setState(() => language = value!),
                      displayNames: {
                        'en': 'English',
                        'es': 'Español',
                        'fr': 'Français',
                        'de': 'Deutsch',
                        'it': 'Italiano',
                        'pt': 'Português',
                        'ja': '日本語',
                        'ko': '한국어',
                        'zh': '中文',
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5F4C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log Out'),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await _authService.signOut();
                              if (context.mounted) {
                                // Close the dialog
                                Navigator.of(context).pop();
                                // Close the settings screen
                                Navigator.of(context).pop();
                                // The AuthWrapper's StreamBuilder will automatically
                                // detect the auth state change and show AuthScreen
                              }
                            },
                            child: const Text(
                              'Log Out',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F4C),
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF2D5F4C),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select date',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    Map<String, String>? displayNames,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(displayNames?[item] ?? item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: suffix,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF2D5F4C),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF2D5F4C),
          ),
        ],
      ),
    );
  }
}