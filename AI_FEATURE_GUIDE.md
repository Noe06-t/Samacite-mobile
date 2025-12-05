# 🤖 Guide Fonctionnalité IA - SamaCité

## 📋 Vue d'ensemble

La fonctionnalité d'analyse IA permet aux utilisateurs de créer des signalements plus rapidement en prenant simplement une photo. L'IA analyse automatiquement l'image et pré-remplit :
- ✅ Le titre du signalement
- ✅ La description détaillée
- ✅ La catégorie appropriée

## 🎯 Workflow Utilisateur

### 1. Création de signalement simplifiée

```
Utilisateur ouvre CreateReportPage
    ↓
Prend photo (caméra) ou sélectionne depuis galerie
    ↓
⏳ Analyse IA automatique (30s max)
    ↓
✨ Champs pré-remplis automatiquement
    ↓
👤 Utilisateur vérifie/édite si nécessaire
    ↓
📤 Soumet le signalement
```

### 2. États de l'analyse

| État | Description | UI |
|------|-------------|-----|
| **Aucune photo** | Aucune analyse possible | Boutons Galerie/Caméra |
| **Analyse en cours** | IA traite l'image | Spinner + "🤖 Analyse IA en cours..." |
| **Analyse terminée** | Champs pré-remplis | ✅ Bouton "Réanalyser avec IA" |
| **Erreur analyse** | Fallback manuel | ⚠️ SnackBar d'avertissement |

## 🔧 Implémentation Flutter

### Fichiers modifiés

#### 1. **lib/features/reports/providers/report_state.dart**
```dart
@freezed
class ReportState with _$ReportState {
  const factory ReportState({
    // ... champs existants
    @Default(false) bool isAnalyzing,
    AIAnalysisResult? aiAnalysisResult,
    String? aiAnalysisError,
  }) = _ReportState;
}
```

#### 2. **lib/features/reports/providers/report_notifier.dart**

**Nouvelles méthodes :**
- `analyzeImageWithAI()` : Lance l'analyse IA
- `clearAIAnalysis()` : Réinitialise pour réanalyser

**Auto-déclenchement :**
- Après `selectImages()` si 1ère photo
- Après `takePicture()` si 1ère photo

#### 3. **lib/core/services/ai_analysis_service.dart** (NOUVEAU)

Service Dio pour appeler l'endpoint backend :
```dart
class AIAnalysisService {
  Future<AIAnalysisResult> analyzeImage(String imagePath) async {
    // Upload multipart/form-data vers /api/ai/analyze-image
    // Timeout: 30 secondes
    // Retourne: {title, description, category, confidence}
  }
}
```

#### 4. **lib/features/reports/pages/create_report_page.dart**

**Ajouts UI :**
- Indicateur d'analyse en cours (CircularProgressIndicator)
- Bouton "Réanalyser avec IA"
- SnackBars pour feedback utilisateur
- Auto-remplissage des champs après analyse

**Listener :**
```dart
ref.listenManual(reportNotifierProvider, (previous, next) {
  if (previous?.isAnalyzing == true && next.aiAnalysisResult != null) {
    _handleAIAnalysisSuccess(next.aiAnalysisResult!);
  }
});
```

## 🌐 Backend Laravel (À implémenter)

### Endpoint requis

**Route :** `POST /api/ai/analyze-image`

**Middleware :** `auth:api`

**Request :**
```
Content-Type: multipart/form-data

image: [fichier jpg/png, max 5MB]
```

**Response (succès) :**
```json
{
  "success": true,
  "data": {
    "title": "Nid de poule sur Avenue Bourguiba",
    "description": "Un large nid de poule d'environ 50cm de diamètre...",
    "category": "nid_de_poule",
    "confidence": 0.85
  },
  "message": "Analyse terminée avec succès"
}
```

**Response (erreur) :**
```json
{
  "success": false,
  "message": "Image non valide ou trop volumineuse"
}
```

### Intégration Google Gemini Pro Vision

Voir fichier : **AI_BACKEND_IMPLEMENTATION.md**

#### Installation
```bash
composer require google/generative-ai-php
```

#### Configuration .env
```env
GEMINI_API_KEY=votre_clé_api_ici
```

