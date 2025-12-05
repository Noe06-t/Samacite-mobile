# 🤖 Analyse IA - Quick Start

## ⚡ En bref

L'utilisateur prend une photo → L'IA analyse → Pré-remplit titre/description/catégorie automatiquement.

## ✅ Ce qui est fait (Flutter)

✅ Service d'analyse IA (`AIAnalysisService`)  
✅ Auto-déclenchement après ajout première photo  
✅ Indicateur visuel d'analyse en cours  
✅ Pré-remplissage automatique des champs  
✅ Bouton "Réanalyser avec IA"  
✅ Gestion erreurs avec fallback manuel  
✅ Photo obligatoire, description optionnelle  

## ❌ Ce qui reste (Backend Laravel)

❌ Endpoint `POST /api/ai/analyze-image` **À IMPLÉMENTER**  
❌ Intégration Google Gemini Pro Vision  
❌ Variable `GEMINI_API_KEY` dans `.env`  

## 🚀 Backend Laravel - Code complet

### 1. Installer Gemini SDK
```bash
composer require google/generative-ai-php
```

### 2. Ajouter dans `.env`
```env
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXX
```

Obtenir gratuitement : https://makersuite.google.com/app/apikey

### 3. Route (routes/api.php)
```php
Route::middleware('auth:api')->group(function () {
    Route::post('/ai/analyze-image', [AIAnalysisController::class, 'analyzeImage']);
});
```

### 4. Controller
```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Google\GenerativeAI\GenerativeModel;

class AIAnalysisController extends Controller
{
    public function analyzeImage(Request $request)
    {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg|max:5120', // 5MB max
        ]);

        try {
            $imagePath = $request->file('image')->getRealPath();
            $imageData = base64_encode(file_get_contents($imagePath));
            
            $model = new GenerativeModel(
                apiKey: env('GEMINI_API_KEY'),
                model: 'gemini-pro-vision'
            );

            $prompt = "Analyse cette photo d'un problème urbain et renvoie UNIQUEMENT un JSON avec cette structure exacte : {\"title\": \"titre court\", \"description\": \"description détaillée\", \"category\": \"nid_de_poule|ordures|eclairage|graffitis|autre\", \"confidence\": 0.85}. Ne renvoie RIEN d'autre que le JSON.";

            $response = $model->generateContent([
                'parts' => [
                    ['text' => $prompt],
                    [
                        'inlineData' => [
                            'mimeType' => 'image/jpeg',
                            'data' => $imageData
                        ]
                    ]
                ]
            ]);

            $aiText = $response->text();
            $jsonStart = strpos($aiText, '{');
            $jsonEnd = strrpos($aiText, '}') + 1;
            $jsonStr = substr($aiText, $jsonStart, $jsonEnd - $jsonStart);
            $aiResult = json_decode($jsonStr, true);

            return response()->json([
                'success' => true,
                'data' => [
                    'title' => $aiResult['title'] ?? 'Signalement',
                    'description' => $aiResult['description'] ?? 'Problème urbain détecté',
                    'category' => $aiResult['category'] ?? 'autre',
                    'confidence' => $aiResult['confidence'] ?? 0.5,
                ],
                'message' => 'Analyse terminée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur analyse IA: ' . $e->getMessage()
            ], 500);
        }
    }
}
```

### 5. Tester
```bash
php artisan serve

# Depuis autre terminal
curl -X POST http://localhost:8000/api/ai/analyze-image \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -F "image=@/chemin/vers/image.jpg"
```

## 📱 Test Flutter

1. **Backend NON implémenté** : L'analyse échouera, mais l'utilisateur peut créer le signalement manuellement
2. **Backend implémenté** : Workflow complet fonctionne

### Test workflow complet
```
1. Ouvrir "Créer un signalement"
2. Prendre photo
3. Voir "🤖 Analyse IA en cours..."
4. Champs pré-remplis automatiquement
5. Vérifier/éditer
6. Soumettre
```

## 🎨 UI States

| État | Affichage |
|------|-----------|
| Aucune photo | Boutons Galerie/Caméra |
| Analyse en cours | 🤖 Spinner orange + texte |
| Analyse réussie | ✅ Champs remplis + Bouton "Réanalyser" |
| Analyse échouée | ⚠️ SnackBar orange + Saisie manuelle |

## 📊 Limites gratuites Gemini

- ✅ 60 requêtes/minute
- ✅ 1 500 requêtes/jour
- ✅ Pas de carte bancaire
- ✅ Suffisant pour MVP

## 🔍 Debugging

### Backend ne répond pas
```bash
tail -f storage/logs/laravel.log
```

### Erreur Gemini API
```bash
# Tester clé API
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=VOTRE_CLÉ" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"Test"}]}]}'
```

### Flutter ne trouve pas backend
- Émulateur Android : `http://10.0.2.2:8000/api`
- Appareil physique : `http://192.168.x.x:8000/api`
- iOS Simulator : `http://localhost:8000/api`

## 📚 Documentation complète

- **Backend détaillé** : `AI_BACKEND_IMPLEMENTATION.md`
- **Guide utilisateur** : `AI_FEATURE_GUIDE.md`
- **Configuration** : `CONFIGURATION.md`
- **Changelog** : `CHANGELOG.md`

## ⏱️ Temps d'implémentation

- **Backend Laravel** : 2-3 heures
- **Configuration Gemini** : 30 minutes
- **Tests** : 1 heure
- **Total** : ~4 heures

## ✅ Checklist

Backend :
- [ ] Installer `google/generative-ai-php`
- [ ] Ajouter `GEMINI_API_KEY` dans `.env`
- [ ] Créer `AIAnalysisController`
- [ ] Ajouter route `/api/ai/analyze-image`
- [ ] Tester avec curl

Frontend :
- [x] Service `AIAnalysisService` ✅
- [x] UI indicateur analyse ✅
- [x] Pré-remplissage automatique ✅
- [x] Gestion erreurs ✅

---

**Questions ?** Voir `AI_FEATURE_GUIDE.md` ou `CONFIGURATION.md`
