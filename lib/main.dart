// ignore: unused_import
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const FaceConditionApp());
}

class FaceConditionApp extends StatelessWidget {
  const FaceConditionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const FaceConditionHome(),
    );
  }
}

class FaceConditionHome extends StatefulWidget {
  const FaceConditionHome({super.key});

  @override
  State<FaceConditionHome> createState() => _FaceConditionHomeState();
}

class _FaceConditionHomeState extends State<FaceConditionHome> {
  late CameraController _controller;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 1; // Default to front camera
  String _detectionStatus = "No faces detected";
  String _lightingStatus = "Unknown lighting";
  int _frameCounter = 0;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode:
          FaceDetectorMode.accurate, // Fixed from FaceDetectorPerformanceMode
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      CameraDescription selectedCamera = cameras[0];
      if (cameras.length > 1) {
        selectedCamera = cameras[_selectedCameraIndex];
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller.initialize();

      // Set initial exposure for dim lighting
      try {
        await _controller.setExposurePoint(null); // Auto exposure
        await _controller.setExposureOffset(0.5); // Slight boost for low light
      } catch (e) {
        debugPrint("Error setting exposure: $e");
      }

      debugPrint("Camera initialized: ${selectedCamera.name}");

      _controller.startImageStream((CameraImage image) async {
        _frameCounter++;
        if (_frameCounter % 3 != 0) {
          _isDetecting = false;
          return; // Skip every 3rd frame
        }

        if (_isDetecting) {
          debugPrint("Skipping frame: Detection in progress");
          return;
        }
        _isDetecting = true;

        try {
          // Estimate lighting
          final lightingLevel = _estimateLighting(image);
          _updateLightingStatus(lightingLevel);

          // Adjust exposure based on lighting
          if (lightingLevel < 100) {
            try {
              await _controller.setExposureOffset(1.0); // Boost for dim/dark
            } catch (e) {
              debugPrint("Error adjusting exposure: $e");
            }
          } else {
            try {
              await _controller.setExposureOffset(0.0); // Normal
            } catch (e) {
              debugPrint("Error resetting exposure: $e");
            }
          }

          debugPrint(
              "Processing frame: ${image.width}x${image.height}, format: ${image.format.group}");
          final inputImage =
              await _cameraImageToInputImage(image, selectedCamera);
          final List<Face> faces = await _faceDetector.processImage(inputImage);

          if (faces.isNotEmpty) {
            debugPrint("Detected ${faces.length} face(s)");
            String status = "Detected ${faces.length} face(s):\n";
            for (int i = 0; i < faces.length; i++) {
              final face = faces[i];
              final mood = _analyzeMood(face);
              status += "Face $i: $mood\n";
            }
            setState(() {
              _detectionStatus = status;
            });
          } else {
            debugPrint("No faces detected in this frame");
            setState(() {
              _detectionStatus = "No faces detected";
            });
          }
        } catch (e, stackTrace) {
          debugPrint("Error detecting face: $e");
          debugPrint("Stack trace: $stackTrace");
          setState(() {
            _detectionStatus = "Error: $e";
          });
        } finally {
          _isDetecting = false;
        }
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      setState(() {
        _isCameraInitialized = false;
        _detectionStatus = "Camera initialization failed";
      });
    }
  }

  double _estimateLighting(CameraImage image) {
    // Calculate average brightness from Y plane (YUV format)
    if (image.format.group != ImageFormatGroup.yuv420) return 128.0;
    final plane = image.planes[0]; // Y plane
    final bytes = plane.bytes;
    int total = 0;
    for (int i = 0; i < bytes.length; i++) {
      total += bytes[i];
    }
    return total / bytes.length; // Average intensity (0-255)
  }

  void _updateLightingStatus(double lightingLevel) {
    String newStatus;
    if (lightingLevel > 200) {
      newStatus = "Bright lighting";
    } else if (lightingLevel > 100) {
      newStatus = "Normal lighting";
    } else if (lightingLevel > 50) {
      newStatus = "Dim lighting: Detection may be less accurate";
    } else {
      newStatus = "Dark lighting: Detection may be limited";
    }
    setState(() {
      _lightingStatus = newStatus;
    });
  }

  String _analyzeMood(Face face) {
    String mood = "";
    double? smile = face.smilingProbability;
    double? leftEye = face.leftEyeOpenProbability;
    double? rightEye = face.rightEyeOpenProbability;

    if (smile != null) {
      if (smile > 0.75) {
        mood += "Happy: ${(smile * 100).toStringAsFixed(1)}%\n";
      } else if (smile < 0.25) {
        mood += "Sad: ${((1 - smile) * 100).toStringAsFixed(1)}%\n";
      } else {
        mood += "Neutral: ${(smile * 100).toStringAsFixed(1)}%\n";
      }
    }

    if (leftEye != null && rightEye != null) {
      double avgEyeOpen = (leftEye + rightEye) / 2;
      if (avgEyeOpen < 0.5) {
        mood += "Tired: ${(100 - avgEyeOpen * 100).toStringAsFixed(1)}%\n";
      } else if (avgEyeOpen > 0.9 && smile != null && smile < 0.25) {
        mood += "Stressed: ${(avgEyeOpen * 100).toStringAsFixed(1)}%\n";
      } else {
        mood += "Alert: ${(avgEyeOpen * 100).toStringAsFixed(1)}%\n";
      }
    }

    return mood.isEmpty ? "Unknown mood" : mood;
  }

  Future<InputImage> _cameraImageToInputImage(
      CameraImage image, CameraDescription camera) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    InputImageFormat format;
    if (image.format.group == ImageFormatGroup.yuv420) {
      format = InputImageFormat.yuv_420_888;
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      format = InputImageFormat.bgra8888;
    } else {
      throw Exception("Unsupported image format: ${image.format.group}");
    }

    final rotation = _calculateInputImageRotation(camera);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  InputImageRotation _calculateInputImageRotation(CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    final isFrontCamera = camera.lensDirection == CameraLensDirection.front;

    final deviceOrientation = _controller.value.deviceOrientation;
    int rotationCompensation = 0;

    switch (deviceOrientation) {
      case DeviceOrientation.portraitUp:
        rotationCompensation = 0;
        break;
      case DeviceOrientation.landscapeRight:
        rotationCompensation = 90;
        break;
      case DeviceOrientation.portraitDown:
        rotationCompensation = 180;
        break;
      case DeviceOrientation.landscapeLeft:
        rotationCompensation = 270;
        break;
      default:
        rotationCompensation = 0;
    }

    int rotationDegrees;
    if (isFrontCamera) {
      rotationDegrees = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationDegrees = (sensorOrientation - rotationCompensation + 360) % 360;
    }

    switch (rotationDegrees) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _switchCamera() async {
    setState(() {
      _isCameraInitialized = false;
      _detectionStatus = "Switching camera...";
    });
    await _controller.dispose();
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    await _initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Condition Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: _switchCamera,
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                CameraPreview(_controller),
                // Mood and detection overlay
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withOpacity(0.7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detectionStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lightingStatus,
                          style: TextStyle(
                            color: _lightingStatus.contains("Dim") ||
                                    _lightingStatus.contains("Dark")
                                ? Colors.yellow
                                : Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
