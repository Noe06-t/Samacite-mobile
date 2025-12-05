# 🔧 Checklist Backend - Routes Likes

**Date** : 24 novembre 2025

## ❌ Problème : Route `/api/reports/{id}/like` introuvable

L'erreur montre clairement :
```
[DioService] ❌ Status Code: 404
[DioService] 🔸 Path: /reports/4/like
message: The route api/reports/4/like could not be found.
```

## ✅ Vérifications à faire dans le backend Laravel

### 1. Vérifier le fichier `routes/api.php`

Ouvrez `C:\Users\HP\Desktop\Flutter_SDK\Samacite\routes\api.php` et vérifiez que ces lignes existent :

```php
Route::middleware('auth:sanctum')->group(function () {
    // ... autres routes
    
    // LIKES - À AJOUTER SI MANQUANT
    Route::post('/reports/{report}/like', [LikeController::class, 'store']);
    Route::delete('/reports/{report}/like', [LikeController::class, 'destroy']);
});
```

### 2. Vérifier que le controller existe

```bash
php artisan route:list | findstr "like"
```

Cette commande devrait afficher :
```
POST      api/reports/{report}/like ........ LikeController@store
DELETE    api/reports/{report}/like ........ LikeController@destroy
```

### 3. Si les routes n'existent PAS

Créez le controller :
```bash
php artisan make:controller Api/LikeController
```

Puis copiez le code depuis `BACKEND_LIKES_TODO.md` lignes 159-218.

### 4. Créer la migration `likes`

```bash
php artisan make:migration create_likes_table
```

Contenu :
```php
Schema::create('likes', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->foreignId('report_id')->constrained()->onDelete('cascade');
    $table->timestamps();
    
    $table->unique(['user_id', 'report_id']);
});
```

Puis :
```bash
php artisan migrate
```

### 5. Créer le modèle `Like.php`

```bash
php artisan make:model Like
```

Contenu :
```php
<?php

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

### 6. Ajouter la relation dans `Report.php`

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

## 🧪 Tests à effectuer

Une fois les routes ajoutées :

### Test 1 : POST Like
```bash
curl -X POST http://localhost:8000/api/reports/4/like \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Accept: application/json"
```

Réponse attendue :
```json
{
  "success": true,
  "message": "Signalement liké",
  "likes_count": 1
}
```

### Test 2 : DELETE Like
```bash
curl -X DELETE http://localhost:8000/api/reports/4/like \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Accept: application/json"
```

Réponse attendue :
```json
{
  "success": true,
  "message": "Like retiré",
  "likes_count": 0
}
```

## 📍 Fichiers à créer/modifier

1. ✅ `routes/api.php` - Ajouter 2 routes
2. ✅ `app/Http/Controllers/Api/LikeController.php` - Créer
3. ✅ `database/migrations/xxxx_create_likes_table.php` - Créer
4. ✅ `app/Models/Like.php` - Créer
5. ✅ `app/Models/Report.php` - Ajouter méthode `likes()`

## 🎯 Après implémentation

1. Redémarrer le serveur Laravel :
```bash
php artisan serve
```

2. Vérifier les routes :
```bash
php artisan route:list | findstr "like"
```

3. Tester avec Postman/curl

4. Relancer l'app mobile Flutter

---

**Référence** : Voir `BACKEND_LIKES_TODO.md` pour le code complet
