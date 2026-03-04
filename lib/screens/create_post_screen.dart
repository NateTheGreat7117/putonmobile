import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/models.dart';
import '../services/wardrobe_service.dart';
import '../widgets/brand_selector.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _wardrobeService = WardrobeService();
  
  File? _selectedImage;
  bool _isUploading = false;
  final List<String> _selectedStyles = [];
  final List<String> _selectedSeasons = [];
  final List<String> _selectedOccasions = [];
  final List<ClothingItem> _taggedItems = [];
  List<ClothingItem> _wardrobeItems = [];
  bool _showTips = true;

  final List<String> _styles = [
    'Streetwear',
    'Casual',
    'Formal',
    'Business Casual',
    'Athleisure',
    'Vintage',
    'Minimalist',
    'Bohemian',
    'Preppy',
    'Grunge',
    'Y2K',
    'Techwear',
  ];
  final List<String> _seasons = ['Spring', 'Summer', 'Fall', 'Winter'];
  final List<String> _occasions = [
    'Date Night',
    'Beach',
    'Gym/Workout',
    'Office',
    'Party',
    'Brunch',
    'Travel',
    'Concert',
    'Wedding',
    'Casual Hangout',
    'Interview',
    'Festival',
  ];

  @override
  void initState() {
    super.initState();
    _loadWardrobeItems();
  }

  Future<void> _loadWardrobeItems() async {
    final items = await _wardrobeService.getWardrobeItems();
    if (mounted) {
      setState(() {
        _wardrobeItems = items;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF2D5F4C)),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2D5F4C)),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectItemDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Items',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Add New Item Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddItemDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5F4C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Create New Item',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'From Your Wardrobe',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Wardrobe Items Grid
              Expanded(
                child: _wardrobeItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No items in wardrobe',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _wardrobeItems.length,
                        itemBuilder: (context, index) {
                          final item = _wardrobeItems[index];
                          final isSelected = _taggedItems.any((i) => i.id == item.id);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _taggedItems.removeWhere((i) => i.id == item.id);
                                } else {
                                  _taggedItems.add(item);
                                }
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2D5F4C)
                                      : Colors.white24,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildWardrobeItemImage(item.imageUrl),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2D5F4C),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWardrobeItemImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF2D2D2D),
        child: const Icon(Icons.checkroom, color: Colors.white54),
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF2D2D2D),
            child: const Icon(Icons.broken_image, color: Colors.white54),
          );
        },
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF2D2D2D),
      child: const Icon(Icons.checkroom, color: Colors.white54),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    String selectedBrand = ''; // Changed from TextEditingController
    final colorController = TextEditingController();
    final sizeController = TextEditingController();
    final minPriceController = TextEditingController();
    final maxPriceController = TextEditingController();
    final purchaseUrlController = TextEditingController();
    String selectedCategory = 'Tops';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Add Item', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: const Color(0xFF2D2D2D),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  items: ['Tops', 'Bottoms', 'Shoes', 'Accessories', 'Outerwear']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Brand',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                BrandSelector(
                  onBrandSelected: (brand) {
                    selectedBrand = brand;
                  },
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2D5F4C)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: colorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sizeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Size',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Price',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Price',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: purchaseUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Purchase URL',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5F4C),
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final item = ClothingItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    category: selectedCategory,
                    name: nameController.text,
                    brand: selectedBrand, // Using the selected brand string
                    color: colorController.text,
                    size: sizeController.text,
                    minPrice: double.tryParse(minPriceController.text) ?? 0,
                    maxPrice: double.tryParse(maxPriceController.text) ?? 0,
                    imageUrl: '',
                    purchaseUrl: purchaseUrlController.text,
                  );
                  setState(() {
                    _taggedItems.add(item);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPost() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Upload image to Supabase Storage
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _selectedImage!.readAsBytes();
      
      await supabase.storage
          .from('outfits')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final imageUrl = supabase.storage
          .from('outfits')
          .getPublicUrl(fileName);

      // Get user profile for username
      final userProfile = await supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      // Insert outfit into database
      final outfitData = {
        'user_id': userId,
        'user_name': userProfile['username'],
        'image_url': imageUrl,
        'tab_category': 'For You',  // Default feed
        'styles': _selectedStyles,
        'seasons': _selectedSeasons,
        'occasions': _selectedOccasions,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'items': _taggedItems.map((item) => {
          'id': item.id,
          'category': item.category,
          'name': item.name,
          'brand': item.brand,
          'color': item.color,
          'size': item.size,
          'minPrice': item.minPrice,
          'maxPrice': item.maxPrice,
          'imageUrl': item.imageUrl,
          'purchaseUrl': item.purchaseUrl,
        }).toList(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('outfits').insert(outfitData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Color(0xFF2D5F4C),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5F4C),
        title: const Text(
          'CREATE POST',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _uploadPost,
              child: const Text(
                'POST',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tips Section
                if (_showTips) _buildTipsSection(),
                
                // Image Section
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 80,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to add photo',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Style Selection (up to 3)
                const Text(
                  'Styles (Select up to 3)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _styles.map((style) {
                    final isSelected = _selectedStyles.contains(style);
                    return FilterChip(
                      label: Text(style),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected && _selectedStyles.length < 3) {
                            _selectedStyles.add(style);
                          } else if (!selected) {
                            _selectedStyles.remove(style);
                          }
                        });
                      },
                      backgroundColor: const Color(0xFF1A1A1A),
                      selectedColor: const Color(0xFF2D5F4C),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2D5F4C) : Colors.white24,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Season Selection (up to 2)
                const Text(
                  'Seasons (Select up to 2)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _seasons.map((season) {
                    final isSelected = _selectedSeasons.contains(season);
                    return FilterChip(
                      label: Text(season),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected && _selectedSeasons.length < 2) {
                            _selectedSeasons.add(season);
                          } else if (!selected) {
                            _selectedSeasons.remove(season);
                          }
                        });
                      },
                      backgroundColor: const Color(0xFF1A1A1A),
                      selectedColor: const Color(0xFF2D5F4C),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2D5F4C) : Colors.white24,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Occasion Selection (up to 3)
                const Text(
                  'Occasions (Select up to 3)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _occasions.map((occasion) {
                    final isSelected = _selectedOccasions.contains(occasion);
                    return FilterChip(
                      label: Text(occasion),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected && _selectedOccasions.length < 3) {
                            _selectedOccasions.add(occasion);
                          } else if (!selected) {
                            _selectedOccasions.remove(occasion);
                          }
                        });
                      },
                      backgroundColor: const Color(0xFF1A1A1A),
                      selectedColor: const Color(0xFF2D5F4C),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2D5F4C) : Colors.white24,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Tagged Items Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tagged Items',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showSelectItemDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5F4C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text(
                        'Add Item',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_taggedItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Text(
                        _wardrobeItems.isEmpty
                            ? 'Add items to your wardrobe first'
                            : 'Tap "Add Item" to tag items from your wardrobe',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  )
                else
                  ..._taggedItems.map((item) => _buildTaggedItemCard(item)),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D5F4C).withOpacity(0.2),
            const Color(0xFF1A1A1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D5F4C).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFF2D5F4C), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tips for Better Engagement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () => setState(() => _showTips = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('✨', 'Use less well-known brands to earn more points'),
          _buildTip('🏷️', 'Tag every item accurately for better discoverability'),
          _buildTip('🔗', 'Include purchase links for each item'),
          _buildTip('📂', 'Select appropriate categories (Style, Season, Occasion)'),
          _buildTip('📸', 'Use high-quality, well-lit photos'),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaggedItemCard(ClothingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.imageUrl.isNotEmpty && item.imageUrl.startsWith('http')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.checkroom, color: Colors.white54);
                      },
                    ),
                  )
                : const Icon(Icons.checkroom, color: Colors.white54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF2D5F4C),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.brand} • ${item.color}${item.size.isNotEmpty ? ' • ${item.size}' : ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (item.purchaseUrl.isEmpty)
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, size: 12, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'No purchase link',
                        style: TextStyle(color: Colors.orange, fontSize: 10),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              setState(() {
                _taggedItems.remove(item);
              });
            },
          ),
        ],
      ),
    );
  }
}