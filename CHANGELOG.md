# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

## [1.1.0] - 2025-01-XX - 🤖 Analyse IA Automatique

### 🤖 Nouvelles fonctionnalités majeures

#### Analyse IA des photos de signalements
- **Auto-analyse intelligente** : Après ajout de la première photo, l'IA analyse automatiquement l'image
- **Pré-remplissage automatique** : Génère titre, description et catégorie automatiquement
- **Bouton réanalyse** : Permet de relancer l'analyse si résultat insatisfaisant
- **Feedback temps réel** : Indicateur visuel "🤖 Analyse IA en cours..."
- **Gestion d'erreurs robuste** : Fallback manuel si l'analyse échoue

#### Interface utilisateur améliorée
- Indicateur d'analyse avec spinner orange (#FFA000)
- SnackBars de feedback : succès (vert), erreur (orange)
- Bouton "Réanalyser avec IA" avec icône ✨
- Auto-remplissage des champs après analyse réussie

### 🔧 Modifications techniques

#### Nouveaux fichiers
- `lib/core/services/ai_analysis_service.dart` - Service Dio pour analyse IA
- `AI_BACKEND_IMPLEMENTATION.md` - Guide implémentation Laravel + Gemini
- `AI_FEATURE_GUIDE.md` - Documentation complète fonctionnalité IA
- `CONFIGURATION.md` - Guide configuration environnement

#### Fichiers modifiés
- `report_state.dart` : Ajout champs `isAnalyzing`, `aiAnalysisResult`, `aiAnalysisError`
- `report_notifier.dart` : Méthodes `analyzeImageWithAI()` et `clearAIAnalysis()`
- `create_report_page.dart` : UI analyse IA + listener pré-remplissage
- `map_page.dart` : Correction build_runner

### ✅ Validation améliorée

**Changements majeurs :**
- Photo : **Obligatoire** (minimum 1) - Avant : facultative
- Description : **Facultative** - Avant : obligatoire

Justification : L'IA génère la description automatiquement.

### 🐛 Corrections de bugs
- Profile page : Boutons navigation maintenant fonctionnels
- Map page : Correction caractères invisibles
- Validation : Photo obligatoire avant soumission

### 📚 Documentation
- 3 nouveaux guides Markdown (~1200 lignes)
- Guide obtention clé API Gemini gratuite
- Configuration .env backend complète
- Checklist configuration + debugging

### 🚀 Backend requis

**Endpoint Laravel à implémenter :**
```
POST /api/ai/analyze-image
Content-Type: multipart/form-data
Auth: Bearer token
```

Voir `AI_BACKEND_IMPLEMENTATION.md` pour code complet.

**Configuration .env :**
```env
GEMINI_API_KEY=AIzaSy...
```

### 📊 Workflow utilisateur simplifié
```
Prendre photo → ⏳ Analyse IA → ✨ Pré-remplissage → Vérifier → Soumettre
```

## [1.0.0] - 2025-11-21

### ✨ Ajouté

#### Phase 1 : Authentification complète

- **Pages UI**
  - Page de connexion avec validation
  - Page d'inscription complète
  - Page d'accueil post-authentification

- **Navigation**
  - Navigation fluide entre login et register
  - Navigation automatique après authentification
  - Déconnexion avec retour au login

- **Architecture**
  - Repository Pattern pour l'accès aux données
  - State Management avec Riverpod + code generation
  - Service Dio avec interceptors (logs, auth)
  - Stockage sécurisé des tokens (flutter_secure_storage)
  - Modèles Freezed pour immutabilité

- **Validations**
  - Validation locale des formulaires
  - Gestion des erreurs API
  - Feedback utilisateur (SnackBar, loading states)

- **Tests**
  - Tests unitaires pour DioService
  - Tests unitaires pour AuthRepository avec mocks
  - Tests d'intégration pour RegisterPage
  - ✅ 10/10 tests passent

- **Documentation**
  - README.md complet
  - IMPLEMENTATION.md détaillé
  - GUIDE_DEV.md avec toutes les commandes
  - Spécifications dans .github/instructions/

### 🎨 Design

- Palette de couleurs selon spécifications SamaCité
- Material Design 3
- Interfaces responsive
- Animations et transitions fluides

### 🔐 Sécurité

- Stockage sécurisé des tokens
- Validation côté client
- Headers Authorization automatiques
- Nettoyage complet à la déconnexion

### 📦 Dépendances

- dio ^5.4.0
- flutter_riverpod ^2.4.9
- riverpod_annotation ^2.3.3
- flutter_secure_storage ^9.0.0
- freezed ^2.4.6
- json_serializable ^6.7.1
- logger ^2.0.2+1
- mockito ^5.4.4

---

## [0.0.1] - 2025-11-21

### Initialisation

- Création du projet Flutter
- Configuration de la structure de base
- Setup des outils de développement
