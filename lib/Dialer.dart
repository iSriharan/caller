import 'package:direct_dialer/direct_dialer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class DialerPage extends StatefulWidget {
  const DialerPage({super.key});

  @override
  State<DialerPage> createState() => _DialerPageState();
}

class _DialerPageState extends State<DialerPage> {
  String typedVal = "";
  String? clipboardNum;
  final List<String> numbers = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '*',
    '0',
    '#',
  ];

  @override
  void initState() {
    super.initState();
    _checkClipboardForNumber();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Center(
              child: const Text(
                "Dialer",
                style: TextStyle(fontSize: 25),
              ),
            )),
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

  /// Display area
  Widget _display() {
    return Container(
      height: 135,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            typedVal.isEmpty ? "" : typedVal,
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          if (typedVal.isEmpty && clipboardNum != null)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  typedVal = clipboardNum!;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Paste"),
            ),
        ],
      ),
    );
  }

  /// Image search icon
  Widget imagesearch() {
    return IconButton(
      icon: const Icon(Icons.image_search, color: Colors.white),
      tooltip: 'Image Search',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text(
                      "Gallery",
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _scanImageForPhoneNumber(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text("Camera", style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      _scanImageForPhoneNumber(ImageSource.camera);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Number pad
  Widget _numpad() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      itemCount: numbers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        return _circle(numbers[index]);
      },
    );
  }

  Widget _circle(String n) {
    return GestureDetector(
      onTap: () => addDigitfn(n),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54.withValues(alpha: 0.1),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Text(
          n,
          style: const TextStyle(
            fontSize: 30,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Bottom actions
  Widget _bottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.backspace, color: Colors.white, size: 30),
          onPressed: backspacefn,
          onLongPress: () => setState(() => typedVal = ""),
        ),
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
      ],
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
    if (data != null && RegExp(r'^[\d+\-\s]+$').hasMatch(data.text!)) {
      setState(() {
        clipboardNum = data.text!;
      });
    }
  }

  /// OCR function
  Future<void> _scanImageForPhoneNumber(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    final text = recognizedText.text;
    final phoneRegex = RegExp(r'(\+?\d[\d\s\-\(\)]{6,})');

    final matches = phoneRegex.allMatches(text);

    if (matches.isNotEmpty) {
      final number = matches.first.group(0);
      if (number != null) {
        setState(() {
          typedVal = number; // paste into dialer field
        });
      }
    }

    textRecognizer.close();
  }
}
