import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  final TextEditingController _budgetController = TextEditingController();
  String _selectedMode = 'balanced';
  bool _comfortPreference = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final prof = await StorageService.getUserProfile();
    if (prof != null) {
      _profile = prof;
      _budgetController.text = prof.monthlyBudget.toInt().toString();
      _selectedMode = prof.preferences.mode;
      _comfortPreference = prof.preferences.comfort;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _savePreferences() async {
    setState(() => _isSaving = true);
    final budget = double.tryParse(_budgetController.text.trim()) ?? 4500.0;
    final updated = UserProfile(
      phone: _profile?.phone ?? '+919876543210',
      monthlyBudget: budget,
      preferences: UserPreferences(mode: _selectedMode, comfort: _comfortPreference),
      createdAt: _profile?.createdAt ?? DateTime.now().toIso8601String(),
      lastLoginAt: DateTime.now().toIso8601String(),
    );
    await StorageService.saveUserProfile(updated);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile preferences saved!')),
      );
    }
  }

  void _handleLogout() async {
    await StorageService.logout();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile & Preferences')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: const Icon(Icons.person, size: 32, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile?.phone ?? '+91 98765 43210',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Text('KaroCab Mobility Member', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Monthly Budget
            const Text('Monthly Commute Budget', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),

            // Default Mode
            const Text('Default Scoring Preference', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              items: const [
                DropdownMenuItem(value: 'budget', child: Text('Budget (Lowest Fare Priority)')),
                DropdownMenuItem(value: 'hurry', child: Text('Hurry (Quickest Arrival Priority)')),
                DropdownMenuItem(value: 'balanced', child: Text('Balanced (KaroScore Harmonious Blend)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedMode = val);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // AC / Comfort toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('AC & High Comfort Preference', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Filter for sedans/SUVs when available', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              value: _comfortPreference,
              onChanged: (val) => setState(() => _comfortPreference = val),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePreferences,
                child: Text(_isSaving ? 'Saving...' : 'Save Preferences'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 12),

            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Log Out of KaroCab'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
