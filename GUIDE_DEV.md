# Guide de développement - SamaCité Mobile

## 🚀 Commandes essentielles

### Installation et setup initial

```bash
# Installer les dépendances
flutter pub get

# Générer le code (Freezed, Riverpod, JSON)
flutter pub run build_runner build --delete-conflicting-outputs

# En mode watch (régénère automatiquement)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Tests

```bash
# Tous les tests
flutter test

# Tests spécifiques
flutter test test/features/auth/

# Tests avec coverage
flutter test --coverage
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
```

### Lancement

```bash
# Mode debug (défaut)
flutter run

# Mode profile (performance)
flutter run --profile

# Mode release
flutter run --release

# Spécifier un device
flutter devices
flutter run -d <device-id>
```

### Qualité du code

```bash
# Analyser le code
flutter analyze

# Formater le code
dart format .
dart format lib/

# Vérifier les dépendances obsolètes
flutter pub outdated
```

### Maintenance

```bash
# Nettoyer le projet
flutter clean

# Upgrade des dépendances
flutter pub upgrade

# Vérifier les conflits
flutter doctor
flutter doctor -v
```

## 🧪 TDD Workflow

1. **Écrire le test**
   ```bash
   # Créer le fichier de test
   touch test/features/auth/repositories/new_repository_test.dart
   ```

2. **Lancer le test (qui doit échouer)**
   ```bash
   flutter test test/features/auth/repositories/new_repository_test.dart
   ```

3. **Implémenter le code minimum**
   ```bash
   # Créer le fichier source
   touch lib/features/auth/repositories/new_repository.dart
   ```

4. **Relancer le test (qui doit passer)**
   ```bash
   flutter test
   ```

5. **Refactoriser si nécessaire**

## 🔧 Résolution de problèmes courants

### Erreurs de génération de code

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problèmes de dépendances

```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
```

### Erreurs de compilation Android

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter run
```

### Erreurs de compilation iOS

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter run
```

## 📱 Testing sur devices

### Android

```bash
# Lister les devices
adb devices

# Installer l'APK
flutter build apk
adb install build/app/outputs/flutter-apk/app-release.apk

# Logs
adb logcat | grep flutter
```

### iOS

```bash
# Ouvrir dans Xcode
open ios/Runner.xcworkspace

# Build depuis CLI
flutter build ios
```

## 🔍 Debugging

### Activer les logs Dio

Dans `lib/core/services/dio_service.dart`, les logs sont déjà activés via Logger.

### Inspecter le state Riverpod

Ajoutez un observer dans `main.dart`:

```dart
class MyObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('Provider ${provider.name ?? provider.runtimeType} updated');
    print('Previous: $previousValue');
    print('New: $newValue');
  }
}

void main() {
  runApp(
    ProviderScope(
      observers: [MyObserver()],
      child: const MyApp(),
    ),
  );
}
```

## 📊 Performance profiling

```bash
# Profiler l'app
flutter run --profile
# Puis dans DevTools, analyser les performances

# Lancer DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## 🎯 Best practices

1. **Toujours écrire les tests d'abord (TDD)**
2. **Utiliser Freezed pour les modèles**
3. **Gérer les états avec Riverpod**
4. **Logger les erreurs** (Logger package)
5. **Valider les entrées** côté client ET serveur
6. **Utiliser secure_storage** pour les données sensibles
7. **Gérer les erreurs réseau** gracieusement
8. **Optimiser les images** avant upload
9. **Tester sur plusieurs devices**
10. **Formater le code** avant chaque commit

## 🔐 Sécurité

- ✅ Tokens stockés dans secure_storage
- ✅ HTTPS uniquement (backend)
- ✅ Validation des entrées
- ✅ Nettoyage des données à la déconnexion
- 🔜 Certificate pinning
- 🔜 Obfuscation en release

## 📚 Ressources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Dio Documentation](https://pub.dev/packages/dio)
- [Freezed Documentation](https://pub.dev/packages/freezed)
- [Spécifications SamaCité](.github/instructions/spec.instructions.md)
