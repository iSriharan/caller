import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactProfilePage extends StatefulWidget {
  final Contact contact;

  const ContactProfilePage({super.key, required this.contact});

  @override
  State<ContactProfilePage> createState() => _ContactProfilePageState();
}

class _ContactProfilePageState extends State<ContactProfilePage> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final String? number = widget.contact.phones.firstOrNull?.number;

    return Scaffold(
      appBar: AppBar(
        title: Text("Contact Profile"),
       
      ),
      body: Column(
        children: [
          profilecircle(),
          SizedBox(height: 15),
          details(number),
        ],
      ),
    );
  }

  Widget profilecircle() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Center(
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Colors.green,
          child: Text(
            widget.contact.displayName.isNotEmpty ? widget.contact.displayName[0] : '',
            style: const TextStyle(fontSize: 40, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget details(String? number) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 120, 
                child: Text("Name:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Expanded(
                child: Text(widget.contact.displayName, style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: Text("Phone number:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Expanded(
                child: Text(number ?? "No number available", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                child:
                    Text("Whatsapp:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              InkWell(
                onTap: () async {
                  final number = widget.contact.phones.firstOrNull?.number;
                  if (number != null) {
                    final uri = Uri.parse("https://wa.me/$number");
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Image.asset('assets/images/whatsapp.png', width: 40, height: 40),
              )
            ],
          ),
        ],
      ),
    );
  }
}