#### Obtenir une clé API (gratuite)
1. Aller sur https://makersuite.google.com/app/apikey
2. Créer un projet Google Cloud
3. Copier la clé API
4. Ajouter dans `.env`

#### Limites gratuites
- 60 requêtes/minute
- 1 500 requêtes/jour
- Suffisant pour MVP/tests

## ✅ Tests utilisateur

### Scénarios de test

#### ✅ Test 1 : Analyse réussie
1. Ouvrir CreateReportPage
2. Prendre photo d'un nid de poule
3. **Attendre** indicateur "🤖 Analyse IA en cours..."
4. **Vérifier** champs pré-remplis automatiquement
5. **Optionnel** : Éditer titre/description
6. Soumettre → Succès

#### ✅ Test 2 : Réanalyse
1. Photo déjà analysée
2. Cliquer "Réanalyser avec IA"
3. **Vérifier** nouveaux résultats
4. Soumettre

#### ⚠️ Test 3 : Erreur réseau (backend non implémenté)
1. Prendre photo
2. **Vérifier** SnackBar d'erreur : "⚠️ Analyse IA échouée: ..."
3. **Vérifier** possibilité de saisir manuellement
4. Soumettre manuellement

#### ✅ Test 4 : Photo obligatoire
1. Ne pas ajouter de photo
2. Cliquer "Créer le signalement"
3. **Vérifier** erreur : "📸 Veuillez ajouter au moins une photo"

#### ✅ Test 5 : Description optionnelle
1. Ajouter photo
2. Ne rien écrire dans "Description"
3. **Vérifier** possibilité de soumettre sans description

## 🔥 Points d'attention

### ⚠️ Backend non implémenté
**État actuel :** L'endpoint Laravel n'existe pas encore.

**Comportement :** L'analyse échouera avec une erreur 404.

**Workaround :** L'utilisateur peut toujours créer le signalement manuellement.

### 🎨 UI/UX

**Indicateur d'analyse :**
- Spinner circulaire orange (#FFA000)
- Texte "🤖 Analyse IA en cours..."
- Désactive boutons galerie/caméra pendant analyse

**Feedback utilisateur :**
- ✅ Succès : "✨ Analyse IA terminée !" (vert)
- ⚠️ Erreur : "⚠️ Analyse IA échouée: ..." (orange)
- 📸 Photo obligatoire : "📸 Veuillez ajouter au moins une photo" (rouge)

### 📱 Performance

**Timeout :**
- Send: 30s
- Receive: 30s

**Taille max image :**
- Backend: 5MB
- Flutter: Compression automatique via ImageService

**Cache :**
- Résultat analysé conservé dans ReportState
- Réanalyse possible avec bouton dédié

## 📚 Documentation complète

- **Backend Laravel** : `AI_BACKEND_IMPLEMENTATION.md`
- **Spécifications** : `.github/instructions/spec.instructions.md`
- **Architecture** : Repository Pattern + Service Layer + Riverpod

## 🚀 Prochaines étapes

### Priorité HAUTE
1. ✅ **Implémentation backend Laravel** (voir AI_BACKEND_IMPLEMENTATION.md)
2. ✅ **Configuration GEMINI_API_KEY** dans .env
3. ✅ **Tests end-to-end** avec vraies photos

### Priorité MOYENNE
4. ⏳ Améliorer prompt IA pour meilleure précision
5. ⏳ Gérer cas particuliers (photos floues, hors contexte)
6. ⏳ Analytics: tracker taux succès analyse IA

### Priorité BASSE
7. ⏳ Feedback confiance IA (afficher score confidence)
8. ⏳ Historique analyses pour debugging
9. ⏳ Support multi-langues (FR/EN)

## 🎉 Résumé

✅ **Flutter mobile** : Complet et fonctionnel
✅ **UI/UX** : Indicateurs, feedback, auto-remplissage
✅ **Validation** : Photo obligatoire, description optionnelle
✅ **Documentation backend** : Guide complet fourni

❌ **Backend Laravel** : À implémenter par développeur backend
❌ **Tests E2E** : Attendent backend fonctionnel

---

**Auteur** : GitHub Copilot (Claude Sonnet 4.5)
**Date** : Janvier 2025
**Version** : 1.0.0
