# 🔴 Problème Critique - Champ `is_liked` manquant dans l'API

**Date** : 24 novembre 2025  
**Priorité** : 🔴 HAUTE  
**Status** : ⚠️ Bloquant pour le système de likes

---

## 🐛 Problème identifié

### Symptôme
L'utilisateur voit le bouton like dans l'état "non liké" (icône grise ❤️‍🩹) même après avoir liké le signalement. Quand il clique à nouveau, le backend retourne :

```
ERROR 409: L'utilisateur a déjà aimé ce signalement
```

### Cause racine
Le backend **ne retourne PAS** le champ `is_liked` dans la réponse GET `/api/reports/{id}`.

**Réponse actuelle du backend** :
```json
{
  "success": true,
  "data": {
    "id": 4,
    "title": "Route endommagée",
    "description": "Problème urgent",
    "status": "pending",
    "user": { ... },
    "category": { ... },
    "images": [ ... ]
    // ❌ MANQUE: "likes_count": 5
    // ❌ MANQUE: "is_liked": true
  }
}
```

**Réponse attendue** :
```json
{
  "success": true,
  "data": {
    "id": 4,
    "title": "Route endommagée",
    "description": "Problème urgent",
    "status": "pending",
    "likes_count": 5,        // ✅ Nombre total de likes
    "is_liked": true,        // ✅ Si l'utilisateur connecté a liké
    "user": { ... },
    "category": { ... },
    "images": [ ... ]
  }
}
```

### Impact
- ❌ Le widget `_LikeButton` initialise `_isLiked = widget.report.isLiked` avec `false`
- ❌ L'utilisateur ne voit pas qu'il a déjà liké
- ❌ Le prochain clic appelle POST au lieu de DELETE
- ❌ Le backend retourne erreur 409 (conflit)
- ❌ Expérience utilisateur dégradée

---

## ✅ Solution requise (Backend Laravel)

### Méthode 1 : Modifier le Controller (Recommandé)

**Fichier** : `app/Http/Controllers/Api/ReportController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Models\Report;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    /**
     * Afficher un signalement avec ses relations
     * 
     * GET /api/reports/{id}?include=user,category,images
     */
    public function show(Request $request, $id)
    {
        // Charger le signalement avec ses relations
        $report = Report::with(['user', 'category', 'images', 'location'])
            ->findOrFail($id);
        
        // ✅ AJOUT 1: Calculer le nombre total de likes
        $report->likes_count = $report->likes()->count();
        
        // ✅ AJOUT 2: Vérifier si l'utilisateur connecté a liké
        if (auth()->check()) {
            $report->is_liked = $report->likes()
                ->where('user_id', auth()->id())
                ->exists();
        } else {
            $report->is_liked = false;
        }
        
        return response()->json([
            'success' => true,
            'data' => $report,
        ]);
    }
    
    /**
     * Liste des signalements avec pagination
     * 
     * GET /api/reports?page=1&per_page=15&include=user,category,images
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        
        $reports = Report::with(['user', 'category', 'images', 'location'])
            ->latest()
            ->paginate($perPage);
        
        // ✅ AJOUT: Pour chaque signalement, ajouter likes_count et is_liked
        $reports->getCollection()->transform(function ($report) {
            $report->likes_count = $report->likes()->count();
            
            if (auth()->check()) {
                $report->is_liked = $report->likes()
                    ->where('user_id', auth()->id())
                    ->exists();
            } else {
                $report->is_liked = false;
            }
            
            return $report;
        });
        
        return response()->json([
            'success' => true,
            'data' => $reports->items(),
            'pagination' => [
                'current_page' => $reports->currentPage(),
                'last_page' => $reports->lastPage(),
                'per_page' => $reports->perPage(),
                'total' => $reports->total(),
            ],
        ]);
    }
}
```

---

### Méthode 2 : Utiliser des Accessors (Plus propre)

