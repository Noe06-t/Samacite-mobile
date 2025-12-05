# 🤖 Installation de l'Analyse IA avec Google Gemini

## ✅ Fichiers Créés

Les fichiers suivants ont été créés/modifiés :

1. ✅ `app/Http/Controllers/Api/AIAnalysisController.php` - Controller pour l'analyse IA
2. ✅ `config/services.php` - Configuration Gemini ajoutée
3. ✅ `routes/api.php` - Route `POST /api/ai/analyze-image` ajoutée
4. ✅ `.env.example` - Variable `GEMINI_API_KEY` ajoutée
5. ✅ `tests/Feature/AI/AnalyzeImageTest.php` - Tests complets (9 tests)

## 📦 Installation

### Étape 1 : Pas besoin de composer require !

**Bonne nouvelle** : On utilise l'API REST de Gemini directement via `Http::post()` de Laravel.
**Aucun package supplémentaire n'est requis** ! 🎉

### Étape 2 : Obtenir une clé API Gemini (GRATUIT)

1. Aller sur https://aistudio.google.com/app/apikey
2. Cliquer sur **"Create API Key"**
3. Sélectionner un projet Google Cloud (ou en créer un - c'est gratuit)
4. Copier la clé générée (format : `AIza...`)

**Quotas gratuits** :
- ✅ 60 requêtes/minute
- ✅ 1500 requêtes/jour
- ✅ 100% gratuit jusqu'à ces limites

### Étape 3 : Configurer .env

Ajouter dans votre fichier `.env` :

```env
GEMINI_API_KEY=votre_cle_api_ici
```

Exemple :
```env
GEMINI_API_KEY=AIzaSyBcD1eFgH2iJkLmN3oPqRsTuVwXyZ4
```

### Étape 4 : Vider le cache de configuration

```bash
php artisan config:clear
```

### Étape 5 : Lancer les tests

```bash
php artisan test tests/Feature/AI/AnalyzeImageTest.php
```

Résultat attendu : **9 tests passent** ✅

## 🚀 Utilisation

### Endpoint

```
POST /api/ai/analyze-image
```

### Headers

```
Authorization: Bearer {votre_token_sanctum}
Content-Type: multipart/form-data
```

### Body (form-data)

| Clé | Type | Requis | Description |
|-----|------|--------|-------------|
| image | File | ✅ | Image JPEG/PNG, max 10MB |

### Réponse (Succès)

```json
{
  "success": true,
  "message": "Image analysée avec succès",
  "data": {
    "title": "Nid de poule avenue principale",
    "description": "Important trou dans la chaussée présentant un danger. Profondeur estimée 15cm.",
    "category_id": 1,
    "confidence": 0.92
  }
}
```

### Mapping des Catégories

| category_name | category_id | Description |
|---------------|-------------|-------------|
| nid_de_poule | 1 | Trous, dégradations chaussée |
| ordures | 2 | Déchets, poubelles |
| eclairage | 3 | Lampadaires cassés |
| graffitis | 4 | Tags, vandalisme |
| infrastructure | 5 | Panneaux, équipements |
| autre | 6 | Autres problèmes |

⚠️ **Important** : Vérifiez que ces IDs correspondent à votre table `categories` !

## 🧪 Test avec cURL

```bash
curl -X POST http://localhost:8000/api/ai/analyze-image \
  -H "Authorization: Bearer votre_token_sanctum" \
  -H "Accept: application/json" \
  -F "image=@/chemin/vers/photo.jpg"
```

## 🧪 Test avec Postman

1. **Method** : POST
2. **URL** : `http://localhost:8000/api/ai/analyze-image`
3. **Headers** :
   - `Authorization` : `Bearer votre_token`
   - `Accept` : `application/json`
4. **Body** (form-data) :
   - Clé : `image`
   - Type : File
   - Valeur : Sélectionner une image

## 🔧 Vérifications

### 1. Vérifier que la clé API fonctionne

```bash
php artisan tinker
```

Puis :
```php
config('services.gemini.api_key')
// Devrait afficher votre clé API
```

### 2. Vérifier la route

```bash
php artisan route:list --name=ai
```

Devrait afficher :
```
POST  api/ai/analyze-image  ai.analyze-image
```

### 3. Lancer tous les tests

```bash
php artisan test
```

Tous les tests doivent passer, y compris les 9 nouveaux tests AI.

## 📊 Liste des Tests Créés

1. ✅ `test_user_can_analyze_image_with_gemini` - Test d'analyse réussie
2. ✅ `test_analyze_image_requires_authentication` - Vérification auth
3. ✅ `test_analyze_image_validates_file_type` - Validation type fichier
4. ✅ `test_analyze_image_validates_file_size` - Validation taille (10MB max)
5. ✅ `test_analyze_image_requires_image_field` - Champ requis
6. ✅ `test_analyze_image_maps_categories_correctly` - Mapping catégories
7. ✅ `test_analyze_image_handles_unknown_category` - Catégorie inconnue → "autre"
8. ✅ `test_analyze_image_handles_api_errors` - Erreurs API Gemini
9. ✅ `test_analyze_image_handles_invalid_json_response` - Réponse JSON invalide

## 🐛 Dépannage

### Erreur "API key not valid"

1. Vérifier que la clé est correcte dans `.env`
2. Lancer `php artisan config:clear`
3. Vérifier avec `php artisan tinker` : `config('services.gemini.api_key')`

### Erreur "Model not found"

Le modèle utilisé est `gemini-1.5-flash` (le plus rapide et gratuit).
Si besoin de changer, modifier dans `AIAnalysisController.php` ligne 67.

### Timeout

Augmenter le timeout dans le controller :
```php
Http::timeout(60)->post(...)
```

### Les tests échouent

Si les tests échouent parce que la clé API n'est pas configurée, c'est normal !
Les tests utilisent `Http::fake()` pour mocker l'API.

Pour tester avec une vraie clé API :
1. Ajouter `GEMINI_API_KEY` dans `.env`
2. Commenter les lignes `Http::fake()` dans les tests

## 💰 Coûts

### Gemini 1.5 Flash (utilisé par défaut)

- ✅ **GRATUIT** : 1500 requêtes/jour
- ✅ **Après quota gratuit** : $0.00035 par image (~0.035 centimes)
- ✅ **Vitesse** : ~2 secondes par analyse

### Alternative : Gemini 1.5 Pro (plus précis)

Changer ligne 67 dans `AIAnalysisController.php` :
```php
'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent...'
```

Coût : $0.00125 par image (~0.125 centimes)

## 📚 Ressources

- [Google Gemini API Docs](https://ai.google.dev/docs)
- [Laravel HTTP Client](https://laravel.com/docs/http-client)
- [Obtenir une clé API](https://aistudio.google.com/app/apikey)

## ✅ Résumé

Tout est prêt ! Il suffit de :

1. ✅ Obtenir une clé API Gemini (gratuite)
2. ✅ Ajouter `GEMINI_API_KEY=votre_cle` dans `.env`
3. ✅ Lancer `php artisan config:clear`
4. ✅ Tester avec `php artisan test tests/Feature/AI/AnalyzeImageTest.php`
5. ✅ Utiliser l'endpoint depuis Flutter : `POST /api/ai/analyze-image`

**Aucune dépendance composer requise** ! 🎉

L'implémentation utilise uniquement le client HTTP natif de Laravel (`Http::post()`), ce qui évite les problèmes de versions et de dépendances.
