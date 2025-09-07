import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, theme, _) {
      final bool isDark = theme.isDarkMode;
      final Color bg = isDark ? const Color(0xFF0F1113) : Colors.white;
      final Color heading = isDark ? Colors.white : Colors.black87;
      final Color text = isDark ? Colors.white70 : Colors.black54;
      final Color divider = isDark ? Colors.white12 : Colors.black12;

      return Container(
        width: double.infinity,
        color: bg,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment:
                      isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    // Brand + description
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment:
                            isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                        children: [
                          _buildLogo(white: isDark),
                          const SizedBox(height: 16),
                          Text(
                            'Fresh, seasonal ingredients cooked with care. Order online, dine in, or take away — we make great food simple.',
                            style: TextStyle(color: text, height: 1.6, fontSize: 14),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isWide ? 48 : 0, height: isWide ? 0 : 32),

                    // Quick Links
                    Expanded(
                      child: _FooterLinks(
                        title: 'Navigation',
                        links: const [
                          _FooterLink(label: 'Home', route: '/'),
                          _FooterLink(label: 'Menu', route: '/menu'),
                          _FooterLink(label: 'About', route: '/about'),
                          _FooterLink(label: 'Contact', route: '/contact'),
                        ],
                        headingColor: heading,
                        textColor: text,
                      ),
                    ),

                    SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),

                    // Contact info
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                        children: [
                          Text('Contact',
                              style: TextStyle(
                                  color: heading,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          Text('hello@byteeat.com', style: TextStyle(color: text)),
                          const SizedBox(height: 8),
                          Text('+91 90000 00000', style: TextStyle(color: text)),
                          const SizedBox(height: 8),
                          Text('Hyderabad, India', style: TextStyle(color: text)),
                        ],
                      ),
                    ),

                    SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),

                    // Newsletter
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                        children: [
                          Text('Subscribe',
                              style: TextStyle(
                                  color: heading,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _NewsletterField(isDark: isDark, textColor: text),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SocialIcon(icon: Icons.facebook, color: text, bg: divider),
                              const SizedBox(width: 10),
                              _SocialIcon(icon: Icons.camera_alt, color: text, bg: divider),
                              const SizedBox(width: 10),
                              _SocialIcon(icon: Icons.chat, color: text, bg: divider),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Divider + copyright
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: divider, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('© 2024 ByteEat', style: TextStyle(color: text)),
                Text('All rights reserved.',
                    style: TextStyle(color: text, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      );
    });
  }

  Widget _buildLogo({bool white = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Image.asset('assets/logo/logoLP.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Text(
          'ByteEat',
          style: TextStyle(
            color: white ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  final String title;
  final List<_FooterLink> links;
  final Color headingColor;
  final Color textColor;
  const _FooterLinks({required this.title, required this.links, required this.headingColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: headingColor, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...links.map((l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, l.route),
                child: Text(l.label, style: TextStyle(color: textColor)),
              ),
            )),
      ],
    );
  }
}

class _FooterLink {
  final String label;
  final String route;
  const _FooterLink({required this.label, required this.route});
}

class _NewsletterField extends StatefulWidget {
  final bool isDark;
  final Color textColor;
  const _NewsletterField({required this.isDark, required this.textColor});
  @override
  State createState() => _NewsletterFieldState();
}

class _NewsletterFieldState extends State<_NewsletterField> {
  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: widget.isDark ? Colors.white12 : Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.mail_outline, color: widget.textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Your email address',
                hintStyle: TextStyle(color: widget.textColor),
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _controller.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanks for subscribing!')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: const Color(0xFFDAE952),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            child: const Text('Subscribe'),
          )
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  const _SocialIcon({required this.icon, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
