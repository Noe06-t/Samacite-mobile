# Backend IA - Analyse d'images pour signalements

## 📋 Endpoint à créer dans Laravel

### Route
```php
POST /api/ai/analyze-image
```

### Headers requis
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

### Body (multipart/form-data)
```
image: File (JPEG/PNG, max 10MB)
```

### Réponse JSON (succès)
```json
{
  "success": true,
  "data": {
    "title": "Nid de poule sur avenue principale",
    "description": "Importante dégradation de la chaussée causant un danger pour les véhicules. Le nid de poule fait environ 30cm de diamètre.",
    "category_id": 2,
    "confidence": 0.92
  }
}
```

### Réponse JSON (erreur)
```json
{
  "success": false,
  "message": "Erreur lors de l'analyse de l'image"
}
```

---

## 🔧 Implémentation Laravel recommandée

### 1. Installation Google Gemini PHP SDK

```bash
composer require google/generative-ai-php
```

### 2. Configuration `.env`

Ajouter dans votre fichier `.env` Laravel :

```env
GEMINI_API_KEY=votre_cle_api_gemini_ici
```

**Obtenir une clé API gratuite** :
1. Aller sur https://makersuite.google.com/app/apikey
2. Créer un projet Google Cloud (gratuit)
3. Activer l'API Generative Language
4. Copier la clé API

**Quotas gratuits** :
- 60 requêtes/minute
- 1500 requêtes/jour
- Totalement gratuit jusqu'à ces limites

### 3. Créer le Controller

Créer `app/Http/Controllers/Api/AIAnalysisController.php` :

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Google\GenerativeAI\Client;
use Google\GenerativeAI\GenerationConfig;

