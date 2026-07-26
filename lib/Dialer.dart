import 'package:direct_dialer/direct_dialer.dart';
import 'package:flutter/material.dart';

class DialerPage extends StatefulWidget {
  const DialerPage({super.key});

  @override
  State<DialerPage> createState() => _DialerPageState();
}

class _DialerPageState extends State<DialerPage> {
  String typedVal = "";

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _display(),
            const Spacer(),
            _numpad(),
            const SizedBox(height: 30),
            _bottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _display() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Text(
        typedVal.isEmpty ? 'Enter number' : typedVal,
        style: const TextStyle(
          fontSize: 36,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _numpad() {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: numbers.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.2,
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
          color: Colors.grey.shade900,
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Text(
          n,
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _bottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.backspace,
              color: Colors.white, size: 30),
          onPressed: backspacefn,
          onLongPress: backspacefn,
        ),
        FloatingActionButton(
          backgroundColor: Colors.greenAccent.shade700,
          onPressed: () async {
            DirectDialer plugIN =
                await DirectDialer.instance;
            await plugIN.dial(typedVal);
          },
          child: const Icon(Icons.call,
              color: Colors.white, size: 28),
        ),
      ],
    );
  }
////FUNCTIONS

  void backspacefn() {
    if (typedVal.isNotEmpty) {
      setState(() {
        typedVal =
            typedVal.substring(0, typedVal.length - 1);
      });
    }
  }

  void addDigitfn(String digit) {
    setState(() {
      String upcomingRes = typedVal + digit;
      typedVal = upcomingRes;
    });
  }
}
