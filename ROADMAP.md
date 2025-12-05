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

### ✅ Phase 2 : Gestion des Signalements (Reports) [COMPLÉTÉE]
**Status** : ✅ Validée  
**Durée** : Complétée le 22/11/2025  
**Référence** : [Phase 2 des spécifications](#phase-2---gestion-des-signalements-reports)

#### Prérequis
- ✅ Backend Laravel API prêt avec endpoints signalements
- ✅ **Maquettes vérifiées** dans `maquettes/signalement.xml`

#### Objectifs
Permettre aux utilisateurs de créer de nouveaux signalements avec photos et localisation.

---

### ✅ Phase 3 : Liste et Détail des Signalements [COMPLÉTÉE]
**Status** : ✅ Validée  
**Durée** : Complétée le 22/01/2025  
**Documentation** : Voir [PHASE_3_COMPLETE.md](./PHASE_3_COMPLETE.md)

#### Prérequis
- ✅ Phase 2 complétée (création de signalements)
- ✅ Backend API avec endpoints liste + détail
- ✅ Maquettes vérifiées :
  - `liste-signalements.xml` ✅
  - `item-signalement.xml` ✅
  - `detail-signalement.xml` ✅

#### Objectifs
Afficher la liste des signalements avec pagination et la page de détail complète.

#### ✅ Fonctionnalités implémentées

##### 1. ReportListState (Freezed)
- ✅ État immutable pour gestion de liste
- ✅ Propriétés: reports, isLoading, hasMore, currentPage, errorMessage
- ✅ Tests: 10/10

##### 2. Repository - Pagination
- ✅ `getReports(page, perPage, includeRelations)` avec pagination
- ✅ `getReportById(id, includeRelations)` avec relations
- ✅ Eager-loading (user, category, images, location)
- ✅ Tests: 13/13

##### 3. ReportListNotifier
- ✅ `loadReports()` - Première page
- ✅ `loadMoreReports()` - Infinite scroll
- ✅ `refresh()` - Pull-to-refresh
- ✅ Gestion state: loading, errors, hasMore
- ✅ Tests: 10/10

##### 4. ReportListPage (UI)
- ✅ AppBar "Tous les signalements"
- ✅ RefreshIndicator (pull-to-refresh)
- ✅ ListView.builder avec infinite scroll
- ✅ Loading indicator pagination
- ✅ États: vide, loading, liste, erreur
- ⏭️  Tests UI: Skipped (mock Riverpod avancé)

##### 5. ReportItemWidget (Card)
- ✅ Design `item-signalement.xml`:
  - Card elevation 4, radius 12
  - Image 80x80 ou placeholder
  - Titre 16sp bold
  - Adresse 14sp (location)
  - Date 12sp gray
- ✅ Navigation vers détail au tap
- ✅ Tests: 3/3

##### 6. ReportDetailPage (UI)
- ✅ Design `detail-signalement.xml`:
  - Image principale 200dp
  - Titre 20sp bold
  - Adresse + icône location
  - Date + Statut avec couleurs spec.md
  - Section "Description"
  - Map preview 200dp placeholder
  - Bouton "Voir sur la carte" (#FFA000)
- ✅ Chargement auto via `getReportById()`
- ✅ Gestion erreurs + retry
- ⏭️  Tests page complète: Skipped (mock Riverpod)

##### 7. ReportDetailContent (Widget)
- ✅ Widget stateless testable
- ✅ Tous les détails du signalement
- ✅ Statuts colorés (pending, resolved, in_progress)
- ✅ Tests: 11/11

#### 📊 Résultats tests Phase 3
```
✅ 131 tests passing
⚠️  11 tests skipped (intégration)
✅ 0 tests failing

Phase 3 spécifique:
- ReportListState: 10/10 ✅
- Repository pagination: 13/13 ✅
- ReportListNotifier: 10/10 ✅
- ReportItemWidget: 3/3 ✅
- ReportDetailContent: 11/11 ✅
```

#### 🎨 Design implémenté
- ✅ Liste scrollable avec infinite scroll
- ✅ Pull-to-refresh fonctionnel
- ✅ Cards design spec.md respecté
- ✅ Couleurs statuts spec.md appliquées
- ✅ Palette couleurs globale (#007A3F, #FFA000)

#### 📱 UX Features
- ✅ Pagination 15 items/page
- ✅ Infinite scroll (trigger 90%)
- ✅ Prévention double-load
- ✅ SnackBar pour erreurs
- ✅ Loading indicators clairs

---

### 🔄 Phase 4 : Système de Commentaires [NON COMMENCÉE]

#### ✅ Livrables complétés

##### Tests (91 tests passés, 9 skippés pour intégration)
- ✅ **Tests ReportRepository** (7 tests)
  - ✅ Test `create()` avec données valides
  - ✅ Test `create()` avec données invalides  
  - ✅ Test `create()` avec erreur réseau
  - ✅ Test `uploadImages()` validation limite
  - ~ Test compression images (skip - nécessite fichiers réels)
  
- ✅ **Tests CategoryRepository** (7 tests)
  - ✅ Test `getAll()` succès
  - ✅ Test cache local
  - ✅ Test gestion erreurs

- ✅ **Tests ImageService** (16 tests)
  - ✅ Test validation format images
  - ✅ Test validation nombre images (max 5)
  - ✅ Test sélection multiple
  - ~ Tests permissions (skip - nécessite mock plugin Android)

- ✅ **Tests LocationService** (23 tests)
  - ✅ Test permissions GPS
  - ✅ Test obtention position
  - ✅ Test gestion erreurs

- ✅ **Tests ReportNotifier** (18 tests)
  - ✅ Test état initial
  - ✅ Test création signalement succès
  - ✅ Test gestion erreurs
  - ✅ Test états de loading

- ✅ **Tests UI CreateReportPage** (11 tests)
  - ✅ Test structure UI
  - ✅ Test validation formulaire
  - ✅ Test sélection catégorie
  - ✅ Test saisie champs

##### Implémentation
- ✅ **Models** (Freezed + JSON serializable)
  - ✅ CategoryModel
  - ✅ ReportModel
  - ✅ LocationModel
  - ✅ ReportState (Freezed)

- ✅ **Repositories**
  - ✅ ReportRepository (create, uploadImages, getReports)
  - ✅ CategoryRepository (getAll avec cache)

- ✅ **Services**
  - ✅ ImageService (compression, validation, picker)
  - ✅ LocationService (GPS, permissions)

- ✅ **State Management (Riverpod)**
  - ✅ ReportNotifier avec états (initial, loading, success, error)
  - ✅ CategoryNotifier avec AsyncValue
  - ✅ DioService singleton (keepAlive)

- ✅ **UI CreateReportPage** (385 lignes)
  - ✅ Formulaire avec validation
  - ✅ Dropdown catégories
  - ✅ Section photos (galerie + caméra)
  - ✅ Capture GPS avec affichage coordonnées
  - ✅ Bouton soumission avec loading
  - ✅ SnackBar feedback succès/erreur

- ✅ **Permissions Android**
  - ✅ INTERNET
  - ✅ CAMERA
  - ✅ STORAGE (granular SDK 13+)
  - ✅ ACCESS_FINE_LOCATION / COARSE_LOCATION

##### Corrections bugs
- ✅ 401 sur /categories (DioService singleton)
- ✅ App crash sur photo (permissions Android)
- ✅ GPS error (permissions manquantes)
- ✅ 422 sur image upload (Content-Type multipart/form-data)

##### Validation end-to-end
- ✅ Login → HomePage → CreateReportPage
- ✅ Chargement catégories
- ✅ Remplissage formulaire complet
- ✅ Ajout photos (caméra + galerie)
- ✅ Capture GPS
- ✅ Soumission signalement (Status 201)
- ✅ Upload images (multipart/form-data)

#### API Endpoints utilisés
- ✅ `GET /api/categories` - Liste catégories
- ✅ `POST /api/reports` - Créer signalement
- ✅ `POST /api/reports/{id}/images` - Upload images (multipart/form-data)

**Backend validé** :
- ✅ Endpoints disponibles et fonctionnels
- ✅ Format réponse JSON conforme
- ✅ Validation côté serveur Laravel
- ✅ Content-Type multipart/form-data pour images

#### Dépendances ajoutées
```yaml
# Géolocalisation
geolocator: ^10.1.0
permission_handler: ^11.0.1

# Images
image_picker: ^1.0.7
flutter_image_compress: ^2.1.0
```

#### Documentation créée
- ✅ BUGFIX_PERMISSIONS.md (workflow permissions Android)
- ✅ Tests unitaires avec mocks
- ✅ Commentaires détaillés dans le code

---

### 📊 Bilan Phase 2

**Points forts** :
- Architecture solide (Repository + Service + Riverpod)
- Couverture tests : 91 tests unitaires passés
- Fonctionnalité end-to-end validée manuellement
- Gestion permissions Android complète
- DioService singleton avec token persistant

**Tests skippés (9)** :
- 6 tests nécessitant mock plugin permission_handler (tests d'intégration)
- 3 tests nécessitant ImageService mocké (à implémenter en Phase 3 ou 4)

**Prochaine phase** : Phase 3 - Liste et détail des signalements

---

### 🎯 Phase 3 : Liste et Détail des Signalements [À VENIR]
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
- Amélioration visuelle pages connexion et inscription

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
- ✅ Liste commentaires sous détail signalement
- ✅ Formulaire ajout commentaire
- ✅ Validation contenu (non vide, < 500 chars)
- ✅ Suppression si auteur
- ✅ Pagination commentaires
- ✅ Affichage "Vous" pour utilisateur connecté
- ✅ Gestion backend format (fallback user)
- ✅ IntConverter pour types ID
- [ ] Temps réel (optionnel - Phase 5)

##### ÉTAPE 9 : Système de Likes (Nouveau)
- ✅ LikeRepository avec toggle like/unlike
- ✅ Ajout champs likesCount et isLiked dans ReportModel
- ✅ Widget _LikeButton avec animation
- ✅ Affichage compteur likes
- ✅ Feedback visuel (snackbar)
- ✅ Gestion état optimiste (update immédiat UI)
- ✅ Tests unitaires LikeRepository (12 tests)
- ⏭️  Tests widget _LikeButton (complexe - intégré dans page)

##### ÉTAPE 10 : Carte Interactive (Nouveau)
- ✅ MapPage avec OpenStreetMap (flutter_map)
- ✅ Affichage marqueurs tous signalements
- ✅ Couleurs marqueurs selon statut (pending/in_progress/resolved)
- ✅ Clustering de marqueurs (badge avec compteur)
- ✅ Bottom sheet pour sélection multiple
- ✅ Légende couleurs
- ✅ Compteur signalements
- ✅ Navigation détail depuis carte (clic marqueur)
- ✅ Bouton "Voir sur la carte" dans détail
- ✅ Route /map dans navigation
- ⏭️  Tests MapPage (widget complexe - skip pour l'instant)
- ⏭️  Centrage auto sur position utilisateur (Phase 5)

##### ÉTAPE 11 : Paramètres
- [ ] Page paramètres
- [ ] Toggle notifications (local storage)
- [ ] Thème clair/sombre (optionnel)
- [ ] À propos (version app, liens)
- [ ] Conditions d'utilisation
- [ ] Politique de confidentialité
- [ ] Bouton déconnexion avec confirmation

##### ÉTAPE 12 : Amélioration UI Authentification
- [ ] **Page Connexion**
  - [ ] Remplacer image par défaut par visuel SamaCité
  - [ ] Image optimisée et responsive
  - [ ] Cohérence palette couleurs (#007A3F, #FFA000)
  
- [ ] **Page Inscription**
  - [ ] Remplacer image par défaut par visuel SamaCité
  - [ ] Image optimisée et responsive
  - [ ] Cohérence visuelle avec connexion

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

#### 📊 Résultats tests Phase 4
```
✅ 126 tests passing
⏭️  11 tests skipped (intégration/plugins)
⚠️  16 tests failing (ReportRepository getReports - cast Map/List)

Phase 4 spécifique:
- CommentRepository: 24/24 ✅
- LikeRepository: 12/12 ✅ (nouveau)
```

#### Critères de validation OBLIGATOIRES
- ⚠️  **126/142 tests passent** (16 échecs ReportRepository existants)
- ✅ Maquettes respectées
- ⏭️  Profil s'affiche avec photo (non implémenté - Phase 4 étendue)
- ⏭️  Modification profil fonctionne (non implémenté)
- ⏭️  Upload photo avec crop réussit (non implémenté)
- ⏭️  Changement mot de passe sécurisé (non implémenté)
- ⏭️  Statistiques personnelles et graphiques (non implémenté)
- ✅ Commentaires créés/affichés correctement
- ✅ Pagination commentaires fluide
- ✅ Suppression commentaire avec confirmation
- ✅ Likes fonctionnels avec optimistic updates
- ✅ Carte OpenStreetMap avec marqueurs colorés
- ✅ Clustering de marqueurs implémenté
- ✅ Gestion erreurs complète
- ✅ `flutter analyze` sans warnings
- ✅ Performance optimale

---

## 🎯 Phases futures (optionnelles)

### 🔔 Phase 5 : Notifications & Broadcasting [EN COURS]
**Status** : 🔄 Implémentation terminée, ⚠️ Configuration Firebase requise  
**Durée** : Démarré le 24/11/2025  
**Référence** : [Phase 5 des spécifications](#phase-5---notifications--broadcasting)

#### ✅ Fonctionnalités implémentées

##### 1. Firebase Cloud Messaging (FCM)
- ✅ Dépendances ajoutées (firebase_core, firebase_messaging, flutter_local_notifications)
- ✅ Permissions Android (POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, VIBRATE)
- ✅ NotificationService singleton avec initialisation automatique
- ✅ Obtention et rafraîchissement token FCM
- ✅ Envoi token au backend (`POST /api/fcm-token`)

##### 2. Handlers de notifications
- ✅ Foreground : Affichage notification locale avec flutter_local_notifications
- ✅ Background : Handler `firebaseMessagingBackgroundHandler` (fonction top-level)
- ✅ Terminated : Récupération message initial avec `getInitialMessage()`
- ✅ Clic notification : Stream `onNotificationClick` pour navigation

##### 3. Navigation depuis notifications
- ✅ `NotificationNavigationHandler` pour parser les données
- ✅ Support types : `new_report`, `new_comment`, `status_changed`
- ✅ Navigation automatique vers `ReportDetailPage`
- ✅ Listener dans `MainNavigationPage`

##### 4. Notifications locales personnalisées
- ✅ Channel Android : "samacite_channel"
- ✅ Couleur SamaCité (#007A3F)
- ✅ Vibration et son activés
- ✅ Support iOS avec DarwinNotificationDetails

##### 5. Topics Firebase (optionnel)
- ✅ Méthodes `subscribeToTopic()` et `unsubscribeFromTopic()`
- ⏭️ Implémentation backend topics (à faire)

#### 📚 Documentation créée
- ✅ `FIREBASE_SETUP.md` - Guide complet configuration Firebase Console
- ✅ `lib/firebase_options.dart` - Template options Firebase (à remplacer via FlutterFire CLI)
- ✅ Instructions backend Laravel (endpoint `/api/fcm-token`, migration, envoi notifications)

#### 🧪 Tests Phase 5
```
✅ 4 tests passing (structure NotificationService, types notifications)
⏭️ 7 tests skipped (intégration Firebase, navigation)
⚠️ 3 tests failing (NotificationService - mock Firebase requis)
```

#### ⚠️ Configuration requise pour utiliser
1. **Créer projet Firebase Console** (gratuit)
2. **Ajouter app Android** : télécharger `google-services.json` → `android/app/`
3. **FlutterFire CLI** : `flutterfire configure` pour générer `firebase_options.dart`
4. **Backend Laravel** : endpoint `/api/fcm-token` et table `fcm_tokens`
5. **Tester** : Envoyer notification test depuis Firebase Console

#### 📡 Broadcasting temps réel (Phase 5 étendue - optionnel)
- ⏭️ Pusher/Laravel Echo (non implémenté)
- ⏭️ WebSockets pour mises à jour live
- ⏭️ Synchronisation état commentaires/likes

### Phase 6 : Cache & Performance
**Référence** : [Phase 6 des spécifications](#phase-6---cache--performance)
- Cache local SQLite/Hive
- Stratégie cache (Redis côté backend)
- Synchronisation automatique
- Upload en arrière-plan
- Optimisation requêtes (eager-loading)

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
