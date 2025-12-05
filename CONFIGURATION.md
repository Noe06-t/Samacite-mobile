# Configuration Environnement - SamaCité

## 🔧 Variables d'environnement requises

### Backend Laravel

Créer/modifier le fichier `.env` à la racine du projet backend :

```env
# Application
APP_NAME=SamaCite
APP_ENV=local
APP_KEY=base64:...
APP_DEBUG=true
APP_URL=http://localhost:8000

# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=samacite_db
DB_USERNAME=root
DB_PASSWORD=

# Redis (Cache & Queues)
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

# Google Gemini AI (OBLIGATOIRE pour analyse IA)
GEMINI_API_KEY=votre_clé_api_ici

# Sanctum
SANCTUM_STATEFUL_DOMAINS=localhost:3000,127.0.0.1:3000
SESSION_DOMAIN=localhost

# Broadcasting (Notifications)
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=mt1

# Mail (Notifications)
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@samacite.sn"
MAIL_FROM_NAME="${APP_NAME}"

# Storage (Images)
FILESYSTEM_DISK=local
# Pour production: s3 ou minio
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

# Logs
LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug
```

## 🤖 Obtenir une clé Google Gemini API (GRATUIT)

### Étape 1 : Créer un compte Google Cloud
1. Aller sur https://cloud.google.com/
2. Se connecter avec un compte Google
3. Créer un nouveau projet (ex: "SamaCité IA")

### Étape 2 : Activer l'API Gemini
1. Aller sur https://makersuite.google.com/app/apikey
2. Cliquer "Create API Key"
3. Sélectionner votre projet Google Cloud
4. Copier la clé générée (commence par `AIza...`)

### Étape 3 : Ajouter au .env
```env
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Limites gratuites (Tier gratuit)
- ✅ 60 requêtes/minute
- ✅ 1 500 requêtes/jour
- ✅ Pas de carte bancaire requise
- ✅ Suffisant pour développement et tests

### Vérifier que ça marche
```bash
curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=VOTRE_CLÉ" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{"text": "Test"}]
    }]
  }'
```

Si vous recevez une réponse JSON → ✅ La clé fonctionne

## 📱 Configuration Flutter (Mobile)

### Fichier de configuration API

Le fichier `lib/core/constants/api_constants.dart` doit pointer vers votre backend :

```dart
class ApiConstants {
  // URL de base du backend Laravel
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Émulateur Android
  // static const String baseUrl = 'http://localhost:8000/api'; // iOS Simulator
  // static const String baseUrl = 'https://api.samacite.sn/api'; // Production
  
  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String reports = '/reports';
  static const String categories = '/categories';
  static const String aiAnalyze = '/ai/analyze-image'; // ← Endpoint IA
}
```

### Configuration réseau par plateforme

| Plateforme | URL Backend | Notes |
|------------|-------------|-------|
| **Émulateur Android** | `http://10.0.2.2:8000/api` | Alias pour localhost de la machine hôte |
| **iOS Simulator** | `http://localhost:8000/api` | Accès direct au localhost |
| **Appareil physique** | `http://192.168.x.x:8000/api` | IP locale de votre machine |
| **Production** | `https://api.samacite.sn/api` | Domaine de production |

### Permissions Android

Vérifier `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Permissions iOS

Vérifier `ios/Runner/Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string>SamaCité a besoin d'accéder à la caméra pour prendre des photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>SamaCité a besoin d'accéder à la galerie pour sélectionner des photos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>SamaCité a besoin de votre localisation pour géolocaliser vos signalements</string>
```

## 🚀 Démarrage rapide

### Backend Laravel
```bash
# 1. Installer dépendances
composer install

# 2. Copier .env.example vers .env
cp .env.example .env

# 3. Générer clé application
php artisan key:generate

# 4. Ajouter GEMINI_API_KEY dans .env
nano .env  # ou notepad .env sur Windows

# 5. Migrer base de données
php artisan migrate --seed

# 6. Démarrer serveur
php artisan serve
```

### Frontend Flutter
```bash
# 1. Installer dépendances
flutter pub get

# 2. Régénérer code généré (Freezed, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 3. Lancer app
flutter run
```

## ✅ Checklist Configuration

### Backend
- [ ] `.env` créé et configuré
- [ ] `GEMINI_API_KEY` ajouté
- [ ] Base de données migrée
- [ ] Serveur Laravel démarré (`php artisan serve`)
- [ ] Redis démarré (si utilisé)
- [ ] Endpoint `/api/ai/analyze-image` implémenté

### Frontend
- [ ] `flutter pub get` exécuté
- [ ] `build_runner` exécuté sans erreurs
- [ ] `api_constants.dart` configuré avec bonne URL
- [ ] Permissions Android/iOS configurées
- [ ] App compile et démarre

### Tests
- [ ] Inscription/Connexion fonctionne
- [ ] Création signalement fonctionne
- [ ] Ajout photo fonctionne
- [ ] Analyse IA déclenche (même si erreur)
- [ ] Affichage erreur réseau propre

## 🔍 Debugging

### Backend ne répond pas
```bash
# Vérifier que Laravel tourne
curl http://localhost:8000/api/categories

# Vérifier logs Laravel
tail -f storage/logs/laravel.log
```

### Erreur CORS depuis Flutter
Ajouter dans `config/cors.php` :
```php
'allowed_origins' => ['*'],
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

### Erreur Gemini API
```bash
# Test manuel
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=VOTRE_CLÉ" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
```

### Flutter ne trouve pas le backend
- Émulateur Android : `http://10.0.2.2:8000/api`
- Appareil physique : `http://192.168.x.x:8000/api` (IP locale)
- iOS Simulator : `http://localhost:8000/api`

## 📞 Support

Si problème persistant :
1. Vérifier logs Laravel : `storage/logs/laravel.log`
2. Vérifier console Flutter : `flutter run -v`
3. Vérifier network requests dans DevTools
4. Consulter `AI_BACKEND_IMPLEMENTATION.md`
5. Consulter `AI_FEATURE_GUIDE.md`

---

**Dernière mise à jour** : Janvier 2025
**Version** : 1.0.0
