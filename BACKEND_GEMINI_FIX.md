# 🔧 Backend Laravel - Fix API Gemini (Erreur MAX_TOKENS)

## ⚠️ Problème Actuel

L'API `/ai/analyze-image` retourne une **erreur 500** avec le message :
```
"Format de réponse invalide de l'IA"
```

### 📊 Logs d'erreur

```
[2025-12-06 00:44:23] local.INFO: Gemini Raw Response: {
  "candidates": [{
    "content": {"role": "model"},  // ❌ PAS DE "parts" !
    "finishReason": "MAX_TOKENS",  // ⚠️ LIMITE ATTEINTE
    "index": 0
  }],
  "usageMetadata": {
    "promptTokenCount": 478,
    "totalTokenCount": 1977,
    "thoughtsTokenCount": 1499
  }
}

[2025-12-06 00:44:23] local.ERROR: No text found in Gemini response structure
```

### 🔍 Cause racine

Gemini répond avec `"finishReason": "MAX_TOKENS"` ce qui signifie que :
- La réponse a été **tronquée** avant d'être complète
- Le champ `content.parts` est **vide ou absent**
- Le parsing échoue car il cherche `parts[0].text`

---

## ✅ Solution 1 : Augmenter la limite de tokens (RECOMMANDÉ)

### Fichier à modifier : `app/Services/GeminiService.php` (ou équivalent)

**Avant :**
```php
$response = $client->post('/v1beta/models/gemini-2.5-flash:generateContent', [
    'json' => [
        'contents' => [
            [
                'role' => 'user',
                'parts' => [
                    ['text' => $prompt],
                    ['inline_data' => [
                        'mime_type' => $mimeType,
                        'data' => $imageBase64
                    ]]
                ]
            ]
        ],
        // ⚠️ Limite trop basse ou absente
    ]
]);
```

**Après :**
```php
$response = $client->post('/v1beta/models/gemini-2.5-flash:generateContent', [
    'json' => [
        'contents' => [
            [
                'role' => 'user',
                'parts' => [
                    ['text' => $prompt],
                    ['inline_data' => [
                        'mime_type' => $mimeType,
                        'data' => $imageBase64
                    ]]
                ]
            ]
        ],
        'generationConfig' => [
            'maxOutputTokens' => 2048,  // ✅ Augmenter la limite
            'temperature' => 0.7,
            'topK' => 40,
            'topP' => 0.95,
        ]
    ]
]);
```

**Valeurs recommandées :**
- `maxOutputTokens: 2048` - Pour des réponses complètes
- `maxOutputTokens: 4096` - Pour des analyses très détaillées
- `maxOutputTokens: 8192` - Maximum supporté par Gemini 2.5 Flash

---

## ✅ Solution 2 : Gérer le cas MAX_TOKENS

### Ajouter un fallback dans le parsing

**Fichier : `app/Services/GeminiService.php` (méthode de parsing)**

```php
private function parseGeminiResponse($response)
{
    $data = json_decode($response->getBody()->getContents(), true);
    
    \Log::info('Gemini Raw Response:', $data);
    
    // ✅ VÉRIFIER finishReason
    $finishReason = $data['candidates'][0]['finishReason'] ?? null;
    
    if ($finishReason === 'MAX_TOKENS') {
        \Log::warning('Gemini response truncated due to MAX_TOKENS');
        throw new \Exception(
            'La réponse de l\'IA a été tronquée. ' .
            'Veuillez réessayer avec une image plus simple ou contacter le support.'
        );
    }
    
    if ($finishReason !== 'STOP') {
        \Log::error("Unexpected finishReason: {$finishReason}");
        throw new \Exception("Réponse IA invalide (raison: {$finishReason})");
    }
    
    // Vérifier que parts existe
    if (!isset($data['candidates'][0]['content']['parts'][0]['text'])) {
        \Log::error('No text found in Gemini response structure:', $data);
        throw new \Exception('Format de réponse invalide de l\'IA');
    }
    
    $text = $data['candidates'][0]['content']['parts'][0]['text'];
    \Log::info('Extracted text from Gemini:', $text);
    
    // Extraire le JSON de la réponse
    if (preg_match('/```json\s*(.*?)\s*```/s', $text, $matches)) {
        $jsonText = $matches[1];
    } else {
        $jsonText = $text;
    }
    
    $result = json_decode($jsonText, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new \Exception('Impossible de parser la réponse JSON de l\'IA');
    }
    
    return $result;
}
```

