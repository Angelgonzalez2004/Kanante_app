<div align="center">
  <img src="assets/images/logoapp.jpg" alt="Logo" width="150" height="150">
  <h1 align="center">Kanante App</h1>
  <p align="center">
    Una aplicación móvil construida con Flutter para conectar usuarios y profesionales.
    <br />
    <a href="https://github.com/Angelgonzalez2004/Kanante_app"><strong>Explora la documentación »</strong></a>
    <br />
    <br />
    <a href="https://github.com/Angelgonzalez2004/Kanante_app/issues">Reportar Bug</a>
    ·
    <a href="https://github.com/Angelgonzalez2004/Kanante_app/issues">Solicitar Feature</a>
  </p>
</div>

## 📜 Descripción

**Kanante App** es una plataforma móvil que facilita la conexión entre usuarios que buscan servicios y profesionales que los ofrecen. La aplicación permite a los profesionales crear publicaciones, gestionar su perfil y agenda, mientras que los usuarios pueden buscar profesionales, ver su contenido, agendar citas y comunicarse directamente.

La aplicación cuenta con tres roles principales:
*   **👤 Usuario:** Busca y contacta profesionales, agenda citas y gestiona su perfil.
*   **🧑‍⚕️ Profesional:** Publica contenido, gestiona su perfil, su agenda de citas y se comunica con los usuarios.
*   **👑 Administrador:** Modera el contenido y gestiona las verificaciones de los profesionales.

## ✨ Características Principales

*   **🔐 Autenticación:** Registro e inicio de sesión con correo/contraseña y Google Sign-In.
*   **👤 Perfiles de Usuario:** Perfiles personalizables para usuarios y profesionales.
*   **📝 Publicaciones:** Los profesionales pueden crear y editar publicaciones con un editor de texto enriquecido.
*   **🗓️ Gestión de Citas:** Sistema para que los usuarios agenden citas y los profesionales las gestionen.
*   **💬 Chat en Tiempo Real:** Comunicación directa entre usuarios y profesionales.
*   **🗺️ Geolocalización:** Búsqueda de profesionales basada en la ubicación.
*   **🎨 Panel de Administración:** Interfaz para la moderación de contenido y la gestión de la plataforma.

## 🛠️ Tecnologías Utilizadas

Este proyecto está construido con una pila de tecnologías modernas para el desarrollo de aplicaciones móviles:

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Lenguaje:** [Dart](https://dart.dev/)
*   **Backend:** [Firebase](https://firebase.google.com/)
    *   **🔥 Autenticación:** Firebase Auth
    *   **🗄️ Base de Datos:** Firebase Realtime Database
    *   **📦 Almacenamiento:** Firebase Storage
*   **Gestión de Estado:** [Provider](https://pub.dev/packages/provider)
*   **Mapas:** [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
*   **Editor de Texto:** [Flutter Quill](https://pub.dev/packages/flutter_quill)

## 📂 Estructura del Proyecto

La estructura del proyecto está organizada para mantener una separación clara de responsabilidades, siguiendo las mejores prácticas de Flutter.

```
├── lib
│   ├── models          # Clases de modelo de datos (Usuario, Cita, etc.)
│   ├── screens         # Widgets de pantalla principal para cada flujo de la app
│   │   ├── admin
│   │   ├── professional
│   │   ├── shared
│   │   └── user
│   ├── services        # Lógica de negocio y servicios (e.g., FirebaseService)
│   ├── theme           # Definiciones de tema y colores de la app
│   └── widgets         # Widgets reutilizables (botones, campos de texto, etc.)
├── assets              # Archivos estáticos como imágenes y fuentes
├── pubspec.yaml        # Definiciones y dependencias del proyecto
```

## 🚀 Comenzando

Para obtener una copia local y ponerla en marcha, sigue estos sencillos pasos.

### Prerrequisitos

Asegúrate de tener instalado el SDK de Flutter. Para más información, consulta la [documentación oficial de Flutter](https://flutter.dev/docs/get-started/install).

*   **Flutter SDK**

### Instalación

1.  Clona el repositorio:
    ```sh
    git clone https://github.com/Angelgonzalez2004/Kanante_app.git
    ```
2.  Navega al directorio del proyecto:
    ```sh
    cd kanante_app
    ```
3.  Instala las dependencias:
    ```sh
    flutter pub get
    ```
4.  Ejecuta la aplicación:
    ```sh
    flutter run
    ```

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulta `LICENSE` para más información.

## 📧 Contacto

Link del Proyecto: [https://github.com/Angelgonzalez2004/Kanante_app](https://github.com/Angelgonzalez2004/Kanante_app)