import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';
import '../models/price_alert_model.dart';

class StorageService {
  static const _profileKey = 'karocab_user_profile';
  static const _alertsKey = 'karocab_price_alerts';
  static const _emergencyKey = 'karocab_emergency_contact';
  static const _onboardedKey = 'karocab_onboarded';

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  static Future<void> setOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, value);
  }

  static Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }

  static Future<List<PriceAlert>> getPriceAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alertsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => PriceAlert.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePriceAlert(PriceAlert alert) async {
    final alerts = await getPriceAlerts();
    alerts.insert(0, alert);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsKey, jsonEncode(alerts.map((e) => e.toJson()).toList()));
  }

  static Future<void> deletePriceAlert(String id) async {
    final alerts = await getPriceAlerts();
    alerts.removeWhere((a) => a.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsKey, jsonEncode(alerts.map((e) => e.toJson()).toList()));
  }

  static Future<EmergencyContact> getEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emergencyKey);
    if (raw == null) {
      return const EmergencyContact(name: 'Family / Guardian', phone: '+919876543210');
    }
    try {
      return EmergencyContact.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const EmergencyContact(name: 'Family / Guardian', phone: '+919876543210');
    }
  }

  static Future<void> saveEmergencyContact(EmergencyContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emergencyKey, jsonEncode(contact.toJson()));
  }
}