---

## ✅ Solution 3 : Retry automatique avec prompt plus court

```php
public function analyzeImage($imageBase64, $mimeType, $retryCount = 0)
{
    try {
        $prompt = $retryCount > 0 
            ? $this->getShortPrompt()  // Prompt plus court en cas de retry
            : $this->getFullPrompt();   // Prompt complet
        
        $response = $this->callGeminiAPI($imageBase64, $mimeType, $prompt);
        return $this->parseGeminiResponse($response);
        
    } catch (\Exception $e) {
        if ($retryCount < 2 && str_contains($e->getMessage(), 'MAX_TOKENS')) {
            \Log::info("Retrying with shorter prompt (attempt {$retryCount})");
            return $this->analyzeImage($imageBase64, $mimeType, $retryCount + 1);
        }
        throw $e;
    }
}

private function getFullPrompt()
{
    return "Analyse cette image de signalement urbain et retourne un JSON avec...";
}

private function getShortPrompt()
{
    return "En 50 mots max, décris ce problème urbain en JSON: {title, description, category_name, confidence}";
}
```

---

## 🧪 Test de la correction

### 1. Test avec Tinker

```bash
php artisan tinker
```

```php
$service = app(\App\Services\GeminiService::class);

// Lire une image de test
$imagePath = storage_path('app/public/reports/test.jpg');
$imageData = base64_encode(file_get_contents($imagePath));

// Tester l'analyse
try {
    $result = $service->analyzeImage($imageData, 'image/jpeg');
    print_r($result);
    echo "✅ Analyse réussie !\n";
} catch (\Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
```

### 2. Test via API

```bash
# Créer un signalement avec analyse IA
curl -X POST http://192.168.1.7:8000/api/ai/analyze-image \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "data:image/jpeg;base64,/9j/4AAQ...",
    "mime_type": "image/jpeg"
  }'
```

### 3. Vérifier les logs

```bash
tail -f storage/logs/laravel.log | grep -i gemini
```

Vous devriez voir :
```
✅ [local.INFO]: Gemini Raw Response: {"candidates":[{"finishReason":"STOP",...
✅ [local.INFO]: Extracted text from Gemini: {"title":"...","description":"..."}
```

---

## 📊 Comparaison des solutions

| Solution | Avantages | Inconvénients |
|----------|-----------|---------------|
| **1. Augmenter maxOutputTokens** | Simple, résout le problème définitivement | Coût API légèrement plus élevé |
| **2. Gérer MAX_TOKENS** | Messages d'erreur clairs | N'évite pas le problème |
| **3. Retry avec prompt court** | Robuste, fallback automatique | Plus complexe à implémenter |

**Recommandation** : Implémenter **Solution 1 + Solution 2** ensemble pour avoir :
- ✅ Limite suffisante pour la plupart des cas
- ✅ Gestion d'erreur claire si problème persiste

---

## 🚀 Configuration recommandée finale

