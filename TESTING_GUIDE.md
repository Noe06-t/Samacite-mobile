# 🧪 Guide de Test - Analyse IA SamaCité

## ✅ État de l'implémentation

### Flutter Mobile : 100% ✅
- Service IA : `ai_analysis_service.dart` ✅
- État global : `report_state.dart` avec champs IA ✅
- Logique métier : `report_notifier.dart` avec auto-analyse ✅
- Interface : `create_report_page.dart` avec UI IA ✅
- Endpoint constant : `ApiConstants.aiAnalyzeImage` ✅

### Backend Laravel : 100% ✅
- Controller : `AIAnalysisController.php` ✅
- Route : `POST /api/ai/analyze-image` ✅
- Tests : 9 tests dans `AnalyzeImageTest.php` ✅
- Configuration : `config/services.php` ✅

### Configuration requise : ⏳
- `GEMINI_API_KEY` dans `.env` backend
- Backend Laravel démarré sur `http://192.168.1.7:8000`
- Vérification IDs catégories

---

## 📋 Prérequis avant test

### 1. Backend Laravel configuré

```bash
# Dans le projet Laravel backend

# 1. Ajouter clé Gemini dans .env
echo "GEMINI_API_KEY=AIzaSy_votre_cle_ici" >> .env

# 2. Vider cache config
php artisan config:clear

# 3. Vérifier la clé
php artisan tinker
>>> config('services.gemini.api_key')
# Devrait afficher votre clé

# 4. Démarrer le serveur
php artisan serve --host=172.16.1.113 --port=8000
```

### 2. Obtenir clé Gemini (gratuit)

1. Aller sur https://aistudio.google.com/app/apikey
2. Cliquer **"Create API Key"**
3. Sélectionner/créer un projet Google Cloud
4. Copier la clé (format : `AIza...`)
5. Coller dans `.env` du backend

**Quotas gratuits :**
- 60 requêtes/minute
- 1 500 requêtes/jour

### 3. Vérifier les IDs de catégories

Dans votre base de données Laravel :

```sql
SELECT id, name FROM categories ORDER BY id;
```

**Mapping attendu dans le backend :**
```
1 → nid_de_poule
2 → ordures
3 → eclairage
4 → graffitis
5 → infrastructure
6 → autre
```

⚠️ **Si les IDs ne correspondent pas**, modifier le mapping dans `AIAnalysisController.php` ligne 145.

### 4. Device Flutter

**Appareil physique Android :**
- Backend : `http://192.168.1.7:8000` (votre IP locale)
- Appareil et PC sur **même WiFi**

**Émulateur Android :**
- Backend : `http://10.0.2.2:8000`
- Modifier `api_constants.dart` si besoin

**Configuration actuelle :**
```dart
// lib/core/constants/api_constants.dart
static const String baseUrl = 'http://172.16.1.113:8000/api';
```

---

## 🧪 Scénarios de Test

### ✅ Test 1 : Analyse IA complète (backend configuré)

**Objectif :** Vérifier le workflow complet photo → IA → auto-remplissage

**Étapes :**

1. **Lancer l'application Flutter**
   ```bash
   flutter run -d R58X40LHL2W  # Votre device
   ```

2. **Se connecter** (si pas déjà connecté)
   - Email / Mot de passe

3. **Aller sur "Créer un signalement"**
   - Depuis HomePage → Bouton "+"
   - Ou depuis BottomNav → "Reports" → "+"

4. **Prendre une photo de nid de poule**
   - Cliquer **"Caméra"** ou **"Galerie"**
   - Sélectionner/prendre photo d'un trou dans la route

5. **Observer l'indicateur IA** 🤖
   ```
   Devrait apparaître immédiatement :
   
   ┌──────────────────────────────────┐
   │ 🤖 Analyse IA en cours...        │
   │ ●●●● (spinner orange)            │
   └──────────────────────────────────┘
   ```

6. **Attendre 5-15 secondes**

7. **Vérifier auto-remplissage** ✨
   - **SnackBar vert** : "✨ Analyse IA terminée ! Vérifiez les informations pré-remplies"
   - **Champ Titre** : Pré-rempli (ex: "Nid de poule avenue principale")
   - **Champ Description** : Pré-rempli (ex: "Important trou dans la chaussée...")
   - **Catégorie** : Sélectionnée automatiquement (ex: "Nid de poule")

8. **Vérifier/éditer** les informations si nécessaire

9. **Soumettre le signalement**
   - Cliquer **"Créer le signalement"**
   - Attendre succès

**Résultat attendu :** ✅
- Indicateur IA affiché
- Champs pré-remplis automatiquement
- Signalement créé avec succès

---

### ⚠️ Test 2 : Backend non disponible (erreur réseau)

