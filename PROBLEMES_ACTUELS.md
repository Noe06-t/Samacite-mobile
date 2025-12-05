# 🚨 Problèmes Actuels - Mobile SamaCité

**Date** : 24 novembre 2025  
**Status** : ⚠️ 2 problèmes identifiés

---

## 1. ❌ LIKES - Route backend 404

### Symptôme
```
[DioService] ❌ Status Code: 404
[DioService] 🔸 Path: /reports/4/like
message: The route api/reports/4/like could not be found.
```

### Cause
**Les routes backend Laravel pour les likes n'existent PAS.**

### Solution Backend Laravel

Vous DEVEZ implémenter côté backend (dossier `C:\Users\HP\Desktop\Flutter_SDK\Samacite`) :

#### Étape 1 : Ajouter les routes dans `routes/api.php`

```php
Route::middleware('auth:sanctum')->group(function () {
    // ... routes existantes
    
    // ✅ AJOUTER CES ROUTES
    Route::post('/reports/{report}/like', [LikeController::class, 'store']);
    Route::delete('/reports/{report}/like', [LikeController::class, 'destroy']);
});
```

N'oubliez pas l'import en haut du fichier :
```php
use App\Http\Controllers\Api\LikeController;
```

#### Étape 2 : Créer le controller

```bash
cd C:\Users\HP\Desktop\Flutter_SDK\Samacite
php artisan make:controller Api/LikeController
```

Contenu du controller (fichier `app/Http/Controllers/Api/LikeController.php`) :

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Report;

class LikeController extends Controller
{
    /**
     * Liker un signalement
     */
    public function store(Report $report)
    {
        $user = auth()->user();
        
        // Vérifier si déjà liké
        if ($report->likes()->where('user_id', $user->id)->exists()) {
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

#### Étape 3 : Créer la table `likes`

```bash
php artisan make:migration create_likes_table
```

Contenu de la migration :

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('likes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('report_id')->constrained()->onDelete('cascade');
            $table->timestamps();
            
            // Un user ne peut liker qu'une fois un signalement
            $table->unique(['user_id', 'report_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('likes');
    }
};
```

Puis exécuter :
```bash
php artisan migrate
```

#### Étape 4 : Créer le modèle `Like`

```bash
php artisan make:model Like
```

Contenu du modèle (`app/Models/Like.php`) :

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

#### Étape 5 : Ajouter la relation dans `Report.php`

Dans le fichier `app/Models/Report.php`, ajoutez :

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

#### Étape 6 : Vérifier que tout fonctionne

```bash
# Vérifier les routes
php artisan route:list | findstr "like"

# Résultat attendu :
POST      api/reports/{report}/like ........ LikeController@store
DELETE    api/reports/{report}/like ........ LikeController@destroy

# Redémarrer le serveur
php artisan serve
```

### Côté Mobile Flutter
✅ **Rien à faire** - Le mobile est déjà prêt !

---

## 2. ⚠️ CARTE - Tuiles OpenStreetMap ne se chargent pas

### Symptôme
```
ClientException with SocketException: Connection attempt cancelled, 
host: tile.openstreetmap.org, port: 443
```

### Cause Possible
- Émulateur Android bloque les connexions HTTPS externes
- OpenStreetMap peut avoir des restrictions sur les émulateurs
- Problème de certificats SSL

### Solution 1 : Attendre et retry (déjà implémenté)
La MapPage charge correctement même si les tuiles ne s'affichent pas. Les marqueurs devraient s'afficher.

### Solution 2 : Tester sur device physique
L'émulateur a parfois des restrictions réseau. Sur un vrai téléphone, OpenStreetMap fonctionne généralement mieux.

### Solution 3 : Alternative - Utiliser Mapbox (nécessite clé API)
Si OpenStreetMap ne fonctionne pas, on peut utiliser Mapbox :

```dart
TileLayer(
  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}',
  additionalOptions: {
    'accessToken': 'VOTRE_CLE_MAPBOX',
  },
),
```

### Statut actuel
⚠️ Les marqueurs devraient s'afficher même sans les tuiles. Vérifiez dans l'onglet "Carte".

---

## ✅ Ce qui fonctionne déjà

1. ✅ Liste des signalements (2 reports chargés)
2. ✅ Navigation vers page détail
3. ✅ Commentaires
4. ✅ Import MapPage corrigé
5. ✅ LikeRepository corrigé (format réponse)

---

## 📝 Actions prioritaires

### URGENT - Backend Laravel

1. [ ] Ouvrir le projet backend : `C:\Users\HP\Desktop\Flutter_SDK\Samacite`
2. [ ] Ajouter les routes dans `routes/api.php`
3. [ ] Créer `LikeController.php`
4. [ ] Créer la migration `likes`
5. [ ] Exécuter `php artisan migrate`
6. [ ] Créer le modèle `Like.php`
7. [ ] Modifier `Report.php` (ajouter `likes()`)
8. [ ] Tester avec `curl` ou Postman
9. [ ] Redémarrer `php artisan serve`

### Mobile Flutter

1. [ ] Hot restart après implémentation backend : `r` dans le terminal Flutter
2. [ ] Tester les likes sur un signalement
3. [ ] Vérifier si la carte affiche au moins les marqueurs (même sans tuiles)

---

## 🧪 Tests après correction

### Test Likes
1. Ouvrir un signalement dans l'app
2. Cliquer sur le bouton ❤️
3. Vérifier le compteur s'incrémente
4. Vérifier le SnackBar "Vous aimez ce signalement"
5. Re-cliquer → Compteur décrémente

### Test Carte
1. Aller sur l'onglet "Carte" (🗺️)
2. Vérifier que les marqueurs colorés apparaissent
3. Cliquer sur un marqueur → Navigation vers détail

---

**Références** :
- `BACKEND_LIKES_TODO.md` - Documentation complète backend
- `BACKEND_CHECKLIST_LIKES.md` - Checklist étape par étape
- `BUGFIX_LIKES_CARTE.md` - Corrections mobile effectuées
