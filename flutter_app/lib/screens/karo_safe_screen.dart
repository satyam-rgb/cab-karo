import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_profile_model.dart';
import '../models/coordinate_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class KaroSafeScreen extends StatefulWidget {
  final LocationCoordinate? currentCoord;

  const KaroSafeScreen({super.key, this.currentCoord});

  @override
  State<KaroSafeScreen> createState() => _KaroSafeScreenState();
}

class _KaroSafeScreenState extends State<KaroSafeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  void _loadContact() async {
    final contact = await StorageService.getEmergencyContact();
    _nameController.text = contact.name;
    _phoneController.text = contact.phone;
    if (mounted) setState(() => _isLoading = false);
  }

  void _saveContact() async {
    setState(() => _isSaving = true);
    final contact = EmergencyContact(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    await StorageService.saveEmergencyContact(contact);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contact saved successfully!')),
      );
    }
  }

  void _confirmAndTriggerSos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed),
            SizedBox(width: 8),
            Text('Confirm SOS Alert'),
          ],
        ),
        content: Text(
          'This will send an emergency SMS with your live GPS location to ${_nameController.text} (${_phoneController.text}). Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              Navigator.pop(context);
              _dispatchSosMessage();
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  void _dispatchSosMessage() async {
    final lat = widget.currentCoord?.latitude ?? 21.1458;
    final lng = widget.currentCoord?.longitude ?? 79.0882;
    final mapsLink = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final message = '🚨 KaroCab SOS Alert: I need immediate assistance! Current GPS location: $mapsLink';

    final uri = Uri.parse('sms:${_phoneController.text.trim()}?body=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open SMS application.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, size: 20, color: AppTheme.accentRed),
            SizedBox(width: 8),
            Text('KaroSafe Emergency Hub'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOS Trigger Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emergency, size: 48, color: AppTheme.accentRed),
                  const SizedBox(height: 12),
                  const Text(
                    'Emergency SOS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentRed),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap below in an emergency to send your GPS coordinates to your registered emergency contact.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
                      onPressed: _confirmAndTriggerSos,
                      icon: const Icon(Icons.send),
                      label: const Text('Trigger Emergency SOS'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Emergency Contact Section
            const Text(
              'Emergency Contact Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Phone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _saveContact,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Emergency Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
