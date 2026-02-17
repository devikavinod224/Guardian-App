# Guardian - Advanced Parental Control & Safety App 🛡️

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

Guardian is a next-generation parental control application built with Flutter, designed to offer a balance of safety, productivity, and modern user experience. It provides parents with real-time insights and controls while empowering children with gamified productivity tools.

---

## 🚀 Comprehensive Feature List

### 📱 Dashboard & Monitoring
-   **Multi-Child Management**: Monitor multiple devices from a single parent account.
-   **Live Status Indicators**: Instantly see if a child is *Online*, *Offline*, or *In Danger*.
-   **Activity Leaderboard** 🏆: Visual leaderboard highlighting the child with the highest daily screen time to encourage healthy competition.
-   **7-Day Activity Charts** 📊: Beautiful bar charts showing historical screen time trends.

### 🛡️ App Control & Limits
-   **Smart App Blocking**: Indefinitely block distracting applications (e.g., Games, Social Media).
-   **Daily Time Limits**: Set granular daily usage limits (e.g., "1 hour of YouTube").
-   **Permission Requests** ✋: Children can request unblocking or more time directly from their blocked screen.
-   **Remote Approval**: Parents receive real-time requests and can grant temporary access (15m, 30m, 1hr) or reject them instantly.

### 📍 Location & Geofencing
-   **Real-Time GPS Tracking**: Precise location tracking using OpenStreetMap.
-   **Safe Zones (Geofencing)** 🏠: Set a "Home Base" (500m radius). Receive visual alerts ("OUT OF SAFE ZONE") when the child wanders too far.
-   **Speed & Driving Safety** 🚗: Automatically detects if the device is moving > 20 km/h. Locks the screen with an "Eyes on the Road" interface to prevent distracted driving. Includes a "Passenger Mode" override (valid for 15 mins).

### 🚨 Safety & Emergency
-   **SOS Panic Button** 🆘: A dedicated floating action button on the child's dashboard. A long-press triggers a high-priority alarm on the parent's device with the child's last known location.
-   **Uninstall Protection** 🛡️: integrated with Android's **Device Admin API** to prevent unauthorized uninstallation of the Guardian app.

### 🧠 Productivity & Bio-Rhythms
-   **Gamified Focus Mode** 🎯: encourages study habits! Children can start a "Focus Session" (30 mins). If completed without leaving the app, they earn **10 minutes of Bonus Screen Time**.
-   **Bedtime Mode** 🌙: Enforce healthy sleep schedules. Automatically locks all non-essential apps during set hours (e.g., 9 PM - 7 AM) with a calming "Good Night" interface.

### 🔐 Setup & Security
-   **Secure QR Pairing**: Easy, secure onboarding process using QR codes to link child devices to parent accounts.
-   **Role-Based Access**: Distinct interfaces for Parents (Admin/Dashboard) and Children (Client/Status).

---

## 📸 Screenshots

<p align="center">
  <img src="screenshots/Screenshot 2026-02-18 005347.png" width="30%" />
  <img src="screenshots/Screenshot 2026-02-18 005357.png" width="30%" />
  <img src="screenshots/Screenshot 2026-02-18 005409.png" width="30%" />
  <img src="screenshots/Screenshot 2026-02-18 005426.png" width="30%" />
  <img src="screenshots/Screenshot 2026-02-18 005436.png" width="30%" />
  <img src="screenshots/Screenshot 2026-02-18 005459.png" width="30%" />
  <img src="screenshots/Screenshot 2026-02-18 005535.png" width="30%" />
  <img src="screenshots/Screenshot 2026-02-18 005556.png" width="30%" />
  <img src="screenshots/Screenshot 2026-02-18 005608.png" width="30%" />
  <img src="screenshots/Screenshot 2026-02-18 005627.png" width="30%" />
</p>

---

## 🛠️ Tech Stack & Architecture

This project uses a robust integration of Flutter and Native Android code to achieve system-level control.

| Feature | Tech Used |
|---------|-----------|
| **UI Framework** | Flutter 3.x (Material 3 + Glassmorphism) |
| **Backend** | Firebase Firestore (Real-time Sync) |
| **Auth** | Firebase Auth (Anonymous & Email) |
| **Background Service** | `flutter_background_service` + Foreground Notifications |
| **Native Bridge** | MethodChannels (Kotlin) & DeviceAdminReceiver |
| **Charts** | `fl_chart` |
| **Location** | `geolocator` & `flutter_map` (OSM) |
| **Usage Stats** | `usage_stats` (Android Package Usage) |
| **Animations** | `flutter_animate` |

---

## ⚙️ Installation & Setup

1.  **Clone the repository**
    ```bash
    git clone https://github.com/devikavinod224/Guardian-App.git
    ```
2.  **Firebase Configuration**
    -   Create a Firebase project.
    -   Download `google-services.json` and place it in `android/app/`.
3.  **Run the App**
    ```bash
    flutter pub get
    flutter run
    ```
3.  **Build the App**
    ```bash
    flutter pub get
    flutter build apk
    ```

## 📝 Required Permissions
Guardian requires the following sensitive permissions to function effectively:
-   `PACKAGE_USAGE_STATS`: monitoring app usage.
-   `ACCESS_FINE_LOCATION`: real-time tracking & speed detection.
-   `BIND_DEVICE_ADMIN`: uninstall protection.
-   `SYSTEM_ALERT_WINDOW`: blocking overlay.

---

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

---

Built with ❤️ using **Flutter**.

**Made by Devika Vinod**
