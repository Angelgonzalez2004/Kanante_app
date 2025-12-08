<div align="center">
  <img src="assets/images/logoapp.jpg" alt="Logo" width="150" height="150">
  <h1 align="center">Kanante App</h1>
  <p align="center">
    Una aplicación móvil construida con Flutter para conectar usuarios y profesionales del bienestar.
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

**Kanante App** es una plataforma móvil, construida con Flutter y Firebase, diseñada para ser un ecosistema de bienestar integral. Facilita la conexión entre usuarios que buscan servicios de salud y bienestar y los profesionales que los ofrecen. La aplicación permite a los profesionales verificados crear contenido, gestionar su perfil y agenda, mientras que los usuarios pueden buscar profesionales, consumir su contenido, agendar citas y comunicarse de forma segura.

La aplicación está estructurada en tres roles principales:
*   **👤 Usuario:** Busca y contacta profesionales, agenda citas, consume el feed de contenido, gestiona su perfil y accede a soporte y FAQs.
*   **🧑‍⚕️ Profesional:** Publica artículos en el feed, gestiona su perfil (biografía, especialidades), su agenda de citas, se comunica con los usuarios y solicita la verificación de su cuenta.
*   **👑 Administrador:** Modera el contenido, gestiona las verificaciones de los profesionales, supervisa tickets de soporte y chats de la plataforma.

## ✨ Características Principales

*   **🚀 Flujo de Inicio de Aplicación Mejorado:** La aplicación ahora sigue un flujo claro de `Splash Screen` (logo) -> `Welcome Screen` (información atractiva) -> `Login Screen`. La `Welcome Screen` es la puerta de entrada principal para nuevos usuarios o aquellos que desean iniciar sesión, y la `Login Screen` permite regresar a la `Welcome Screen`.
*   **🔐 Autenticación Multi-plataforma:** Registro e inicio de sesión con correo/contraseña y Google Sign-In, con flujos seguros y persistencia de sesión.
*   **🎨 Diseño Responsivo y Adaptativo:** Interfaz de usuario completamente responsiva que se adapta a móviles, tabletas y web, utilizando `LayoutBuilder` para cambiar entre menús laterales (`Drawer`) y barras de navegación persistentes (`NavigationRail`) para una experiencia de usuario óptima.
*   **👤 Perfiles y Configuraciones Claramente Separados:**
    *   **Páginas de Perfil:** Dedicadas a la información de identidad del usuario (nombre, teléfono, foto de perfil, biografía, etc.). Ahora con campos editables como género, fecha de nacimiento (con selector de calendario), teléfono y RFC.
    *   **Redes Sociales para Profesionales:** Una nueva sección en el perfil del profesional permite añadir y mostrar enlaces a sus redes sociales (Facebook, Instagram, TikTok, WhatsApp, Correo electrónico) con iconos interactivos y enlaces funcionales.
    *   **Páginas de Configuración:** Enfocadas en las preferencias y el comportamiento de la aplicación (notificaciones, tema, seguridad, cerrar sesión, etc.). Ahora incluyen un indicador de estado de verificación y navegación a la política de privacidad.
    *   **Gestión de Fotos de Perfil:**
        *   Solo los **Profesionales con cuentas manuales** pueden subir, cambiar y eliminar su foto de perfil directamente en la aplicación.
        *   Los usuarios con **cuentas de Google** (tanto Usuarios como Profesionales) deben gestionar su foto directamente desde su cuenta de Google; la app no permite la subida en estos casos.
        *   Los **Usuarios Normales y Administradores** no pueden subir fotos de perfil, aunque sus perfiles las mostrarán si existen (e.g., de una cuenta de Google).