class AIAnalysisController extends Controller
{
    /**
     * Analyser une image de signalement avec Google Gemini Vision
     */
    public function analyzeImage(Request $request)
    {
        // Validation
        $validator = Validator::make($request->all(), [
            'image' => 'required|image|mimes:jpeg,png,jpg|max:10240', // 10MB max
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Image invalide',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            // 1. Récupérer l'image
            $image = $request->file('image');
            $imagePath = $image->getRealPath();
            $imageData = base64_encode(file_get_contents($imagePath));
            $mimeType = $image->getMimeType();

            // 2. Initialiser Gemini
            $apiKey = config('services.gemini.api_key');
            $client = new Client($apiKey);
            
            // 3. Préparer le prompt
            $prompt = "Analyse cette photo d'un problème urbain et génère un JSON avec:
- title: titre court et descriptif (max 60 caractères)
- description: description détaillée du problème (80-200 caractères)
- category_name: catégorie parmi (nid_de_poule, ordures, eclairage, graffitis, infrastructure, autre)
- confidence: score de confiance 0.0-1.0

Concentre-toi sur le type de problème, la gravité et les éléments visibles.
Réponds UNIQUEMENT avec le JSON, sans texte supplémentaire.

Exemple de réponse:
{
  \"title\": \"Nid de poule avenue principale\",
  \"description\": \"Important trou dans la chaussée présentant un danger. Profondeur estimée 15cm.\",
  \"category_name\": \"nid_de_poule\",
  \"confidence\": 0.95
}";

            // 4. Appeler Gemini Vision
            $response = $client->models()->generate([
                'model' => 'gemini-1.5-flash',
                'contents' => [
                    [
                        'parts' => [
                            ['text' => $prompt],
                            [
                                'inline_data' => [
                                    'mime_type' => $mimeType,
                                    'data' => $imageData
                                ]
                            ]
                        ]
                    ]
                ],
                'generationConfig' => new GenerationConfig([
                    'temperature' => 0.4,
                    'maxOutputTokens' => 200,
                ])
            ]);

            // 5. Parser la réponse
            $resultText = $response->candidates[0]->content->parts[0]->text ?? '';
            
            // Extraire le JSON de la réponse
            $resultText = trim($resultText);
            $resultText = preg_replace('/^```json\s*|\s*```$/m', '', $resultText);
            
            $aiResult = json_decode($resultText, true);

            if (!$aiResult || !isset($aiResult['title'])) {
                throw new \Exception('Format de réponse invalide');
            }

            // 6. Mapper catégorie vers ID
            $categoryMap = [
                'nid_de_poule' => 1,
                'ordures' => 2,
                'eclairage' => 3,
                'graffitis' => 4,
                'infrastructure' => 5,
                'autre' => 6,
            ];

            $categoryName = strtolower($aiResult['category_name'] ?? 'autre');
            $categoryId = $categoryMap[$categoryName] ?? 6;

            // 7. Retourner le résultat
            return response()->json([
                'success' => true,
                'data' => [
                    'title' => $aiResult['title'],
                    'description' => $aiResult['description'],
                    'category_id' => $categoryId,
                    'confidence' => $aiResult['confidence'] ?? 0.8,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('AI Analysis Error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'analyse de l\'image',
                'error' => config('app.debug') ? $e->getMessage() : null
            ], 500);
        }
    }
}
```

### 4. Ajouter la route

Dans `routes/api.php` :

```php
use App\Http\Controllers\Api\AIAnalysisController;

// Routes protégées par auth:sanctum
Route::middleware('auth:sanctum')->group(function () {
    // ... autres routes existantes
    
    // Route analyse IA
    Route::post('/ai/analyze-image', [AIAnalysisController::class, 'analyzeImage']);
});
```

### 5. Configuration dans `config/services.php`

Ajouter :

```php
return [
    // ... autres services

    'gemini' => [
        'api_key' => env('GEMINI_API_KEY'),
    ],
];
```

---

## 🧪 Tester l'endpoint

### Avec Postman / Thunder Client

1. **Method**: POST
2. **URL**: `http://localhost:8000/api/ai/analyze-image`
3. **Headers**:
   - `Authorization`: `Bearer votre_token_sanctum`
   - `Accept`: `application/json`
4. **Body** (form-data):
   - Clé: `image`
   - Type: File
   - Valeur: Sélectionner une image

### Avec cURL

```bash
curl -X POST http://localhost:8000/api/ai/analyze-image \
  -H "Authorization: Bearer votre_token" \
  -H "Accept: application/json" \
  -F "image=@/chemin/vers/photo.jpg"
```

---

## 📊 Mapping des catégories

Assurez-vous que vos IDs de catégories correspondent :

| category_name | category_id | Description |
|---------------|-------------|-------------|
| nid_de_poule | 1 | Trous, dégradations chaussée |
| ordures | 2 | Déchets, poubelles débordantes |
| eclairage | 3 | Lampadaires cassés, manque éclairage |
| graffitis | 4 | Tags, vandalisme |
| infrastructure | 5 | Panneaux, bancs, équipements |
| autre | 6 | Autres problèmes urbains |

⚠️ **Ajustez le mapping dans le controller selon votre base de données** !

---

## 🚀 Alternative : OpenRouter (multi-modèles)

Si vous préférez OpenRouter pour basculer entre plusieurs modèles IA :

```bash
composer require guzzlehttp/guzzle
```

```php
// Dans AIAnalysisController
private function analyzeWithOpenRouter($imageData, $mimeType)
{
    $client = new \GuzzleHttp\Client();
    
    $response = $client->post('https://openrouter.ai/api/v1/chat/completions', [
        'headers' => [
            'Authorization' => 'Bearer ' . config('services.openrouter.api_key'),
            'Content-Type' => 'application/json',
        ],
        'json' => [
            'model' => 'google/gemini-flash-1.5', // ou anthropic/claude-3-haiku
            'messages' => [
                [
                    'role' => 'user',
                    'content' => [
                        ['type' => 'text', 'text' => $prompt],
                        [
                            'type' => 'image_url',
                            'image_url' => [
                                'url' => "data:{$mimeType};base64,{$imageData}"
                            ]
                        ]
                    ]
                ]
            ],
            'temperature' => 0.4,
            'max_tokens' => 200,
        ]
    ]);

    $result = json_decode($response->getBody(), true);
    return $result['choices'][0]['message']['content'];
}
```

---

## 💰 Coûts estimés

### Google Gemini Flash (gratuit)
- **Gratuit** : 1500 requêtes/jour
- **Après quota** : $0.00035 par image

### OpenRouter (payant)
- **Claude 3 Haiku** : $0.00025 par image
- **Gemini Flash** : $0.00035 par image
- **GPT-4o mini** : $0.00015 par image

**Recommandation** : Commencer avec Gemini gratuit, passer à OpenRouter si besoin de plus de volume.

---

## ✅ Checklist d'implémentation

- [ ] Installer `google/generative-ai-php`
- [ ] Créer clé API Gemini sur Google AI Studio
- [ ] Ajouter `GEMINI_API_KEY` dans `.env`
- [ ] Créer `AIAnalysisController.php`
- [ ] Ajouter route dans `routes/api.php`
- [ ] Ajouter config dans `config/services.php`
- [ ] Vérifier mapping des catégories
- [ ] Tester endpoint avec Postman
- [ ] Tester depuis l'app Flutter

---

## 🐛 Troubleshooting

### Erreur "API key not valid"
→ Vérifier que `GEMINI_API_KEY` est correct dans `.env`
→ Lancer `php artisan config:clear`

### Erreur "Model not found"
→ Vérifier le nom du modèle : `gemini-1.5-flash` ou `gemini-1.5-pro`

### Timeout
→ Augmenter `max_execution_time` dans `php.ini` ou :
```php
set_time_limit(60); // En début de méthode
```

### JSON invalide dans réponse
→ Ajouter plus de contexte au prompt
→ Vérifier extraction du JSON avec regex

---

## 📚 Ressources

- [Google Gemini API Docs](https://ai.google.dev/docs)
- [OpenRouter Docs](https://openrouter.ai/docs)
- [Laravel Sanctum](https://laravel.com/docs/sanctum)
