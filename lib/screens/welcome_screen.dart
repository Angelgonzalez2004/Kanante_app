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
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0), // Fixed horizontal margin for the card
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: const Color.fromRGBO(255, 255, 255, 0.9), // Card background color
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0), // Fixed padding inside the card
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Use constraints.maxWidth instead of size.width here
                        return Column(
                          children: [
                            SizedBox(height: size.height * 0.05),
                            Column(
                              children: [
                            Text(
                              'Kananté',
                              style: TextStyle(
                                fontSize: min(constraints.maxWidth * 0.1, maxFontSizeKanante),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Bienestar Joven Campeche',
                              style: TextStyle(
                                fontSize: min(constraints.maxWidth * 0.045, maxFontSizeSubtitle),
                                color: const Color.fromRGBO(255, 255, 255, 0.9),
                              ),
                            ),
                            SizedBox(height: size.height * 0.04),
                            Text(
                              '"Tu salud mental también importa."',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: min(constraints.maxWidth * 0.05, maxFontSizeQuote),
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: size.height * 0.02),
                            Text(
                              'Kananté te conecta con apoyo emocional, recursos de salud mental y orientación gratuita en Campeche. Porque nadie debería enfrentar sus batallas en soledad.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: min(constraints.maxWidth * 0.04, maxFontSizeDescription),
                                color: const Color.fromRGBO(255, 255, 255, 0.95),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: size.height * 0.08),
                          child: Column(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.teal[700],
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
                                                                    fontSize: min(constraints.maxWidth * 0.045, maxButtonTextFontSize),                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: min(constraints.maxWidth * 0.2, maxButtonHorizontalPadding),
                                    vertical: min(size.height * 0.02, maxButtonVerticalPadding),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                child: Text(
                                  'Crear cuenta',
                                  style: TextStyle(
                                    fontSize: min(constraints.maxWidth * 0.045, maxButtonTextFontSize),
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/recover');
                                },
                                child: Text(
                                  'Recuperar contraseña',
                                  style: TextStyle(
                                    fontSize: min(constraints.maxWidth * 0.04, maxFontSizeDescription),
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ); // Closing main Column
                  }), // Closing LayoutBuilder
                ), // Closing Padding inside Card
              ), // Closing Card
            ), // Closing Center inside ConstrainedBox
          ), // Closing ConstrainedBox
        ), // Closing Center (outer)
      ), // Closing SafeArea
    ), // Closing Container
  ); // Closing Scaffold
} // Closing build method
}