**Fichier** : `app/Models/Report.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    protected $fillable = [
        'title', 'description', 'status', 'user_id', 'category_id',
        'latitude', 'longitude', 'address',
    ];
    
    // ✅ AJOUT: Ajouter automatiquement ces champs dans les réponses JSON
    protected $appends = ['likes_count', 'is_liked'];
    
    /**
     * Relation : Un signalement a plusieurs likes
     */
    public function likes()
    {
        return $this->hasMany(Like::class);
    }
    
    /**
     * Accessor : Nombre total de likes
     * 
     * @return int
     */
    public function getLikesCountAttribute()
    {
        return $this->likes()->count();
    }
    
    /**
     * Accessor : Si l'utilisateur connecté a liké ce signalement
     * 
     * @return bool
     */
    public function getIsLikedAttribute()
    {
        if (!auth()->check()) {
            return false;
        }
        
        return $this->likes()
            ->where('user_id', auth()->id())
            ->exists();
    }
    
    /**
     * Autres relations existantes
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
    
    public function category()
    {
        return $this->belongsTo(Category::class);
    }
    
    public function images()
    {
        return $this->hasMany(ReportImage::class);
    }
}
```

**Avantages de la Méthode 2** :
- ✅ Automatique : `likes_count` et `is_liked` ajoutés à **toutes** les réponses
- ✅ DRY : Pas besoin de répéter le code dans chaque controller
- ✅ Maintenable : Une seule source de vérité

---

## 🧪 Tests backend requis

### Test 1 : Vérifier GET `/api/reports/{id}` avec utilisateur non connecté
```bash
curl -X GET http://localhost:8000/api/reports/4 \
  -H "Accept: application/json"
```

**Réponse attendue** :
```json
{
  "success": true,
  "data": {
    "id": 4,
    "title": "Route endommagée",
    "likes_count": 5,
    "is_liked": false,  // Non connecté = false
    ...
  }
}
```

---

### Test 2 : Vérifier GET `/api/reports/{id}` avec utilisateur connecté QUI N'A PAS liké
```bash
curl -X GET http://localhost:8000/api/reports/4 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer {token}"
```

**Réponse attendue** :
```json
{
  "success": true,
  "data": {
    "id": 4,
    "title": "Route endommagée",
    "likes_count": 5,
    "is_liked": false,  // N'a pas liké = false
    ...
  }
}
```

---

### Test 3 : Vérifier GET `/api/reports/{id}` avec utilisateur connecté QUI A liké
```bash
# 1. D'abord liker le signalement
curl -X POST http://localhost:8000/api/reports/4/likes \
  -H "Accept: application/json" \
  -H "Authorization: Bearer {token}"

# 2. Puis récupérer le signalement
curl -X GET http://localhost:8000/api/reports/4 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer {token}"
```

**Réponse attendue** :
```json
{
  "success": true,
  "data": {
    "id": 4,
    "title": "Route endommagée",
    "likes_count": 6,    // Incrémenté de 1
    "is_liked": true,    // ✅ Maintenant true !
    ...
  }
}
```

---

### Test 4 : Vérifier GET `/api/reports` (liste) avec likes
```bash
curl -X GET "http://localhost:8000/api/reports?page=1&per_page=15" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer {token}"
```

**Réponse attendue** :
```json
{
  "success": true,
  "data": [
    {
      "id": 4,
      "title": "Route endommagée",
      "likes_count": 6,
      "is_liked": true,
      ...
    },
    {
      "id": 3,
      "title": "Fuite d'eau",
      "likes_count": 2,
      "is_liked": false,
      ...
    }
  ],
  "pagination": { ... }
}
```

---

## 📊 Optimisation performance (optionnel mais recommandé)

Le problème de l'approche ci-dessus est qu'elle fait une requête SQL supplémentaire par signalement pour compter les likes et vérifier `is_liked`.

**Problème N+1** :
```
GET /api/reports?per_page=15
→ 1 requête pour charger 15 signalements
→ 15 requêtes pour compter likes_count (1 par signalement)
→ 15 requêtes pour vérifier is_liked (1 par signalement)
= 31 requêtes SQL au total ! ❌
```

