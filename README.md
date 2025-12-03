<p align="center">
  <img src="assets/images/logoapp.jpg" alt="Kanante App Logo" width="200"/>
</p>

<h1 align="center">Kanante App</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter Badge"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase Badge"/>
</p>

**Kanante_app** es una aplicación móvil desarrollada con Flutter que conecta usuarios y profesionales, ofreciendo una amplia gama de funcionalidades que incluyen autenticación, gestión de datos en tiempo real, geolocalización y más, utilizando los servicios de Firebase como backend.

## ✨ Características Principales

*   **Autenticación de Usuarios:** Integración completa con Firebase Authentication.
*   **Base de Datos en Tiempo Real:** Sincronización de datos instantánea con Firebase Realtime Database.
*   **Almacenamiento de Archivos:** Gestión de imágenes y archivos con Firebase Storage.
*   **Geolocalización y Mapas:** Funcionalidades de geolocalización y visualización en Google Maps.
*   **Gestión de Datos Locales:** Soporte para base de datos SQLite.
*   **Interacción Multimedia:** Permite a los usuarios seleccionar imágenes de la galería o tomar fotos.
*   **Funcionalidades Sociales:** Opciones para compartir contenido desde la aplicación.

## 🛠️ Tecnologías Utilizadas

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Lenguaje:** [Dart](https://dart.dev/)
*   **Backend:** [Firebase](https://firebase.google.com/)
    *   Authentication
    *   Realtime Database
    *   Storage
*   **Paquetes Clave de Flutter:**
    *   `geolocator` & `geocoding`
    *   `google_maps_flutter`
    *   `image_picker`
    *   `sqflite` y `shared_preferences`
    *   `url_launcher` y `share_plus`

## 📂 Estructura del Proyecto

```
kanante_app/
├── lib/
│   ├── main.dart             # Punto de entrada de la aplicación
│   ├── models/               # Modelos de datos (Usuario, Cita, etc.)
│   ├── screens/              # Pantallas de la aplicación
│   ├── services/             # Lógica de negocio y comunicación con Firebase
│   └── widgets/              # Componentes de UI reutilizables
├── assets/
│   └── images/               # Recursos gráficos
├── android/
├── ios/
├── pubspec.yaml              # Dependencias y metadatos
└── README.md
```

## 🚀 Cómo Empezar

Para configurar y ejecutar este proyecto localmente, sigue estos pasos:

### 1. Requisitos

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado.
*   Un proyecto configurado en [Firebase](https://console.firebase.google.com/).
*   [Android Studio](https://developer.android.com/studio) o [Xcode](https://developer.apple.com/xcode/) (para desarrollo iOS).

### 2. Clonar el Repositorio

```bash
git clone https://github.com/Angelgonzalez2004/Kanante_app.git
cd Kanante_app
```

### 3. Configurar Firebase

1.  Desde la consola de Firebase, añade una aplicación Android y/o iOS.
2.  Descarga `google-services.json` (Android) y colócalo en `android/app/`.
3.  Descarga `GoogleService-Info.plist` (iOS) y colócalo en `ios/Runner/`.
4.  Genera las opciones de configuración de Firebase para Flutter:
    ```bash
    flutterfire configure
    ```

### 4. Instalar Dependencias

```bash
flutter pub get
```

### 5. Ejecutar la App

```bash
flutter run
```
