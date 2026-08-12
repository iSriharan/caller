import 'package:caller/Dialer.dart';
import 'package:caller/contact_profile.dart';
import 'package:direct_dialer/direct_dialer.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'keyboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController pageController = PageController();
  List<Contact> _contacts = const [];

  bool isTamil = true;

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
      body: body(),
      bottomNavigationBar: bottomNav(),
    );
  }

  /// AppBar used by recents and all-contacts pages (not dialer).
  PreferredSizeWidget _pageAppBar() {
    return AppBar(
      title: const Center(
        child: Text('Caller', style: TextStyle(fontSize: 26)),
      ),
      leading: languageButton(),
      actions: [searchicon()],
    );
  }

  Widget searchicon() {
    return IconButton(
      icon: const Icon(Icons.search),
      tooltip: 'Open Keyboard',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Keyboard()),
        );
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

          if (_scrollController.hasClients) _scrollController.jumpTo(0);
        });
      },
    );
  }

  Widget body() {
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

  /// Extracts unique Tamil first-characters from all contacts.
  List<String> get tamilAlphabets {
    final Set<String> chars = {};
    for (final contact in contacts) {
      final name = contact.displayName.trim();
      if (name.isEmpty) continue;
      final firstChar = name.characters.first;
      if (!RegExp(r'[a-zA-Z]').hasMatch(firstChar)) {
        chars.add(firstChar);
      }
    }
    final sorted = chars.toList()..sort();
    return sorted;
  }

  /// Extracts unique English first-letters (A–Z) from all contacts.
  List<String> get englishAlphabets {
    final Set<String> chars = {};
    for (final contact in contacts) {
      final name = contact.displayName.trim();
      if (name.isEmpty) continue;
      final firstChar = name.characters.first;
      if (RegExp(r'[a-zA-Z]').hasMatch(firstChar)) {
        chars.add(firstChar.toUpperCase());
      }
    }
    final sorted = chars.toList()..sort();
    return sorted;
  }

  Widget allPage() {
    List<Contact> list = contacts.where((c) {
      if (selectedAlphabet.isEmpty) return true;
      final firstChar = c.displayName.trim().characters.firstOrNull ?? '';
      if (isTamil) {
        return firstChar == selectedAlphabet;
      } else {
        return firstChar.toUpperCase() == selectedAlphabet;
      }
    }).toList();

    final alphabets = isTamil ? tamilAlphabets : englishAlphabets;

    return Column(
      children: [
        _pageAppBar(),
        Expanded(
          child: Row(
            children: [
              _alphabetSidebar(alphabets),
              Expanded(
                child: Column(
                  children: [
                    _listView(list),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _alphabetSidebar(List<String> alphabets) {
    if (alphabets.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 42,
      color: keyboardBg,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: alphabets.length,
        itemBuilder: (context, index) {
          final char = alphabets[index];
          final isSelected = selectedAlphabet == char;
          return InkWell(
            onTap: () {
              setState(() {
                selectedAlphabet = isSelected ? '' : char;
                if (_scrollController.hasClients) _scrollController.jumpTo(0);
              });
            },
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                char,
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget recentsPage() {
    List<Contact> list = contacts.where((c) {
      return c.phones.any((phone) => _recentNumbers.contains(phone.number));
    }).toList();

    return Column(
      children: [
        _pageAppBar(),
        Expanded(
          child: Column(
            children: [
              _listView(list),
            ],
          ),
        ),
      ],
    );
  }

  Widget dialpad() {
    return DialerPage();
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
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContactProfilePage(contact: contact),
                      ),
                    );
                  },
                  child: Container(
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
            BottomNavigationBarItem(
                icon: Icon(Icons.history, size: 30), label: 'Recent'),
            BottomNavigationBarItem(
                icon: Icon(Icons.list, size: 30), label: 'All'),
            BottomNavigationBarItem(
                icon: Icon(Icons.dialpad, size: 28), label: 'Dialer'),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _highlightAlphabet(String displayName) {
    if (selectedAlphabet.isEmpty) {
      return [TextSpan(text: displayName)];
    }
    final matches =
        RegExp(RegExp.escape(selectedAlphabet)).allMatches(displayName);
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
