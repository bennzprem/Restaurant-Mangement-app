// TODO Implement this library.// lib/widgets/enhanced_chat_bot_widget.dart

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/auth_provider.dart';
import '../services/chat_service.dart';

class EnhancedChatBotWidget extends StatefulWidget {
  const EnhancedChatBotWidget({super.key});

  @override
  State<EnhancedChatBotWidget> createState() => _EnhancedChatBotWidgetState();
}

class _EnhancedChatBotWidgetState extends State<EnhancedChatBotWidget>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Services
  final ChatService _chatService = ChatService();
  late final GenerativeModel _model;
  String? _currentSessionId;

  // Replace with your actual Gemini API key
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeGeminiAI();
    _loadChatHistory();
    _addWelcomeMessage();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initializeGeminiAI() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
  }

  void _addWelcomeMessage() {
    _addMessage(ChatMessage(
      text:
          "Hello! I'm your restaurant assistant. I can help you with menu items, reservations, orders, and any questions about our restaurant. How can I assist you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _loadChatHistory() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId != null) {
        final history = await _chatService.getChatHistory(userId: userId);
        setState(() {
          _messages.clear();
          _messages.addAll(history.map((msg) => ChatMessage(
                text: msg['message'],
                isUser: msg['is_user'],
                timestamp: DateTime.parse(msg['created_at']),
              )));
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _animationController.forward();
      _pulseController.stop();
    } else {
      _animationController.reverse();
      _pulseController.repeat(reverse: true);
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();

    // Save to Supabase
    _saveMessageToDatabase(message);
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

  Future<void> _saveMessageToDatabase(ChatMessage message) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId != null) {
        _currentSessionId ??= DateTime.now().millisecondsSinceEpoch.toString();

        await _chatService.saveMessage(
          userId: userId,
          message: message.text,
          isUser: message.isUser,
          sessionId: _currentSessionId,
        );
      }
    } catch (e) {
      print('Error saving message to database: $e');
    }
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
            "I apologize, but I'm experiencing some technical difficulties. Please try again in a moment, or feel free to call our restaurant directly for immediate assistance.",
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
      // Get user context
      final authProvider = context.read<AuthProvider>();
      final userName = authProvider.user?.name ?? 'Guest';

      // Create restaurant-specific context
      final prompt = '''
You are a friendly and helpful AI assistant for a restaurant. Your name is "Resto Assistant".

Context about the user:
- User name: $userName
- They are logged into our restaurant app
- They can view their order history, make reservations, and order food through the app

Your capabilities:
- Answer questions about menu items, ingredients, and dietary restrictions
- Help with reservation inquiries and table availability
- Provide information about order status and delivery times
- Explain restaurant policies, hours, and location
- Suggest dishes based on preferences
- Help with account-related questions

Restaurant Information:
- We serve a variety of cuisines with fresh, high-quality ingredients
- We offer both dine-in and delivery services
- We accommodate dietary restrictions (vegetarian, vegan, gluten-free options available)
- We accept reservations through the app
- Operating hours: 11 AM to 11 PM daily

Guidelines:
- Be friendly, professional, and helpful
- Keep responses conversational but informative
- If you don't know specific menu details or current availability, suggest they check the menu section of the app
- For urgent issues, recommend calling the restaurant directly
- Always maintain a positive, welcoming tone

Customer message: $message

Provide a helpful response:
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ??
          "I'm sorry, I couldn't process that request. Could you please rephrase your question?";
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
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
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 380,
                  height: 550,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildChatHeader(),
                      _buildMessagesList(),
                      if (_isTyping) _buildTypingIndicator(),
                      _buildMessageInput(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Floating chat button with pulse animation
        Positioned(
          bottom: 20,
          right: 20,
          child: ScaleTransition(
            scale: _isOpen ? _scaleAnimation : _pulseAnimation,
            child: FloatingActionButton(
              onPressed: _toggleChat,
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 6,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isOpen ? Icons.close : Icons.chat_bubble,
                  key: ValueKey(_isOpen),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8)
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurant Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Here to help with your dining needs',
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
    );
  }

  Widget _buildMessagesList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return _buildMessageBubble(_messages[index]);
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Typing...',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
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
                hintText: 'Ask me anything about our restaurant...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                prefixIcon: const Icon(Icons.message_outlined),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: _sendMessage,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 2,
            child: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.restaurant, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Theme.of(context).primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomLeft: message.isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: message.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final user = auth.user;
                final initials = (user?.name.isNotEmpty ?? false)
                    ? user!.name
                        .trim()
                        .split(" ")
                        .map((n) => n.isNotEmpty ? n[0] : "")
                        .take(2)
                        .join()
                        .toUpperCase()
                    : "U";

                return CircleAvatar(
                  radius: 16,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: user?.avatarUrl == null
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
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
