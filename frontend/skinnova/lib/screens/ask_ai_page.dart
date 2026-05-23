import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AskAiPage extends StatelessWidget {
  const AskAiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFAF8),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF202124)),
        title: Text(
          'Ask AI',
          style: GoogleFonts.marcellus(
            color: const Color(0xFF202124),
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 50,
                    color: Color(0xFF61707B),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ask Skinova AI',
                    style: GoogleFonts.marcellus(
                      fontSize: 24,
                      color: const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get help with skincare ingredients, routines, and product choices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Hi! Ask me anything about your skin.',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8E3DE)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
