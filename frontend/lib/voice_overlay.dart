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
  // Track if animation should be showing
  bool _showListeningAnimation = false;
  // Track wake word listening timeout
  bool _wakeWordTimeout = false;

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

    // Start wake word timeout - stop listening for wake words after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _wakeWordTimeout = true;
        });
        _wakeLoopActive = false;
        print('Wake word listening timeout - stopping wake word detection');
      }
    });
  }

  void _initSpeech() async {
    bool available = await _speechToText.initialize();
    print('Speech recognition available: $available');
    
    _speechToText.statusListener = (status) {
      print('Speech recognition status: $status');
      if (status == 'done' && _currentState == VoiceState.listening) {
        print('Speech recognition done, stopping listening');
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
    while (mounted && _wakeLoopActive && !_wakeWordTimeout) {
      try {
        // Only start wake word detection if we're truly idle and not listening
        if (_currentState == VoiceState.idle && 
            !_speechToText.isListening && 
            !_showListeningAnimation &&
            _currentState != VoiceState.listening &&
            !_wakeWordTimeout) {
          print('Starting wake word detection...'); // Debug log
          await _speechToText.listen(
            onResult: _onWakeResult,
            listenFor: const Duration(seconds: 8),
            pauseFor: const Duration(seconds: 2),
            partialResults: true,
            localeId: 'en_US',
          );
        }
      } catch (e) {
        print('Wake word detection error: $e'); // Debug log
        // ignore listen errors and retry
      }
      // small delay before next loop iteration
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    print('Wake word loop stopped - timeout reached or overlay closed');
  }

  void _onWakeResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.toLowerCase();
    print('Wake word detected: "$words"'); // Debug log
    
    // More flexible wake word detection
    if (words.contains('hey bytebot') || 
        words.contains('hi bytebot') || 
        words.contains('bytebot') ||
        words.contains('hey byte bot') ||
        words.contains('hi byte bot') ||
        words.contains('hey bitebot') ||
        words.contains('hi bitebot')) {
      
      print('Wake word matched! Starting listening...'); // Debug log
      
      // Stop the wake listener and start active listening
      try {
        _speechToText.stop();
        print('Wake word speech recognition stopped');
      } catch (e) {
        print('Error stopping wake word speech recognition: $e');
      }
      
      if (mounted) {
        // Stop any ongoing speech first
        _flutterTts.stop();
        print('Stopped any ongoing speech');
        // Immediately start listening with animation
        print('Calling _startListening() from wake word detection');
        _startListening();
      } else {
        print('Widget not mounted, cannot start listening');
      }
    } else {
      print('Wake word not matched for: "$words"');
    }
  }

  void _startListening() async {
    print('_startListening() called - starting listening with animation'); // Debug log
    
    // Stop any existing speech recognition first
    try {
      await _speechToText.stop();
    } catch (_) {}
    
    // Stop any ongoing speech
    await _flutterTts.stop();
    
    // Stop any existing animation
    _listeningController.stop();
    
    setState(() {
      _currentState = VoiceState.listening;
      _showListeningAnimation = true;
      _lastWords = "";
      _aiResponse = ""; // Clear previous AI response
      _currentSpeechText = ""; // Clear previous speech text
    });
    
    print('State set to listening, animation flag set to true'); // Debug log
    
    // Start animation immediately
    _listeningController.reset();
    _listeningController.repeat(reverse: true);
    
    print('Animation started, beginning speech recognition for 10 seconds'); // Debug log
    
    // Start speech recognition
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    // Stop the listening animation
    _listeningController.stop();
    setState(() {
      _showListeningAnimation = false;
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
      _currentSpeechText = result.recognizedWords; // Show current speech
    });
  }

  Future<void> _sendCommandToBackend() async {
    try {
      print('Sending command to backend: "$_lastWords"');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final url = Uri.parse('http://127.0.0.1:5000/voice-command');
      print('Backend URL: $url');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'text': _lastWords,
          'context': _conversationContext, // Send the memory to the backend
        }),
      );
      
      print('Backend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final message = responseData['message'];
        final action = responseData['action'];
        final newContext = responseData['new_context'];
        final cartData = responseData['updated_cart'];

        print('Backend response message: "$message"');
        print('Backend response action: "$action"');

        setState(() {
          _aiResponse = message;
          _currentState = VoiceState.responding;
          _showListeningAnimation = false;
          _currentSpeechText = ""; // Clear speech text when responding
          // Receive and save the updated memory from the backend
          if (newContext != null && newContext is Map) {
            _conversationContext = Map<String, dynamic>.from(newContext);
          }
        });
        // Stop listening animation when responding
        _listeningController.stop();

        print('Speaking response: "$_aiResponse"');
        await _flutterTts.speak(_aiResponse);
        
        // Keep the response visible for a few seconds before clearing
        await Future.delayed(const Duration(seconds: 3));
        
        // Return to idle state after speaking
        if (mounted) {
          setState(() {
            _currentState = VoiceState.idle;
            _aiResponse = ""; // Clear AI response when returning to idle
          });
        }

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
        print('Backend error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get response from server: ${response.statusCode}');
      }
    } catch (e) {
      print('Backend communication error: $e');
      setState(() {
        _aiResponse = "Sorry, I'm having trouble connecting. Please try again.";
        _currentState = VoiceState.responding;
        _showListeningAnimation = false;
        _currentSpeechText = "";
      });
      _listeningController.stop();
      await _flutterTts.speak(_aiResponse);
      
      // Return to idle state after error
      if (mounted) {
        setState(() {
          _currentState = VoiceState.idle;
          _aiResponse = ""; // Clear AI response on error
        });
      }
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
            "$timeGreeting, $userName! I'm ByteBot, your friendly guide to a tastier day. Tap the mic or say 'Hey ByteBot' to speak.";
      } else {
        text =
            "$timeGreeting! I'm ByteBot, your friendly guide to a tastier day. Tap the mic or say 'Hey ByteBot' to speak.";
      }
    }

    // Speak the greeting once when overlay is shown (only if not listening and not responding)
    if (!_hasSpokenGreeting && !_showListeningAnimation && _currentState != VoiceState.responding) {
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
              
              // If already listening, stop it
              if (_currentState == VoiceState.listening) {
                _stopListening();
              } else {
                // Otherwise start listening
                _startListening();
              }
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