*   **✅ Sistema de Verificación:** Los profesionales deben subir documentos para ser verificados por un administrador, aumentando la confianza y seguridad en la plataforma.
*   **📝 Feed de Contenido Dinámico:** Los profesionales pueden crear, editar y publicar artículos con un editor de texto enriquecido e imágenes. Los usuarios pueden explorar este contenido en un feed interactivo.
*   **🗓️ Gestión de Citas:** Sistema para que los usuarios soliciten citas y los profesionales las gestionen. Ahora con la posibilidad de solicitar cita directamente desde el chat con un profesional, y **opciones para cancelar o reprogramar citas** para ambos roles.
*   **💬 Chat en Tiempo Real:** Comunicación directa y segura entre usuarios y profesionales, y entre usuarios y el equipo de soporte. Ahora incluye **recibos de lectura e indicadores de escritura** para una experiencia más fluida.
*   **🧭 Navegación por Roles:** Paneles de control (`Dashboards`) personalizados para cada rol (Usuario, Profesional, Administrador), mostrando solo las opciones y vistas relevantes para cada uno.
*   **🔍 Búsqueda y Filtro de Profesionales:** Los usuarios pueden **buscar y filtrar profesionales por nombre, especialidad y email**, facilitando la conexión con el especialista adecuado.
*   **⭐️ Sistema de Calificación y Reseñas:** Los usuarios pueden **calificar y dejar reseñas** sobre los profesionales después de las citas. Los perfiles de los profesionales muestran su **calificación promedio** y una lista de todas las reseñas.
*   **🆘 Soporte y Ayuda Integrado:**
    *   Chat directo con administradores de soporte.
    *   Formularios de quejas y sugerencias (anónimos o identificados).
    *   Acceso a políticas de privacidad.
    *   Secciones de Preguntas Frecuentes (FAQ) personalizadas por rol.
    *   **Nueva Sección "Sobre Nosotros"**: Conoce la misión, origen e información de contacto de Kananté.

## 🚀 Nuevas Características y Mejoras Recientes

Hemos implementado una serie de mejoras significativas en la aplicación para enriquecer la experiencia de usuario y la funcionalidad en todos los roles:

*   **¡Nuevo! Notificaciones Push Integradas:**
    *   Implementación de Firebase Cloud Messaging (FCM) para enviar notificaciones.
    *   Manejo y almacenamiento de tokens de dispositivo (`fcmToken`) en el perfil del usuario.
    *   Gestión de permisos de notificación y manejo de mensajes en primer y segundo plano.
*   **¡Nuevo! Recordatorios de Citas (Basados en FCM):**
    *   Se ha delineado una arquitectura para una Cloud Function de Firebase que enviaría recordatorios de citas automáticos (24h y 1h antes) a través de FCM.
    *   La aplicación está preparada en el lado de Flutter para recibir y manejar estas notificaciones de recordatorio.
*   **¡Nuevo! Moderación de Publicaciones para Administradores:**
    *   Se ha añadido un campo `status` al modelo `Publication` para controlar su visibilidad ('pending', 'published', 'unpublished', 'rejected').
    *   La `FirebaseService` incluye métodos para `updatePublicationStatus` y `deletePublication`.
    *   La interfaz de administrador en `admin_publication_list.dart` permite a los administradores **ver el estado de las publicaciones**, y tienen **opciones para editar, publicar/despublicar y eliminar** publicaciones.
*   **¡Nuevo! Priorización y Asignación de Tickets de Soporte:**
    *   El `SupportTicketModel` ha sido extendido con campos para `priority` ('low', 'medium', 'high') y `assignedTo` (UID del administrador).
    *   La `FirebaseService` incluye un método `updateSupportTicketDetails` para gestionar estos campos.
    *   La interfaz de administrador (`SupportCenterScreen` y `SupportTicketDetailScreen`) ahora permite **visualizar, filtrar, y modificar el estado, la prioridad y la asignación** de los tickets de soporte.
*   **¡Nuevo! Análisis y Reportes Básicos para Administradores:**
    *   Se ha creado una pantalla dedicada (`AdminAnalyticsScreen`) para mostrar métricas clave como el total de usuarios, profesionales, publicaciones, reseñas, y un desglose de citas por estado (pendientes, completadas, canceladas).
    *   La `FirebaseService` incluye nuevos métodos para obtener estos datos agregados.
    *   Integrado en el `AdminDashboard` para un fácil acceso.
*   **¡Nuevo! Agendamiento de Citas Integrado en Chats:**
    *   Ahora es posible solicitar una cita con un profesional directamente desde la pantalla de chat.
    *   Se ha añadido un botón "Agendar Cita" en la barra superior del chat (visible para usuarios al chatear con profesionales), que permite seleccionar fecha y hora.
    *   La funcionalidad de agendamiento de cita se integra con `FirebaseService.requestAppointment`.
