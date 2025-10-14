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
  // Mic hover state for UI
  bool _isMicHovered = false;
  // Track if animation should be showing
  bool _showListeningAnimation = false;

  VoiceState _currentState = VoiceState.idle;
  String _lastWords = "";
  String _aiResponse = "";
  String _currentSpeechText = ""; // Current speech being recognized
  Map<String, dynamic> _conversationContext = {};

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _clickController;
  late Animation<double> _clickAnimation;
  late AnimationController _listeningController;
  late Animation<double> _listeningPulseAnimation;
  late Animation<double> _listeningRotationAnimation;

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

    // Listening animation controller
    _listeningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _listeningPulseAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _listeningController, curve: Curves.easeInOut),
    );

    _listeningRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listeningController, curve: Curves.linear),
    );

    // Wake word detection disabled - no timeout needed
  }

  void _initSpeech() async {
    bool available = await _speechToText.initialize();

    _speechToText.statusListener = (status) {

      if (status == 'done' && _currentState == VoiceState.listening) {

        _stopListening();
      }
      // Auto-stop listening after 30 seconds to give user enough time
      if (status == 'listening' && _currentState == VoiceState.listening) {
        Future.delayed(const Duration(seconds: 30), () {
          if (_currentState == VoiceState.listening) {

            _stopListening();
          }
        });
      }
    };
    setState(() {});
    // Wake word detection disabled - only respond to mic tap
  }

  // Wake word detection methods removed - only respond to mic tap

  void _startListening() async {
    
    // Stop any existing speech recognition first
    try {
      await _speechToText.stop();
    } catch (_) {}
    
    // Stop any ongoing speech
    await _flutterTts.stop();

    // Wake word detection disabled - no wake loop to stop

    // Ensure the speech engine is initialized (in case user taps immediately)
    try {
      final available = await _speechToText.initialize();
      if (!available) {

        return;
      }
    } catch (e) {

      return;
    }
    
    // Stop any existing animation
    _listeningController.stop();
    
    setState(() {
      _currentState = VoiceState.listening;
      _showListeningAnimation = true;
      _lastWords = "";
      _aiResponse = ""; // Clear previous AI response
      _currentSpeechText = ""; // Clear previous speech text
    });

    // Start animation immediately
    _listeningController.reset();
    _listeningController.repeat(reverse: true);

    // Start active listening
    _startActiveListening();
  }

  void _startActiveListening() async {
    
    try {
      // Start speech recognition with longer listening time for complete sentences
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30), // Increased to 30 seconds for complete sentences
        pauseFor: const Duration(seconds: 3), // Increased to 3 seconds for better response
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: false, // Don't cancel on minor errors
      );

    } catch (e) {

      // If speech recognition fails, reset to idle state
      setState(() {
        _currentState = VoiceState.idle;
        _showListeningAnimation = false;
      });
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
    } catch (e) {

    }
    
    // Stop the listening animation
    _listeningController.stop();
    setState(() {
      _showListeningAnimation = false;
      if (_lastWords.isNotEmpty) {
        _currentState = VoiceState.processing;
        _sendCommandToBackend();
      } else {
        _currentState = VoiceState.idle;
        // Wake word detection disabled - no wake loop to restart
      }
    });
  }

  Future<void> _waitForSpeechToComplete() async {
    // Calculate estimated speech duration based on message length
    // Average speaking rate is about 150 words per minute (2.5 words per second)
    int wordCount = _aiResponse.split(' ').length;
    int estimatedDurationMs = (wordCount / 2.5 * 1000).round();
    
    // Add buffer time for natural speech pauses
    int totalWaitTime = estimatedDurationMs + 1000; // Add 1 second buffer

    await Future.delayed(Duration(milliseconds: totalWaitTime));
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _currentSpeechText = result.recognizedWords; // Show current speech
    });
    
    // If we have a final result with words, stop listening after a short delay
    if (result.finalResult && result.recognizedWords.isNotEmpty) {

      Future.delayed(const Duration(seconds: 1), () {
        if (_currentState == VoiceState.listening) {
          _stopListening();
        }
      });
    }
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
      ).timeout(const Duration(seconds: 15)); // Add 15 second timeout for better response

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final message = responseData['message'];
        final action = responseData['action'];
        final newContext = responseData['new_context'];
        final cartData = responseData['updated_cart'];

        setState(() {
          _aiResponse = message ?? "";
          _currentState = VoiceState.responding;
          _showListeningAnimation = false;
          _currentSpeechText = _aiResponse; // Mirror spoken text in UI
          if (newContext != null && newContext is Map) {
            _conversationContext = Map<String, dynamic>.from(newContext);
          }
        });
        // Stop listening animation when responding
        _listeningController.stop();

        if (_aiResponse.isNotEmpty) {
          // Set faster speech rate for quicker response
          await _flutterTts.setSpeechRate(1.2); // Faster speech rate
          await _flutterTts.speak(_aiResponse);
        }
        
        // Keep the response visible and don't clear it - stay in responding state
        // This ensures the AI response stays on screen instead of reverting to greeting
        
        // Wake word detection disabled - no wake loop to restart

        // --- THIS IS THE FIX FOR REDIRECTION ---
        if (action == 'NAVIGATE_TO_LOGIN') {
          // Wait for speech to complete before navigating
          await _waitForSpeechToComplete();
          if (mounted) {
            Navigator.of(context).pop(); // Close the overlay
            Navigator.of(context).pushNamed('/login'); // Navigate to login page
          }
        } else if (action == 'NAVIGATE_TO_MENU') {
          // Wait for speech to complete before navigating
          await _waitForSpeechToComplete();
          if (mounted) {
            Navigator.of(context).pop(); // Close the overlay
            Navigator.of(context).pushNamed('/menu'); // Navigate to menu page
          }
        } else if (action == 'NAVIGATE_TO_ORDER_HISTORY') {
          // Wait for speech to complete before navigating
          await _waitForSpeechToComplete();
          if (mounted) {
            Navigator.of(context).pop(); // Close the overlay
            Navigator.of(context).pushNamed('/order-history'); // Navigate to order history page
          }
        } else if (action == 'NAVIGATE_TO_RESERVE_TABLE') {
          // Wait for speech to complete before navigating
          await _waitForSpeechToComplete();
          if (mounted) {
            Navigator.of(context).pop(); // Close the overlay
            Navigator.of(context).pushNamed('/reserve-table'); // Navigate to reserve table page
          }
        } else if (action == 'NAVIGATE_TO_RESERVATION_HISTORY') {
          // Wait for speech to complete before navigating
          await _waitForSpeechToComplete();
          if (mounted) {
            Navigator.of(context).pop(); // Close the overlay
            Navigator.of(context).pushNamed('/reservation-history'); // Navigate to reservation history page
          }
        }

        if (cartData != null && cartData is List && mounted) {
          Provider.of<CartProvider>(context, listen: false)
              .updateCartFromVoice(cartData);
        }
      } else {

        throw Exception('Failed to get response from server: ${response.statusCode}');
      }
    } catch (e) {

      setState(() {
        _aiResponse = "Sorry, I'm having trouble connecting. Please try again.";
        _currentState = VoiceState.responding;
        _showListeningAnimation = false;
        _currentSpeechText = _aiResponse; // Show error text too
      });
      _listeningController.stop();
      // Set faster speech rate for quicker response
      await _flutterTts.setSpeechRate(1.2); // Faster speech rate
      await _flutterTts.speak(_aiResponse);
      
      // Keep error response visible instead of clearing it
      // This ensures error messages stay on screen instead of reverting to greeting
      
      // Wake word detection disabled - no wake loop to restart
    }
  }

  @override
  void dispose() {
    // stop ongoing speech/listening
    try {
      _speechToText.stop();
    } catch (_) {}
    try {
      _flutterTts.stop();
    } catch (_) {}
    try {
      _clickController.dispose();
    } catch (_) {}
    try {
      _listeningController.dispose();
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
    
    // If ByteBot is responding, show the AI response
    if (_currentState == VoiceState.responding && _aiResponse.isNotEmpty) {
      text = "ByteBot: \"$_aiResponse\"";
    }
    // If processing (thinking), keep showing what the user said instead of greeting
    else if (_currentState == VoiceState.processing) {
      if (_lastWords.isNotEmpty) {
        text = "You said: \"$_lastWords\"";
      } else {
        text = ""; // keep UI clean while thinking if nothing was captured
      }
    }
    // If listening and user is speaking, show speech text
    else if (_showListeningAnimation && _currentSpeechText.isNotEmpty) {
      text = "You said: \"$_currentSpeechText\"";
    } else if (_showListeningAnimation) {
      text = "Listening... Say something or tap the mic to stop.";
    } else {
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
            "$timeGreeting, $userName! I'm ByteBot, your friendly guide to a tastier day. Tap the mic to speak.";
      } else {
        text =
            "$timeGreeting! I'm ByteBot, your friendly guide to a tastier day. Tap the mic to speak.";
      }
    }

    // Speak the greeting once when overlay is shown (only when idle)
    if (!_hasSpokenGreeting && !_showListeningAnimation && _currentState == VoiceState.idle) {
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
        style: TextStyle(
          color: _currentState == VoiceState.responding ? Colors.lightGreen : Colors.white,
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

              // Always start (will internally stop any existing sessions)
              _startListening();
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _pulseAnimation,
                _listeningPulseAnimation,
                _listeningRotationAnimation,
              ]),
              builder: (context, child) {
                final isListening = _currentState == VoiceState.listening;
                final baseScale = isListening
                    ? 1.0 + (_listeningPulseAnimation.value - 1.0) * 0.1  // Subtle scaling for main button
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
                    // Listening state: Multiple zooming rings
                    if (_showListeningAnimation) ...[
                      // Always visible base ring
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      // Animated pulsing ring
                      AnimatedBuilder(
                        animation: _listeningPulseAnimation,
                        builder: (context, child) {
                          final scale = _listeningPulseAnimation.value;
                          final opacity = (1.0 - (scale - 0.5) * 0.5).clamp(0.2, 0.8);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(opacity),
                                  width: 3,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Second animated ring
                      AnimatedBuilder(
                        animation: _listeningPulseAnimation,
                        builder: (context, child) {
                          final scale = (_listeningPulseAnimation.value - 0.3).clamp(0.0, 1.2);
                          final opacity = (1.0 - (scale - 0.0) * 0.6).clamp(0.1, 0.7);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(opacity),
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // Enhanced rotating sweep-gradient ring for hover (when not listening)
                    if (!_showListeningAnimation)
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
                    AnimatedBuilder(
                      animation: _listeningRotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _showListeningAnimation
                              ? _listeningRotationAnimation.value * 6.28
                              : 0.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _showListeningAnimation
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
                                  color: _showListeningAnimation
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.4)
                                      : Colors.black
                                          .withOpacity(_isMicHovered ? 0.18 : 0.08),
                                  blurRadius: _showListeningAnimation
                                      ? 25
                                      : (_isMicHovered ? 18 : 8),
                                  spreadRadius: _showListeningAnimation
                                      ? 8
                                      : (_isMicHovered ? 14 : 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.android,
                              // White only when actively listening; use primary color on hover for contrast
                              color: _showListeningAnimation
                                  ? Colors.white
                                  : (_isMicHovered
                                      ? Theme.of(context).primaryColor
                                      : Colors.black),
                              size: 56,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: _showListeningAnimation 
                ? Theme.of(context).primaryColor 
                : Colors.white70, 
            fontSize: 14,
            fontWeight: _showListeningAnimation 
                ? FontWeight.w600 
                : FontWeight.normal,
          ),
          child: Text(
            _showListeningAnimation 
                ? 'Listening...' 
                : 'Tap to speak',
          ),
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
