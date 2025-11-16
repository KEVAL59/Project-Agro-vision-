import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:agrovision/config.dart';

class ScanCropScreen extends StatefulWidget {
  const ScanCropScreen({super.key});

  @override
  State<ScanCropScreen> createState() => _ScanCropScreenState();
}

class _ScanCropScreenState extends State<ScanCropScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  String? _diagnosisResult; // To store the diagnosis result

  final ImagePicker _picker = ImagePicker();

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permissions first
      if (source == ImageSource.camera) {
        final ok = await _requestPermission(Permission.camera);
        if (!ok) {
          _showSnack('Camera permission denied');
          return;
        }
      } else {
        final ok = await _requestPermission(Permission.photos) ||
            await _requestPermission(Permission.storage);
        if (!ok) {
          _showSnack('Storage permission denied');
          return;
        }
      }

      final pickedFile = await _picker.pickImage(source: source, imageQuality: 100);
      if (pickedFile == null) return;

      File imageFile = File(pickedFile.path);

      // Crop the image
      final cropped = await _cropImage(imageFile);
      if (cropped == null) return;
      imageFile = cropped;

      // Optionally compress (small sizes help upload & ML inference)
      final compressed = await _compressImage(imageFile);
      if (compressed != null) imageFile = compressed as File;

      setState(() {
        _selectedImage = imageFile;
        _diagnosisResult = null; // Clear previous result
      });

      // Process image for diagnosis
      await _processImageForDiagnosis(imageFile);
    } catch (e, st) {
      debugPrint('pickImage error: $e\n$st');
      _showSnack('Failed to pick image: $e');
    }
  }

  Future<File?> _cropImage(File file) async {
    try {
      final result = await ImageCropper().cropImage(
        sourcePath: file.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop image',
            toolbarColor: Colors.green,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio4x3,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop image',
          ),
        ],
      );
      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      debugPrint('crop error: $e');
      return null;
    }
  }

  Future<XFile?> _compressImage(File file) async {
    try {
      final targetPath = '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        keepExif: true,
      );
      return result;
    } catch (e) {
      debugPrint('compress error: $e');
      return null;
    }
  }

  Future<void> _processImageForDiagnosis(File image) async {
    setState(() => _isProcessing = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading image for diagnosis...')),
    );

    // Use the SERVER_BASE constant from config.dart
    final String apiUrl = '$SERVER_BASE/predict';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath(
        'file', // This must match the field name in your Flask API (request.files['file'])
        image.path,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final respJson = jsonDecode(response.body);
        String prediction = respJson['prediction'] ?? 'Unknown';
        setState(() {
          _diagnosisResult = prediction;
        });
        _showResultDialog(prediction);
      } else {
        _showSnack('Server error: ${response.statusCode}: ${response.body}');
      }
    } catch (e, st) {
      debugPrint('process error: $e\n$st');
      _showSnack('Error processing image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diagnosis Result'),
        content: SingleChildScrollView(
          child: Text('Predicted Class: $result'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSnack(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Diagnosis', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50!, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Identify plant diseases instantly!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/crop_placeholder.png',
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 250,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: Icon(Icons.broken_image, size: 80, color: Colors.grey[400]),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                if (_diagnosisResult != null)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Card(
                      elevation: 6,
                      color: Colors.green.shade50,
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Diagnosis Result:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _diagnosisResult!,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.green.shade800,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.camera_alt,
                        label: 'Take Photo',
                        onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.photo_library,
                        label: 'From Gallery',
                        onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                        color: Colors.lightGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isProcessing)
                  const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Poppins')),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: color.withOpacity(0.4),
      ),
    );
  }
}