*   **¡Nuevo! Pantalla de Recordatorios de Citas:**
    *   Se ha creado una pantalla dedicada (`AppointmentsReminderScreen`) para que usuarios y profesionales puedan visualizar sus citas agendadas de forma centralizada.
    *   Esta pantalla muestra las citas ordenadas cronológicamente, con detalles del otro participante y el estado de la cita.
    *   Se ha integrado en la navegación principal (menú lateral y barra de navegación) de los Dashboards de Usuario y Profesional.
    *   **¡Nuevo! Gestión de Cancelaciones y Reprogramaciones:** Dentro de la `AppointmentsReminderScreen`, usuarios y profesionales pueden **cancelar citas** (con confirmación) o **reprogramarlas** seleccionando una nueva fecha y hora.
*   **¡Nuevo! Gestión de Disponibilidad para Profesionales:**
    *   Los profesionales ahora tienen una pantalla dedicada (`ProfessionalAvailabilityScreen`) para configurar sus **horarios de trabajo semanales** y la **duración estándar de sus citas**.
    *   El sistema de agendamiento de citas en el chat ahora utiliza esta disponibilidad para mostrar solo los **días y horarios disponibles** del profesional.
*   **¡Nuevo! Mejoras en el Chat en Tiempo Real:**
    *   **Recibos de Lectura:** Los usuarios pueden ver cuándo sus mensajes han sido leídos por el receptor (doble checkmark azul).
    *   **Indicadores de Escritura:** Se muestra un mensaje "Escribiendo..." en la barra superior del chat cuando el otro usuario está redactando un mensaje.
*   **¡Nuevo! Búsqueda y Filtrado Avanzado de Profesionales:**
    *   La pantalla de búsqueda permite a los usuarios **encontrar profesionales por nombre, email o especialidad**, con la opción de **filtrar los resultados por especialidad**.
    *   La navegación a los perfiles de los profesionales desde los resultados de búsqueda ha sido mejorada.
*   **¡Nuevo! Sistema de Calificación y Reseñas:**
    *   Los usuarios pueden **enviar calificaciones (estrellas) y comentarios** a los profesionales después de una cita completada, a través de una pantalla de envío de reseñas.
    *   Los perfiles de los profesionales ahora muestran su **calificación promedio** y una lista de las **reseñas** detalladas recibidas.
*   **¡Corrección Crítica de Estabilidad!** Se identificó y solucionó un error crítico de `type casting` en los métodos de `FirebaseService` relacionados con la obtención de conversaciones. Este error causaba cierres inesperados de la aplicación o redirecciones a la pantalla de inicio de sesión, lo que mejora significativamente la estabilidad de la aplicación.

*   **Optimización del Acceso y Visualización del Feed Social:**
    *   Para el rol de **Usuario**, el dashboard ahora muestra el Feed Social Interactivo como pantalla por defecto al iniciar sesión, asegurando que esta funcionalidad principal sea lo primero que vean.
    *   Para el rol de **Administrador**, el acceso a "Supervisar Publicaciones" se ha cambiado para mostrar también el **Feed Social Interactivo** (`PublicationFeedPage`), pero con la interactividad (likes, comentarios) deshabilitada; solo permite la visualización y el compartir, tal como se solicitó.

*   **Consolidación de Títulos y Navegación:**
    *   Se realizó una auditoría exhaustiva y se eliminaron títulos duplicados en múltiples pantallas (perfiles, mensajes, ajustes, FAQ, Mis Alertas) a lo largo de la aplicación para una experiencia de usuario más limpia y consistente.
    *   Se verificó que la navegación en los dashboards funcione correctamente, mitigando problemas de redirección inesperada.

*   **Feed de Publicaciones Social e Interactivo:**
    *   Un feed de publicaciones dinámico al estilo "TikTok/Facebook" que permite a todos los roles visualizar el contenido.
    *   **Usuarios:** Pueden dar "Me gusta" a las publicaciones, añadir comentarios y compartir publicaciones.
    *   **Profesionales y Administradores:** Pueden ver el feed, y ahora **todos los roles** pueden compartir publicaciones en diversas plataformas (WhatsApp, Facebook, Twitter, Correo, etc.) a través del diálogo de compartir del dispositivo.
    *   Restricciones de interacción aplicadas: solo los usuarios pueden "Me gusta" y "Comentar".

