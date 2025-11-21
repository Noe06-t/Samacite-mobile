# 🗺️ ROADMAP - SamaCité Mobile

## Vue d'ensemble du projet

Application mobile Flutter pour la plateforme de signalement citoyen SamaCité. Développement itératif avec validation à chaque phase.

## ⚠️ Contraintes obligatoires

### 1. Test-Driven Development (TDD)
- **Les tests DOIVENT être écrits AVANT l'implémentation**
- Ordre strict : Tests → Implémentation → Refactoring
- Aucune fonctionnalité sans tests

### 2. Design des interfaces
- **Si les maquettes ne sont pas disponibles dans `maquettes/`, DEMANDER le design**
- Ne PAS créer de design arbitraire
- Respecter strictement les maquettes fournies
- Utiliser la palette de couleurs définie

### 3. Architecture backend (référence)
- Suivre le Repository Pattern de Laravel
- Utiliser Dio pour toutes les requêtes API
- Eager-loading systématique pour éviter N+1

---

## 📋 Phases du projet

### ✅ Phase 1 : Authentification [COMPLÉTÉE]
**Status** : ✅ Validée  
**Durée** : Complétée le 21/11/2025

#### Fonctionnalités
- ✅ Page de connexion
  - Formulaire email/mot de passe
  - Validation des champs
  - Gestion des erreurs
  - Toggle visibilité mot de passe
  
- ✅ Page d'inscription
  - Formulaire complet (nom, email, téléphone, mot de passe)
  - Validation locale et serveur
  - Confirmation mot de passe
  - Acceptation conditions d'utilisation
  
- ✅ Gestion de session
  - Stockage sécurisé du token
  - Auto-login si token valide
  - Déconnexion avec nettoyage
  
- ✅ Navigation
  - Login ↔️ Register
  - Login/Register → HomePage
  - Logout → Login

#### Livrables
- ✅ Code source
- ✅ Tests unitaires (10/10)
- ✅ Documentation (README, IMPLEMENTATION, GUIDE_DEV)
- ✅ Architecture (Repository Pattern + Riverpod)

