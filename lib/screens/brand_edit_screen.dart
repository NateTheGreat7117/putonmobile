import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/brands_service.dart';

class BrandEditScreen extends StatefulWidget {
  final Brand brand;

  const BrandEditScreen({
    super.key,
    required this.brand,
  });

  @override
  State<BrandEditScreen> createState() => _BrandEditScreenState();
}

class _BrandEditScreenState extends State<BrandEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandsService = BrandsService();
  
  late TextEditingController _descriptionController;
  late TextEditingController _taglineController;
  late TextEditingController _ctaHeadingController;
  late TextEditingController _ctaDescriptionController;
  late TextEditingController _shopUrlController;
  
  File? _selectedHeroImage;
  File? _selectedLogoImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.brand.description);
    _taglineController = TextEditingController(text: widget.brand.tagline);
    _ctaHeadingController = TextEditingController(text: widget.brand.ctaHeading);
    _ctaDescriptionController = TextEditingController(text: widget.brand.ctaDescription);
    _shopUrlController = TextEditingController(text: widget.brand.shopUrl);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _taglineController.dispose();
    _ctaHeadingController.dispose();
    _ctaDescriptionController.dispose();
    _shopUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isHero) async {
    final ImagePicker picker = ImagePicker();
    
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHero ? 'Choose Hero Image' : 'Choose Logo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        if (isHero) {
          _selectedHeroImage = File(pickedFile.path);
        } else {
          _selectedLogoImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? heroImageUrl;
      String? logoUrl;
      
      // Upload hero image if selected
      if (_selectedHeroImage != null) {
        heroImageUrl = await _brandsService.uploadBrandImage(_selectedHeroImage!, 'hero');
        if (heroImageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload hero image'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      // Upload logo if selected
      if (_selectedLogoImage != null) {
        logoUrl = await _brandsService.uploadBrandImage(_selectedLogoImage!, 'logo');
        if (logoUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload logo'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      final success = await _brandsService.updateBrand(
        brandId: widget.brand.id,
        description: _descriptionController.text.trim(),
        tagline: _taglineController.text.trim(),
        ctaHeading: _ctaHeadingController.text.trim(),
        ctaDescription: _ctaDescriptionController.text.trim(),
        heroImageUrl: heroImageUrl,
        logoUrl: logoUrl,
        shopUrl: _shopUrlController.text.trim(), // ADD THIS LINE
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Brand updated successfully!'),
              backgroundColor: Color(0xFF2D5F4C),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update brand'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        title: const Text(
          'Edit Brand Page',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero Image Section
            _buildImageSection(
              title: 'Hero Image',
              subtitle: 'Large banner image at the top of your brand page',
              currentImageUrl: widget.brand.heroImageUrl,
              selectedImage: _selectedHeroImage,
              onTap: () => _pickImage(true),
            ),
            const SizedBox(height: 24),

            // Logo Section
            _buildImageSection(
              title: 'Brand Logo',
              subtitle: 'Your brand\'s logo (optional)',
              currentImageUrl: widget.brand.logoUrl,
              selectedImage: _selectedLogoImage,
              onTap: () => _pickImage(false),
              isSquare: true,
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 24),

            // Brand Name (Read-only)
            const Text(
              'Brand Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                widget.brand.name,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tagline
            _buildTextField(
              controller: _taglineController,
              label: 'Tagline',
              hint: 'A short, catchy phrase about your brand',
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Brand Description',
              hint: 'Tell the story of your brand...',
              maxLines: 5,
              required: true,
            ),
            const SizedBox(height: 24),

            // CTA Heading
            _buildTextField(
              controller: _ctaHeadingController,
              label: 'Call-to-Action Heading',
              hint: 'Explore Our Collection',
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // CTA Description
            _buildTextField(
              controller: _ctaDescriptionController,
              label: 'Call-to-Action Description',
              hint: 'Experience innovation and performance...',
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Shop URL
            _buildTextField(
              controller: _shopUrlController,
              label: 'Shop URL',
              hint: 'https://yourbrand.com/shop',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 40),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required String subtitle,
    required String currentImageUrl,
    required File? selectedImage,
    required VoidCallback onTap,
    bool isSquare = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
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
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: isSquare ? 150 : 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage,
                      fit: BoxFit.cover,
                    ),
                  )
                : currentImageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          currentImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder(title);
                          },
                        ),
                      )
                    : _buildImagePlaceholder(title),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(String type) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 50,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to add $type',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF6B35),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}