*   **Gestión de Cuentas para Administradores Mejorada:**
    *   Nueva pantalla "Gestionar Cuentas" que permite a los administradores listar, buscar y ver detalles completos de los perfiles de usuarios y profesionales.
    *   Capacidad de **eliminar cuentas de usuarios** de la Realtime Database de Firebase (se aclara que la eliminación de la cuenta de autenticación debe hacerse manualmente en la consola de Firebase o a través de un servicio de backend).
    *   Funcionalidad directa para **enviar alertas** a usuarios o profesionales específicos desde esta pantalla de gestión.
    *   Se ha mejorado la visibilidad de los IDs de usuario/profesional en esta pantalla para facilitar la intervención del soporte técnico.

*   **Sistema de Alertas Bidireccional Completo:**
    *   Los administradores pueden enviar alertas personalizadas (título y mensaje) a cualquier usuario o profesional.
    *   Los usuarios/profesionales reciben notificaciones visuales (badges en el menú de navegación) sobre alertas no leídas.
    *   Pantallas dedicadas para visualizar los detalles de las alertas y la opción de **responder directamente** al administrador.

*   **Perfiles y Configuraciones Mejorados (Detalle):**
    *   Ampliación de `UserModel` con campos adicionales como género, idioma preferido, zona horaria, sitio web, enlaces a redes sociales, educación y certificaciones para perfiles más completos.
    *   Actualización de las páginas de perfil de Usuarios y Profesionales para permitir la visualización y edición de estos nuevos campos.
    *   La página de perfil del Administrador ahora muestra los nuevos campos relevantes en modo de solo lectura.
    *   Todas las páginas de configuración (Administrador, Profesional, Usuario) incluyen nuevas secciones de "Privacidad" y "Seguridad", ofreciendo opciones para políticas de privacidad, gestión de datos, cambio de contraseña y configuración de autenticación de dos factores.

*   **Interfaz de Mensajería con Pestañas:**
    *   El dashboard del Administrador ahora incluye una opción de "Mensajes" para acceder a las comunicaciones.
    *   Las páginas de mensajes de Usuarios y Profesionales se han rediseñado con una interfaz de dos pestañas:
        *   **"Chats":** Para ver las conversaciones existentes.
        *   **"Contactos":** Permite iniciar nuevas conversaciones. Para usuarios, lista a profesionales de la salud. Para profesionales, lista a usuarios normales (filtrando otros profesionales y administradores).
    *   Los botones flotantes de acción (FAB) para iniciar chats en los dashboards de Usuario y Profesional han sido eliminados, ya que la funcionalidad de iniciar chat se integra ahora en las páginas de mensajes.
    *   **¡Nuevo! Pestaña de Mensajes en el Perfil del Profesional:** Al ver el perfil de un profesional, ahora se incluye una pestaña dedicada a la mensajería, permitiendo iniciar o continuar un chat directamente desde el perfil.

*   **Sistema de Soporte Optimizado:**
    *   La sección de "Soporte" ahora incluye una opción "Mis Tickets de Soporte", donde usuarios y profesionales pueden revisar el estado de sus quejas y sugerencias, y ver las respuestas del administrador.
    *   La funcionalidad de chat directo con soporte y el sistema de gestión de quejas/sugerencias (incluyendo las respuestas del administrador) han sido verificados y están funcionando.

*   **Mejora de la Pantalla de Preguntas Frecuentes (FAQ):**
    *   La `FaqScreen` ha sido actualizada para utilizar un `Scaffold` y un `AppBar`, moviendo la barra de pestañas al `bottom` del `AppBar`. Esto resuelve problemas de visualización del fondo y mejora la consistencia del diseño.

*   **Manejo de Imágenes en Publicaciones:**
    *   Se corrigió el error "Exception: Invalid image data" al registrar publicaciones con URLs de imágenes. La aplicación ahora maneja correctamente tanto imágenes locales (subiéndolas a Firebase Storage) como imágenes externas (guardando directamente la URL).

*   **✅ Estabilidad y Mantenimiento del Código:**
    *   Resolución de todos los errores, advertencias y lints críticos reportados por `flutter analyze`, asegurando un código base más robusto y limpio.
    *   Corrección del error de tiempo de ejecución "No Material widget found" en pantallas de contenido principal, envolviendo sus cuerpos en widgets `Material`.
    *   Refinamiento de `UserProfilePage` para cargar datos internamente, eliminando la necesidad del parámetro `userData`.
    *   Eliminación de errores de argumentos duplicados y aplicación de las mejores prácticas de sintaxis (`curly_braces_in_flow_control_structures`).

