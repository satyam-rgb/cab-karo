class UserPreferences {
  final String mode; // 'budget' | 'hurry' | 'balanced'
  final bool comfort;

  const UserPreferences({
    this.mode = 'balanced',
    this.comfort = false,
  });

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'comfort': comfort,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      mode: json['mode'] as String? ?? 'balanced',
      comfort: json['comfort'] as bool? ?? false,
    );
  }
}

class UserProfile {
  final String phone;
  final double monthlyBudget;
  final UserPreferences preferences;
  final String createdAt;
  final String lastLoginAt;

  const UserProfile({
    required this.phone,
    this.monthlyBudget = 4500.0,
    this.preferences = const UserPreferences(),
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'monthlyBudget': monthlyBudget,
    'preferences': preferences.toJson(),
    'createdAt': createdAt,
    'lastLoginAt': lastLoginAt,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phone: json['phone'] as String? ?? '+919876543210',
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 4500.0,
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>)
          : const UserPreferences(),
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      lastLoginAt: json['lastLoginAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

class EmergencyContact {
  final String name;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String? ?? 'Family / Guardian',
      phone: json['phone'] as String? ?? '+919876543210',
    );
  }
}
