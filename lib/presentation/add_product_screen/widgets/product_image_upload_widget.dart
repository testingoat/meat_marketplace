import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class ProductImageUploadWidget extends StatefulWidget {
  final Function(List<XFile>) onImagesSelected;
  final List<XFile> selectedImages;

  const ProductImageUploadWidget({
    Key? key,
    required this.onImagesSelected,
    required this.selectedImages,
  }) : super(key: key);

  @override
  State<ProductImageUploadWidget> createState() =>
      _ProductImageUploadWidgetState();
}

class _ProductImageUploadWidgetState extends State<ProductImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _showCamera = false;
  int _primaryImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    return (await Permission.camera.request()).isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      if (!await _requestCameraPermission()) return;

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first);

      _cameraController = CameraController(
          camera, kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high);

      await _cameraController!.initialize();
      await _applySettings();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization failed: \$e');
    }
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Focus mode setting failed: \$e');
    }

    if (!kIsWeb) {
      try {
        await _cameraController!.setFlashMode(FlashMode.auto);
      } catch (e) {
        debugPrint('Flash mode setting failed: \$e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      final updatedImages = List<XFile>.from(widget.selectedImages)..add(photo);
      widget.onImagesSelected(updatedImages);

      setState(() {
        _showCamera = false;
      });
    } catch (e) {
      debugPrint('Photo capture failed: \$e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 1920, maxHeight: 1080, imageQuality: 85);

      if (images.isNotEmpty) {
        final updatedImages = List<XFile>.from(widget.selectedImages)
          ..addAll(images);
        widget.onImagesSelected(updatedImages);
      }
    } catch (e) {
      debugPrint('Gallery selection failed: \$e');
    }
  }

  void _removeImage(int index) {
    final updatedImages = List<XFile>.from(widget.selectedImages)
      ..removeAt(index);
    widget.onImagesSelected(updatedImages);

    if (_primaryImageIndex >= updatedImages.length &&
        updatedImages.isNotEmpty) {
      setState(() {
        _primaryImageIndex = 0;
      });
    }
  }

  void _setPrimaryImage(int index) {
    setState(() {
      _primaryImageIndex = index;
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final updatedImages = List<XFile>.from(widget.selectedImages);
    final item = updatedImages.removeAt(oldIndex);
    updatedImages.insert(newIndex, item);

    widget.onImagesSelected(updatedImages);

    if (_primaryImageIndex == oldIndex) {
      setState(() {
        _primaryImageIndex = newIndex;
      });
    } else if (oldIndex < _primaryImageIndex &&
        newIndex >= _primaryImageIndex) {
      setState(() {
        _primaryImageIndex -= 1;
      });
    } else if (oldIndex > _primaryImageIndex &&
        newIndex <= _primaryImageIndex) {
      setState(() {
        _primaryImageIndex += 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline, width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CustomIconWidget(
                iconName: 'photo_camera',
                color: AppTheme.primaryEmerald,
                size: 20),
            SizedBox(width: 2.w),
            Text('Product Images',
                style: AppTheme.lightTheme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${widget.selectedImages.length}/10',
                style: AppTheme.lightTheme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.mutedText)),
          ]),
          SizedBox(height: 2.h),
          if (_showCamera && _isCameraInitialized && _cameraController != null)
            Container(
                height: 40.h,
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(children: [
                      CameraPreview(_cameraController!),
                      Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showCamera = false;
                                      });
                                    },
                                    icon: Container(
                                        padding: EdgeInsets.all(2.w),
                                        decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            shape: BoxShape.circle),
                                        child: CustomIconWidget(
                                            iconName: 'close',
                                            color: Colors.white,
                                            size: 24))),
                                IconButton(
                                    onPressed: _capturePhoto,
                                    icon: Container(
                                        padding: EdgeInsets.all(4.w),
                                        decoration: BoxDecoration(
                                            color: AppTheme.primaryEmerald,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 3)),
                                        child: CustomIconWidget(
                                            iconName: 'camera_alt',
                                            color: Colors.white,
                                            size: 28))),
                                IconButton(
                                    onPressed: _pickFromGallery,
                                    icon: Container(
                                        padding: EdgeInsets.all(2.w),
                                        decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            shape: BoxShape.circle),
                                        child: CustomIconWidget(
                                            iconName: 'photo_library',
                                            color: Colors.white,
                                            size: 24))),
                              ])),
                    ])))
          else
            Column(children: [
              if (widget.selectedImages.isNotEmpty)
                Container(
                    height: 25.h,
                    child: ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.selectedImages.length,
                        onReorder: _reorderImages,
                        itemBuilder: (context, index) {
                          final image = widget.selectedImages[index];
                          final isPrimary = index == _primaryImageIndex;

                          return Container(
                              key: ValueKey(image.path),
                              margin: EdgeInsets.only(right: 3.w),
                              child: Stack(children: [
                                Container(
                                    width: 35.w,
                                    height: 25.h,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: isPrimary
                                                ? AppTheme.primaryEmerald
                                                : AppTheme.borderSubtle,
                                            width: isPrimary ? 3 : 1)),
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: kIsWeb
                                            ? Image.network(image.path,
                                                fit: BoxFit.cover, errorBuilder:
                                                    (context, error,
                                                        stackTrace) {
                                                return Container(
                                                    color: AppTheme.accentLight,
                                                    child: Center(
                                                        child: CustomIconWidget(
                                                            iconName:
                                                                'broken_image',
                                                            color: AppTheme
                                                                .mutedText,
                                                            size: 32)));
                                              })
                                            : Image.asset(image.path,
                                                fit: BoxFit.cover, errorBuilder:
                                                    (context, error,
                                                        stackTrace) {
                                                return Container(
                                                    color: AppTheme.accentLight,
                                                    child: Center(
                                                        child: CustomIconWidget(
                                                            iconName:
                                                                'broken_image',
                                                            color: AppTheme
                                                                .mutedText,
                                                            size: 32)));
                                              }))),
                                if (isPrimary)
                                  Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 2.w, vertical: 1.w),
                                          decoration: BoxDecoration(
                                              color: AppTheme.primaryEmerald,
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text('Primary',
                                              style: AppTheme.lightTheme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600)))),
                                Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                            padding: EdgeInsets.all(1.w),
                                            decoration: BoxDecoration(
                                                color: AppTheme.errorRed,
                                                shape: BoxShape.circle),
                                            child: CustomIconWidget(
                                                iconName: 'close',
                                                color: Colors.white,
                                                size: 16)))),
                                if (!isPrimary)
                                  Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: GestureDetector(
                                          onTap: () => _setPrimaryImage(index),
                                          child: Container(
                                              padding: EdgeInsets.all(1.w),
                                              decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.6),
                                                  shape: BoxShape.circle),
                                              child: CustomIconWidget(
                                                  iconName: 'star_border',
                                                  color: Colors.white,
                                                  size: 16)))),
                              ]));
                        })),
              SizedBox(height: widget.selectedImages.isNotEmpty ? 3.h : 0),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: widget.selectedImages.length < 10
                            ? () {
                                setState(() {
                                  _showCamera = true;
                                });
                              }
                            : null,
                        icon: CustomIconWidget(
                            iconName: 'camera_alt',
                            color: widget.selectedImages.length < 10
                                ? AppTheme.primaryEmerald
                                : AppTheme.mutedText,
                            size: 20),
                        label: Text('Camera'),
                        style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 3.h)))),
                SizedBox(width: 4.w),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: widget.selectedImages.length < 10
                            ? _pickFromGallery
                            : null,
                        icon: CustomIconWidget(
                            iconName: 'photo_library',
                            color: widget.selectedImages.length < 10
                                ? AppTheme.primaryEmerald
                                : AppTheme.mutedText,
                            size: 20),
                        label: Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 3.h)))),
              ]),
            ]),
          if (widget.selectedImages.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  CustomIconWidget(
                      iconName: 'info',
                      color: AppTheme.primaryEmerald,
                      size: 16),
                  SizedBox(width: 2.w),
                  Expanded(
                      child: Text(
                          'Drag to reorder images. Tap star to set as primary image.',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mutedText))),
                ])),
          ],
        ]));
  }
}
