import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/auth_provider.dart';

class ChatBotWidget extends StatefulWidget {
  const ChatBotWidget({super.key});

  @override
  State<ChatBotWidget> createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends State<ChatBotWidget>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Initialize Gemini AI
  late final GenerativeModel _model;
  static const String _apiKey =
      'AIzaSyB_y6KC5Ybghk8el612HB7UmCBkQ1PvqN0'; // Replace with your API key

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // Initialize Gemini AI
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );

    // Add welcome message
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final userName = authProvider.user?.name;

    // Get current time for greeting
    final now = DateTime.now();
    final hour = now.hour;

    String timeGreeting;
    if (hour < 12) {
      timeGreeting = "Good morning";
    } else if (hour < 17) {
      timeGreeting = "Good afternoon";
    } else {
      timeGreeting = "Good evening";
    }

    String welcomeMessage;
    if (isLoggedIn && userName != null && userName.isNotEmpty) {
      welcomeMessage =
          "✨ $timeGreeting, $userName! I'm ByteBot — your friendly dining guide. Tap the chat or say 'Hi ByteBot' to get started.";
    } else {
      welcomeMessage =
          "✨ $timeGreeting! I'm ByteBot — your friendly dining guide. Tap the chat or say 'Hi ByteBot' to get started.";
    }

    _addMessage(ChatMessage(
      text: welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();

    // Save to Supabase (you can implement this later)
    // _saveMessageToSupabase(message);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    _addMessage(ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _messageController.clear();
    setState(() {
      _isTyping = true;
    });

    try {
      // Send to Gemini AI
      final response = await _sendToGeminiAI(message);

      // Add AI response
      _addMessage(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _addMessage(ChatMessage(
        text:
            "Sorry, I'm having trouble connecting right now. Please try again later.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isTyping = false;
    });
  }

  Future<String> _sendToGeminiAI(String message) async {
    try {
      // Create context for ByteBot (restaurant assistant)
      final prompt = '''
You are ByteBot, a helpful restaurant assistant chatbot. You help customers with:
- Menu inquiries
- Reservation questions
- Order status
- Restaurant information
- General dining questions

Customer message: $message

Please provide a helpful, friendly response focused on restaurant services.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? "I'm sorry, I couldn't process that request.";
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  // Future method to save messages to Supabase
  Future<void> _saveMessageToSupabase(ChatMessage message) async {
    // Implement Supabase integration here
    // Example:
    /*
    try {
      await Supabase.instance.client
        .from('chat_messages')
        .insert({
          'user_id': 'current_user_id', // Get from your auth provider
          'message': message.text,
          'is_user': message.isUser,
          'timestamp': message.timestamp.toIso8601String(),
        });
    } catch (e) {
      print('Error saving message: $e');
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Chat popup
        if (_isOpen)
          Positioned(
            bottom: 80,
            right: 20,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 350,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blueAccent],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.smart_toy, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ByteBot',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleChat,
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
                    ),
                    // Typing indicator
                    if (_isTyping)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.smart_toy,
                                  size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Typing...'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Input field
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            onPressed: _sendMessage,
                            backgroundColor: Colors.blue,
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Floating chat button
        Positioned(
          bottom: 20,
          right: 20,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: FloatingActionButton(
              onPressed: _toggleChat,
              backgroundColor: Colors.blue,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isOpen ? Icons.close : Icons.chat,
                  key: ValueKey(_isOpen),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// 3. Update your user_dashboard_page.dart to include the chatbot

// Add this import at the top of your user_dashboard_page.dart:
// import 'widgets/chat_bot_widget.dart';

// Then modify your build method to include the chatbot as a Stack:

/*
@override
Widget build(BuildContext context) {
  bool isWideScreen = MediaQuery.of(context).size.width > 800;

  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      title: Text(_tabs[_selectedIndex]['title']),
      leading: isWideScreen
          ? null
          : Builder(
              builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer())),
    ),
    drawer: isWideScreen ? null : Drawer(child: _buildSidebar(context)),
    body: Stack(  // Wrap with Stack
      children: [
        Row(
          children: [
            if (isWideScreen) _buildSidebar(context),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
        // Add the chatbot widget
        const ChatBotWidget(),
      ],
    ),
  );
}
*/