#### API Endpoints utilisés
- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/logout`

---

### 🔄 Phase 2 : Gestion des Signalements (Reports) [EN COURS]
**Status** : 🔄 En développement  
**Estimation** : 5-7 jours  
**Référence** : [Phase 2 des spécifications](#phase-2---gestion-des-signalements-reports)

#### Prérequis
- ✅ Backend Laravel API prêt avec endpoints signalements
- ⚠️ **Vérifier disponibilité des maquettes** dans `maquettes/signalement.xml`
- ⚠️ **Si maquettes manquantes : DEMANDER le design avant de commencer**

#### Objectifs
Permettre aux utilisateurs de créer de nouveaux signalements avec photos et localisation.

#### 🧪 Tests à écrire EN PREMIER

##### ÉTAPE 1 : Tests unitaires (TDD)
- [ ] **Tests ReportRepository**
  - [ ] Test `create()` avec données valides
  - [ ] Test `create()` avec données invalides
  - [ ] Test `create()` avec erreur réseau
  - [ ] Test `uploadImages()` avec 1 image
  - [ ] Test `uploadImages()` avec 5 images
  - [ ] Test `uploadImages()` avec limite dépassée
  - [ ] Test compression images
  
- [ ] **Tests ReportModel (Freezed)**
  - [ ] Test sérialisation JSON
  - [ ] Test désérialisation JSON
  - [ ] Test validation champs requis

- [ ] **Tests ReportNotifier (Riverpod)**
  - [ ] Test état initial
  - [ ] Test création signalement succès
  - [ ] Test création signalement erreur
  - [ ] Test upload images progressif
  - [ ] Test états de loading

##### ÉTAPE 2 : Implémentation des modèles
- [ ] **CategoryModel** (Freezed + JSON serializable)
- [ ] **ReportModel** (Freezed + JSON serializable)
- [ ] **LocationModel** (latitude, longitude)
- [ ] Génération code avec build_runner

##### ÉTAPE 3 : Implémentation Repository
- [ ] **ReportRepository**
  - [ ] `create(ReportData)` → API POST /api/reports
  - [ ] `uploadImages(reportId, images)` → API POST /api/reports/{id}/images
  - [ ] Gestion erreurs API
  - [ ] Validation locale

- [ ] **CategoryRepository**
  - [ ] `getCategories()` → API GET /api/categories
  - [ ] Cache local des catégories

##### ÉTAPE 4 : Tests widgets (avant UI)
- [ ] Test formulaire création
- [ ] Test validation champs
- [ ] Test sélection catégorie
- [ ] Test ajout/suppression photos
- [ ] Test bouton soumettre (enabled/disabled)

##### ÉTAPE 5 : Interface de création
- [ ] ⚠️ **VÉRIFIER maquette `signalement.xml` existe**
- [ ] ⚠️ **SI NON : DEMANDER le design de la page de création**
- [ ] Page de création de signalement
- [ ] Formulaire avec champs :
  - Titre (requis)
  - Description (requis)
  - Catégorie (sélection, requis)
  - Localisation (map picker)
  - Photos (1-5 images)
- [ ] Validation des champs
- [ ] Preview des photos avant envoi
- [ ] Indicateur de progression upload

##### ÉTAPE 6 : Gestion des photos
- [ ] Service ImageService (tests écrits)
  - Compression images
  - Validation taille/format
  - Conversion base64 si nécessaire
- [ ] Intégration image_picker
  - Prendre photo (caméra)
  - Choisir depuis galerie
  - Support multi-sélection
- [ ] Preview avec possibilité de suppression
- [ ] Limite de 5 photos stricte

##### ÉTAPE 7 : Géolocalisation
- [ ] Service LocationService (tests écrits)
  - Vérifier permissions
  - Obtenir position actuelle
  - Gestion erreurs GPS
- [ ] Intégration carte (à définir : Google Maps ou OpenStreetMap)
- [ ] Permettre déplacement du marqueur
- [ ] Validation coordonnées

##### ÉTAPE 8 : Provider Riverpod
- [ ] ReportNotifier avec états
- [ ] CategoryNotifier avec cache
- [ ] Gestion états de loading
- [ ] Gestion erreurs

##### ÉTAPE 9 : Intégration complète
- [ ] Connexion formulaire → repository
- [ ] Upload progressif (texte puis images)
- [ ] Feedback succès/échec (SnackBar)
- [ ] Navigation vers détail après création
- [ ] Cleanup après soumission

#### API Endpoints requis (Backend Laravel)
- `GET /api/categories` - Liste catégories
- `POST /api/reports` - Créer signalement (avec eager-loading)
- `POST /api/reports/{id}/images` - Upload images

**Vérifier avec backend** :
- [ ] Endpoints disponibles
- [ ] Format réponse JSON conforme
- [ ] Relations eager-loadées (user, images, category)
- [ ] Validation côté serveur

#### Dépendances à ajouter
```yaml
# Géolocalisation
geolocator: ^10.1.0
permission_handler: ^11.0.1

