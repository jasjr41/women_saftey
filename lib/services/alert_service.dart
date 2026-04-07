import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/contact.dart';
import '../data/emergency_numbers_data.dart';

class AlertService {
  // Load saved emergency contacts
  Future<List<Contact>> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(AppConstants.contactsKey);
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => Contact.fromJson(e)).toList();
  }

  // Get current location as Google Maps link
  Future<String?> _getLocationLink() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return null;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }

  Future<void> sendSOSAlert(BuildContext context) async {
    HapticFeedback.heavyImpact();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Sending SOS Alert...'),
          ],
        ),
      ),
    );

    try {
      // Load contacts + location simultaneously
      final contacts = await _loadContacts();
      final locationLink = await _getLocationLink();

      Navigator.pop(context); // close loading

      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No emergency contacts found! Please add contacts first.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      // Build message
      final String message = locationLink != null
          ? '${AppConstants.sosMessage}\n📍 My location: $locationLink'
          : AppConstants.sosMessage;

      // Send SMS + WhatsApp to ALL contacts
      for (final contact in contacts) {
        // SMS
        final smsUri = Uri(
          scheme: 'sms',
          path: contact.number,
          queryParameters: {'body': message},
        );
        await launchUrl(smsUri);

        // WhatsApp
        final whatsappUrl =
            'https://wa.me/91${contact.number}?text=${Uri.encodeComponent(message)}';
        await launchUrl(Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS sent to ${contacts.length} contact(s)!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send SOS alert'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void showHotlineOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Emergency Hotlines',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...emergencyHotlines.map((hotline) => ListTile(
              leading: Icon(hotline.icon, color: hotline.color),
              title: Text(hotline.name),
              subtitle: Text(hotline.number),
              onTap: () async {
                Navigator.pop(context);
                await launchUrl(Uri.parse('tel:${hotline.number}'));
              },
            )).toList(),
          ],
        ),
      ),
    );
  }
}