**Objectif :** Vérifier le fallback manuel

**Simulation :**
- Backend arrêté OU clé Gemini invalide OU réseau coupé

**Étapes :**

1. **Arrêter le backend Laravel** (pour simuler)
   ```bash
   # Sur le serveur Laravel
   Ctrl+C  # Arrêter php artisan serve
   ```

2. **Flutter : Créer un signalement**
   - Prendre une photo
   - Observer indicateur "🤖 Analyse IA en cours..."

3. **Attendre timeout (~30 secondes)**

4. **Vérifier SnackBar d'erreur** ⚠️
   ```
   ⚠️ Analyse IA échouée: Connection failed
   ```
   (Orange, pas rouge)

5. **Remplir manuellement**
   - Titre : "Mon signalement"
   - Description : "Description manuelle"
   - Catégorie : Sélectionner manuellement

6. **Soumettre**

**Résultat attendu :** ✅
- Erreur affichée proprement
- Utilisateur peut continuer manuellement
- Signalement créé quand même

---

### ✅ Test 3 : Réanalyse manuelle

**Objectif :** Tester le bouton "Réanalyser avec IA"

**Étapes :**

1. **Photo déjà analysée**
   - Une photo ajoutée
   - Analyse IA terminée
   - Champs pré-remplis

2. **Vérifier bouton "Réanalyser avec IA"**
   ```
   Devrait apparaître sous les photos :
   
   ┌──────────────────────────────────┐
   │ ✨ Réanalyser avec IA            │
   └──────────────────────────────────┘
   ```

3. **Cliquer sur "Réanalyser avec IA"**

4. **Observer nouvel indicateur**
   - "🤖 Analyse IA en cours..."

5. **Vérifier nouveaux résultats**
   - Champs re-remplis avec nouveaux résultats
   - Possiblement différents de la première fois

**Résultat attendu :** ✅
- Bouton visible
- Réanalyse déclenche
- Nouveaux résultats appliqués

---

### ✅ Test 4 : Photo obligatoire

**Objectif :** Vérifier validation photo obligatoire

**Étapes :**

1. **Créer un signalement**
   - **NE PAS** ajouter de photo
   - Remplir titre, description, catégorie

2. **Cliquer "Créer le signalement"**

3. **Vérifier SnackBar d'erreur** ❌
   ```
   📸 Veuillez ajouter au moins une photo
   ```
   (Rouge)

4. **Vérifier soumission bloquée**
   - Signalement non créé
   - Reste sur la page

**Résultat attendu :** ✅
- Soumission bloquée
- Message clair
- Utilisateur comprend qu'il faut une photo

---

### ✅ Test 5 : Description facultative

**Objectif :** Vérifier que description n'est plus obligatoire

**Étapes :**

1. **Créer un signalement**
   - Ajouter photo (avec ou sans IA)
   - Remplir **uniquement Titre et Catégorie**
   - **Laisser Description VIDE**

2. **Soumettre**

3. **Vérifier succès**

**Résultat attendu :** ✅
- Soumission réussie
- Signalement créé sans description
- Pas d'erreur de validation

---

### 🔍 Test 6 : Vérification backend direct

**Objectif :** Tester endpoint backend indépendamment

**Étapes :**

1. **Obtenir un token Sanctum valide**
   ```bash
   # Se connecter via API
   curl -X POST http://172.16.1.113:8000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@test.com","password":"password"}'
   
   # Copier le "token" de la réponse
   ```

2. **Tester endpoint IA avec cURL**
   ```bash
   curl -X POST http://172.16.1.113:8000/api/ai/analyze-image \
     -H "Authorization: Bearer VOTRE_TOKEN_ICI" \
     -H "Accept: application/json" \
     -F "image=@/chemin/vers/photo_nid_de_poule.jpg"
   ```

3. **Vérifier réponse JSON**
   ```json
   {
     "success": true,
     "message": "Image analysée avec succès",
     "data": {
       "title": "Nid de poule avenue principale",
       "description": "Important trou dans la chaussée...",
       "category_id": 1,
       "confidence": 0.92
     }
   }
   ```

**Résultat attendu :** ✅
- Status 200
- JSON valide
- `category_id` correspond à votre DB

---

### 🧪 Test 7 : Tests unitaires backend

**Objectif :** Exécuter les tests Laravel

**Étapes :**

```bash
# Dans le projet Laravel backend

# 1. Tous les tests
php artisan test

# 2. Tests IA uniquement
php artisan test tests/Feature/AI/AnalyzeImageTest.php

# 3. Test spécifique
php artisan test --filter test_user_can_analyze_image_with_gemini
```

**Résultat attendu :** ✅
- 9/9 tests passent
- Aucune erreur

---

## 📊 Checklist de validation complète

