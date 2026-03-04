import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';
import 'brand_onboarding_screen.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  final String accountType; // 'creator' or 'brand'
  
  const AuthScreen({
    super.key,
    this.accountType = 'creator',
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();
  final _activationCodeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _useActivationCode = false;

  bool get isBrandAccount => widget.accountType == 'brand';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _brandNameController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    _activationCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final userId = _authService.supabase.auth.currentUser?.id;
      if (userId == null) return;

      final profile = await _authService.supabase
          .from('profiles')
          .select('onboarding_completed, account_type')
          .eq('id', userId)
          .maybeSingle();

      final needsOnboarding = profile == null || 
                             profile['onboarding_completed'] != true;
      final accountType = profile?['account_type'] ?? 'creator';

      if (mounted) {
        if (needsOnboarding) {
          if (accountType == 'brand') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const BrandOnboardingScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainScreen(key: mainScreenKey)),
          );
        }
      }
    } catch (e) {
      print('Error checking onboarding: $e');
      // Default to main screen on error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainScreen(key: mainScreenKey)),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (isLogin) {
          // Sign in
          await _authService.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          // Navigation handled by AuthWrapper stream
        } else {
          // Sign up
          if (isBrandAccount) {
            if (_useActivationCode) {
              // Sign up with activation code - immediate access
              await _authService.signUpBrandWithCode(
                email: _emailController.text.trim(),
                password: _passwordController.text,
                brandName: _brandNameController.text.trim(),
                contactName: _nameController.text.trim(),
                activationCode: _activationCodeController.text.trim(),
              );
              await _checkOnboardingStatus();
            } else {
              // Join waitlist with verification
              final result = await _authService.joinBrandWaitlist(
                email: _emailController.text.trim(),
                brandName: _brandNameController.text.trim(),
                contactName: _nameController.text.trim(),
                instagramHandle: _instagramController.text.trim(),
                website: _websiteController.text.trim(),
              );
              
              if (mounted) {
                // Show result dialog
                _showWaitlistResultDialog(result);
              }
              return; // Don't proceed with normal signup
            }
          } else {
            // Creator signup
            await _authService.signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
              username: _usernameController.text.trim(),
            );
            await _checkOnboardingStatus();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showWaitlistResultDialog(Map<String, dynamic> result) {
    final success = result['success'] as bool;
    final message = result['message'] as String;
    final autoApproved = result['auto_approved'] as bool? ?? false;
    final activationCode = result['activation_code'] as String?;
    final verificationScore = result['verification_score'] as int?;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? (autoApproved ? Icons.check_circle : Icons.schedule) : Icons.error,
              color: success 
                  ? (autoApproved ? const Color(0xFF2D5F4C) : Colors.orange)
                  : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success 
                    ? (autoApproved ? 'Approved!' : 'On Waitlist')
                    : 'Verification Failed',
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              
              // Auto-approved with activation code
              if (success && autoApproved && activationCode != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5F4C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2D5F4C),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Activation Code:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        activationCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Color(0xFF2D5F4C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Use this code to complete your signup',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              
              // Manual review waitlist
              if (success && !autoApproved) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What happens next?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. We\'ll review your brand\n'
                        '2. Verify your information\n'
                        '3. Approve within 24 hours\n'
                        '4. Send activation code via email',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      if (verificationScore != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Verification Score: $verificationScore/100',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              // Failed verification
              if (!success) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tips for approval:\n'
                    '• Use your official brand email\n'
                    '• Provide your brand Instagram\n'
                    '• Include your website URL\n'
                    '• Ensure information is accurate',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (success && autoApproved && activationCode != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                setState(() {
                  _useActivationCode = true;
                  _activationCodeController.text = activationCode;
                });
              },
              child: const Text('Use Code Now'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (success && !autoApproved) {
                Navigator.pop(context); // Go back to account selection
              }
            },
            child: Text(success && autoApproved ? 'Close' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isBrandAccount ? const Color(0xFFFF6B35) : const Color(0xFF2D5F4C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Account Type Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBrandAccount ? Icons.storefront : Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isBrandAccount ? 'Brand Account' : 'Creator Account',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    isLogin 
                        ? 'Welcome back!' 
                        : (isBrandAccount && !_useActivationCode 
                            ? 'Join the waitlist' 
                            : 'Join the community'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Form container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Toggle between Login and Signup
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isLogin
                                        ? (isBrandAccount ? const Color(0xFFFF6B35) : const Color(0xFF2D5F4C))
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Login',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isLogin ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !isLogin
                                        ? (isBrandAccount ? const Color(0xFFFF6B35) : const Color(0xFF2D5F4C))
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !isLogin ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Brand-specific fields
                        if (!isLogin && isBrandAccount) ...[
                          TextFormField(
                            controller: _brandNameController,
                            decoration: InputDecoration(
                              labelText: 'Brand Name',
                              prefixIcon: const Icon(Icons.storefront),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF6B35),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your brand name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Instagram handle (for waitlist)
                          if (!_useActivationCode) ...[
                            TextFormField(
                              controller: _instagramController,
                              decoration: InputDecoration(
                                labelText: 'Instagram Handle',
                                hintText: '@yourbrand',
                                prefixIcon: const Icon(Icons.camera_alt),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFF6B35),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Website
                            TextFormField(
                              controller: _websiteController,
                              decoration: InputDecoration(
                                labelText: 'Website (Optional)',
                                hintText: 'https://yourbrand.com',
                                prefixIcon: const Icon(Icons.language),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFF6B35),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Toggle for activation code
                          InkWell(
                            onTap: () {
                              setState(() => _useActivationCode = !_useActivationCode);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _useActivationCode,
                                    onChanged: (value) {
                                      setState(() => _useActivationCode = value ?? false);
                                    },
                                    activeColor: const Color(0xFFFF6B35),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'I have an activation code',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Activation code field
                          if (_useActivationCode) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _activationCodeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'Activation Code',
                                prefixIcon: const Icon(Icons.vpn_key),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFF6B35),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (_useActivationCode && (value == null || value.isEmpty)) {
                                  return 'Please enter your activation code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        
                        // Name field (only for signup)
                        if (!isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: isBrandAccount ? 'Contact Name' : 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isBrandAccount ? const Color(0xFFFF6B35) : const Color(0xFF2D5F4C),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Username field (only for creator signup)
                        if (!isLogin && !isBrandAccount) ...[
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: const Icon(Icons.alternate_email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2D5F4C),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: isBrandAccount && !isLogin && !_useActivationCode 
                                ? 'Use your brand email'
                                : null,
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isBrandAccount ? const Color(0xFFFF6B35) : const Color(0xFF2D5F4C),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field (not needed for waitlist)
                        if (!(!isLogin && isBrandAccount && !_useActivationCode)) ...[
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isBrandAccount ? const Color(0xFFFF6B35) : const Color(0xFF2D5F4C),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (!isLogin && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                        ] else
                          const SizedBox(height: 24),
                        
                        // Submit button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBrandAccount ? const Color(0xFFFF6B35) : const Color(0xFF2D5F4C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isLogin 
                                      ? 'Login' 
                                      : (isBrandAccount && !_useActivationCode 
                                          ? 'Join Waitlist' 
                                          : 'Create Account'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        
                        // Waitlist info
                        if (!isLogin && isBrandAccount && !_useActivationCode) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D5F4C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF2D5F4C).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  size: 20,
                                  color: const Color(0xFF2D5F4C),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Use your official brand email for instant approval',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}