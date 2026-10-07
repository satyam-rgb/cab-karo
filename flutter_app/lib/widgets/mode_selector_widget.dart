import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModeSelectorWidget extends StatelessWidget {
  final String activeMode; // 'budget' | 'hurry' | 'balanced'
  final ValueChanged<String> onSelectMode;

  const ModeSelectorWidget({
    super.key,
    required this.activeMode,
    required this.onSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildItem(
            mode: 'budget',
            title: 'Budget',
            subtitle: '40% Price',
            icon: Icons.savings_outlined,
          ),
          _buildItem(
            mode: 'hurry',
            title: 'Hurry',
            subtitle: '30% Speed',
            icon: Icons.bolt,
          ),
          _buildItem(
            mode: 'balanced',
            title: 'Balanced',
            subtitle: 'Optimal Mix',
            icon: Icons.balance,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = activeMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelectMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
