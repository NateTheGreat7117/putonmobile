import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/brands_service.dart';

class CustomFieldsScreen extends StatefulWidget {
  final Brand brand;

  const CustomFieldsScreen({
    super.key,
    required this.brand,
  });

  @override
  State<CustomFieldsScreen> createState() => _CustomFieldsScreenState();
}

class _CustomFieldsScreenState extends State<CustomFieldsScreen> {
  final _brandsService = BrandsService();
  bool _isLoading = true;
  List<BrandCustomField> _customFields = [];

  // Predefined field templates
  final Map<String, String> _fieldTemplates = {
    'Founded': 'YYYY',
    'Headquarters': 'City, State/Country',
    'Philosophy': 'Your brand philosophy...',
    'Price Range': '\$ - \$\$\$',
    'Sustainability': 'Our sustainability practices...',
    'Materials': 'Primary materials used...',
    'Manufacturing': 'Where products are made...',
    'Size Range': 'XS - XXL',
    'Target Audience': 'Who we design for...',
    'Brand Values': 'What we stand for...',
    'Certifications': 'B-Corp, Fair Trade, etc.',
    'Shipping': 'Worldwide, US Only, etc.',
    'Return Policy': '30 days, 60 days, etc.',
    'Social Impact': 'How we give back...',
    'Designer/Founder': 'Name of founder...',
    'Year Established': 'YYYY',
    'Style': 'Minimalist, Streetwear, etc.',
    'Specialty': 'What we\'re known for...',
  };

  @override
  void initState() {
    super.initState();
    _loadCustomFields();
  }

  Future<void> _loadCustomFields() async {
    setState(() => _isLoading = true);

    try {
      final fields = await _brandsService.getBrandCustomFields(widget.brand.id);
      if (mounted) {
        setState(() {
          _customFields = fields;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading custom fields: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddFieldDialog() async {
    String? selectedTemplate;
    String? customLabel;
    final valueController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a field type:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTemplate,
                  decoration: InputDecoration(
                    hintText: 'Select field type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    ..._fieldTemplates.keys.map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        )),
                    const DropdownMenuItem(
                      value: 'custom',
                      child: Text('Custom Field'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTemplate = value;
                      if (value != null && value != 'custom') {
                        valueController.text = _fieldTemplates[value] ?? '';
                      }
                    });
                  },
                ),
                if (selectedTemplate == 'custom') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Field Label',
                      hintText: 'e.g., "Store Locations"',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      customLabel = value;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: 'Value',
                    hintText: selectedTemplate != null && selectedTemplate != 'custom'
                        ? _fieldTemplates[selectedTemplate]
                        : 'Enter value...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedTemplate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a field type'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final label = selectedTemplate == 'custom'
                    ? customLabel
                    : selectedTemplate;

                if (label == null || label.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a field label'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (valueController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a value'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context, {
                  'label': label,
                  'value': valueController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final success = await _brandsService.addBrandCustomField(
        brandId: widget.brand.id,
        label: result['label']!,
        value: result['value']!,
      );

      if (success) {
        _loadCustomFields();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Field added successfully!'),
              backgroundColor: Color(0xFF2D5F4C),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add field'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editField(BrandCustomField field) async {
    final valueController = TextEditingController(text: field.value);

    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${field.label}'),
        content: TextFormField(
          controller: valueController,
          decoration: InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, valueController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue != null && newValue.isNotEmpty) {
      final success = await _brandsService.updateBrandCustomField(
        fieldId: field.id,
        value: newValue,
      );

      if (success) {
        _loadCustomFields();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Field updated successfully!'),
              backgroundColor: Color(0xFF2D5F4C),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteField(BrandCustomField field) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text('Are you sure you want to delete "${field.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final success = await _brandsService.deleteBrandCustomField(field.id);
      if (success) {
        _loadCustomFields();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${field.label} deleted'),
              backgroundColor: const Color(0xFF2D5F4C),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        title: const Text(
          'Brand Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadCustomFields,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : Column(
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add details about your brand to help customers learn more about you',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Fields list
                Expanded(
                  child: _customFields.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _customFields.length,
                          itemBuilder: (context, index) {
                            return _buildFieldCard(_customFields[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFieldDialog,
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Field',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'No Information Added',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add details like founding year, headquarters, philosophy, and more',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showAddFieldDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Field'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(BrandCustomField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  field.value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: const Color(0xFFFF6B35),
                onPressed: () => _editField(field),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                onPressed: () => _deleteField(field),
              ),
            ],
          ),
        ],
      ),
    );
  }
}