### Avant de tester
- [ ] Backend Laravel démarré sur `172.16.1.113:8000`
- [ ] `GEMINI_API_KEY` configuré dans `.env` backend
- [ ] `php artisan config:clear` exécuté
- [ ] IDs catégories vérifiés dans DB
- [ ] Flutter app compilée sans erreurs

### Tests fonctionnels
- [ ] ✅ Test 1 : Analyse IA complète fonctionne
- [ ] ⚠️ Test 2 : Erreur backend gérée proprement
- [ ] ✅ Test 3 : Bouton "Réanalyser" fonctionne
- [ ] ✅ Test 4 : Photo obligatoire validée
- [ ] ✅ Test 5 : Description facultative OK
- [ ] 🔍 Test 6 : Backend cURL fonctionne
- [ ] 🧪 Test 7 : Tests unitaires passent (9/9)

### Validation finale
- [ ] Workflow complet testé au moins 3 fois
- [ ] Performance acceptable (< 15s par analyse)
- [ ] Pas de crash/freeze
- [ ] Messages d'erreur clairs
- [ ] Données sauvegardées correctement

---

## 🐛 Dépannage

### Erreur "Connection failed"

**Causes possibles :**
1. Backend non démarré
2. Firewall bloque le port 8000
3. Mauvaise IP dans `api_constants.dart`
4. Device et PC sur WiFi différents

**Solutions :**
```bash
# 1. Vérifier backend accessible
curl http://172.16.1.113:8000/api/categories

# 2. Désactiver firewall temporairement
# Windows : Paramètres → Pare-feu

# 3. Vérifier IP
ipconfig | Select-String "IPv4"

# 4. Même WiFi : Vérifier sur device
# Ouvrir navigateur → http://172.16.1.113:8000
```

### Erreur "API key not valid"

**Solutions :**
```bash
# 1. Vérifier clé dans .env
cat .env | grep GEMINI

# 2. Tester clé directement
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=VOTRE_CLÉ" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"Test"}]}]}'

# 3. Régénérer clé sur https://aistudio.google.com/app/apikey
```

### Timeout IA (> 30 secondes)

**Causes :**
- Connexion internet lente
- Image trop volumineuse
- Gemini API surchargée

**Solutions :**
```dart
// Augmenter timeout dans ai_analysis_service.dart
sendTimeout: const Duration(seconds: 60),
receiveTimeout: const Duration(seconds: 60),
```

### Category_id incorrect

**Problème :** L'IA retourne un `category_id` qui n'existe pas dans la DB.

**Solution :**
```php
// Modifier mapping dans AIAnalysisController.php
private function mapCategoryToId(string $categoryName): int
{
    $mapping = [
        'nid_de_poule' => 1,  // ← Vérifier ces IDs !
        'ordures' => 2,
        'eclairage' => 3,
        // ...
    ];
    // ...
}
```

### L'analyse ne se déclenche pas

**Vérifications :**
1. Photo bien ajoutée ? (compteur "1/5 photos")
2. Déjà analysé ? (sinon pas de redéclenchement)
3. Logs Dart : Vérifier console Flutter
4. Breakpoint : Dans `report_notifier.dart` ligne ~70

---

## 📝 Notes importantes

### Limitations actuelles

1. **Analyse une seule fois automatiquement**
   - Auto-déclenchée uniquement à la 1ère photo
   - Utiliser "Réanalyser" pour relancer

2. **Catégories limitées**
   - Mapping fixe dans backend
   - Ajouter nouvelles catégories nécessite modification code

3. **Pas de cache**
   - Chaque réanalyse appelle Gemini API
   - Consomme quota

4. **Description générée en français uniquement**
   - Prompt hardcodé en français
   - Multi-langue nécessite modifications

### Améliorations futures

- [ ] Cache résultats analyse (Redis)
- [ ] Afficher score de confiance dans UI
- [ ] Support multi-langues
- [ ] Analytics : tracker taux succès/échec
- [ ] Feedback utilisateur sur qualité analyse
- [ ] Optimisation prompt Gemini
- [ ] Compression image côté mobile avant upload

---

## ✅ Workflow validé

Si tous les tests passent, le workflow complet fonctionne :

```
📱 Utilisateur ouvre app
    ↓
📷 Prend photo d'un problème
    ↓
🤖 IA analyse automatiquement (5-15s)
    ↓
✨ Formulaire pré-rempli automatiquement
    ↓
✏️ Utilisateur vérifie/édite (optionnel)
    ↓
📤 Soumet signalement
    ↓
✅ Signalement créé avec succès
```

**Gain de temps utilisateur : ~80%**
(Plus besoin de taper titre + description + catégorie)

---

**Date** : Janvier 2025  
**Version** : 1.1.0  
**Status** : Prêt pour tests ✅
