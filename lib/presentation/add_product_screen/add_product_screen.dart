import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import './widgets/additional_details_widget.dart';
import './widgets/document_upload_widget.dart';
import './widgets/inventory_section_widget.dart';
import './widgets/product_image_upload_widget.dart';
import './widgets/product_information_widget.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Supabase services
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _nutritionalInfoController =
      TextEditingController();
  final TextEditingController _preparationController = TextEditingController();
  final TextEditingController _storageController = TextEditingController();

  // Form State
  List<XFile> _selectedImages = [];
  String _selectedCategory = '';
  String _selectedUnit = 'kg';
  bool _isAvailable = true;
  List<PlatformFile> _uploadedDocuments = [];

  // UI State
  bool _isSaving = false;
  bool _isPublishing = false;
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupFormListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _nutritionalInfoController.dispose();
    _preparationController.dispose();
    _storageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupFormListeners() {
    _nameController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _priceController.addListener(_onFormChanged);
    _stockController.addListener(_onFormChanged);
    _nutritionalInfoController.addListener(_onFormChanged);
    _preparationController.addListener(_onFormChanged);
    _storageController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onImagesChanged(List<XFile> images) {
    setState(() {
      _selectedImages = images;
      _hasUnsavedChanges = true;
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _hasUnsavedChanges = true;
    });
  }

  void _onUnitChanged(String unit) {
    setState(() {
      _selectedUnit = unit;
      _hasUnsavedChanges = true;
    });
  }

  void _onAvailabilityChanged(bool isAvailable) {
    setState(() {
      _isAvailable = isAvailable;
      _hasUnsavedChanges = true;
    });
  }

  void _onDocumentsChanged(List<String> documents) {
    setState(() {
      _uploadedDocuments = documents
          .map((path) => PlatformFile(name: path, path: path, size: 0))
          .toList();
      _hasUnsavedChanges = true;
    });
  }

  bool _validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _publishProduct() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // FIXED: Get actual user ID from Supabase auth
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in to continue.');
      }

      final imageUrls = _selectedImages.isNotEmpty
          ? [
              'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500'
            ]
          : <String>[];

      final documentUrls = _uploadedDocuments.isNotEmpty
          ? ['document_placeholder_url']
          : <String>[];

      final product = Product(
        sellerId: user.id, // FIXED: Use actual user ID
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        unit: _selectedUnit,
        stockQuantity: int.parse(_stockController.text.trim()),
        minimumOrderQuantity: 1,
        isAvailable: true,
        nutritionalInfo: _nutritionalInfoController.text.trim().isNotEmpty
            ? _nutritionalInfoController.text.trim()
            : null,
        preparationInstructions: _preparationController.text.trim().isNotEmpty
            ? _preparationController.text.trim()
            : null,
        storageInstructions: _storageController.text.trim().isNotEmpty
            ? _storageController.text.trim()
            : null,
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        documentUrls: documentUrls.isNotEmpty ? documentUrls : null,
        isApproved: false,
      );

      await _productService.publishProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product published successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to publish product: ${e.toString()}';
        });

        // Show error dialog for better user feedback
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(_errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDraft() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // FIXED: Get actual user ID from Supabase auth
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in to continue.');
      }

      final imageUrls = _selectedImages.isNotEmpty
          ? [
              'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500'
            ]
          : <String>[];

      final documentUrls = _uploadedDocuments.isNotEmpty
          ? ['document_placeholder_url']
          : <String>[];

      final product = Product(
        sellerId: user.id, // FIXED: Use actual user ID
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'Draft Product',
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : 'others',
        price: _priceController.text.trim().isNotEmpty
            ? double.parse(_priceController.text.trim())
            : 0.0,
        unit: _selectedUnit,
        stockQuantity: _stockController.text.trim().isNotEmpty
            ? int.parse(_stockController.text.trim())
            : 0,
        minimumOrderQuantity: 1,
        isAvailable: false,
        nutritionalInfo: _nutritionalInfoController.text.trim().isNotEmpty
            ? _nutritionalInfoController.text.trim()
            : null,
        preparationInstructions: _preparationController.text.trim().isNotEmpty
            ? _preparationController.text.trim()
            : null,
        storageInstructions: _storageController.text.trim().isNotEmpty
            ? _storageController.text.trim()
            : null,
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        documentUrls: documentUrls.isNotEmpty ? documentUrls : null,
        isApproved: false,
      );

      await _productService.saveDraft(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product saved as draft!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save draft: ${e.toString()}';
        });

        // Show error dialog for better user feedback
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(_errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProduct({required bool isDraft}) async {
    // Check if user is authenticated
    if (!_authService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    // For demo purposes, we'll use placeholder URLs for images and documents
    // In a real app, you would upload these to Supabase Storage first
    final imageUrls = _selectedImages.isNotEmpty
        ? ['https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500']
        : <String>[];

    final documentUrls = _uploadedDocuments.isNotEmpty
        ? ['document_placeholder_url']
        : <String>[];

    final productData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'stock': int.tryParse(_stockController.text.trim()) ?? 0,
      'category': _selectedCategory.isNotEmpty ? _selectedCategory : 'other',
      'unit': _selectedUnit,
      'is_available': _isAvailable,
      'nutritional_info': _nutritionalInfoController.text.trim().isNotEmpty
          ? _nutritionalInfoController.text.trim()
          : null,
      'preparation': _preparationController.text.trim().isNotEmpty
          ? _preparationController.text.trim()
          : null,
      'storage': _storageController.text.trim().isNotEmpty
          ? _storageController.text.trim()
          : null,
      'is_draft': isDraft,
      'image_urls': imageUrls,
      'document_urls': documentUrls,
    };

    final product = await _productService.createProduct(productData);

    debugPrint(
        'Product ${isDraft ? 'draft saved' : 'published'}: ${product['id']}');
  }

  void _showSuccessDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.successGreen,
                        size: 48)),
                SizedBox(height: 3.h),
                Text('Product Submitted!',
                    style: AppTheme.lightTheme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
                SizedBox(height: 2.h),
                Text(
                    'Your product "${_nameController.text}" has been submitted for approval. You will be notified once it is approved and live on the marketplace.',
                    style: AppTheme.lightTheme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.mutedText),
                    textAlign: TextAlign.center),
                SizedBox(height: 3.h),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacementNamed(
                              context, '/seller-dashboard-screen');
                        },
                        child: Text('Back to Dashboard'))),
              ]));
        });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Unsaved Changes'),
              content: Text(
                  'You have unsaved changes. Do you want to save them before leaving?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Discard')),
                TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop(true);
                      await _saveDraft();
                    },
                    child: Text('Save Draft')),
              ]);
        });

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            backgroundColor: AppTheme.backgroundLight,
            appBar: AppBar(
                title: Text('Add Product'),
                leading: IconButton(
                    onPressed: () async {
                      if (await _onWillPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 24)),
                actions: [
                  if (_hasUnsavedChanges)
                    TextButton(
                        onPressed: _isSaving ? null : _saveDraft,
                        child: _isSaving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryEmerald)))
                            : Text('Save Draft')),
                  SizedBox(width: 2.w),
                ]),
            body: Column(children: [
              // Progress Indicator
              Container(
                  padding: EdgeInsets.all(4.w),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: LinearProgressIndicator(
                              value: _calculateProgress(),
                              backgroundColor: AppTheme.accentLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryEmerald))),
                      SizedBox(width: 3.w),
                      Text('${(_calculateProgress() * 100).toInt()}%',
                          style: AppTheme.lightTheme.textTheme.labelMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryEmerald)),
                    ]),
                    SizedBox(height: 1.h),
                    Text('Complete all sections to publish your product',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.mutedText)),
                  ])),

              // Form Content
              Expanded(
                  child: SingleChildScrollView(
                      controller: _scrollController,
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      child: Column(children: [
                        // Product Images Section
                        ProductImageUploadWidget(
                            selectedImages: _selectedImages,
                            onImagesSelected: _onImagesChanged),
                        SizedBox(height: 3.h),

                        // Product Information Section
                        ProductInformationWidget(
                            nameController: _nameController,
                            descriptionController: _descriptionController,
                            priceController: _priceController,
                            selectedCategory: _selectedCategory,
                            onCategoryChanged: _onCategoryChanged,
                            formKey: _formKey),
                        SizedBox(height: 3.h),

                        // Inventory Section
                        InventorySectionWidget(
                            stockController: _stockController,
                            selectedUnit: _selectedUnit,
                            isAvailable: _isAvailable,
                            onUnitChanged: _onUnitChanged,
                            onAvailabilityChanged: _onAvailabilityChanged),
                        SizedBox(height: 3.h),

                        // Additional Details Section
                        AdditionalDetailsWidget(
                            nutritionalInfoController:
                                _nutritionalInfoController,
                            preparationController: _preparationController,
                            storageController: _storageController),
                        SizedBox(height: 3.h),

                        // Document Upload Section
                        DocumentUploadWidget(
                            onDocumentsChanged: _onDocumentsChanged),
                        SizedBox(height: 10.h),
                      ]))),
            ]),
            bottomNavigationBar: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.shadowLight,
                          blurRadius: 8,
                          offset: const Offset(0, -2)),
                    ]),
                child: SafeArea(
                    child: Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed:
                              _isSaving || _isPublishing ? null : _saveDraft,
                          child: _isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      AppTheme
                                                          .primaryEmerald))),
                                      SizedBox(width: 2.w),
                                      Text('Saving...'),
                                    ])
                              : Text('Save Draft'))),
                  SizedBox(width: 4.w),
                  Expanded(
                      flex: 2,
                      child: Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryEmerald,
                                    AppTheme.accentDark
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(12)),
                          child: ElevatedButton(
                              onPressed: _isSaving || _isPublishing
                                  ? null
                                  : _publishProduct,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent),
                              child: _isPublishing
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                          SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Colors.white))),
                                          SizedBox(width: 2.w),
                                          Text('Publishing...'),
                                        ])
                                  : Text('Publish Product')))),
                ])))));
  }

  double _calculateProgress() {
    double progress = 0.0;

    // Required fields
    if (_nameController.text.isNotEmpty) progress += 0.2;
    if (_selectedCategory.isNotEmpty) progress += 0.2;
    if (_descriptionController.text.isNotEmpty) progress += 0.2;
    if (_priceController.text.isNotEmpty) progress += 0.2;
    if (_stockController.text.isNotEmpty) progress += 0.1;
    if (_selectedImages.isNotEmpty) progress += 0.1;

    return progress.clamp(0.0, 1.0);
  }
}
