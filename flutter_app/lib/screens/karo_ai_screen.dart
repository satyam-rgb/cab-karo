import 'package:flutter/material.dart';
import '../models/pricing_response_model.dart';
import '../services/karo_ai_service.dart';
import '../theme/app_theme.dart';

class KaroAiScreen extends StatefulWidget {
  final PricingResponse? pricingContext;
  final String fromAddress;
  final String toAddress;

  const KaroAiScreen({
    super.key,
    this.pricingContext,
    required this.fromAddress,
    required this.toAddress,
  });

  @override
  State<KaroAiScreen> createState() => _KaroAiScreenState();
}

class _KaroAiScreenState extends State<KaroAiScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  final List<String> _suggestedPrompts = [
    'Which ride is cheapest?',
    'Which is fastest?',
    'Which ride should I take?',
    'Is this fare worth the price?',
  ];

  @override
  void initState() {
    super.initState();
    final greeting = KaroAiService.respond(
      query: 'overview',
      context: widget.pricingContext,
      fromAddress: widget.fromAddress,
      toAddress: widget.toAddress,
    );
    _messages.add({'sender': 'ai', 'text': greeting});
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
    });
    _inputController.clear();

    Future.delayed(const Duration(milliseconds: 300), () {
      final reply = KaroAiService.respond(
        query: text,
        context: widget.pricingContext,
        fromAddress: widget.fromAddress,
        toAddress: widget.toAddress,
      );
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': reply});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, size: 20, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('KaroAI Mobility Advisor'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Suggested Quick Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: isUser ? null : Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: isUser ? Colors.white : AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'Ask KaroAI about rides or routes...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendMessage(_inputController.text),
                  icon: const Icon(Icons.send, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
