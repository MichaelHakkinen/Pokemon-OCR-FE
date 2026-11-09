import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../services/api_service.dart';
import '../utils/image_cropper.dart';
import '../widgets/card_cutout_overlay.dart';
import 'collection_screen.dart';
import 'settings_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isTorchOn = false;
  bool _isExposureLocked = false;
  bool _isScanning = false;
  Offset? _focusPoint;

  String _selectedLanguageHint = 'auto';
  final List<Map<String, String>> _languageOptions = [
    {'label': 'Auto', 'value': 'auto'},
    {'label': 'English / Latin', 'value': 'latin'},
    {'label': 'Japanese (日本語)', 'value': 'japanese'},
    {'label': 'Indonesian', 'value': 'latin'},
    {'label': 'Korean (한국어)', 'value': 'korean'},
    {'label': 'Chinese (中文)', 'value': 'chinese'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras found on device.');
        return;
      }

      final controller = CameraController(
        _cameras.first,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      await controller.initialize();
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null) return;
    try {
      final newTorchState = !_isTorchOn;
      await _cameraController!.setFlashMode(
        newTorchState ? FlashMode.torch : FlashMode.off,
      );
      setState(() {
        _isTorchOn = newTorchState;
      });
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  Future<void> _toggleExposureLock() async {
    if (_cameraController == null) return;
    try {
      final newLockState = !_isExposureLocked;
      await _cameraController!.setExposureMode(
        newLockState ? ExposureMode.locked : ExposureMode.auto,
      );
      setState(() {
        _isExposureLocked = newLockState;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newLockState ? 'Exposure locked' : 'Exposure set to auto'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('Error toggling exposure lock: $e');
    }
  }

  Future<void> _handleTapToFocus(TapDownDetails details, Rect cutoutRect) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final Offset tapPosition = details.localPosition;
    setState(() {
      _focusPoint = tapPosition;
    });

    try {
      final screenSize = MediaQuery.of(context).size;
      final double x = (tapPosition.dx / screenSize.width).clamp(0.0, 1.0);
      final double y = (tapPosition.dy / screenSize.height).clamp(0.0, 1.0);

      await _cameraController!.setFocusPoint(Offset(x, y));
      await _cameraController!.setFocusMode(FocusMode.auto);

      // Auto-hide focus reticle after 1.5 seconds
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _focusPoint = null;
          });
        }
      });
    } catch (e) {
      debugPrint('Error setting tap to focus: $e');
    }
  }

  Rect _calculateCutoutRect(Size screenSize) {
    // Standard Pokemon card aspect ratio: 2.5 : 3.5 = 63mm : 88mm (~1 : 1.3968)
    const cardRatio = 2.5 / 3.5;
    final double cardWidth = screenSize.width * 0.82;
    final double cardHeight = cardWidth / cardRatio;
    final double top = (screenSize.height - cardHeight) / 2.3;
    final double left = (screenSize.width - cardWidth) / 2.0;

    return Rect.fromLTWH(left, top, cardWidth, cardHeight);
  }

  Future<void> _captureAndScan(Rect cutoutRect) async {
    if (_cameraController == null || _isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // 1. Capture still photo
      final xFile = await _cameraController!.takePicture();
      final screenSize = MediaQuery.of(context).size;

      // 2. Crop image precisely to card cutout bounds using image package
      final croppedFile = await ImageCropperHelper.cropImageToCutout(
        sourceImagePath: xFile.path,
        cutoutRect: cutoutRect,
        screenSize: screenSize,
      );

      // 3. Upload cropped image to backend OCR endpoint
      final scanResult = await ApiService.scanCard(
        imageFile: croppedFile,
        languageHint: _selectedLanguageHint,
      );

      if (mounted) {
        _showScanResultBottomSheet(scanResult, croppedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _showScanResultBottomSheet(ScanCardResponse result, File croppedImage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scan Result',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(
                          'Script: ${result.detectedScript}',
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF1B53BA),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (result.matchedCards.isNotEmpty) ...[
                    const Text(
                      'Matched Cards in Database:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    ...result.matchedCards.map((card) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: card.imageUrl != null
                              ? Image.network(card.imageUrl!, width: 48, fit: BoxFit.contain)
                              : Container(
                                  width: 48,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.style),
                                ),
                          title: Text(
                            card.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Set: ${card.setCode} (${card.setName})\n#${card.collectorNumber} • ${card.rarity ?? "Common"}',
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B53BA),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Add'),
                            onPressed: () async {
                              await ApiService.addToCollection(cardId: card.id);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${card.name} to Collection!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No exact card found in catalog.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('Candidate Names: ${result.nameCandidates.join(", ")}'),
                          Text('Candidate Numbers: ${result.setNumberCandidates.join(", ")}'),
                          Text('Candidate Sets: ${result.setCodeCandidates.join(", ")}'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final cutoutRect = _calculateCutoutRect(screenSize);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewfinder with Tap to Focus
          GestureDetector(
            onTapDown: (details) => _handleTapToFocus(details, cutoutRect),
            child: CameraPreview(_cameraController!),
          ),

          // 2. Custom Painter Card Cutout Frame
          CardCutoutOverlay(
            cutoutRect: cutoutRect,
            isTorchOn: _isTorchOn,
            onToggleTorch: _toggleTorch,
          ),

          // 3. Tap to Focus Reticle Animation
          if (_focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 28,
              top: _focusPoint!.dy - 28,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCB05), width: 2),
                ),
              ),
            ),

          // 4. Top Controls Bar: Torch, Exposure Lock, Language Hint Selector, Settings
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Torch Button
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: _isTorchOn ? const Color(0xFFFFCB05) : Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleTorch,
                    ),

                    // Exposure Lock Button
                    IconButton(
                      icon: Icon(
                        _isExposureLocked ? Icons.lock : Icons.lock_open,
                        color: _isExposureLocked ? const Color(0xFFFFCB05) : Colors.white,
                        size: 26,
                      ),
                      onPressed: _toggleExposureLock,
                    ),

                    // Language Script Hint Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguageHint,
                          dropdownColor: Colors.grey.shade900,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: _languageOptions.map((opt) {
                            return DropdownMenuItem<String>(
                              value: opt['value'],
                              child: Text(opt['label']!),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedLanguageHint = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    // Settings Navigation
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 26),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Instruction Prompt Banner
          Positioned(
            top: cutoutRect.top - 48,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Align card inside the frame',
                  style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 0.3),
                ),
              ),
            ),
          ),

          // 6. Bottom Action Bar: Collection Gallery & Shutter Capture Trigger
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0, left: 30, right: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Collection Button
                    IconButton(
                      icon: const Icon(Icons.collections_bookmark_rounded,
                          color: Colors.white, size: 32),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CollectionScreen()),
                        );
                      },
                    ),

                    // Shutter Capture Button
                    GestureDetector(
                      onTap: _isScanning ? null : () => _captureAndScan(cutoutRect),
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Center(
                          child: _isScanning
                              ? const CircularProgressIndicator(
                                  color: Color(0xFFFFCB05),
                                )
                              : Container(
                                  width: 58,
                                  height: 58,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFFCB05),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black87,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Spacer / Future feature
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

