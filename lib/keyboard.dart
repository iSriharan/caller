import 'package:flutter/material.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:caller/contact_profile.dart';
import 'package:direct_dialer/direct_dialer.dart';

class Keyboard extends StatefulWidget {
  const Keyboard({super.key});

  @override
  State<Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends State<Keyboard> {
  final TextEditingController _controller = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final status = await Permission.contacts.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contacts permission denied")),
      );
      return;
    }

    final contacts = await FastContacts.getAllContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _filteredContacts = contacts;
    });
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _contacts.where((c) {
        return c.displayName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _callNumber(String number) async {
    final dialer = await DirectDialer.instance;
    await dialer.dial(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keyboard")),
      body: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: "Search Contacts",
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _filterContacts,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _filteredContacts.isEmpty
                ? const Center(child: Text("No contacts found"))
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final number = contact.phones.isNotEmpty
                          ? contact.phones.first.number
                          : null;

                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(contact.displayName),
                        subtitle: number != null
                            ? Text(number)
                            : const Text("No number"),
                        trailing: number != null
                            ? IconButton(
                                icon:
                                    const Icon(Icons.call, color: Colors.green),
                                onPressed: () => _callNumber(number),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ContactProfilePage(contact: contact),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
