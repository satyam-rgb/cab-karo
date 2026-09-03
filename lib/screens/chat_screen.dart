import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = []; // Store chat messages
  late final GenerativeModel model;

  @override
  void initState() {
    super.initState();
    // Initialize the Gemini model
    model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: 'gemini_key', // Replace with your actual API key
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Chat with KaroCab'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'Type something to start the conversation!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(messages[index]['sender']!),
                        subtitle: Text(messages[index]['message']!),
                      );
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                _sendMessage(_controller.text);
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    // Add user message to the list
    setState(() {
      messages.add({'sender': 'You', 'message': message});
    });

    // Call Gemini API to get response
    String response = await fetchResponseFromGemini(message);

    // Add chatbot response to the list
    setState(() {
      messages.add({'sender': 'KaroCab Bots', 'message': response});
    });
  }

  String createPrompt(String userMessage) {
    return 'You are a chatbot for KaroCab, a Cab Price Comparison service developed by students of GHRCE. Answer the user\'s questions in a friendly manner. User: $userMessage';
  }

  Future<String> fetchResponseFromGemini(String message) async {
    final prompt =
        createPrompt(message); // Use the user message with the prompt template
    final content = [Content.text(prompt)];

    // Generate response using the Gemini model
    final response = await model.generateContent(content);

    return response.text ??
        'No response'; // Return the generated response or a default message
  }
}
