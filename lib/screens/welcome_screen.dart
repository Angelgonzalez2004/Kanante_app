import 'package:flutter/material.dart';
import 'dart:math'; // Import for min function

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Define max values for responsiveness
    const double maxFontSizeKanante = 60.0;
    const double maxFontSizeSubtitle = 24.0;
    const double maxFontSizeQuote = 28.0;
    const double maxFontSizeDescription = 20.0;
    const double maxButtonHorizontalPadding = 150.0;
    const double maxButtonVerticalPadding = 20.0;
    const double maxButtonTextFontSize = 24.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700.0), // Max width for content on large screens
              child: Card(
                margin: const EdgeInsets.all(20.0),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: const Color.fromRGBO(255, 255, 255, 0.9), // Card background color
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Kananté',
                              style: TextStyle(
                                fontSize: min(constraints.maxWidth * 0.1, maxFontSizeKanante),
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                            Text(
                              'Bienestar Joven Campeche',
                              style: TextStyle(
                                fontSize: min(constraints.maxWidth * 0.045, maxFontSizeSubtitle),
                                color: Colors.teal[700],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              '"Tu salud mental también importa."',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: min(constraints.maxWidth * 0.05, maxFontSizeQuote),
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Kananté te conecta con apoyo emocional, recursos de salud mental y orientación gratuita en Campeche. Porque nadie debería enfrentar sus batallas en soledad.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: min(constraints.maxWidth * 0.04, maxFontSizeDescription),
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 50),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: min(constraints.maxWidth * 0.25, maxButtonHorizontalPadding),
                                  vertical: min(size.height * 0.02, maxButtonVerticalPadding),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 4,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: min(constraints.maxWidth * 0.045, maxButtonTextFontSize),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  } // Closing build method
}