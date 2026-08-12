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

  @override
  void initState() {
    super.initState();
    _checkClipboardForNumber();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text("Dialer", style: TextStyle(fontSize: 25)),
        ),
        actions: [imagesearch()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _display(),
            const Divider(color: Colors.grey),
            Expanded(child: _numpad()),
            const SizedBox(height: 20),
            _bottomActions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Display area with camera preview
  Widget _display() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Stack(
        children: [
          if (_cameraActive &&
              _cameraController != null &&
              _cameraController!.value.isInitialized)
            Positioned.fill(child: CameraPreview(_cameraController!)),
          Center(
            child: Text(
              typedVal.isEmpty ? "" : typedVal,
              style: const TextStyle(
                fontSize: 50,
                color: Colors.white,
                letterSpacing: 5,
              ),
            ),
          ),
          if (typedVal.isEmpty && clipboardNum != null)
            Center(
              child: ElevatedButton(
                onPressed: _onPaste,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Paste"),
              ),
            ),
        ],
      ),
    );
  }

  /// Camera icon
  Widget imagesearch() {
    return IconButton(
      icon: const Icon(Icons.photo_camera_outlined, color: Colors.white),
      tooltip: 'Scan Number',
      onPressed: () async {
        setState(() => _cameraActive = !_cameraActive);
        if (_cameraActive) {
          // short delay to let camera settle
          await Future.delayed(const Duration(seconds: 2));
          await _captureAndScan();
          setState(() => _cameraActive = false);
        }
      },
    );
  }

  /// Number pad
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
          padding: const EdgeInsets.only(left: 10, right: 10, top: 27),
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
                          fontSize: 30,
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

  /// Bottom actions
  Widget _bottomActions() {
    return SizedBox(
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.greenAccent.shade700,
            onPressed: () async {
              if (typedVal.isNotEmpty) {
                DirectDialer plugIN = await DirectDialer.instance;
                await plugIN.dial(typedVal);
              }
            },
            child: const Icon(Icons.call, color: Colors.white, size: 28),
          ),
          if (typedVal.isNotEmpty)
            Padding(
              padding: EdgeInsetsGeometry.only(left: 200),
              child: IconButton(
                icon:
                    const Icon(Icons.backspace, color: Colors.white, size: 30),
                onPressed: backspacefn,
                onLongPress: () => setState(() => typedVal = ""),
              ),
            ),
        ],
      ),
    );
  }

  //// FUNCTIONS
  void backspacefn() {
    if (typedVal.isNotEmpty) {
      setState(() {
        typedVal = typedVal.substring(0, typedVal.length - 1);
      });
    }
  }

  void addDigitfn(String digit) {
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
      setState(() {
        typedVal = clipboardNum!;
        clipboardNum = null;
      });
    }
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    final image = await _cameraController!.takePicture();
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final text = recognizedText.text.trim();
    final phoneRegex = RegExp(r'\d{5,}');
    final matches = phoneRegex.allMatches(text);

    if (matches.isNotEmpty) {
      final number = matches.first.group(0);
      if (number != null) {
        final cleanNumber = number.replaceAll(RegExp(r'[^0-9+]'), '');
        setState(() {
          typedVal = cleanNumber;
        });
      }
    }

    textRecognizer.close();
  }
}
