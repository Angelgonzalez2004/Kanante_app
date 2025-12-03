# Kanante_app

Una aplicación móvil desarrollada con Flutter que integra una amplia gama de funcionalidades, incluyendo autenticación de usuarios, gestión de datos en tiempo real, almacenamiento de archivos, geolocalización, mapas y más, utilizando principalmente los servicios de Firebase.

## Características Principales

*   **Autenticación de Usuarios:** Integración con Firebase Authentication para la gestión de usuarios.
*   **Base de Datos en Tiempo Real:** Utiliza Firebase Realtime Database para la sincronización de datos.
*   **Almacenamiento de Archivos:** Gestión de imágenes y otros archivos con Firebase Storage.
*   **Geolocalización y Mapas:** Funcionalidades de geolocalización, geocodificación y visualización en Google Maps.
*   **Gestión de Datos Locales:** Soporte para base de datos SQLite para almacenamiento local.
*   **Selección de Imágenes:** Permite a los usuarios seleccionar imágenes de la galería o cámara.
*   **Compartir Contenido:** Funcionalidad para compartir información desde la aplicación.
*   **Información del Dispositivo:** Acceso a detalles del dispositivo.

## Tecnologías Utilizadas

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Lenguaje:** [Dart](https://dart.dev/)
*   **Backend como Servicio (BaaS):** [Firebase](https://firebase.google.com/)
    *   Firebase Authentication
    *   Firebase Realtime Database
    *   Firebase Storage
*   **Paquetes de Flutter Clave:**
    *   `firebase_core`: Core de Firebase para Flutter.
    *   `firebase_auth`: Autenticación con Firebase.
    *   `firebase_database`: Base de datos en tiempo real.
    *   `firebase_storage`: Almacenamiento de archivos.
    *   `geolocator`: Geolocalización.
    *   `geocoding`: Geocodificación.
    *   `google_maps_flutter`: Mapas de Google.
    *   `image_picker`: Selección de imágenes.
    *   `sqflite`: Base de datos SQLite local.
    *   `shared_preferences`: Almacenamiento de preferencias simples.
    *   `url_launcher`: Abrir URLs externas.
    *   `device_info_plus`: Información del dispositivo.
    *   `flutter_keyboard_visibility`: Detección de teclado en pantalla.
    *   `share_plus`: Compartir contenido.

## Estructura del Proyecto

```
kanante_app/
├── lib/
│   ├── main.dart             # Punto de entrada de la aplicación
│   ├── firebase_options.dart # Configuración de Firebase
│   ├── models/               # Definiciones de modelos de datos
│   ├── screens/              # Implementación de las pantallas/vistas
│   ├── services/             # Lógica de negocio y servicios
│   └── widgets/              # Componentes de UI reutilizables
├── assets/
│   └── images/               # Imágenes y recursos gráficos
├── android/                  # Proyecto Android
├── ios/                      # Proyecto iOS
├── web/                      # Proyecto Web
├── pubspec.yaml              # Dependencias y metadatos del proyecto
└── README.md                 # Este archivo
```

## Configuración del Proyecto

Para configurar y ejecutar este proyecto localmente, sigue estos pasos:

### 1. Requisitos Previos

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado y configurado.
*   Una cuenta de Firebase y un proyecto configurado.
*   [Android Studio](https://developer.android.com/studio) o [Xcode](https://developer.apple.com/xcode/) (para desarrollo iOS).

### 2. Clonar el Repositorio

```bash
git clone https://github.com/Angelgonzalez2004/Kanante_app.git
cd Kanante_app
```

### 3. Configurar Firebase

1.  Crea un nuevo proyecto en la [Consola de Firebase](https://console.firebase.google.com/).
2.  Añade una aplicación Android y/o iOS a tu proyecto de Firebase.
3.  Descarga el archivo `google-services.json` para Android y colócalo en `android/app/`.
4.  Descarga el archivo `GoogleService-Info.plist` para iOS y colócalo en `ios/Runner/`.
5.  Genera el archivo `lib/firebase_options.dart` ejecutando el siguiente comando en la raíz de tu proyecto Flutter:
    ```bash
    flutterfire configure
    ```
    Asegúrate de tener el CLI de Firebase instalado (`npm install -g firebase-tools`).

### 4. Instalar Dependencias

```bash
flutter pub get
```

### 5. Ejecutar la Aplicación

```bash
flutter run
```

Esto debería iniciar la aplicación en tu dispositivo o emulador conectado.