# 🔧 Backend Laravel - Implémentation Profile (Phase 4)

## ⚠️ ENDPOINTS MANQUANTS

L'application mobile Flutter **attend les endpoints suivants** (définis dans spec.md Phase 4) :

```
GET    /api/user/profile          # Récupérer profil utilisateur connecté
PUT    /api/user/profile          # Modifier profil (nom, prenom, email, telephone)
POST   /api/user/profile/photo    # Upload photo de profil
PUT    /api/user/password         # Changer mot de passe
```

---

## 📁 Fichiers Backend à créer/modifier

### 1️⃣ Route API (`routes/api.php`)

Ajouter dans le groupe middleware `auth:sanctum` :

```php
// routes/api.php

Route::middleware('auth:sanctum')->group(function () {
    // ... routes existantes (reports, categories, etc.)

    // ✨ NOUVEAUX ENDPOINTS PROFILE (Phase 4)
    Route::prefix('user')->group(function () {
        Route::get('/profile', [ProfileController::class, 'show']);
        Route::put('/profile', [ProfileController::class, 'update']);
        Route::post('/profile/photo', [ProfileController::class, 'uploadPhoto']);
        Route::put('/password', [ProfileController::class, 'changePassword']);
    });
});
```

---

### 2️⃣ Controller Profile (`app/Http/Controllers/ProfileController.php`)

**Créer ce fichier** :

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rules\Password;

class ProfileController extends Controller
{
    /**
     * GET /api/user/profile
     * Récupérer le profil de l'utilisateur connecté
     */
    public function show(Request $request)
    {
        $user = Auth::user();

        return response()->json([
            'success' => true,
            'message' => 'Profil récupéré avec succès',
            'data' => [
                'id' => $user->id,
                'nom' => $user->nom,
                'prenom' => $user->prenom,
                'email' => $user->email,
                'telephone' => $user->telephone,
                'photo_url' => $user->photo_url ?? null, // URL photo si existe
                'created_at' => $user->created_at->toISOString(),
                'updated_at' => $user->updated_at->toISOString(),
            ]
        ], 200);
    }

    /**
     * PUT /api/user/profile
     * Modifier le profil (nom, prenom, email, telephone)
     */
    public function update(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'nom' => 'sometimes|required|string|max:255',
            'prenom' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|nullable|email|unique:users,email,' . $user->id,
            'telephone' => 'sometimes|required|string|unique:users,telephone,' . $user->id,
        ]);

        $user->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Profil mis à jour avec succès',
            'data' => [
                'id' => $user->id,
                'nom' => $user->nom,
                'prenom' => $user->prenom,
                'email' => $user->email,
                'telephone' => $user->telephone,
                'photo_url' => $user->photo_url ?? null,
                'created_at' => $user->created_at->toISOString(),
                'updated_at' => $user->updated_at->toISOString(),
            ]
        ], 200);
    }

    /**
     * POST /api/user/profile/photo
     * Upload/changer photo de profil
     */
    public function uploadPhoto(Request $request)
    {
        $request->validate([
            'photo' => 'required|image|mimes:jpeg,jpg,png|max:2048', // Max 2MB
        ]);

        $user = Auth::user();

        // Supprimer ancienne photo si existe
        if ($user->photo_url && Storage::disk('public')->exists($user->photo_url)) {
            Storage::disk('public')->delete($user->photo_url);
        }

        // Sauvegarder nouvelle photo
        $path = $request->file('photo')->store('profile_photos', 'public');

        $user->update([
            'photo_url' => $path,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Photo de profil mise à jour avec succès',
            'data' => [
                'photo_url' => Storage::url($path), // URL complète
            ]
        ], 200);
    }

    /**
     * PUT /api/user/password
     * Changer le mot de passe
     */
    public function changePassword(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'current_password' => 'required|string',
            'new_password' => ['required', 'string', 'confirmed', Password::min(8)],
            // 'new_password_confirmation' => 'required' (géré par 'confirmed')
        ]);

        // Vérifier que le mot de passe actuel est correct
        if (!Hash::check($validated['current_password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Le mot de passe actuel est incorrect',
            ], 400);
        }

        // Mettre à jour le mot de passe
        $user->update([
            'password' => Hash::make($validated['new_password']),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Mot de passe modifié avec succès',
        ], 200);
    }
}
```

---

### 3️⃣ Migration - Ajouter colonne `photo_url` à la table `users`

**Si la colonne n'existe pas encore**, créer une migration :

```bash
php artisan make:migration add_photo_url_to_users_table --table=users
```

**Contenu du fichier de migration** :

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('photo_url')->nullable()->after('telephone');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('photo_url');
        });
    }
};
```

**Exécuter la migration** :

```bash
php artisan migrate
```

---

### 4️⃣ Model User (`app/Models/User.php`)

