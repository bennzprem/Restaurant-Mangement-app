import 'package:flutter/material.dart';
import 'widgets/header_widget.dart';
import 'widgets/navbar_widget.dart';
import 'widgets/footer_widget.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 120),
                const NavbarWidget(),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Get in touch',
                                    style: TextStyle(
                                        fontSize: 36, fontWeight: FontWeight.bold)),
                                SizedBox(height: 12),
                                Text(
                                  'Questions, feedback, or catering requests? We’d love to hear from you.',
                                  style: TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                                SizedBox(height: 24),
                              ],
                            ),
                          ),
                          SizedBox(width: isWide ? 48 : 0, height: isWide ? 0 : 24),
                          Expanded(
                            child: _ContactForm(),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const FooterWidget(),
              ],
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(
              active: HeaderActive.contact,
              showBack: true,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactForm extends StatefulWidget {
  @override
  State createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(_name, 'Your name'),
          const SizedBox(height: 12),
          _field(_email, 'Email address', keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(_message, 'Message', maxLines: 5),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message sent!')),
                );
                _name.clear();
                _email.clear();
                _message.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDAE952),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {int maxLines = 1, TextInputType? keyboard}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}


