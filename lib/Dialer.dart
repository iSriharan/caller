import 'package:direct_dialer/direct_dialer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';

class DialerPage extends StatefulWidget {
  const DialerPage({super.key});

  @override
  State<DialerPage> createState() => _DialerPageState();
}

class _DialerPageState extends State<DialerPage> {
  String typedVal = "";
  String? clipboardNum;
  String? lastClipboardvalue;

  CameraController? _cameraController;
  bool _cameraActive = false;
  bool _isProcessingImage = false;

  @override
  void initState() {
    
    super.initState();
    _checkClipboardForNumber();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final firstCamera = cameras.first;
      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors., // Recommended for dialers
      appBar: AppBar(
        // backgroundColor: Colors.transparent,
        title: const Center(
          child: Padding(
            padding: EdgeInsets.only(left: 50.0), // Offset for the action button
            child: Text("Dialer", style: TextStyle(fontSize: 28, color: Colors.white)),
          ),
        ),
        actions: [imagesearch()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _display(),
            const Divider(color: Colors.grey, height: 1),
            Expanded(child: _numpad()),
            const SizedBox(height: 10),
            _bottomActions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  

  Widget _display() {
    return Container(
      height: 150,
      width: double.infinity,
      alignment: Alignment.center,
      child: Stack(
        children: [
          // Camera Preview Box
          if (_cameraActive &&
              _cameraController != null &&
              _cameraController!.value.isInitialized)
            Positioned.fill(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    // Flips width/height for portrait aspect ratio
                    width: _cameraController!.value.previewSize?.height ?? 1,
                    height: _cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),
            
          // Scanning Indicator
          if (_isProcessingImage)
            const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
            
          // Typed or Scanned Value
          Center(
            child: Text(
              typedVal.isEmpty ? "" : typedVal,
              style: const TextStyle(
                fontSize: 45, // Slightly smaller to fit longer numbers
                color: Colors.white,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Paste Button
          if (typedVal.isEmpty && clipboardNum != null && !_cameraActive)
            Center(
              child: ElevatedButton(
                onPressed: _onPaste,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Paste Copied Number"),
              ),
            ),
        ],
      ),
    );
  }


Widget imagesearch() {
    return IconButton(
      icon: Icon(
        _cameraActive ? Icons.camera : Icons.photo_camera_outlined,
        color: _cameraActive ? Colors.green : Colors.white,
      ),
      tooltip: 'Scan Number',
      onPressed: () async {
        if (_cameraController == null || !_cameraController!.value.isInitialized) {
          await _initCamera();
        }
        if (!mounted) return;
        
        setState(() => _cameraActive = !_cameraActive);
        
        if (_cameraActive) {
          // Give camera 1.5 seconds to open and auto-adjust lighting
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!mounted || !_cameraActive) return;
          await _captureAndScan();
        }
      },
    );
  }
  
  Widget _numpad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#']
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((x) {
              return SizedBox(
                height: 80,
                width: 80,
                child: Material(
                  color: Colors.white10,
                  elevation: 1,
                  shadowColor: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => addDigitfn(x),
                    child: Center(
                      child: Text(
                        x,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }


Widget _bottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty space to perfectly center the call button
          const SizedBox(width: 50),
          const Spacer(),
          
          // Call Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(90),
              onTap: () async {
                if (typedVal.isNotEmpty) {
                  HapticFeedback.lightImpact();
                  DirectDialer plugIN = await DirectDialer.instance;
                  await plugIN.dial(typedVal);
                }
              },
              child: Container(
                height: 75,
                width: 75,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Backspace Button (Takes exactly 50 width to balance layout)
          SizedBox(
            width: 50,
            child: typedVal.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.backspace, color: Colors.white, size: 28),
                    onPressed: backspacefn,
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      setState(() => typedVal = "");
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }




 

  void backspacefn() {
    if (typedVal.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        typedVal = typedVal.substring(0, typedVal.length - 1);
      });
    }
  }

  void addDigitfn(String digit) {
    HapticFeedback.heavyImpact();
    setState(() {
      typedVal += digit;
    });
  }

  Future<void> _checkClipboardForNumber() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text != null &&
        RegExp(r'^[\d+\-\s]+$').hasMatch(text) &&
        text != lastClipboardvalue) {
      setState(() {
        clipboardNum = text;
        lastClipboardvalue = text;
      });
    }
  }

  void _onPaste() {
    if (clipboardNum != null) {
      final cleanNum= clipboardNum!.replaceAll(RegExp(r'[^0-9+]'),'');
      setState(() {
        typedVal = cleanNum;
        clipboardNum = null;
      });
    }
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    setState(() => _isProcessingImage = true);

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      while (_cameraActive && mounted) {
        if (_cameraController!.value.isTakingPicture) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        try {
          await _cameraController!.setFocusMode(FocusMode.auto);
        } catch (_) {}

        final image = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(image.path);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        String? detectedphone;
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            final rawLine = line.text;
            final digitsonly = rawLine.replaceAll(RegExp(r'[^0-9+]'), '');
            final match = RegExp(r'(\+?\d{7,15})').firstMatch(digitsonly);
            if (match != null) {
              detectedphone = match.group(0);
              break;
            }
          }
          if (detectedphone != null) break;
        }

        if (detectedphone != null) {
          final String foundNumber = detectedphone;
          debugPrint('Phone number detected: $foundNumber');
          if (mounted) {
            setState(() {
              typedVal = foundNumber;
              _cameraActive = false;
              _isProcessingImage = false;
            });
            HapticFeedback.vibrate();
          }
          return; // exit the method entirely
        }

        // Wait 1 second before capturing the next frame to try again
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      debugPrint('Error taking picture or recognizing text:$e');
    } finally {
      textRecognizer.close();
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }
}







