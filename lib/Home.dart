import 'package:caller/Dialer.dart';
import 'package:direct_dialer/direct_dialer.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController pageController = PageController();
  List<Contact> _contacts = const [];
  bool isTamil = true;
  bool showkeyboard = false;
  Color txtclr = Color(0XFFF0F6F6);
  Color keyboardBg = Color(0xFF0B131A);
  Color whiter = Color(0XFFFFFFFF);

  List<Contact> get contacts {
    return _contacts.where((c) {
      final displayName = c.displayName;

      final containsEnglish = RegExp(r'[a-zA-Z]').hasMatch(displayName);
      return isTamil ? !containsEnglish : containsEnglish;
    }).toList();
  }

  bool _isLoading = false;
  String selectedAlphabet = '';
  final ScrollController _scrollController = ScrollController();

  // Add for recent calls
  List<String> _recentNumbers = [];

  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    loadContacts();
    loadRecentNumbers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: body(),
      bottomNavigationBar: bottomNav(),
    );
  }

  AppBar? appBar() {
    if (currentPage == 2) {
      return null;
    }
    return AppBar(
      title: Center(child: Text('Caller',style: TextStyle(fontSize: 26))),
      leading: languageButton(),
      actions: [
        searchbutton(),
        // languageButton(),
      ],
    );
  }

  Widget searchbutton() {
    return IconButton(
      icon: Icon(
        Icons.search,
        color: Colors.white,
      ),
      tooltip: 'Keyboard',
      onPressed: () {
        setState(() {
          showkeyboard = !showkeyboard;
        });
      },
    );
  }

  Widget languageButton() {
    return IconButton(
      icon: Icon(
        Icons.translate,
        color: isTamil ? Colors.white : Colors.green,
      ),
      tooltip: isTamil ? 'Turn off Tamil' : 'Turn on Tamil',
      onPressed: () {
        setState(() {
          isTamil = !isTamil;
          selectedAlphabet = '';
          pageController.jumpToPage(1);
          _scrollController.jumpTo(0);
        });
      },
    );
  }

  Widget body() {
    // return DialerPage();
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else {
      return PageView(
        controller: pageController,
        onPageChanged: (int i) async {
          setState(() => currentPage = i);
          if (i == 0) await loadRecentNumbers();
        },
        children: [recentsPage(), allPage(), dialpad()],
      );
    }
  }

  Widget allPage() {
    List<Contact> list = contacts.where((c) {
      String fullName = c.displayName;
      // String firstLetter = fullName.characters.firstOrNull ?? '';
      return selectedAlphabet.isEmpty ? true : fullName.contains(selectedAlphabet);
      // firstLetter == selectedAlphabet;
    }).toList();
    return Column(
      children: [
        _listView(list),
        if (showkeyboard) keyboard(),
      ],
    );
  }

  Widget recentsPage() {
    List<Contact> list = contacts.where((c) {
      return c.phones.any((phone) => _recentNumbers.contains(phone.number));
    }).toList();

    return Column(
      children: [
        _listView(list),
      ],
    );
  }

  Widget dialpad() {
    return DialerPage();
  }

  Widget keyboard() {
    List<String> alphabets = [];
    for (Contact contact in contacts) {
      String firstLetter = contact.displayName.trim().characters.firstOrNull ?? '';
      if (firstLetter.isNotEmpty && !alphabets.contains(firstLetter)) {
        alphabets.add(firstLetter);
      }
    }

    alphabets.sort();

    return Container(
      height: 350,
      color: keyboardBg,
      // color: const Color.fromARGB(255, 47, 1, 26),
      child: GridView.builder(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 2,
        ),
        itemCount: alphabets.length,
        itemBuilder: (BuildContext context, int index) {
          String a = alphabets[index];
          bool isSelected = selectedAlphabet == a;
          Color color = isSelected ? Colors.green : Colors.transparent;
          return InkWell(
            onTap: () {
              setState(() {
                selectedAlphabet = isSelected ? '' : a;
              });
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                // borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Text(
                a,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontSize: 22,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _listView(List<Contact> list) {
    return Expanded(
      child: list.isEmpty
          ? Center(child: Text('No contacts found'))
          : ListView.builder(
              physics: BouncingScrollPhysics(),
              controller: _scrollController,
              itemCount: list.length,
              itemBuilder: (context, int index) {
                final Contact contact = list[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 0.25,
                        color: Colors.yellow.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}. ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: _highlightAlphabet(contact.displayName),
                            style: TextStyle(
                              fontSize: 22,
                              color: txtclr,
                            ),
                          ),
                        ),
                      ),
                      callButton(contact.phones.firstOrNull?.number),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget callButton(String? number) {
    if (number == null) return SizedBox.shrink();
    return CircleAvatar(
      backgroundColor: Colors.green.shade800,
      child: IconButton(
        icon: Icon(
          Icons.call,
          size: 18,
          color: whiter,
        ),
        onPressed: () async {
          if (kDebugMode) {
            print('Dialing $number');
          }
          final DirectDialer dialer = await DirectDialer.instance;
          await dialer.dial(number);

          await saveRecentNumber(number);
        },
      ),
    );
  }

  Widget bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30), 
        ),
        child: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade600,
          currentIndex: currentPage,
          onTap: pageController.jumpToPage,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.history, size: 30), label: 'Recent'),
            BottomNavigationBarItem(icon: Icon(Icons.list, size: 30), label: 'All'),
            BottomNavigationBarItem(icon: Icon(Icons.dialpad, size: 28), label: 'Dialer'),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _highlightAlphabet(String displayName) {
    if (selectedAlphabet.isEmpty) {
      return [TextSpan(text: displayName)];
    }
    final matches = RegExp(RegExp.escape(selectedAlphabet)).allMatches(displayName);
    if (matches.isEmpty) {
      return [TextSpan(text: displayName)];
    }
    List<InlineSpan> spans = [];
    int last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(text: displayName.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: displayName.substring(match.start, match.end),
        style: TextStyle(
          backgroundColor: Colors.yellow.withValues(alpha: 0.15),
          color: Colors.white,
        ),
      ));
      last = match.end;
    }
    if (last < displayName.length) {
      spans.add(TextSpan(text: displayName.substring(last)));
    }
    return spans;
  }

  Future<void> loadContacts() async {
    try {
      await Permission.contacts.request();
      _isLoading = true;
      if (mounted) setState(() {});
      final sw = Stopwatch()..start();
      _contacts = await FastContacts.getAllContacts();
      sw.stop();
    } on PlatformException catch (e) {
      'Failed to get contacts:\n${e.details}';
    } finally {
      _isLoading = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  // Save recent number to SharedPreferences
  Future<void> saveRecentNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentNumbers.remove(number); // Remove if already exists
      _recentNumbers.insert(0, number); // Add to start
      if (_recentNumbers.length > 500) {
        _recentNumbers = _recentNumbers.sublist(0, 500);
      }
    });
    await prefs.setStringList('recent_numbers', _recentNumbers);
  }

  // Load recent numbers from SharedPreferences
  Future<void> loadRecentNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentNumbers = prefs.getStringList('recent_numbers') ?? [];
    });
  }
}
