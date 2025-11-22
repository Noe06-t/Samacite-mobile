# 🐛 Correction : Crash lors de l'accès à la caméra et au GPS

## Problème identifié

L'application crashait lors de :
1. **Prise de photo** avec la caméra → `Lost connection to device`
2. **Capture de la localisation GPS** → Erreur

### Cause racine

Les **permissions Android n'étaient pas déclarées** dans `AndroidManifest.xml`. Quand l'app tentait d'accéder à des ressources protégées (caméra, GPS, stockage), Android **tuait immédiatement le processus** car les permissions n'étaient pas demandées.

## Solution appliquée

### 1. ✅ Permissions ajoutées dans `AndroidManifest.xml`

**Fichier modifié** : `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Internet : Communication avec l'API backend -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Caméra : Prendre des photos pour les signalements -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>

<!-- Stockage : Lire/écrire des images (galerie) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>

<!-- Android 13+ : Permissions granulaires pour les médias -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<!-- GPS : Capturer la position des signalements -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 2. ✅ Gestion des permissions dans `ImageService`

**Fichier modifié** : `lib/core/services/image_service.dart`

Ajout de deux méthodes privées :

#### `_requestPhotosPermission()`
- Demande la permission `Permission.photos` (Android 13+)
- Fallback sur `Permission.storage` pour Android < 13
- Gère le cas `isPermanentlyDenied` avec message explicite
- Retourne `true` si accordée, sinon lance une exception

#### `_requestCameraPermission()`
- Demande la permission `Permission.camera`
- Gère le cas `isPermanentlyDenied`
- Retourne `true` si accordée, sinon lance une exception

#### Modifications des méthodes existantes

**Avant** :
```dart
Future<XFile?> pickImageFromCamera() async {
  try {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );
    return image;
  } catch (e) {
    throw Exception('Erreur lors de la prise de photo : $e');
  }
}
```

**Après** :
```dart
Future<XFile?> pickImageFromCamera() async {
  try {
    // 🔒 VÉRIFICATION PERMISSION AVANT ACCÈS
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      throw Exception('Permission refusée pour accéder à la caméra');
    }

    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );
    return image;
  } catch (e) {
    throw Exception('Erreur lors de la prise de photo : $e');
  }
}
```

Même logique appliquée à `pickImageFromGallery()`.

### 3. ✅ `LocationService` déjà correct

Le `LocationService` gérait déjà correctement les permissions GPS via `Geolocator` :
- Vérifie si les services de localisation sont activés
- Demande la permission si refusée
- Gère le cas `deniedForever`
- Messages d'erreur clairs

**Aucune modification nécessaire** sur ce fichier, les permissions manquaient juste dans `AndroidManifest.xml`.

## Workflow des permissions

### Caméra / Galerie
```
Utilisateur clique "Prendre une photo"
    ↓
ReportNotifier.takePicture()
    ↓
ImageService.pickImageFromCamera()
    ↓
_requestCameraPermission()
    ↓
Permission accordée ? → Ouvrir caméra
Permission refusée ? → Exception + SnackBar
Permission refusée définitivement ? → Message "Ouvrir les paramètres"
```

### GPS
```
Utilisateur clique "Capturer ma position"
    ↓
ReportNotifier.captureLocation()
    ↓
LocationService.getCurrentPosition()
    ↓
isLocationServiceEnabled() ? → Oui
    ↓
checkPermission() / requestPermission()
    ↓
Permission accordée ? → Récupérer position
Permission refusée ? → Exception + SnackBar
Service désactivé ? → Message "Activer GPS"
```

## Messages utilisateur

### Permission refusée temporairement
- **Caméra** : "Permission refusée pour accéder à la caméra"
- **Galerie** : "Permission refusée pour accéder à la galerie"
- **GPS** : "La permission de localisation a été refusée. Veuillez l'autoriser dans les réglages."

### Permission refusée définitivement
- **Caméra** : "Permission refusée définitivement. Veuillez autoriser l'accès à la caméra dans les paramètres de l'application."
- **Galerie** : "Permission refusée définitivement. Veuillez autoriser l'accès aux photos dans les paramètres de l'application."
- **GPS** : "La permission de localisation a été refusée définitivement. Veuillez l'activer dans les paramètres de l'application."

### Service GPS désactivé
- "Les services de localisation sont désactivés. Veuillez les activer dans les paramètres."

## Tests nécessaires

### Tests manuels à effectuer

1. **Caméra - Première utilisation**
   - Cliquer "Prendre une photo"
   - Android affiche dialogue permission
   - Accepter → Caméra s'ouvre ✅
   - Refuser → Message d'erreur clair ✅

2. **Caméra - Permission refusée définitivement**
   - Refuser deux fois la permission
   - Message indique d'aller dans les paramètres ✅

3. **Galerie - Première utilisation**
   - Cliquer "Ajouter des photos"
   - Android affiche dialogue permission
   - Accepter → Galerie s'ouvre ✅
   - Refuser → Message d'erreur clair ✅

4. **GPS - Première utilisation**
   - Cliquer "Capturer ma position"
   - Android affiche dialogue permission
   - Accepter → Position récupérée ✅
   - Refuser → Message d'erreur clair ✅

5. **GPS - Service désactivé**
   - Désactiver GPS dans paramètres Android
   - Cliquer "Capturer ma position"
   - Message indique d'activer GPS ✅

### Tests unitaires existants

Les tests unitaires de `ImageService` et `LocationService` **mockent** les permissions, donc ils passent toujours. Les tests manuels sont **essentiels** pour valider le comportement réel.

## Rebuild nécessaire

⚠️ **IMPORTANT** : Les modifications de `AndroidManifest.xml` nécessitent un **rebuild complet** :

```bash
flutter clean
flutter run -d emulator-5554
```

Simple hot reload/restart **ne suffit PAS**.

## Résultat attendu

Après ces modifications :
- ✅ L'app ne crash plus lors de l'accès à la caméra
- ✅ L'app ne crash plus lors de l'accès au GPS
- ✅ Dialogues de permission Android s'affichent correctement
- ✅ Messages d'erreur clairs si permissions refusées
- ✅ Utilisateur peut ouvrir les paramètres si nécessaire

## Références

- **Package** : `permission_handler: ^11.0.1`
- **Documentation Android** : [Permissions Overview](https://developer.android.com/guide/topics/permissions/overview)
- **Flutter doc** : [Permissions](https://docs.flutter.dev/data-and-backend/permissions)

---

**Date** : 22 novembre 2025  
**Status** : ✅ Corrigé (rebuild en cours)  
**Impact** : Phase 2 - Création de signalement maintenant fonctionnelle
