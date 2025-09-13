import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'cart_provider.dart'; // <-- CORRECTED
import 'models.dart';      // <-- CORRECTED

enum VoiceState { idle, listening, processing, responding }

class VoiceInteractionOverlay extends StatefulWidget {
  const VoiceInteractionOverlay({super.key});

  @override
  State<VoiceInteractionOverlay> createState() => _VoiceInteractionOverlayState();
}

class _VoiceInteractionOverlayState extends State<VoiceInteractionOverlay> with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  VoiceState _currentState = VoiceState.idle;
  String _lastWords = "";
  String _aiResponse = "";
  Map<String, dynamic> _conversationContext = {};
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    setState(() {
      _currentState = VoiceState.listening;
      _lastWords = "";
      _aiResponse = "";
    });
    await _speechToText.listen(onResult: _onSpeechResult);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      if (_lastWords.isNotEmpty) {
        _currentState = VoiceState.processing;
        _sendCommandToBackend();
      } else {
        _currentState = VoiceState.idle;
      }
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  Future<void> _sendCommandToBackend() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final url = Uri.parse('http://127.0.0.1:5000/voice-command');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'text': _lastWords,
          'context': _conversationContext, // Send the memory to the backend
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final message = responseData['message'];
        final action = responseData['action'];
        final newContext = responseData['new_context'];
        final cartData = responseData['updated_cart'];

        setState(() {
          _aiResponse = message;
          _currentState = VoiceState.responding;
          // Receive and save the updated memory from the backend
          if (newContext != null && newContext is Map) {
            _conversationContext = Map<String, dynamic>.from(newContext);
          }
        });

        await _flutterTts.speak(_aiResponse);

        // --- THIS IS THE FIX FOR REDIRECTION ---
        if (action == 'NAVIGATE_TO_LOGIN') {
          await Future.delayed(const Duration(milliseconds: 2500));
          if (mounted) {
            Navigator.of(context).pop(); // Close the overlay
            Navigator.of(context).pushNamed('/login'); // Navigate to login page
          }
        }
        
        if (cartData != null && cartData is List && mounted) {
          Provider.of<CartProvider>(context, listen: false).updateCartFromVoice(cartData);
        }

      } else {
        throw Exception('Failed to get response from server.');
      }
    } catch (e) {
      setState(() {
        _aiResponse = "Sorry, I'm having trouble connecting. Please try again.";
        _currentState = VoiceState.responding;
      });
       await _flutterTts.speak(_aiResponse);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusText(),
            const SizedBox(height: 40),
            _buildMicButton(),
            const SizedBox(height: 40),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    String text;
    switch (_currentState) {
      case VoiceState.idle:
        text = "Tap the bot to start speaking.";
        break;
      case VoiceState.listening:
        text = _lastWords.isEmpty ? "Listening..." : _lastWords;
        break;
      case VoiceState.processing:
        text = "Thinking...";
        break;
      case VoiceState.responding:
        text = _aiResponse;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTapDown: (_) => _startListening(),
      onTapUp: (_) => _stopListening(),
      onTapCancel: () => _stopListening(),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _currentState == VoiceState.listening ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentState == VoiceState.listening ? Color(0xFFDAE952) : Colors.white.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFDAE952).withOpacity(0.5),
                blurRadius: _currentState == VoiceState.listening ? 30 : 10,
                spreadRadius: _currentState == VoiceState.listening ? 10 : 2,
              )
            ]
          ),
          child: Icon(
            Icons.android, // Bot Icon
            color: Colors.black,
            size: 60,
          ),
        ),
      ),
    );
  }
   Widget _buildCloseButton() {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text(
        "Close",
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}
