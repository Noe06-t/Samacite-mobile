# Notes de déploiement - SamaCité Mobile

## ⚠️ Problèmes connus et solutions

### 1. Firebase sur Windows Desktop

**Problème** : Firebase (firebase_core, firebase_messaging) ne fonctionne PAS sur Windows Desktop.

**Erreur** :
```
CMake Error: The source directory does not contain a CMakeLists.txt file.
```

**Solution** : Firebase a été commenté dans `pubspec.yaml` pour permettre le développement sur Windows.

```yaml
# Notifications (Android/iOS uniquement)
# firebase_core: ^2.24.2
# firebase_messaging: ^14.7.9
```

**Pour Android/iOS** : Décommenter ces lignes et configurer Firebase correctement.

### 2. Plateformes supportées

#### ✅ Plateformes testées
- **Chrome (Web)** : ✅ Fonctionne parfaitement
- **Windows Desktop** : ✅ Fonctionne (sans Firebase)

#### 🔜 À tester
- **Android** : Nécessite émulateur ou device
- **iOS** : Nécessite Mac + Xcode

## 🚀 Commandes de lancement

### Web (Chrome) - Recommandé pour dev
```bash
flutter run -d chrome
```

### Windows Desktop
```bash
flutter run -d windows
```

### Android (avec émulateur)
```bash
# Lister les émulateurs
flutter emulators

# Lancer un émulateur
flutter emulators --launch <emulator_id>

# Lancer l'app
flutter run -d <device_id>
```

### Build production

```bash
# Web
flutter build web

# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# Windows
flutter build windows
```

## 🔧 Configuration Firebase pour Android/iOS

### Étape 1 : Décommenter dans pubspec.yaml
```yaml
firebase_core: ^2.24.2
firebase_messaging: ^14.7.9
flutter_local_notifications: ^16.3.0
```

### Étape 2 : Configuration Android
1. Créer un projet Firebase
2. Télécharger `google-services.json`
3. Placer dans `android/app/`
4. Ajouter dans `android/build.gradle`:
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

### Étape 3 : Configuration iOS
1. Télécharger `GoogleService-Info.plist`
2. Placer dans `ios/Runner/`
3. Configurer dans Xcode

### Étape 4 : Initialiser dans main.dart
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}
```

## 📱 Backend API

### Configuration locale
- URL par défaut : `http://localhost:8000/api`
- Changer dans : `lib/core/constants/api_constants.dart`

### Pour device physique Android
Utiliser l'IP locale de votre machine :
```dart
static const String baseUrl = 'http://192.168.1.X:8000/api';
```

### Pour émulateur Android
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

## 🐛 Dépannage

### flutter_secure_storage sur Windows
Si erreur avec secure_storage sur Windows :
```bash
flutter clean
flutter pub get
```

### CORS sur Web
Si problèmes CORS sur Chrome, ajouter dans le backend Laravel :
```php
// config/cors.php
'supports_credentials' => true,
'paths' => ['api/*'],
```

### Build Windows lent
Première build Windows peut prendre 5-10 minutes. C'est normal.

## ✅ Recommandations

1. **Développement** : Utiliser Chrome (`flutter run -d chrome`)
2. **Tests complets** : Utiliser émulateur Android
3. **Production** : Build pour Android/iOS avec Firebase configuré
4. **CI/CD** : Tests sur Linux + build Android/iOS
