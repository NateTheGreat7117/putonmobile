import 'package:http/http.dart' as http;
import 'dart:convert';

class BrandVerificationService {
  
  /// Calculate verification score for a brand
  Future<Map<String, dynamic>> calculateVerificationScore({
    required String email,
    required String brandName,
    String? instagramHandle,
    String? website,
  }) async {
    int score = 0;
    List<String> flags = [];
    Map<String, dynamic> details = {};
    
    // Check 1: Business email domain (40 points)
    final emailCheck = _verifyBusinessEmail(email, brandName);
    score += emailCheck['points'] as int;
    if (emailCheck['flag'] != null) {
      flags.add(emailCheck['flag'] as String);
    }
    details['email_verified'] = emailCheck['verified'];
    
    // Check 2: Instagram account (30 points)
    if (instagramHandle != null && instagramHandle.isNotEmpty) {
      final igCheck = await _verifyInstagramAccount(instagramHandle);
      score += igCheck['points'] as int;
      if (igCheck['flag'] != null) {
        flags.add(igCheck['flag'] as String);
      }
      details['instagram_followers'] = igCheck['followers'];
      details['instagram_verified'] = igCheck['verified'];
    } else {
      flags.add('No Instagram handle provided');
    }
    
    // Check 3: Website matches domain (20 points)
    if (website != null && website.isNotEmpty) {
      final websiteCheck = _verifyWebsite(website, email);
      score += websiteCheck['points'] as int;
      if (websiteCheck['flag'] != null) {
        flags.add(websiteCheck['flag'] as String);
      }
      details['website_verified'] = websiteCheck['verified'];
    }
    
    // Check 4: Brand name legitimacy (10 points)
    final nameCheck = _verifyBrandName(brandName);
    score += nameCheck['points'] as int;
    if (nameCheck['flag'] != null) {
      flags.add(nameCheck['flag'] as String);
    }
    
    // Determine recommendation
    String recommendation;
    if (score >= 70) {
      recommendation = 'auto_approve';
    } else if (score >= 40) {
      recommendation = 'manual_review';
    } else {
      recommendation = 'reject';
    }
    
    return {
      'score': score,
      'flags': flags,
      'recommendation': recommendation,
      'details': details,
    };
  }
  
  /// Check if email is a business domain
  Map<String, dynamic> _verifyBusinessEmail(String email, String brandName) {
    final domain = email.split('@').last.toLowerCase();
    
    // Generic email providers (0 points)
    final genericDomains = [
      'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
      'icloud.com', 'aol.com', 'protonmail.com', 'mail.com',
      'proton.me', 'zoho.com', 'yandex.com', 'gmx.com'
    ];
    
    if (genericDomains.contains(domain)) {
      return {
        'points': 0,
        'flag': 'Using generic email provider',
        'verified': false,
      };
    }
    
    // Check if domain matches brand name
    final cleanBrandName = brandName.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanDomain = domain.split('.')[0];
    
    // Exact or close match (40 points)
    if (cleanDomain.contains(cleanBrandName) || 
        cleanBrandName.contains(cleanDomain)) {
      return {
        'points': 40,
        'flag': null,
        'verified': true,
      };
    }
    
    // Business email but doesn't match brand (25 points + flag)
    return {
      'points': 25,
      'flag': 'Email domain doesn\'t match brand name',
      'verified': false,
    };
  }
  
  /// Verify Instagram account exists and check followers
  Future<Map<String, dynamic>> _verifyInstagramAccount(String handle) async {
    try {
      // Remove @ if present
      final cleanHandle = handle.replaceAll('@', '').trim();
      
      if (cleanHandle.isEmpty) {
        return {
          'points': 0,
          'flag': 'Invalid Instagram handle',
          'followers': 0,
          'verified': false,
        };
      }
      
      // For now, we'll do basic validation
      // In production, you'd want to use Instagram's API or a service like:
      // - Instagram Basic Display API
      // - Third-party services (RapidAPI, etc.)
      
      // Basic validation: check if handle is valid format
      final validFormat = RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(cleanHandle);
      
      if (!validFormat) {
        return {
          'points': 0,
          'flag': 'Invalid Instagram handle format',
          'followers': 0,
          'verified': false,
        };
      }
      
      // Placeholder: In production, fetch actual follower count
      // For now, award points if handle is properly formatted
      return {
        'points': 15, // Would be 30 if we could verify followers
        'flag': 'Instagram verification pending manual review',
        'followers': 0, // Would be actual count
        'verified': false,
      };
      
    } catch (e) {
      return {
        'points': 0,
        'flag': 'Could not verify Instagram account',
        'followers': 0,
        'verified': false,
      };
    }
  }
  
  /// Verify website matches email domain
  Map<String, dynamic> _verifyWebsite(String website, String email) {
    try {
      // Clean and parse website URL
      String cleanWebsite = website.trim().toLowerCase();
      if (!cleanWebsite.startsWith('http')) {
        cleanWebsite = 'https://$cleanWebsite';
      }
      
      final uri = Uri.parse(cleanWebsite);
      final websiteDomain = uri.host.replaceAll('www.', '');
      final emailDomain = email.split('@').last.toLowerCase();
      
      // Exact match (20 points)
      if (websiteDomain == emailDomain) {
        return {
          'points': 20,
          'flag': null,
          'verified': true,
        };
      }
      
      // Partial match (10 points)
      if (websiteDomain.contains(emailDomain.split('.')[0]) ||
          emailDomain.contains(websiteDomain.split('.')[0])) {
        return {
          'points': 10,
          'flag': 'Website and email domains partially match',
          'verified': false,
        };
      }
      
      // No match (0 points)
      return {
        'points': 0,
        'flag': 'Website doesn\'t match email domain',
        'verified': false,
      };
      
    } catch (e) {
      return {
        'points': 0,
        'flag': 'Invalid website URL',
        'verified': false,
      };
    }
  }
  
  /// Verify brand name is legitimate
  Map<String, dynamic> _verifyBrandName(String brandName) {
    final name = brandName.toLowerCase().trim();
    
    // Check for suspicious keywords
    final suspiciousKeywords = [
      'test', 'fake', 'demo', 'temp', 'sample', 'example',
      'asdf', 'qwerty', '123', 'abc', 'xxx'
    ];
    
    for (final keyword in suspiciousKeywords) {
      if (name.contains(keyword)) {
        return {
          'points': 0,
          'flag': 'Brand name contains suspicious keywords',
        };
      }
    }
    
    // Check minimum length
    if (name.length < 2) {
      return {
        'points': 0,
        'flag': 'Brand name too short',
      };
    }
    
    // Check if contains only special characters
    if (RegExp(r'^[^a-zA-Z0-9]+$').hasMatch(name)) {
      return {
        'points': 0,
        'flag': 'Brand name contains only special characters',
      };
    }
    
    // Looks legitimate (10 points)
    return {
      'points': 10,
      'flag': null,
    };
  }
  
  /// Generate a random activation code
  String generateActivationCode({int length = 8}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    
    for (var i = 0; i < length; i++) {
      code += chars[(random + i) % chars.length];
    }
    
    return code;
  }
}