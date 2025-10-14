import 'package:flutter/material.dart';
import 'dart:async';

class OrderTrackingButton extends StatefulWidget {
  final VoidCallback onTap;
  final int orderCount;
  final bool isVisible;

  const OrderTrackingButton({
    super.key,
    required this.onTap,
    this.orderCount = 0,
    this.isVisible = true,
  });

  @override
  State<OrderTrackingButton> createState() => _OrderTrackingButtonState();
}

class _OrderTrackingButtonState extends State<OrderTrackingButton>
    with TickerProviderStateMixin {
  late AnimationController _scooterController;
  late AnimationController _bounceController;
  late Animation<double> _scooterAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Scooter movement animation
    _scooterController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Bounce animation for the button
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scooterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scooterController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Start continuous scooter animation
    _startScooterAnimation();
  }

  void _startScooterAnimation() {
    _scooterController.repeat(reverse: true);

    // Start bounce animation periodically
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && widget.isVisible) {
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
      }
    });
  }

  @override
  void dispose() {
    _scooterController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scooterAnimation, _bounceAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: GestureDetector(
              onTap: () {

                widget.onTap();
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Scooter icon with animation
                    Transform.translate(
                      offset: Offset(
                        _scooterAnimation.value * 3 - 1.5,
                        0,
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    // Order count badge
                    if (widget.orderCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.orderCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
