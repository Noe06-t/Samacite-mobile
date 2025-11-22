# 🔧 Modification Backend Laravel pour Support Téléphone

## ✅ Problème identifié
L'application Flutter envoie correctement `{telephone: "776891042", password: "..."}` mais le backend Laravel ne gère pas ce champ.

## 📝 Fichier à modifier : `app/Http/Controllers/AuthController.php`

### Code actuel (ne gère que l'email) :
```php
public function login(Request $request)
{
    $credentials = $request->validate([
        'email' => 'required|email',
        'password' => 'required|string'
    ]);

    if (!Auth::attempt($credentials)) {
        return response()->json([
            'success' => false,
            'message' => 'Identifiants invalides'
        ], 401);
    }

    // ... reste du code
}
```

### ✅ Code à utiliser (supporte email OU téléphone) :
```php
public function login(Request $request)
{
    // Validation flexible : email OU téléphone
    $validated = $request->validate([
        'email' => 'nullable|email',
        'telephone' => 'nullable|string',
        'password' => 'required|string'
    ]);

    // Vérifier qu'au moins un identifiant est fourni
    if (!$request->has('email') && !$request->has('telephone')) {
        return response()->json([
            'success' => false,
            'message' => 'Email ou téléphone requis'
        ], 422);
    }

    // Construire les credentials selon le champ fourni
    $credentials = ['password' => $validated['password']];
    
    if ($request->has('email') && !empty($request->email)) {
        $credentials['email'] = $validated['email'];
    } elseif ($request->has('telephone') && !empty($request->telephone)) {
        $credentials['telephone'] = $validated['telephone'];
    }

    // Tentative d'authentification
    if (!Auth::attempt($credentials)) {
        return response()->json([
            'success' => false,
            'message' => 'Identifiants invalides'
        ], 401);
    }

    $user = Auth::user();
    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'success' => true,
        'message' => 'Connecté avec succès',
        'data' => [
            'user' => $user,
            'token' => $token
        ]
    ], 200);
}
```

## 🔍 Vérification Migration
Assurez-vous que la table `users` a bien la colonne `telephone` :

```php
// Dans la migration create_users_table.php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('nom');
    $table->string('prenom');
    $table->string('email')->nullable()->unique();
    $table->string('telephone')->unique(); // REQUIS
    $table->string('password');
    $table->timestamps();
});
```

## 📋 Étapes à suivre

1. **Ouvrir** `app/Http/Controllers/AuthController.php`
2. **Remplacer** la méthode `login()` par le code ci-dessus
3. **Vérifier** que la colonne `telephone` existe dans la migration
4. **Redémarrer** le serveur Laravel si nécessaire :
   ```bash
   php artisan serve
   ```

## ✅ Test après modification

Depuis l'app Flutter, tester :
- ✅ Connexion avec email : `noe@samacite.sn` / `password123`
- ✅ Connexion avec téléphone : `776891042` / `password123`

Les deux méthodes doivent fonctionner !

---

## 📌 Note importante
L'application Flutter envoie déjà les bonnes requêtes :
- Si email détecté → `{email: "...", password: "..."}`
- Si téléphone détecté → `{telephone: "...", password: "..."}`

Il suffit juste d'adapter le backend Laravel pour accepter les deux formats.
