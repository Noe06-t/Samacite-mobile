# 🔥 Configuration Firebase - Phase 5

## Vue d'ensemble

Ce document explique comment configurer Firebase Cloud Messaging (FCM) pour l'application SamaCité Mobile.

**État actuel** : ✅ Code implémenté, ⚠️ Configuration Firebase Console requise

---

## 📋 Prérequis

- Compte Google/Firebase
- Flutter SDK installé
- FlutterFire CLI installé (`dart pub global activate flutterfire_cli`)
- Accès au backend Laravel (endpoint `/api/fcm-token`)

---

## 🚀 Étapes de configuration

### 1. Créer un projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquer sur **"Ajouter un projet"**
3. Nom du projet : `samacite-mobile`
4. Activer Google Analytics (optionnel)
5. Créer le projet

### 2. Ajouter l'application Android

1. Dans Firebase Console → **Paramètres projet** → **Vos applications**
2. Cliquer sur l'icône Android
3. Renseigner :
   - **Nom du package Android** : `com.samacite.mobile` (voir `android/app/build.gradle`)
   - **Surnom** : SamaCité Mobile
   - **Certificat SHA-1** : Optionnel pour FCM (requis pour auth Google)
4. Télécharger `google-services.json`
5. Placer le fichier dans : `android/app/google-services.json`

### 3. Configurer Android Build

#### `android/build.gradle` (projet)

Vérifier que le plugin Google Services est présent :

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### `android/app/build.gradle` (app)

Ajouter en bas du fichier :

```gradle
apply plugin: 'com.google.gms.google-services'
```

### 4. Générer les options Firebase avec FlutterFire CLI

```bash
# Installer FlutterFire CLI (si pas déjà fait)
dart pub global activate flutterfire_cli

# Configurer Firebase pour le projet Flutter
flutterfire configure
```

Cette commande va :
- Scanner vos apps Firebase
- Créer `lib/firebase_options.dart` automatiquement
- Configurer Android et iOS

### 5. Ajouter l'application iOS (optionnel)

1. Dans Firebase Console → Ajouter iOS
2. **Bundle ID** : `com.samacite.mobile`
3. Télécharger `GoogleService-Info.plist`
4. Ouvrir Xcode : `open ios/Runner.xcworkspace`
5. Glisser-déposer le fichier dans Xcode (dossier Runner)
6. Cocher "Copy items if needed"

### 6. Activer Cloud Messaging

1. Firebase Console → **Cloud Messaging**
2. Onglet **"Server key"** → Copier la clé serveur
3. Cette clé sera utilisée côté backend Laravel pour envoyer les notifications

---

## 🔧 Configuration Backend Laravel

### Endpoint requis : `/api/fcm-token`

Le mobile envoie son token FCM au backend :

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/fcm-token', [FCMController::class, 'store']);
});
```

```php
// app/Http/Controllers/Api/FCMController.php
public function store(Request $request)
{
    $request->validate([
        'token' => 'required|string',
        'device_type' => 'required|in:android,ios',
    ]);

    $user = auth()->user();
    
    // Créer ou mettre à jour le token
    FcmToken::updateOrCreate(
        ['user_id' => $user->id],
        [
            'token' => $request->token,
            'device_type' => $request->device_type,
        ]
    );

    return response()->json([
        'success' => true,
        'message' => 'Token FCM enregistré',
    ]);
}
```

### Migration

```php
Schema::create('fcm_tokens', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('token')->unique();
    $table->enum('device_type', ['android', 'ios']);
    $table->timestamps();
});
```

### Envoyer une notification depuis Laravel

```php
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;

$factory = (new Factory)->withServiceAccount('path/to/firebase-credentials.json');
$messaging = $factory->createMessaging();

$message = CloudMessage::withTarget('token', $fcmToken)
    ->withNotification([
        'title' => 'Nouveau signalement',
        'body' => 'Un nouveau signalement a été créé dans votre zone',
    ])
    ->withData([
        'type' => 'new_report',
        'report_id' => '123',
    ]);

$messaging->send($message);
```

---

## 📱 Types de notifications

### 1. Nouveau signalement

```json
{
  "notification": {
    "title": "Nouveau signalement",
    "body": "Nid-de-poule dans votre zone"
  },
  "data": {
    "type": "new_report",
    "report_id": "123",
    "category_id": "5"
  }
}
```

### 2. Nouveau commentaire

```json
{
  "notification": {
    "title": "Nouveau commentaire",
    "body": "Quelqu'un a commenté votre signalement"
  },
  "data": {
    "type": "new_comment",
    "report_id": "123"
  }
}
```

### 3. Changement de statut

```json
{
  "notification": {
    "title": "Statut mis à jour",
    "body": "Votre signalement est maintenant résolu"
  },
  "data": {
    "type": "status_changed",
    "report_id": "123",
    "new_status": "resolved"
  }
}
```

---

## 🧪 Tester les notifications

### Test manuel depuis Firebase Console

1. Firebase Console → **Cloud Messaging**
2. Cliquer sur **"Envoyer un message de test"**
3. Récupérer le token FCM depuis les logs de l'app :
   ```
   [NotificationService] ✅ FCM Token: eGx...
   ```
4. Entrer le titre, le message et les données personnalisées
5. Envoyer

### Test depuis Postman (avec backend)

```bash
POST https://fcm.googleapis.com/fcm/send
Headers:
  Authorization: key=YOUR_SERVER_KEY
  Content-Type: application/json

Body:
{
  "to": "FCM_TOKEN_FROM_DEVICE",
  "notification": {
    "title": "Test",
    "body": "Message de test"
  },
  "data": {
    "type": "new_report",
    "report_id": "1"
  }
}
```

---

## ✅ Checklist de validation

- [ ] Projet Firebase créé
- [ ] App Android ajoutée avec `google-services.json`
- [ ] FlutterFire CLI configuré (`firebase_options.dart` généré)
- [ ] L'app démarre sans erreur Firebase
- [ ] Token FCM affiché dans les logs
- [ ] Token envoyé au backend (`/api/fcm-token`)
- [ ] Notification de test reçue (foreground)
- [ ] Notification de test reçue (background)
- [ ] Clic sur notification ouvre le signalement
- [ ] Backend peut envoyer des notifications

---

## 🐛 Troubleshooting

### Erreur : "Default FirebaseApp is not initialized"

**Solution** : Vérifier que `Firebase.initializeApp()` est appelé dans `main()` avant `runApp()`

### Erreur : "google-services.json not found"

**Solution** : Placer `google-services.json` dans `android/app/` (pas dans `android/`)

### Token FCM est null

**Solution** :
- Vérifier les permissions notifications accordées
- Attendre quelques secondes (iOS nécessite APNS token d'abord)
- Redémarrer l'app

### Notifications ne s'affichent pas en foreground

**Solution** : C'est normal, le code utilise `flutter_local_notifications` pour afficher une notification locale

### Clic sur notification ne navigue pas

**Solution** :
- Vérifier que `NotificationNavigationHandler` parse correctement les données
- Vérifier que `MainNavigationPage` écoute bien `onNotificationClick`
- Vérifier les logs : `[NotificationNav] 📱 Traitement notification`

---

## 📚 Ressources

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Laravel Firebase Admin SDK](https://github.com/kreait/laravel-firebase)

---

**Dernière mise à jour** : 24 novembre 2025  
**Phase** : 5 - Notifications & Broadcasting
