# SamaCité Mobile 📱

Application mobile de signalement citoyen pour la plateforme SamaCité.

## ✨ Fonctionnalités implémentées

### ✅ Phase 1 : Authentification complète

- ✅ **Page de connexion** avec validation
- ✅ **Page d'inscription** avec tous les champs
- ✅ **Page d'accueil** après authentification
- ✅ **Stockage sécurisé** des tokens (flutter_secure_storage)
- ✅ **Navigation** fluide entre les pages
- ✅ **Déconnexion** avec nettoyage complet
- ✅ **Feedback utilisateur** avec SnackBar et états de chargement

### 🏗️ Architecture

- Pattern **Repository** pour l'accès aux données
- **Riverpod** avec code generation pour le state management
- Service **Dio** avec interceptors pour les requêtes HTTP
- Modèles **Freezed** pour l'immutabilité et la sérialisation
- **TDD** - Tests unitaires et d'intégration
- Respect de la **palette de couleurs** des spécifications

## 🎨 Palette de couleurs

- Bouton primaire : `#FFA000` (texte noir)
- Cadres & sections : `#007A3F` (texte blanc)
- Fond général : `#FFFFFF`
- Danger : `#EA0707` (texte blanc)

## 🚀 Démarrage rapide

### Prérequis

- Flutter SDK >= 3.9.2
- Dart SDK >= 3.0.0
- Backend Laravel sur `http://localhost:8000`
- Un émulateur Android/iOS ou un appareil physique

### Installation

```bash
# Installer les dépendances
flutter pub get

# Générer le code (Freezed, Riverpod, JSON)
flutter pub run build_runner build --delete-conflicting-outputs

# Lancer les tests
flutter test

# Lancer l'application
flutter run
```

## 📁 Structure du projet

```
lib/
├── core/
│   ├── constants/     # API URLs, couleurs
│   ├── models/        # UserModel, AuthResponse
│   ├── services/      # DioService, SecureStorage
│   └── errors/        # ApiException
│
└── features/
    └── auth/
        ├── repositories/  # AuthRepository
        ├── providers/     # Riverpod providers
        └── pages/         # LoginPage, RegisterPage
```

## 🎨 Design

Conforme aux spécifications SamaCité :
- Primaire : `#FFA000`
- Secondaire : `#007A3F`
- Danger : `#EA0707`
- Material Design 3

## 🔗 API Backend

Endpoints utilisés :
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`

## 🧪 Tests

```bash
# Tous les tests
flutter test

# Tests avec coverage
flutter test --coverage
```

✅ Tous les tests passent !

## 📝 Scripts utiles

```bash
# Générer le code en mode watch
flutter pub run build_runner watch

# Analyser le code
flutter analyze

# Nettoyer le projet
flutter clean

# Formater le code
dart format .
```

## 📦 Dépendances

- `dio` - Client HTTP
- `flutter_riverpod` - State management
- `flutter_secure_storage` - Stockage sécurisé
- `freezed` - Code generation
- `firebase_messaging` - Notifications (préparé)
- `mockito` - Tests

## 🔜 Prochaines étapes

- Phase 2 : Gestion des signalements (création, liste, détail)
- Phase 3 : Upload d'images avec compression
- Phase 4 : Système de commentaires
- Phase 5 : Notifications push (FCM)
- Phase 6 : Amélioration des performances et cache

## 👨‍💻 Développement

Le projet suit une approche **TDD** (Test-Driven Development) :
1. Écrire les tests d'abord
2. Implémenter le code minimum
3. Refactoriser

### Convention de code

- Utiliser `dart format` avant chaque commit
- Suivre les conventions Dart officielles
- Documenter les fonctions publiques
- Maintenir la couverture de tests > 80%

## 📱 Captures d'écran

L'application contient :
- ✅ Page de connexion
- ✅ Page d'inscription
- ✅ Page d'accueil
- 🔜 Page de création de signalement
- 🔜 Liste des signalements

## 🐛 Débogage

Si vous rencontrez des problèmes :

```bash
# Nettoyer et réinstaller
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Vérifier le backend
curl http://localhost:8000/api/auth/login
```

## 📄 Licence

Ce projet fait partie de la plateforme SamaCité.

---

**Dernière mise à jour** : 21 novembre 2025
**Version** : 1.0.0+1
**Status** : ✅ Phase 1 (Authentification) complétée

- [ ] Page d'accueil
- [ ] Créer un signalement
- [ ] Liste des signalements
- [ ] Upload d'images
- [ ] Notifications push
- [ ] Carte interactive

## 📄 Documentation

Voir `IMPLEMENTATION.md` pour les détails techniques.