### Solution : withCount() + leftJoin

**Fichier** : `app/Http/Controllers/Api/ReportController.php`

```php
public function index(Request $request)
{
    $userId = auth()->id();
    
    $reports = Report::with(['user', 'category', 'images'])
        ->withCount('likes') // ✅ Ajoute automatiquement 'likes_count'
        ->when($userId, function ($query) use ($userId) {
            // ✅ Ajoute 'is_liked' via LEFT JOIN (1 seule requête)
            $query->leftJoin('likes', function ($join) use ($userId) {
                $join->on('reports.id', '=', 'likes.report_id')
                     ->where('likes.user_id', '=', $userId);
            })
            ->addSelect([
                'reports.*',
                'likes.id as user_like_id'
            ]);
        })
        ->latest()
        ->paginate($request->input('per_page', 15));
    
    // Transformer 'user_like_id' en booléen 'is_liked'
    $reports->getCollection()->transform(function ($report) {
        $report->is_liked = !is_null($report->user_like_id ?? null);
        unset($report->user_like_id); // Nettoyer
        return $report;
    });
    
    return response()->json([
        'success' => true,
        'data' => $reports->items(),
        'pagination' => [
            'current_page' => $reports->currentPage(),
            'last_page' => $reports->lastPage(),
            'per_page' => $reports->perPage(),
            'total' => $reports->total(),
        ],
    ]);
}
```

**Résultat** :
```
GET /api/reports?per_page=15
→ 1 requête pour charger 15 signalements + likes_count + is_liked
= 1 requête SQL au total ! ✅
```

---

## 🚀 Déploiement

### Étapes après modification backend

1. **Tester les endpoints avec Postman** :
   - GET `/api/reports/4` → Vérifier `likes_count` et `is_liked`
   - GET `/api/reports` → Vérifier sur tous les signalements

2. **Vérifier les tests unitaires Laravel** :
   ```bash
   php artisan test --filter=ReportTest
   ```

3. **Hot reload de l'application mobile** :
   - Pas de modification mobile nécessaire
   - Le `ReportModel` a déjà les champs `likesCount` et `isLiked`
   - Ils seront automatiquement remplis par le backend

4. **Tester end-to-end** :
   - Liker un signalement
   - Fermer l'application
   - Rouvrir l'application
   - Vérifier que le like est toujours affiché ✅

---

## ✅ Checklist validation

- [ ] Backend modifié (Méthode 1 OU Méthode 2)
- [ ] Test 1 passé (utilisateur non connecté)
- [ ] Test 2 passé (utilisateur connecté, pas liké)
- [ ] Test 3 passé (utilisateur connecté, liké)
- [ ] Test 4 passé (liste avec likes)
- [ ] Optimisation N+1 appliquée (optionnel)
- [ ] Tests unitaires Laravel passés
- [ ] Application mobile testée (hot reload)

---

## 📝 Impact sur le mobile

**Aucune modification mobile requise** ! 🎉

Le `ReportModel` a déjà les champs :
```dart
@freezed
class ReportModel with _$ReportModel {
  const factory ReportModel({
    required int id,
    required String title,
    required String description,
    @Default(0) int likesCount,        // ✅ Déjà défini
    @Default(false) bool isLiked,      // ✅ Déjà défini
    ...
  }) = _ReportModel;
}
```

Une fois le backend corrigé, ces champs seront automatiquement remplis par la désérialisation JSON.

---

## 🔗 Fichiers backend concernés

1. `app/Models/Report.php` - Ajouter accessors `likes_count` et `is_liked`
2. `app/Http/Controllers/Api/ReportController.php` - Méthodes `show()` et `index()`
3. `tests/Feature/ReportTest.php` - Ajouter tests pour vérifier les nouveaux champs

---

**Priorité** : 🔴 HAUTE - Cette modification est nécessaire pour que le système de likes fonctionne correctement.

**Temps estimé** : 30 minutes (Méthode 2 avec accessors)
