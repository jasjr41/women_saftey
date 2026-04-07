import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';
import '../models/contact.dart';

class LocationService {
  Future<List<Contact>> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(AppConstants.contactsKey);
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => Contact.fromJson(e)).toList();
  }

  Future<void> shareLocation(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Getting location...'),
          ],
        ),
      ),
    );

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      Navigator.pop(context);

      final contacts = await _loadContacts();
      final String locationMessage =
          '${AppConstants.locationMessage}https://maps.google.com/?q=${position.latitude},${position.longitude}';

      // Show share options
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Location Via',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.green),
                title: const Text('WhatsApp (All Contacts)'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final contact in contacts) {
                    final url =
                        'https://wa.me/91${contact.number}?text=${Uri.encodeComponent(locationMessage)}';
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.blue),
                title: const Text('SMS (All Contacts)'),
                onTap: () async {
                  Navigator.pop(context);
                  for (final contact in contacts) {
                    final smsUri = Uri(
                      scheme: 'sms',
                      path: contact.number,
                      queryParameters: {'body': locationMessage},
                    );
                    await launchUrl(smsUri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.red),
                title: const Text('Email'),
                onTap: () async {
                  Navigator.pop(context);
                  final emailUri = Uri(
                    scheme: 'mailto',
                    queryParameters: {
                      'subject': 'EMERGENCY - Location Alert',
                      'body': locationMessage,
                    },
                  );
                  await launchUrl(emailUri);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location')),
      );
    }
  }
}