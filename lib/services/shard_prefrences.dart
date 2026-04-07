import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


Future<void> saveContacts(List<Map<String, String>> contacts) async {
  final prefs = await SharedPreferences.getInstance();
  final String encoded = jsonEncode(contacts);
  await prefs.setString('emergency_contacts', encoded);
}


Future<List<Map<String, String>>> loadContacts() async {
  final prefs = await SharedPreferences.getInstance();
  final String? encoded = prefs.getString('emergency_contacts');
  if (encoded == null) return [];

  final List<dynamic> decoded = jsonDecode(encoded);
  return decoded.map((e) => Map<String, String>.from(e)).toList();
}


Future<void> deleteContact(int index) async {
  final contacts = await loadContacts();
  contacts.removeAt(index);
  await saveContacts(contacts);
}