# Carte (À CONFIRMER : Google Maps ou OpenStreetMap ?)
# google_maps_flutter: ^2.5.0  
# flutter_map: ^6.0.0  # Alternative OSM
```

#### Critères de validation OBLIGATOIRES
- ✅ **TOUS les tests passent (unitaires + widgets)**
- ✅ Maquettes respectées (ou design validé)
- ✅ Création signalement avec texte uniquement
- ✅ Ajout de 1-5 photos avec compression
- ✅ Sélection localisation (GPS ou manuelle)
- ✅ Sélection catégorie fonctionnelle
- ✅ Upload réussi avec feedback utilisateur
- ✅ Gestion erreurs complète
- ✅ Code documenté (commentaires + README)
- ✅ `flutter analyze` sans warnings
- ✅ Pas de régression Phase 1

---

### 📱 Phase 3 : Gestion des Catégories & Affichage Signalements [À FAIRE]
**Status** : ⏳ En attente  
**Estimation** : 4-5 jours  
**Référence** : [Phase 3 des spécifications](#phase-3---gestion-des-catégories--images)

#### Prérequis
- ✅ Phase 2 validée et complétée
- ⚠️ **Vérifier maquettes liste et détail dans `maquettes/`**
- ⚠️ **Si manquantes : DEMANDER le design**
- ✅ Backend endpoints liste/détail prêts

#### Objectifs
Afficher la liste et le détail des signalements avec filtres, recherche et cache.

#### 🧪 Tests à écrire EN PREMIER

##### ÉTAPE 1 : Tests unitaires Repository (TDD)
- [ ] **Tests ReportRepository - Liste**
  - [ ] Test `getReports()` avec pagination
  - [ ] Test `getReports()` avec include (user, images)
  - [ ] Test `getReports()` avec filtres statut
  - [ ] Test `getReports()` avec filtres catégorie
  - [ ] Test `getReports()` avec recherche
  - [ ] Test `getReportById(id)` avec relations
  - [ ] Test `getMyReports()` utilisateur connecté
  - [ ] Test `deleteReport(id)` avec autorisation

- [ ] **Tests Cache (si implémenté)**
  - [ ] Test cache liste signalements
  - [ ] Test invalidation cache après création
  - [ ] Test TTL cache

##### ÉTAPE 2 : Tests Widgets (avant UI)
- [ ] Test ReportListPage affichage
- [ ] Test ReportCard avec données
- [ ] Test pagination infinite scroll
- [ ] Test pull-to-refresh
- [ ] Test filtres multiples
- [ ] Test barre recherche
- [ ] Test états vides (no data, loading, error)
- [ ] Test navigation vers détail

##### ÉTAPE 3 : Implémentation Repository & Providers
- [ ] **ReportRepository** - Méthodes lecture
  - [ ] `getReports({page, filters, search})`
  - [ ] `getReportById(id)`
  - [ ] `getMyReports()`
  - [ ] `deleteReport(id)`
  
- [ ] **ReportsNotifier** (Riverpod)
  - [ ] État liste avec pagination
  - [ ] État filtres actifs
  - [ ] État recherche
  - [ ] Gestion cache

##### ÉTAPE 4 : Interface Liste
- [ ] ⚠️ **VÉRIFIER maquette liste existe**
- [ ] ⚠️ **SI NON : DEMANDER le design**
- [ ] Page liste avec pagination
- [ ] ReportCard pour chaque signalement
  - Photo principale (cached_network_image)
  - Titre
  - Statut avec badge coloré (#0023D142, #34C75936, #FFA00070)
  - Date formatée
  - Distance (si géoloc activée)
- [ ] Pull-to-refresh
- [ ] Infinite scroll
- [ ] États vides avec illustrations

##### ÉTAPE 5 : Filtres et Recherche
- [ ] Barre de recherche (debounce 300ms)
- [ ] Bottom sheet filtres :
  - Par statut (En cours, Résolu, En attente)
  - Par catégorie (liste dynamique)
  - Par date (DateRangePicker)
- [ ] Tri (plus récent, alphabétique)
- [ ] Compteur résultats
- [ ] Reset filtres

##### ÉTAPE 6 : Page Détail
- [ ] ⚠️ **VÉRIFIER maquette détail existe**
- [ ] ⚠️ **SI NON : DEMANDER le design**
- [ ] Tests widget détail
- [ ] Affichage complet :
  - Galerie photos swipeable (photo_view)
  - Titre et description
  - Badge statut
  - Catégorie avec icône
  - Carte localisation
  - Date de création
  - Auteur
- [ ] Actions conditionnelles (si auteur) :
  - Bouton éditer
  - Bouton supprimer (avec confirmation)
- [ ] Bouton partager

##### ÉTAPE 7 : Carte Interactive (optionnelle)
- [ ] Vue carte tous signalements
- [ ] Marqueurs colorés par statut
- [ ] Info window au clic
- [ ] Navigation détail depuis carte

##### ÉTAPE 8 : Mes Signalements
- [ ] Onglet dédié "Mes signalements"
- [ ] Liste filtrée par user_id
- [ ] Actions rapides (swipe actions)
- [ ] Statistiques résumées

#### API Endpoints requis (Backend Laravel)
- `GET /api/reports?include=user,images&page=1&per_page=20`
- `GET /api/reports?filter[status]=pending&filter[category_id]=3`
- `GET /api/reports?search=titre`
- `GET /api/reports/{id}?include=user,images,category`
- `GET /api/reports/my` (signalements de l'utilisateur connecté)
- `DELETE /api/reports/{id}` (avec policy authorization)

**Vérifier avec backend** :
- [ ] Pagination Laravel conforme
- [ ] Eager-loading systématique (éviter N+1)
- [ ] Filtres fonctionnels
- [ ] Recherche optimisée (index DB)
- [ ] Policies autorisation DELETE

#### Dépendances à ajouter
```yaml
cached_network_image: ^3.3.0  # Cache images réseau
shimmer: ^3.0.0               # Loading skeleton
photo_view: ^0.14.0           # Galerie photos zoomable
infinite_scroll_pagination: ^4.0.0  # Pagination
```

#### Critères de validation OBLIGATOIRES
- ✅ **TOUS les tests passent (unitaires + widgets + intégration)**
- ✅ Maquettes respectées strictement
- ✅ Liste paginée performante (smooth scroll)
- ✅ Détail complet avec toutes infos
- ✅ Filtres et recherche fonctionnels
- ✅ Cache images actif (pas de rechargement)
- ✅ États loading avec shimmer
- ✅ Gestion erreurs réseau
- ✅ Pull-to-refresh intuitif
- ✅ Performance : temps chargement < 2s
- ✅ `flutter analyze` sans warnings
- ✅ Documentation API utilisée

---

### 👤 Phase 4 : Interface Profil & Système de Commentaires [À FAIRE]
**Status** : ⏳ En attente  
**Estimation** : 3-4 jours  
**Référence** : [Phase 4 des spécifications](#phase-4---système-de-commentaires)

#### Prérequis
- ✅ Phases 2 et 3 validées
- ⚠️ **Vérifier maquettes profil dans `maquettes/`**
- ⚠️ **Si manquantes : DEMANDER le design**
- ✅ Backend endpoints profil et commentaires prêts

#### Objectifs
- Gestion profil utilisateur (affichage, modification, photo)
- Système de commentaires sur signalements
- Statistiques personnelles

#### 🧪 Tests à écrire EN PREMIER

##### ÉTAPE 1 : Tests unitaires (TDD)
- [ ] **Tests UserRepository - Profil**
  - [ ] Test `getProfile()`
  - [ ] Test `updateProfile(data)`
  - [ ] Test `uploadProfilePhoto(image)`
  - [ ] Test `updatePassword(oldPwd, newPwd)`
  - [ ] Test `getStats()`
  
- [ ] **Tests CommentRepository**
  - [ ] Test `getComments(reportId)`
  - [ ] Test `createComment(reportId, text)`
  - [ ] Test `deleteComment(commentId)`
  - [ ] Test validation contenu

- [ ] **Tests Widgets**
  - [ ] Test ProfilePage affichage
  - [ ] Test formulaire édition
  - [ ] Test upload photo
  - [ ] Test changement mot de passe
  - [ ] Test liste commentaires
  - [ ] Test ajout commentaire

##### ÉTAPE 2 : Implémentation Modèles
- [ ] **CommentModel** (Freezed + JSON)
- [ ] **UserStatsModel** (Freezed + JSON)
- [ ] Génération code build_runner

##### ÉTAPE 3 : Implémentation Repositories
- [ ] **UserRepository** - Profil
  - [ ] `getProfile()`
  - [ ] `updateProfile(UserData)`
  - [ ] `uploadProfilePhoto(File)`
  - [ ] `updatePassword(old, new)`
  - [ ] `getStats()`
  
- [ ] **CommentRepository**
  - [ ] `getComments(reportId, {page})`
  - [ ] `createComment(reportId, text)`
  - [ ] `deleteComment(commentId)`

##### ÉTAPE 4 : Providers Riverpod
- [ ] UserNotifier avec états
- [ ] CommentsNotifier avec pagination
- [ ] Gestion cache profil

##### ÉTAPE 5 : Interface Profil
- [ ] ⚠️ **VÉRIFIER maquette profil existe**
- [ ] ⚠️ **SI NON : DEMANDER le design**
- [ ] Page profil affichage
  - Photo de profil (avatar par défaut)
  - Informations (nom, email, téléphone, date inscription)
  - Statistiques (nombre signalements, par statut)
  - Boutons actions
  
- [ ] Page édition profil
  - Formulaire validation
  - Upload/crop photo (image_cropper)
  - Preview avant sauvegarde
  - Feedback succès/erreur

##### ÉTAPE 6 : Changement mot de passe
- [ ] Formulaire dédié
  - Mot de passe actuel (validation serveur)
  - Nouveau mot de passe (>= 8 caractères)
  - Confirmation
- [ ] Validation sécurité forte
- [ ] Feedback succès

##### ÉTAPE 7 : Statistiques personnelles
- [ ] Graphique répartition par statut (fl_chart)
- [ ] Graphique par catégorie
- [ ] Nombre total signalements
- [ ] Badge/niveau utilisateur (optionnel)

##### ÉTAPE 8 : Système Commentaires
- [ ] ⚠️ **VÉRIFIER design commentaires**
- [ ] Liste commentaires sous détail signalement
- [ ] Formulaire ajout commentaire
- [ ] Validation contenu (non vide, < 500 chars)
- [ ] Suppression si auteur
- [ ] Pagination commentaires
- [ ] Temps réel (optionnel - Phase 5)

##### ÉTAPE 9 : Paramètres
- [ ] Page paramètres
- [ ] Toggle notifications (local storage)
- [ ] Thème clair/sombre (optionnel)
- [ ] À propos (version app, liens)
- [ ] Conditions d'utilisation
- [ ] Politique de confidentialité
- [ ] Bouton déconnexion avec confirmation

#### API Endpoints requis (Backend Laravel)
**Profil** :
- `GET /api/user/profile`
- `PUT /api/user/profile`
- `POST /api/user/profile/photo`
- `PUT /api/user/password`
- `GET /api/user/stats`

**Commentaires** :
- `GET /api/reports/{id}/comments?include=user&page=1`
- `POST /api/reports/{id}/comments`
- `DELETE /api/comments/{id}` (avec policy authorization)

**Vérifier avec backend** :
- [ ] Endpoints disponibles
- [ ] Validation côté serveur (photo max 2MB, password policy)
- [ ] Relations eager-loadées (comments avec user)
- [ ] Policies DELETE comment

#### Dépendances à ajouter
```yaml
image_cropper: ^5.0.0      # Crop photo profil
fl_chart: ^0.65.0          # Graphiques statistiques
timeago: ^3.6.0            # Format dates ("il y a 2h")
```

#### Critères de validation OBLIGATOIRES
- ✅ **TOUS les tests passent**
- ✅ Maquettes respectées
- ✅ Profil s'affiche avec photo
- ✅ Modification profil fonctionne
- ✅ Upload photo avec crop réussit
- ✅ Changement mot de passe sécurisé
- ✅ Statistiques précises et graphiques
- ✅ Commentaires créés/affichés correctement
- ✅ Pagination commentaires fluide
- ✅ Suppression commentaire avec confirmation
- ✅ Gestion erreurs complète
- ✅ `flutter analyze` sans warnings
- ✅ Performance optimale

---

## 🎯 Phases futures (optionnelles)

### Phase 5 : Notifications & Broadcasting
**Référence** : [Phase 5 des spécifications](#phase-5---notifications--broadcasting)
- Configuration Firebase (Android/iOS uniquement)
- Notifications push signalements
- Notifications commentaires
- Notifications changement statut
- Broadcasting temps réel (Pusher/Laravel Echo)

### Phase 6 : Cache & Performance
**Référence** : [Phase 6 des spécifications](#phase-6---cache--performance)
- Cache local SQLite/Hive
- Stratégie cache (Redis côté backend)
- Synchronisation automatique
- Upload en arrière-plan
- Optimisation requêtes (eager-loading)

### Phase 7 : Jobs Asynchrones
**Référence** : [Phase 7 des spécifications](#phase-7---jobs-asynchrones)
- Jobs backend : ProcessReportImages, NotifyUserJob
- Queue Laravel supervisée
- Retry automatique
- Feedback progression côté mobile

### Phase 8 : Statistiques & Analytics
**Référence** : [Phase 8 des spécifications](#phase-8---statistiques--analytics)
- Dashboard admin
- Analytics utilisateur
- Métriques performance
- Crash reporting (Sentry)
- A/B testing

---

## 📊 Métriques de succès

### Par phase
- ✅ Tous les tests passent
- ✅ Code review validé
- ✅ Documentation à jour
- ✅ Pas de régression
- ✅ Performance acceptable

### Global
- Couverture de tests > 80%
- Temps de chargement < 2s
- Taille APK < 50MB
- Note stores > 4.5/5

---

## 🔄 Processus de validation (TDD STRICT)

### Pour chaque phase :

#### 1. **Préparation** ⚠️
   - ✅ Vérifier backend API endpoints prêts
   - ⚠️ **VÉRIFIER maquettes disponibles dans `maquettes/`**
   - ⚠️ **SI MAQUETTES MANQUANTES : ARRÊTER et DEMANDER le design**
   - ✅ Lister dépendances nécessaires
   - ✅ Lire spécifications correspondantes
   - ✅ Créer branche Git dédiée

#### 2. **Tests EN PREMIER (TDD)** 🧪
   - ✅ Écrire TOUS les tests unitaires repository
   - ✅ Écrire TOUS les tests modèles
   - ✅ Écrire TOUS les tests providers
   - ✅ Écrire TOUS les tests widgets
   - ⚠️ **Les tests DOIVENT échouer (pas d'implémentation)**
   - ✅ Valider que les tests sont exécutables
   - ✅ Commit : "tests: add tests for Phase X"

#### 3. **Implémentation minimale**
   - ✅ Implémenter pour faire passer les tests
   - ✅ Vérifier que TOUS les tests passent
   - ✅ Refactoriser si nécessaire
   - ✅ `flutter analyze` sans warnings
   - ✅ Commit : "feat: implement Phase X"

#### 4. **Interface utilisateur**
   - ⚠️ **Respecter strictement les maquettes**
   - ✅ Utiliser palette de couleurs définie
   - ✅ Implémenter gestion erreurs
   - ✅ Ajouter feedback utilisateur
   - ✅ Vérifier responsive
   - ✅ Commit : "ui: add Phase X screens"

#### 5. **Tests manuels**
   - ✅ Test sur émulateur/device
   - ✅ Test cas nominaux
   - ✅ Test cas erreurs (réseau, validation, etc.)
   - ✅ Test performance (pas de lag)
   - ✅ Vérifier aucune régression phases précédentes

#### 6. **Review & Optimisation**
   - ✅ Code review auto (lisibilité, DRY)
   - ✅ Vérification spécifications respectées
   - ✅ Optimisation si besoin
   - ✅ Documentation code (commentaires)
   - ✅ `flutter format .`

#### 7. **Validation développeur** 👤
   - ✅ Démonstration fonctionnalités
   - ✅ Tous critères validation cochés
   - ✅ Tests tous verts (`flutter test`)
   - ✅ Documentation complète
   - ✅ **APPROBATION DÉVELOPPEUR PRINCIPALE**
   - ✅ Merge branche → main

#### 8. **Documentation**
   - ✅ Mise à jour README.md
   - ✅ Mise à jour IMPLEMENTATION.md
   - ✅ Mise à jour CHANGELOG.md
   - ✅ Mise à jour ROADMAP.md (cocher ✅)
   - ✅ Commit : "docs: update documentation for Phase X"

---

## 📝 Notes importantes

### ⚠️ AVANT de commencer chaque phase (CRITIQUE)
1. ✅ Vérifier backend API endpoints disponibles et testés
2. ⚠️ **VÉRIFIER les maquettes dans `maquettes/`**
   - **Si maquettes disponibles** : Suivre strictement
   - **Si maquettes MANQUANTES** : **ARRÊTER et DEMANDER le design**
   - **NE JAMAIS créer de design arbitraire**
3. ✅ Lister toutes les dépendances nécessaires
4. ✅ Lire la phase correspondante dans `spec.instructions.md`
5. ✅ Estimer le temps de développement (réaliste)
6. ✅ Créer branche Git : `feature/phase-X-nom`

### 🧪 Pendant le développement (TDD STRICT)
- ⚠️ **TOUJOURS écrire les tests AVANT le code**
- ✅ Ordre obligatoire : Tests → Implémentation → Refactoring
- ✅ Commits fréquents et clairs (conventional commits)
  - `test: add tests for ...`
  - `feat: implement ...`
  - `fix: correct ...`
  - `refactor: improve ...`
  - `docs: update ...`
- ✅ Documentation au fur et à mesure (commentaires code)
- ✅ Vérifier `flutter analyze` régulièrement
- ⚠️ Communiquer immédiatement si blocage

### ✅ Avant validation (Checklist)
- ✅ **TOUS les tests passent** (`flutter test`)
- ✅ **Aucun warning** (`flutter analyze`)
- ✅ Code formaté (`dart format .`)
- ✅ Maquettes respectées strictement
- ✅ Palette de couleurs respectée
- ✅ Gestion erreurs complète
- ✅ Documentation code complète
- ✅ README/IMPLEMENTATION/CHANGELOG à jour
- ✅ Démonstration fonctionnelle prête
- ✅ Aucune régression phases précédentes

---

## 🎨 Conventions de code & Design

### Code Dart/Flutter
- ✅ Suivre les conventions Dart officielles
- ✅ Utiliser `dart format .` avant chaque commit
- ✅ Commenter TOUTES les fonctions publiques
- ✅ Nommer clairement variables et fonctions (camelCase, PascalCase)
- ✅ Architecture cohérente avec Phase 1 (Repository + Riverpod)
- ✅ Utiliser Freezed pour les modèles immutables
- ✅ Utiliser Dio pour toutes les requêtes API (comme spécifié)

### Design UI/UX
- ⚠️ **Respecter STRICTEMENT les maquettes dans `maquettes/`**
- ⚠️ **Si maquette manquante : DEMANDER, ne PAS improviser**
- ✅ Palette de couleurs obligatoire :
  - Primaire : `#FFA000` (texte noir)
  - Secondaire : `#007A3F` (texte blanc)
  - Danger : `#EA0707` (texte blanc)
  - Fond : `#FFFFFF`
  - États signalements :
    - En cours : `#0023D142`
    - Résolu : `#34C75936`
    - En attente : `#FFA00070`
- ✅ Material Design 3
- ✅ Responsive (mobile uniquement)
- ✅ Accessibilité (semantics, contrast)

### Tests (TDD)
- ⚠️ **Tests AVANT code (obligatoire)**
- ✅ Nomenclature : `nom_test.dart`
- ✅ Coverage > 80%
- ✅ Mocks avec Mockito
- ✅ Tests unitaires + widgets + intégration

---

## 📞 Contact & Support

Pour toute question ou blocage :
1. Vérifier la documentation existante
2. Consulter les issues GitHub
3. Contacter le lead développeur

---

**Dernière mise à jour** : 21 novembre 2025  
**Version actuelle** : 1.0.0 (Phase 1 complétée)  
**Prochaine phase** : Phase 2 - Créer un signalement