**Ajouter `photo_url` dans `$fillable`** :

```php
<?php

namespace App\Models;

// ... autres imports

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'nom',
        'prenom',
        'email',
        'telephone',
        'password',
        'photo_url', // ✨ AJOUTER
    ];

    // ... reste du code
}
```

---

### 5️⃣ Configuration Storage (si pas déjà fait)

**Créer le lien symbolique** pour accéder aux fichiers publics :

```bash
php artisan storage:link
```

Cela créé un lien : `public/storage` → `storage/app/public`

Les photos seront accessibles via : `http://192.168.1.17:8000/storage/profile_photos/xxxxx.jpg`

---

## ✅ Tests après implémentation

### Test 1 : GET /api/user/profile

**Requête** :
```bash
curl -X GET http://192.168.1.17:8000/api/user/profile \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json"
```

**Réponse attendue** :
```json
{
  "success": true,
  "message": "Profil récupéré avec succès",
  "data": {
    "id": 1,
    "nom": "Sall",
    "prenom": "Noé",
    "email": "noe@samacite.sn",
    "telephone": "776891042",
    "photo_url": null,
    "created_at": "2024-11-27T10:30:00.000000Z",
    "updated_at": "2024-11-27T10:30:00.000000Z"
  }
}
```

---

### Test 2 : PUT /api/user/profile

**Requête** :
```bash
curl -X PUT http://192.168.1.17:8000/api/user/profile \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Sall",
    "prenom": "Noé Emmanuel",
    "email": "noe.updated@samacite.sn"
  }'
```

**Réponse attendue** : 200 avec data mise à jour

---

### Test 3 : POST /api/user/profile/photo

**Requête** (avec Postman ou cURL) :
```bash
curl -X POST http://192.168.1.17:8000/api/user/profile/photo \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json" \
  -F "photo=@/path/to/photo.jpg"
```

**Réponse attendue** :
```json
{
  "success": true,
  "message": "Photo de profil mise à jour avec succès",
  "data": {
    "photo_url": "http://192.168.1.17:8000/storage/profile_photos/xxxxx.jpg"
  }
}
```

---

### Test 4 : PUT /api/user/password

**Requête** :
```bash
curl -X PUT http://192.168.1.17:8000/api/user/password \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "password123",
    "new_password": "newpassword123",
    "new_password_confirmation": "newpassword123"
  }'
```

**Réponse attendue** :
```json
{
  "success": true,
  "message": "Mot de passe modifié avec succès"
}
```

---

## 📋 Checklist Backend

Avant de tester l'app Flutter :

- [ ] ✅ Route `GET /api/user/profile` ajoutée
- [ ] ✅ Route `PUT /api/user/profile` ajoutée
- [ ] ✅ Route `POST /api/user/profile/photo` ajoutée
- [ ] ✅ Route `PUT /api/user/password` ajoutée
- [ ] ✅ `ProfileController.php` créé avec les 4 méthodes
- [ ] ✅ Migration `photo_url` exécutée (`php artisan migrate`)
- [ ] ✅ `User` model : `photo_url` dans `$fillable`
- [ ] ✅ Storage link créé (`php artisan storage:link`)
- [ ] ✅ Testé avec cURL/Postman : tous les endpoints répondent 200

---

## 🚀 Après implémentation

Une fois ces endpoints créés, l'app Flutter pourra :

1. **Afficher le profil** automatiquement (ProfilePage)
2. **Modifier les infos** (EditProfilePage - à créer Flutter)
3. **Upload photo** avec cropping (image_picker + image_cropper)
4. **Changer le mot de passe** (ChangePasswordPage - à créer Flutter)

---

## 📌 Notes importantes

### Format JSON attendu

Le backend **DOIT** suivre ce format de réponse pour être compatible avec le `UserModel` Flutter :

```dart
// Flutter UserModel attend :
{
  "id": int,
  "nom": String,
  "prenom": String,
  "email": String?, // optionnel
  "telephone": String,
  "created_at": String, // ISO 8601
  "updated_at": String, // ISO 8601
}
```

### Sécurité

- ✅ Routes protégées par `auth:sanctum`
- ✅ Validation des données entrantes
- ✅ Vérification mot de passe actuel avant changement
- ✅ Hash des mots de passe avec `Hash::make()`
- ✅ Validation taille photo (max 2MB)
- ✅ Nettoyage ancienne photo lors upload

---

## 🔗 Références

- **Spécifications** : `spec.md` - Phase 4 Profile
- **ROADMAP Mobile** : `ROADMAP.md` - Phase 4 ligne 472
- **Structure Flutter** : `lib/features/profile/`

---

**Une fois le backend implémenté, relancer l'app Flutter et cliquer sur l'icône Profile dans l'AppBar. Le profil s'affichera automatiquement !** ✨
