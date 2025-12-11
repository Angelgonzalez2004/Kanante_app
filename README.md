# Kananté App

<p align="center">
  <img src="assets/images/logoapp.jpg" alt="Kananté App Logo" width="200"/>
</p>

## Descripción

**Kananté** (del maya "cuidar" o "proteger") es una aplicación móvil desarrollada con Flutter que sirve como plataforma para conectar a usuarios (pacientes) con profesionales de la salud mental de forma segura y sencilla.

La aplicación permite a los usuarios buscar profesionales, agendar citas, comunicarse a través de un chat seguro y publicar artículos informativos con un formato más profesional y sencillo (incluyendo hashtags) en un feed de contenido. La plataforma también cuenta con paneles de inicio mejorados para cada rol y un panel de administrador para la verificación de profesionales y la gestión general de la aplicación.

## Características Principales

La aplicación se estructura en torno a tres roles principales, cada uno con una experiencia de inicio mejorada y más profesional:

### 👤 Usuario/Paciente
- **Dashboard Personalizado:** Un inicio rediseñado con acceso rápido a citas próximas, búsqueda de profesionales y publicaciones recientes.
- **Búsqueda de Profesionales:** Filtra y encuentra especialistas según tus necesidades.
- **Gestión de Citas:** Agenda, consulta y cancela citas con profesionales.
- **Comunicación Segura:** Chatea en tiempo real con los profesionales contactados.
- **Perfiles y Reseñas:** Consulta perfiles detallados de profesionales y deja tu valoración.
- **Feed de Contenido:** Accede a artículos y publicaciones de los profesionales.

### 🧑‍⚕️ Profesional
- **Dashboard de Actividad:** Un inicio rediseñado que muestra un resumen de próximas citas, mensajes sin leer y calificación promedio.
- **Gestión de Perfil:** Personaliza tu perfil con experiencia, especialidades, ubicación y horarios.
- **Gestión de Citas:** Acepta o rechaza solicitudes de citas de los pacientes.
- **Publicaciones Simplificadas:** Crea y administra artículos y contenido para el feed con un editor más limpio y soporte para hashtags.
- **Interacción:** Comunícate con tus pacientes a través del chat.

### ⚙️ Administrador
- **Dashboard Centralizado:** Un inicio rediseñado que ofrece una visión general de la plataforma, incluyendo profesionales por verificar, publicaciones pendientes y usuarios registrados.
- **Verificación de Cuentas:** Valida y aprueba los registros de nuevos profesionales.
- **Gestión de Contenido:** Supervisa y modera las publicaciones y el contenido de la plataforma.
- **Soporte:** Administra los tickets de soporte de los usuarios.

## Tecnologías Utilizadas

- **Framework:** Flutter
- **Backend y Base de Datos:** Firebase
    - **Authentication:** Para la gestión de usuarios (Email/Contraseña).
    - **Realtime Database:** Para almacenar la información de la aplicación (perfiles, citas, publicaciones, etc.).
    - **Storage:** Para almacenar archivos como imágenes de perfil y adjuntos.
    - **Cloud Messaging:** Para notificaciones push.
    - **App Check:** Para proteger los recursos de backend.

### Dependencias Clave

- **Estado y Utilidades:** `provider`, `shared_preferences`, `logger`, `intl`.
- **Multimedia:** `image_picker`, `cached_network_image`, `photo_view`, `file_picker`.
- **Mapas y Ubicación:** `google_maps_flutter`, `geocoding`, `geolocator`.
- **UI:** `flutter_rating_bar`.
## Monetización y Modelo de Negocio

La aplicación presenta varias vías potenciales de monetización:
- **Comisión por Citas/Servicios:** Se podría cobrar un porcentaje o tarifa fija por cada cita o servicio agendado a través de la plataforma.
- **Suscripciones Premium para Profesionales:** Ofrecer características avanzadas (mayor visibilidad, analíticas, etc.) mediante una suscripción mensual/anual.
- **Listados Destacados/Promociones:** Permitir a los profesionales pagar para aparecer en posiciones destacadas en búsquedas o listados.
- **Modelo Freemium:** Ofrecer un acceso básico gratuito con opciones de pago para funciones premium.

## Configuración y Ejecución del Proyecto

Sigue estos pasos para poner en marcha el proyecto en tu entorno de desarrollo local.

### Prerrequisitos

- Tener [Flutter](https://flutter.dev/docs/get-started/install) instalado en tu sistema.
- Un editor de código como [VS Code](https://code.visualstudio.com/) o [Android Studio](https://developer.android.com/studio).
- Acceso a un proyecto de Firebase.

### Pasos de Instalación

1.  **Clonar el repositorio:**
    ```sh
    git clone <URL_DEL_REPOSITORIO>
    cd kanante_app
    ```

2.  **Configurar Firebase:**
    - **Android:** Coloca tu archivo de configuración `google-services.json` en el directorio `android/app/`.
    - **iOS:** Coloca tu archivo `GoogleService-Info.plist` en el directorio `ios/Runner/`.

    *Nota: Estos archivos son específicos de tu proyecto de Firebase y no se incluyen en el repositorio por razones de seguridad.*

3.  **Instalar dependencias:**
    Ejecuta el siguiente comando para descargar todas las dependencias del proyecto.
    ```sh
    flutter pub get
    ```

4.  **Ejecutar la aplicación:**
    Conecta un dispositivo o inicia un emulador y ejecuta el siguiente comando:
    ```sh
    flutter run
    ```