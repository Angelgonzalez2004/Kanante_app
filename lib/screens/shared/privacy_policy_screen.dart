import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        backgroundColor: Colors.teal,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidad de Kananté',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Fecha de última actualización: 05 de Diciembre de 2025',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 24),
            Text(
              '1. Introducción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Bienvenido a Kananté. Nos comprometemos a proteger tu privacidad. Esta Política de Privacidad explica cómo recopilamos, usamos, divulgamos y salvaguardamos tu información cuando utilizas nuestra aplicación móvil.',
            ),
            SizedBox(height: 16),
            Text(
              '2. Recopilación de tu información',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Podemos recopilar información sobre ti de varias maneras. La información que podemos recopilar a través de la Aplicación incluye:\n\n- **Datos Personales:** Información de identificación personal, como tu nombre, dirección de correo electrónico y número de teléfono, que nos proporcionas voluntariamente cuando te registras en la Aplicación.\n- **Datos de Perfil:** Información que proporcionas para tu perfil, como tu foto, especialidades y biografía.\n- **Datos de Uso:** Información que nuestros servidores recopilan automáticamente cuando accedes a la Aplicación, como tus acciones nativas, sistema operativo, etc.\n',
            ),
             SizedBox(height: 16),
            Text(
              '3. Uso de tu información',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tener información precisa sobre ti nos permite ofrecerte una experiencia fluida, eficiente y personalizada. Específicamente, podemos usar la información recopilada sobre ti a través de la Aplicación para:\n\n- Crear y gestionar tu cuenta.\n- Facilitar la comunicación entre usuarios y profesionales.\n- Enviarte correos electrónicos administrativos, como confirmaciones y avisos de citas.\n- Aumentar la eficiencia y el funcionamiento de la Aplicación.\n- Supervisar y analizar el uso y las tendencias para mejorar tu experiencia con la Aplicación.\n',
            ),
            SizedBox(height: 16),
             Text(
              '4. Seguridad de tu Información',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
             Text(
              'Utilizamos medidas de seguridad administrativas, técnicas y físicas para ayudar a proteger tu información personal. Si bien hemos tomado medidas razonables para asegurar la información personal que nos proporcionas, ten en cuenta que a pesar de nuestros esfuerzos, ninguna medida de seguridad es perfecta o impenetrable, y ningún método de transmisión de datos puede garantizarse contra cualquier interceptación u otro tipo de mal uso.',
            ),
          ],
        ),
      ),
    );
  }
}