## 🛠️ Tecnologías Utilizadas

Este proyecto está construido con una pila de tecnologías modernas para el desarrollo de aplicaciones multiplataforma:

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Lenguaje:** [Dart](https://dart.dev/)
*   **Backend:** [Firebase](https://firebase.google.com/)
    *   **🔥 Autenticación:** Firebase Auth (Email/Password & Google Sign-In)
    *   **🗄️ Base de Datos:** Firebase Realtime Database
    *   **📦 Almacenamiento:** Firebase Storage
*   **Gestión de Estado:** [Provider](https://pub.dev/packages/provider)
*   **Mapas:** [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
*   **Editor de Texto:** [Flutter Quill](https://pub.dev/packages/flutter_quill)

## 🚀 Comenzando

Para obtener una copia local y ponerla en marcha, sigue estos sencillos pasos.

### Prerrequisitos

Asegúrate de tener instalado el SDK de Flutter y las herramientas de línea de comandos de Java (`keytool`) en tu `PATH`. Para más información, consulta la [documentación oficial de Flutter](https://flutter.dev/docs/get-started/install).

*   Flutter SDK
*   Java Development Kit (JDK)

### Configuración de Firebase

Este proyecto requiere una configuración de Firebase para funcionar. **No podrás ejecutar la aplicación sin completar estos pasos.**

1.  **Crear un Proyecto en Firebase:**
    *   Ve a la [Consola de Firebase](https://console.firebase.google.com/) y crea un nuevo proyecto.
    *   Habilita los siguientes servicios: **Authentication** (con proveedores de Email/Contraseña y Google), **Realtime Database**, y **Firebase Storage**.

2.  **Configurar la App para Android:**
    *   En la configuración de tu proyecto de Firebase, añade una nueva aplicación de Android con el `package name`: `com.example.kanante_app`.
    *   Genera una huella digital de certificado **SHA-1** para tu keystore de depuración. Puedes obtenerla ejecutando el siguiente comando en tu terminal:
        ```sh
        keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
        ```
    *   Añade esta huella digital SHA-1 a la configuración de tu app de Android en Firebase.
    *   Descarga el archivo `google-services.json` y colócalo en el directorio `android/app/` de tu proyecto.

3.  **Configurar la App para iOS:**
    *   En Firebase, añade una nueva aplicación de iOS con el `bundle ID`: `com.example.kananteApp`.
    *   Descarga el archivo `GoogleService-Info.plist` y colócalo en el directorio `ios/Runner/` de tu proyecto usando Xcode.

4.  **Configurar la App para Web:**
    *   En Firebase, añade una nueva aplicación Web.
    *   Ve a la [Consola de Google Cloud](https://console.cloud.google.com/), selecciona tu proyecto, y en **APIs y servicios > Credenciales**, crea un nuevo **ID de cliente de OAuth 2.0** para "Aplicación web".
    *   Copia el **ID de cliente** generado (un string que termina en `.apps.googleusercontent.com`).
    *   Abre el archivo `web/index.html` y reemplaza el marcador de posición en la siguiente etiqueta meta:
        ```html
        <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID_HERE">
        ```
    *   **Habilitar People API:** En la consola de Google Cloud, ve a **APIs y servicios > Biblioteca** y busca y habilita la **People API**.

### Instalación

1.  Clona el repositorio:
    ```sh
    git clone https://github.com/Angelgonzalez2004/Kanante_app.git
    ```
2.  Navega al directorio del proyecto:
    ```sh
    cd Kanante_app
    ```
3.  Instala las dependencias:
    ```sh
    flutter pub get
    ```
4.  Ejecuta la aplicación en el dispositivo deseado:
    ```sh
    flutter run
    # Para web
    flutter run -d chrome
    ```

## 📂 Estructura del Proyecto

La estructura del proyecto está organizada para mantener una separación clara de responsabilidades, siguiendo las mejores prácticas de Flutter.

```
├── lib
│   ├── data            # Datos estáticos (ej. FAQs)
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

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulta `LICENSE` para más información.

## 📧 Contacto

Link del Proyecto: [https://github.com/Angelgonzalez2004/Kanante_app](https://github.com/Angelgonzalez2004/Kanante_app)