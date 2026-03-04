import 'package:flutter/material.dart';
import '../services/brands_service.dart';

class BrandSelector extends StatefulWidget {
  final String? initialBrand;
  final Function(String) onBrandSelected;
  final InputDecoration? decoration;

  const BrandSelector({
    super.key,
    this.initialBrand,
    required this.onBrandSelected,
    this.decoration,
  });

  @override
  State<BrandSelector> createState() => _BrandSelectorState();
}

class _BrandSelectorState extends State<BrandSelector> {
  final _brandsService = BrandsService();
  final _customBrandController = TextEditingController();
  
  List<String> _featuredBrands = [];
  String? _selectedBrand;
  bool _isOther = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _customBrandController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoading = true);
    
    final brands = await _brandsService.getFeaturedBrandNames();
    
    if (mounted) {
      setState(() {
        _featuredBrands = brands;
        _isLoading = false;
        
        // Check if initial brand is in the list
        if (widget.initialBrand != null && widget.initialBrand!.isNotEmpty) {
          if (_featuredBrands.contains(widget.initialBrand)) {
            _selectedBrand = widget.initialBrand;
          } else {
            _selectedBrand = 'Other';
            _isOther = true;
            _customBrandController.text = widget.initialBrand!;
          }
        }
      });
    }
  }

  void _handleBrandChange(String? value) {
    setState(() {
      _selectedBrand = value;
      _isOther = value == 'Other';
      
      if (!_isOther) {
        _customBrandController.clear();
        widget.onBrandSelected(value ?? '');
      }
    });
  }

  void _handleCustomBrandChange(String value) {
    widget.onBrandSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(widget.decoration?.border != null ? 12 : 8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedBrand,
          decoration: widget.decoration ?? InputDecoration(
            hintText: 'Select brand...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: [
            ..._featuredBrands.map((brand) => DropdownMenuItem(
              value: brand,
              child: Text(brand), // Simple text, no icon in dropdown items
            )),
            const DropdownMenuItem(
              value: 'Other',
              child: Text('Other (Type your own)'), // Simple text
            ),
          ],
          onChanged: _handleBrandChange,
          // Custom selected item builder to show icon only when selected
          selectedItemBuilder: (BuildContext context) {
            return [
              ..._featuredBrands.map((brand) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: Color(0xFF2D5F4C),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      brand,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text('Other (Type your own)'),
                ],
              ),
            ];
          },
        ),
        if (_isOther) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customBrandController,
            onChanged: _handleCustomBrandChange,
            decoration: InputDecoration(
              hintText: 'Enter brand name...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.edit_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (_isOther && (value == null || value.trim().isEmpty)) {
                return 'Please enter a brand name';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}