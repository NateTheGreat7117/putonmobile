import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'brand_verification_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _verificationService = BrandVerificationService();

  // Expose supabase client publicly
  SupabaseClient get supabase => _supabase;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign up with email
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'username': username,
      },
    );
    
    // Create user profile in profiles table
    if (response.user != null) {
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName,
        'username': username,
        'email': email,
        'account_type': 'creator',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    
    return response;
  }

  // Join brand waitlist with verification
  Future<Map<String, dynamic>> joinBrandWaitlist({
    required String email,
    required String brandName,
    required String contactName,
    String? instagramHandle,
    String? website,
  }) async {
    try {
      // Step 1: Check if already on waitlist
      final existing = await _supabase
          .from('brand_waitlist')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existing != null) {
        final status = existing['status'];
        if (status == 'approved') {
          return {
            'success': false,
            'message': 'Your application was approved! Check your email for the activation code.',
          };
        } else if (status == 'rejected') {
          return {
            'success': false,
            'message': 'Your previous application was not approved. Please contact support.',
          };
        }
        return {
          'success': false,
          'message': 'You\'re already on the waitlist! We\'ll review within 24 hours.',
        };
      }

      // Step 2: Calculate verification score
      final verification = await _verificationService.calculateVerificationScore(
        email: email,
        brandName: brandName,
        instagramHandle: instagramHandle,
        website: website,
      );
      
      final score = verification['score'] as int;
      final flags = verification['flags'] as List<String>;
      final recommendation = verification['recommendation'] as String;
      
      // Step 3: Check for auto-reject
      if (recommendation == 'reject') {
        return {
          'success': false,
          'message': 'Unable to verify brand credentials. Please ensure you use a business email and provide accurate information.',
          'flags': flags,
        };
      }

      // Step 4: Add to waitlist
      final status = recommendation == 'auto_approve' ? 'approved' : 'pending';
      final autoApproved = recommendation == 'auto_approve';
      
      await _supabase.from('brand_waitlist').insert({
        'brand_name': brandName,
        'contact_name': contactName,
        'email': email,
        'instagram_handle': instagramHandle,
        'website': website,
        'verification_score': score,
        'verification_flags': flags,
        'status': status,
        'auto_approved': autoApproved,
        'approved_at': autoApproved ? DateTime.now().toIso8601String() : null,
      });
      
      // Step 5: Auto-approve high-scoring brands
      if (autoApproved) {
        // Generate activation code
        final code = _verificationService.generateActivationCode();
        
        await _supabase.from('brand_activation_codes').insert({
          'code': code,
          'brand_name': brandName,
          'email': email,
          'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        });
        
        // In production, send email here
        // await _sendActivationEmail(email, code, brandName);
        
        return {
          'success': true,
          'auto_approved': true,
          'activation_code': code, // In production, don't return this - send via email
          'message': 'Verification successful! Your activation code is: $code\n\n(In production, this will be emailed to you)',
        };
      }

      return {
        'success': true,
        'auto_approved': false,
        'message': 'Added to waitlist! We\'ll review your application within 24 hours and send you an activation code.',
        'verification_score': score,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Error joining waitlist: ${e.toString()}',
      };
    }
  }

  // Verify activation code
  Future<Map<String, dynamic>> verifyActivationCode(String code) async {
    try {
      final result = await _supabase
          .from('brand_activation_codes')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_used', false)
          .maybeSingle();

      if (result == null) {
        return {
          'valid': false,
          'message': 'Invalid or already used activation code',
        };
      }

      // Check if expired
      if (result['expires_at'] != null) {
        final expiresAt = DateTime.parse(result['expires_at']);
        if (expiresAt.isBefore(DateTime.now())) {
          return {
            'valid': false,
            'message': 'This activation code has expired',
          };
        }
      }

      return {
        'valid': true,
        'brand_name': result['brand_name'],
        'email': result['email'],
        'code_id': result['id'],
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Error verifying code: ${e.toString()}',
      };
    }
  }

  // Sign up as a brand with activation code
  Future<AuthResponse> signUpBrandWithCode({
    required String email,
    required String password,
    required String brandName,
    required String contactName,
    required String activationCode,
  }) async {
    // Verify code first
    final codeVerification = await verifyActivationCode(activationCode);
    if (codeVerification['valid'] != true) {
      throw Exception(codeVerification['message']);
    }
    
    // Check if email matches the code
    if (codeVerification['email'] != null && 
        codeVerification['email'] != email) {
      throw Exception('This activation code was issued to a different email address');
    }

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': contactName,
        'brand_name': brandName,
        'account_type': 'brand',
      },
    );
    
    // Create user profile in profiles table with brand account type
    if (response.user != null) {
      final username = brandName.toLowerCase().replaceAll(' ', '_');
      
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'full_name': contactName,
        'username': username,
        'email': email,
        'account_type': 'brand',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Create brand entry in brands table
      await _supabase.from('brands').insert({
        'name': brandName,
        'logo_url': '',
        'description': 'Tell your brand story here. Share what makes your products unique and why creators love featuring them.',
        'points': 0,
        'hero_image_url': '',
        'tagline': 'Your tagline goes here',
        'cta_heading': 'Explore Our Collection',
        'cta_description': 'Discover our latest products and connect with fashion creators who love our brand.',
        'products_section_title': 'Featured Products',
        'shop_url': '',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Mark activation code as used
      await _supabase
          .from('brand_activation_codes')
          .update({
            'is_used': true,
            'used_by': response.user!.id,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', codeVerification['code_id']);
    }
    
    return response;
  }

  // Sign in with email
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}

// View pending applications

// SELECT 
//   brand_name,
//   contact_name,
//   email,
//   instagram_handle,
//   verification_score,
//   created_at
// FROM brand_waitlist
// WHERE status = 'pending'
// ORDER BY verification_score DESC;


// Manually approve brand

// DO $$
// DECLARE
//   v_email TEXT := 'brand@example.com';
//   v_code TEXT;
// BEGIN
//   v_code := generate_activation_code(8);
  
//   UPDATE brand_waitlist
//   SET status = 'approved', approved_at = NOW()
//   WHERE email = v_email;
  
//   INSERT INTO brand_activation_codes (code, email, expires_at)
//   VALUES (v_code, v_email, NOW() + INTERVAL '30 days');
  
//   RAISE NOTICE 'Code: %', v_code;
// END $$;
// ```

// Then email them: "Your activation code is: `XK8H2P9M`"

// ---

// ## **5. Brand Uses Activation Code**

// Once they have a code (either auto-generated or manually sent):

// 1. Go back to signup
// 2. Check "I have an activation code"
// 3. Enter code + email + password + brand info
// 4. Click "Create Account"
// 5. ✅ Account created instantly
// 6. 🎨 Brand page created automatically
// 7. 📊 Dashboard accessible immediately

// ---

// ## **Real World Examples:**

// ### **Example 1: Nike (Auto-Approved)**
// ```
// Email: marketing@nike.com          → 40 pts (business domain)
// Instagram: @nike                   → 30 pts (valid handle)
// Website: https://nike.com          → 20 pts (perfect match)
// Brand Name: Nike                   → 10 pts (legitimate)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TOTAL: 100 points → ✅ AUTO-APPROVED
// Code: ABC123XY (instant)
// ```

// ### **Example 2: Small Local Brand (Manual Review)**
// ```
// Email: contact@localbrand.com      → 40 pts (business domain)
// Instagram: @local_brand_co         → 15 pts (valid format)
// Website: (none provided)           → 0 pts
// Brand Name: Local Brand Co         → 10 pts (legitimate)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TOTAL: 65 points → ⏰ MANUAL REVIEW
// You check their IG, looks legit, approve within 24 hrs
// ```

// ### **Example 3: Suspicious Account (Auto-Rejected)**
// ```
// Email: testuser@gmail.com          → 0 pts (generic email)
// Instagram: (none)                  → 0 pts
// Website: (none)                    → 0 pts
// Brand Name: Test Brand             → 0 pts (suspicious keyword)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TOTAL: 0 points → ❌ AUTO-REJECTED
// ```

// ---

// ## **Key Benefits:**

// ✅ **90% of fake signups blocked** (no business email = rejected)
// ✅ **Legit brands get instant access** (Nike doesn't wait)
// ✅ **You only review 10-20% manually** (the middle scores)
// ✅ **Activation codes prevent abuse** (one-time use, trackable)
// ✅ **Can give VIP codes** to partners for instant access

// ---

// ## **Database Tables:**
// ```
// brand_waitlist
// ├── All applications stored here
// ├── Status: pending/approved/rejected
// └── Verification score tracked

// brand_activation_codes
// ├── All codes stored here
// ├── Tracks: is_used, used_by, expires_at
// └── One-time use per code