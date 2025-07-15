# 🐮 CollarApp (Emisor) – Proyecto Moova

Aplicación Flutter para dispositivos móviles Android que simula un collar inteligente para ganado. Esta app actúa como **emisor**, registrando y enviando automáticamente la ubicación geográfica de una "vaca" identificada mediante un ID único.

---

## 🚀 Funcionalidades

- 📍 Obtiene la ubicación GPS del dispositivo.
- 🔁 Envía datos automáticamente a intervalos configurables.
- 🧠 Almacena localmente el nombre, ID, última ubicación y fecha/hora.
- ☁️ Sube la información a Firebase Firestore.
- 📡 Cada instalación tiene un **ID único** como `COW0001`, `COW0002`, etc.
- 📂 Registra historial de posiciones por vaca.

---

## 🛠️ Tecnologías usadas

| Tecnología                  | Uso |
|---------------------------|---------------------------------------|
| 🐦 Flutter                | Framework principal                  |
| 📍 Geolocator             | Acceso a GPS                         |
| ☁️ Firebase               | Firestore (base de datos en la nube) |
| 📦 SharedPreferences      | Persistencia local                   |
| 🔧 Device Info            | Obtención de datos del dispositivo   |
| 🧪 Firestore Transactions | Generación atómica de ID únicos      |

---

## 🔧 Instalación del Emisor

1. Clona el repositorio:
   ```bash
   git clone https://github.com/TU-USUARIO/Moova.git
   cd Moova/emisor

2. Conecta un dispositivo Android (activa el modo desarrollador y depuración USB).

3. Instala las dependencias:
   flutter pub get

4. Ejecuta la app:
   flutter run


🧪 Estructura de Firestore
plaintext
Copiar
Editar
ubicaciones (colección)
├── COW0001 (documento)
│   ├── nombre: "Cindirella"
│   ├── historial (subcolección)
│   │   ├── auto-generado doc
│   │   │   ├── latitude
│   │   │   ├── longitude
│   │   │   └── lastUpdate
├── COW0002
...
contador (documento)
└── lastCowId: 2

⚠️ Consideraciones
Si no hay internet, los datos se guardan localmente y se reintentan al recuperar la conexión.
Cada instalación genera su cowId de forma centralizada usando Firestore para evitar colisiones.
El proyecto está diseñado para escalar con múltiples emisores (dispositivos) y un solo receptor.

✅ Requisitos
Android 8.0 o superior
Conexión GPS activa
Firebase Firestore habilitado
Flutter ≥ 3.x.x


Reglas de seguridad Firestore (temporales para desarrollo)


👩🏻‍💻 Autor
Jennifer Santamaría
jenniferl.santamariam23@gmail.com

📦 Próximamente
Panel web (receptor Moova) con mapa y notificaciones

Modo offline para enviar al reconectar

Encriptación básica de los datos enviados