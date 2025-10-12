import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'cart_provider.dart'; // <-- CORRECTED

enum VoiceState { idle, listening, processing, responding }

class VoiceInteractionOverlay extends StatefulWidget {
  const VoiceInteractionOverlay({super.key});

  @override
  State<VoiceInteractionOverlay> createState() =>
      _VoiceInteractionOverlayState();
}

class _VoiceInteractionOverlayState extends State<VoiceInteractionOverlay>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // Ensure we only speak the greeting once per overlay open
  bool _hasSpokenGreeting = false;
  // Control the background wake-word listening loop
  bool _wakeLoopActive = true;
  // Mic hover state for UI
  bool _isMicHovered = false;

  VoiceState _currentState = VoiceState.idle;
  String _lastWords = "";
  String _aiResponse = "";
  Map<String, dynamic> _conversationContext = {};

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _clickController;
  late Animation<double> _clickAnimation;

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
    // small click/tap animation for the mic button
    _clickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _clickAnimation = Tween<double>(begin: 0.0, end: 0.08).animate(
      CurvedAnimation(parent: _clickController, curve: Curves.easeOut),
    );
    _clickController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _clickController.reverse();
      }
    });
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    _speechToText.statusListener = (status) {
      if (status == 'done' && _currentState == VoiceState.listening) {
        _stopListening();
      }
    };
    setState(() {});
    // Start a lightweight wake-word loop to listen for "hey bytebot"
    _startWakeLoop();
  }

  // Lightweight loop that periodically listens for the wake phrase when idle
  void _startWakeLoop() async {
    _wakeLoopActive = true;
    while (mounted && _wakeLoopActive) {
      try {
        if (_currentState == VoiceState.idle && !_speechToText.isListening) {
          await _speechToText.listen(
            onResult: _onWakeResult,
            listenFor: const Duration(seconds: 6),
            pauseFor: const Duration(seconds: 2),
            partialResults: true,
          );
        }
      } catch (_) {
        // ignore listen errors and retry
      }
      // small delay before next loop iteration
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _onWakeResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.toLowerCase();
    if (words.contains('hey bytebot') || words.contains('hi bytebot')) {
      // Stop the wake listener and start active listening
      try {
        _speechToText.stop();
      } catch (_) {}
      if (mounted) {
        _startListening();
      }
    }
  }

  void _startListening() async {
    await _flutterTts.stop();
    setState(() {
      _currentState = VoiceState.listening;
      _lastWords = "";
      _aiResponse = "";
    });
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
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
          Provider.of<CartProvider>(context, listen: false)
              .updateCartFromVoice(cartData);
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
    // stop wake loop and ongoing speech/listening
    _wakeLoopActive = false;
    try {
      _speechToText.stop();
    } catch (_) {}
    try {
      _flutterTts.stop();
    } catch (_) {}
    try {
      _clickController.dispose();
    } catch (_) {}
    _animationController.dispose();
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

  // Builds the status/greeting text and handles speaking the greeting once
  Widget _buildStatusText() {
    String text;
    // Show personalized greeting based on time and user status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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

    if (isLoggedIn && userName != null && userName.isNotEmpty) {
      text =
          "$timeGreeting, $userName! I'm ByteBot — your bite-sized dining guide. Tap the mic or say 'Hey ByteBot' to speak.";
    } else {
      text =
          "$timeGreeting! I'm ByteBot — your bite-sized dining guide. Tap the mic or say 'Hey ByteBot' to speak.";
    }

    // Speak the greeting once when overlay is shown
    if (!_hasSpokenGreeting) {
      _hasSpokenGreeting = true;
      Future.microtask(() {
        _flutterTts.speak(text).catchError((_) {});
      });
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isMicHovered = true),
          onExit: (_) => setState(() => _isMicHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              // play click animation
              try {
                _clickController.forward(from: 0.0);
              } catch (_) {}
              if (_speechToText.isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final baseScale = _currentState == VoiceState.listening
                    ? _pulseAnimation.value
                    : (_isMicHovered ? 1.06 : 1.0);
                final clickFactor = 1.0 + (_clickAnimation.value);
                return Transform.scale(
                    scale: baseScale * clickFactor, child: child);
              },
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Enhanced rotating sweep-gradient ring for hover (modern look)
                    AnimatedOpacity(
                      opacity: _isMicHovered ? 1.0 : 0.72,
                      duration: const Duration(milliseconds: 260),
                      child: AnimatedRotation(
                        turns: _isMicHovered ? 0.12 : 0.0,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeInOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          width: _isMicHovered ? 130 : 100,
                          height: _isMicHovered ? 130 : 100,
                          alignment: Alignment.center,
                          child: Container(
                            width: _isMicHovered ? 122 : 100,
                            height: _isMicHovered ? 122 : 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                startAngle: 0.0,
                                endAngle: 6.28,
                                colors: [
                                  Colors.transparent,
                                  Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.32),
                                  Theme.of(context)
                                      .primaryColorLight
                                      .withOpacity(0.22),
                                  Theme.of(context)
                                      .primaryColorDark
                                      .withOpacity(0.14),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.18, 0.45, 0.75, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(_isMicHovered ? 0.36 : 0.12),
                                  blurRadius: _isMicHovered ? 48 : 18,
                                  spreadRadius: _isMicHovered ? 14 : 4,
                                ),
                              ],
                            ),
                            // inner soft glow to make the button pop
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isMicHovered ? 84 : 68,
                                height: _isMicHovered ? 84 : 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Theme.of(context)
                                          .primaryColor
                                          .withOpacity(
                                              _isMicHovered ? 0.22 : 0.08),
                                      Colors.transparent
                                    ],
                                    stops: const [0.0, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // The actual circular button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentState == VoiceState.listening
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        border: Border.all(
                          color: _isMicHovered
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withOpacity(0.0),
                          width: _isMicHovered ? 2.5 : 0.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(_isMicHovered ? 0.18 : 0.08),
                            blurRadius: _isMicHovered ? 18 : 8,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.android,
                        // White only when actively listening; use primary color on hover for contrast
                        color: _currentState == VoiceState.listening
                            ? Colors.white
                            : (_isMicHovered
                                ? Theme.of(context).primaryColor
                                : Colors.black),
                        size: 56,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap to speak',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
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
