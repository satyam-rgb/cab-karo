import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryFilterWidget extends StatelessWidget {
  final String selectedCategory; // 'all' | 'Auto' | 'Mini' | 'Sedan' | 'XL'
  final ValueChanged<String> onSelect;

  const CategoryFilterWidget({
    super.key,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const categories = ['all', 'Auto', 'Mini', 'Sedan', 'XL'];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
          final label = cat == 'all' ? 'All Rides' : cat;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelect(cat),
            selectedColor: AppTheme.primary,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textPrimary,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppTheme.primary : AppTheme.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