```php
// Dans GeminiService.php

private const MAX_OUTPUT_TOKENS = 2048;
private const TEMPERATURE = 0.7;
private const TOP_K = 40;
private const TOP_P = 0.95;

public function analyzeImage($imageBase64, $mimeType)
{
    $response = $this->client->post(
        '/v1beta/models/gemini-2.5-flash:generateContent',
        [
            'json' => [
                'contents' => [
                    [
                        'role' => 'user',
                        'parts' => [
                            ['text' => $this->buildPrompt()],
                            ['inline_data' => [
                                'mime_type' => $mimeType,
                                'data' => $imageBase64
                            ]]
                        ]
                    ]
                ],
                'generationConfig' => [
                    'maxOutputTokens' => self::MAX_OUTPUT_TOKENS,
                    'temperature' => self::TEMPERATURE,
                    'topK' => self::TOP_K,
                    'topP' => self::TOP_P,
                ],
                'safetySettings' => [
                    [
                        'category' => 'HARM_CATEGORY_HARASSMENT',
                        'threshold' => 'BLOCK_NONE'
                    ],
                    [
                        'category' => 'HARM_CATEGORY_HATE_SPEECH',
                        'threshold' => 'BLOCK_NONE'
                    ],
                    [
                        'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                        'threshold' => 'BLOCK_NONE'
                    ],
                    [
                        'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT',
                        'threshold' => 'BLOCK_NONE'
                    ]
                ]
            ]
        ]
    );
    
    return $this->parseResponse($response);
}

private function parseResponse($response)
{
    $data = json_decode($response->getBody()->getContents(), true);
    
    $finishReason = $data['candidates'][0]['finishReason'] ?? null;
    
    // Gérer tous les cas de finishReason
    switch ($finishReason) {
        case 'STOP':
            // ✅ Réponse complète et normale
            break;
            
        case 'MAX_TOKENS':
            \Log::warning('Gemini MAX_TOKENS reached', ['data' => $data]);
            throw new \Exception(
                'La réponse IA a été tronquée. Veuillez réessayer.'
            );
            
        case 'SAFETY':
            \Log::warning('Gemini SAFETY filter triggered', ['data' => $data]);
            throw new \Exception(
                'L\'image a été bloquée par les filtres de sécurité.'
            );
            
        case 'RECITATION':
            \Log::warning('Gemini RECITATION detected', ['data' => $data]);
            throw new \Exception(
                'Contenu protégé par des droits d\'auteur détecté.'
            );
            
        default:
            \Log::error('Unexpected finishReason', [
                'reason' => $finishReason,
                'data' => $data
            ]);
            throw new \Exception(
                "Erreur IA inattendue (code: {$finishReason})"
            );
    }
    
    if (!isset($data['candidates'][0]['content']['parts'][0]['text'])) {
        throw new \Exception('Format de réponse IA invalide');
    }
    
    return $this->extractJSON($data['candidates'][0]['content']['parts'][0]['text']);
}
```

---

## ✅ Checklist d'implémentation

- [ ] Ajouter `maxOutputTokens: 2048` dans la config Gemini
- [ ] Implémenter la gestion de `finishReason`
- [ ] Ajouter les messages d'erreur clairs pour chaque cas
- [ ] Tester avec une vraie image
- [ ] Vérifier les logs après implémentation
- [ ] Mettre à jour la documentation API si nécessaire

---

## 📱 Impact côté Mobile

**Aucune modification nécessaire** ! Le mobile gère déjà l'erreur correctement :
- ✅ Affiche un message d'erreur si l'analyse échoue
- ✅ Permet de créer le signalement manuellement
- ✅ Ne bloque pas l'utilisateur

Une fois le backend corrigé, l'analyse IA fonctionnera automatiquement. 🚀

---

## 🐛 Debugging

Si le problème persiste après correction :

1. **Vérifier la clé API Gemini**
```bash
echo $GEMINI_API_KEY
```

2. **Tester directement l'API Gemini**
```bash
curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{"text": "Bonjour"}]
    }],
    "generationConfig": {
      "maxOutputTokens": 2048
    }
  }'
```

3. **Vérifier les quotas Gemini**
- Aller sur [Google AI Studio](https://aistudio.google.com/)
- Vérifier les limites de votre clé API
- Vérifier le nombre de requêtes utilisées

---

**Résumé** : Le problème vient du `finishReason: MAX_TOKENS`. Solution : augmenter `maxOutputTokens` à 2048 et gérer proprement tous les cas de `finishReason`. 🔧
