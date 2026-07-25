import 'package:flutter/material.dart';

class DialerPage extends StatefulWidget {
  const DialerPage({super.key});

  @override
  State<DialerPage> createState() => _DialerPageState();
}

class _DialerPageState extends State<DialerPage> {
  List<String> numbers = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '#',
    '0',
    '*'
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: nums(),
      backgroundColor: Colors.black,
    );
  }

  Widget nums() {
    // List<Widget> storage = [];
    // for (int i = 0; i < numbers.length; i++) {
    //   String n = numbers[i];
    //   Widget key = Text(
    //     n,
    //     style: TextStyle(
    //         fontSize: 40, color: Colors.greenAccent),
    //   );
    //   storage.add(key);
    // }

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 160),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.6,
          children: numbers.map((n) {
            return _circle(n);
          }).toList(),
        ),
      ),
    );
  }

  Widget _circle(String n) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade800,
          border: Border.all(
            color: Colors.grey,
          ),
        ),
        child: Text(
          n,
          style: const TextStyle(
            fontSize: 25,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
