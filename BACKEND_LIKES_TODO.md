# ⚠️ Backend Manquant - Système de Likes

## Problème constaté

**Date** : 24 novembre 2025  
**Status** : ❌ BLOQUANT pour la fonctionnalité Likes

### Erreur observée

```
[DioService] ❌ Status Code: 404
[DioService] 🔸 Path: /reports/4/like
[DioService] 🔸 Message: The route api/reports/4/like could not be found.
```

## Routes Backend à implémenter

### 1. Route POST - Créer un Like
```php
POST /api/reports/{id}/like
```

**Controller Laravel** : `LikeController@store`

**Logique** :
- Vérifier que l'utilisateur est authentifié (middleware `auth:sanctum`)
- Vérifier que le signalement existe
- Vérifier que l'utilisateur n'a pas déjà liké (unicité : user_id + report_id)
- Créer le like
- Retourner le nouveau compteur de likes

**Réponse attendue** :
```json
{
  "success": true,
  "message": "Signalement liké",
  "likes_count": 5
}
```

### 2. Route DELETE - Supprimer un Like
```php
DELETE /api/reports/{id}/like
```

**Controller Laravel** : `LikeController@destroy`

**Logique** :
- Vérifier que l'utilisateur est authentifié
- Trouver le like (where user_id = auth()->id() AND report_id = {id})
- Supprimer le like
- Retourner le nouveau compteur de likes

**Réponse attendue** :
```json
{
  "success": true,
  "message": "Like retiré",
  "likes_count": 4
}
```

## Modifications des endpoints existants

### GET /api/reports

Ajouter dans la réponse JSON pour chaque signalement :

```json
{
  "id": 1,
  "title": "...",
  "likes_count": 5,
  "is_liked": true
}
```

**Implémentation Laravel** :

```php
// Dans ReportResource.php
public function toArray($request)
{
    return [
        'id' => $this->id,
        'title' => $this->title,
        // ... autres champs
        'likes_count' => $this->likes()->count(),
        'is_liked' => $this->likes()
            ->where('user_id', auth()->id())
            ->exists(),
    ];
}
```

### GET /api/reports/{id}

Même ajout de `likes_count` et `is_liked`.

## Migrations Laravel nécessaires

### Table `likes`

```php
Schema::create('likes', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->foreignId('report_id')->constrained()->onDelete('cascade');
    $table->timestamps();
    
    // Contrainte unicité : un user ne peut liker qu'une fois
    $table->unique(['user_id', 'report_id']);
});
```

## Modèle Laravel

### Like.php

```php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Like extends Model
{
    protected $fillable = ['user_id', 'report_id'];
    
    public function user()
    {
        return $this->belongsTo(User::class);
    }
    
    public function report()
    {
        return $this->belongsTo(Report::class);
    }
}
```

### Ajouter dans Report.php

```php
public function likes()
{
    return $this->hasMany(Like::class);
}

public function isLikedBy(User $user)
{
    return $this->likes()->where('user_id', $user->id)->exists();
}
```

## Routes Laravel (api.php)

```php
Route::middleware('auth:sanctum')->group(function () {
    // Likes
    Route::post('/reports/{report}/like', [LikeController::class, 'store']);
    Route::delete('/reports/{report}/like', [LikeController::class, 'destroy']);
});
```

## Controller Laravel complet

```php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Report;
use Illuminate\Http\Request;

class LikeController extends Controller
{
    /**
     * Liker un signalement
     */
    public function store(Report $report)
    {
        $user = auth()->user();
        
        // Vérifier si déjà liké
        if ($report->isLikedBy($user)) {
            return response()->json([
                'success' => false,
                'message' => 'Vous avez déjà liké ce signalement',
                'likes_count' => $report->likes()->count(),
            ], 400);
        }
        
        // Créer le like
        $report->likes()->create([
            'user_id' => $user->id,
        ]);
        
        return response()->json([
            'success' => true,
            'message' => 'Signalement liké',
            'likes_count' => $report->likes()->count(),
        ], 201);
    }
    
    /**
     * Retirer un like
     */
    public function destroy(Report $report)
    {
        $user = auth()->user();
        
        // Trouver et supprimer le like
        $like = $report->likes()->where('user_id', $user->id)->first();
        
        if (!$like) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'avez pas liké ce signalement',
                'likes_count' => $report->likes()->count(),
            ], 400);
        }
        
        $like->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Like retiré',
            'likes_count' => $report->likes()->count(),
        ], 200);
    }
}
```

## Tests à effectuer côté backend

1. ✅ Créer un like (POST)
2. ✅ Empêcher double like
3. ✅ Supprimer un like (DELETE)
4. ✅ Vérifier compteur likes_count
5. ✅ Vérifier champ is_liked pour user connecté
6. ✅ Tester avec Postman/Insomnia

## État actuel Mobile (Flutter)

✅ **Mobile prêt** :
- LikeRepository implémenté
- Widget _LikeButton fonctionnel
- Gestion optimiste UI
- Gestion erreurs

❌ **Backend manquant** : Routes 404

## Actions requises

**Côté Backend Laravel** :
1. [ ] Créer migration `likes`
2. [ ] Créer modèle `Like.php`
3. [ ] Ajouter relation dans `Report.php`
4. [ ] Créer `LikeController`
5. [ ] Ajouter routes API
6. [ ] Modifier `ReportResource` (likes_count, is_liked)
7. [ ] Tester avec Postman

**Côté Mobile Flutter** :
- ✅ Rien à faire, déjà implémenté

---

**Dernière mise à jour** : 24 novembre 2025
