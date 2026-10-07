import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DestinationExplorerScreen extends StatefulWidget {
  final ValueChanged<String> onSelectDestination;

  const DestinationExplorerScreen({super.key, required this.onSelectDestination});

  @override
  State<DestinationExplorerScreen> createState() => _DestinationExplorerScreenState();
}

class _DestinationExplorerScreenState extends State<DestinationExplorerScreen> {
  String _selectedCategory = 'Transit';
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, List<Map<String, String>>> _destinationsByCategory = {
    'Transit': [
      {'name': 'Nagpur Railway Station', 'desc': 'Central Railway junction', 'dist': '1.2 km'},
      {'name': 'Itwari Railway Station', 'desc': 'Eastern city terminus', 'dist': '5.8 km'},
      {'name': 'Nagpur Airport (NAG)', 'desc': 'Dr. Babasaheb Ambedkar International', 'dist': '8.5 km'},
      {'name': 'Sitabuldi Interchange Metro', 'desc': 'Central metro hub', 'dist': '0.8 km'},
    ],
    'Shopping': [
      {'name': 'Dharampeth Shopping Street', 'desc': 'Apparel, jewelry, cafes', 'dist': '3.2 km'},
      {'name': 'VR Mall Nagpur', 'desc': 'Premium retail, food court & cinema', 'dist': '7.1 km'},
      {'name': 'Sitabuldi Main Market', 'desc': 'Bustling traditional market', 'dist': '1.0 km'},
    ],
    'Tourism': [
      {'name': 'Deekshabhoomi', 'desc': 'Historic Buddhist monument', 'dist': '4.5 km'},
      {'name': 'Futala Lake', 'desc': 'Scenic promenade & evening fountains', 'dist': '5.2 km'},
      {'name': 'Ambazari Lake & Garden', 'desc': 'Lakeside park & boating', 'dist': '6.4 km'},
    ],
    'Business': [
      {'name': 'MIHAN SEZ / Infosys & TCS', 'desc': 'Multi-modal International Cargo & IT Hub', 'dist': '14.2 km'},
      {'name': 'Civil Lines Administrative Complex', 'desc': 'Government & corporate offices', 'dist': '2.4 km'},
    ],
  };

  void _switchCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _isLoading = true;
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _destinationsByCategory[_selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destination Explorer'),
      ),
      body: Column(
        children: [
          // Category Selector
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: _destinationsByCategory.keys.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => _switchCategory(cat),
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Content States (Loading, Error, Empty, List)
          Expanded(
            child: _buildBody(list),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Map<String, String>> list) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppTheme.accentRed),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _switchCategory(_selectedCategory),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.location_off_outlined, size: 40, color: AppTheme.textSecondary),
            SizedBox(height: 8),
            Text('No destinations found for this category', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.place_outlined, color: AppTheme.primary),
            ),
            title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(item['desc']!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item['dist']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary),
              ],
            ),
            onTap: () {
              widget.onSelectDestination(item['name']!);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}
