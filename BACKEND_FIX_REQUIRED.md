# 🔧 Corrections Backend Requises

## Problème identifié

Lorsqu'un utilisateur se connecte et accède à la liste des signalements, **aucun signalement n'est affiché** car le backend Laravel filtre automatiquement par `user_id` même quand ce paramètre n'est pas fourni dans la requête.

## Comportement actuel (incorrect)

```php
GET /api/reports
// Retourne uniquement les signalements de l'utilisateur connecté
```

## Comportement attendu (correct)

```php
GET /api/reports
// Doit retourner TOUS les signalements de tous les utilisateurs

GET /api/reports?user_id=10
// Doit retourner uniquement les signalements de l'utilisateur 10
```

## Solution Backend Laravel

Dans votre `ReportController` ou `ReportRepository`, il faut conditionner le filtre par `user_id` :

### ❌ Code actuel (probablement)
```php
public function index(Request $request)
{
    $query = Report::with(['user', 'category', 'images']);
    
    // ❌ INCORRECT : Filtre toujours par user authentifié
    $query->where('user_id', auth()->id());
    
    return $query->paginate($request->input('per_page', 15));
}
```

### ✅ Code corrigé
```php
public function index(Request $request)
{
    $query = Report::with(['user', 'category', 'images']);
    
    // ✅ CORRECT : Filtre uniquement si user_id est fourni en paramètre
    if ($request->has('user_id')) {
        $query->where('user_id', $request->input('user_id'));
    }
    
    // Autres filtres optionnels
    if ($request->has('status')) {
        $query->where('status', $request->input('status'));
    }
    
    if ($request->has('category_id')) {
        $query->where('category_id', $request->input('category_id'));
    }
    
    return $query->orderBy('created_at', 'desc')
                 ->paginate($request->input('per_page', 15));
}
```

## Format de réponse attendu

Le backend doit renvoyer une pagination Laravel standard :

```json
{
  "success": true,
  "message": "Signalements récupérés avec succès",
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "title": "Route dégradée",
        "description": "La route...",
        "status": "pending",
        "latitude": 14.739909,
        "longitude": -17.4643129,
        "user_id": 10,
        "category_id": 1,
        "likes_count": 5,
        "is_liked": false,
        "user": {
          "id": 10,
          "nom": "Offinobi",
          "prenom": "Noe"
        },
        "category": {
          "id": 1,
          "name": "Routes & Chaussées"
        },
        "images": [
          {
            "id": 1,
            "image_url": "http://192.168.1.17:8000/storage/reports/xxx.jpg"
          }
        ]
      }
    ],
    "first_page_url": "http://...",
    "from": 1,
    "last_page": 3,
    "last_page_url": "http://...",
    "next_page_url": "http://...",
    "path": "http://...",
    "per_page": 15,
    "prev_page_url": null,
    "to": 15,
    "total": 45
  }
}
```

## Fonctionnalité suppression

Le backend doit autoriser la suppression **UNIQUEMENT** si :
1. L'utilisateur est authentifié
2. L'utilisateur est le créateur du signalement (`user_id` correspond)

### Policy Laravel (recommandée)

Créer une Policy `ReportPolicy` :

```php
php artisan make:policy ReportPolicy --model=Report
```

Dans `app/Policies/ReportPolicy.php` :
```php
public function delete(User $user, Report $report)
{
    // Seul le créateur peut supprimer
    return $user->id === $report->user_id;
}
```

Dans `ReportController` :
```php
public function destroy(Request $request, Report $report)
{
    // Vérifier l'autorisation
    $this->authorize('delete', $report);
    
    // Supprimer les images associées du storage
    foreach ($report->images as $image) {
        Storage::delete($image->image_path);
        $image->delete();
    }
    
    // Supprimer le signalement
    $report->delete();
    
    return response()->json([
        'success' => true,
        'message' => 'Signalement supprimé avec succès',
    ]);
}
```

## Test de l'API

### 1. Tester la liste complète (sans filtre)
```bash
curl -H "Authorization: Bearer {token}" \
     http://192.168.1.17:8000/api/reports
# Doit retourner TOUS les signalements
```

### 2. Tester le filtre par utilisateur
```bash
curl -H "Authorization: Bearer {token}" \
     http://192.168.1.17:8000/api/reports?user_id=10
# Doit retourner uniquement les signalements de l'utilisateur 10
```

### 3. Tester la suppression (autorisée)
```bash
curl -X DELETE \
     -H "Authorization: Bearer {token_createur}" \
     http://192.168.1.17:8000/api/reports/1
# Doit retourner success: true
```

### 4. Tester la suppression (non autorisée)
```bash
curl -X DELETE \
     -H "Authorization: Bearer {token_autre_user}" \
     http://192.168.1.17:8000/api/reports/1
# Doit retourner 403 Forbidden
```

## Checklist

- [ ] Modifier `ReportController::index()` pour rendre le filtre `user_id` optionnel
- [ ] Créer `ReportPolicy` avec méthode `delete()`
- [ ] Enregistrer la Policy dans `AuthServiceProvider`
- [ ] Ajouter `$this->authorize('delete', $report)` dans `destroy()`
- [ ] Tester avec Postman/cURL les 4 scénarios ci-dessus
- [ ] Vérifier que la pagination fonctionne correctement
- [ ] Vérifier que les relations (user, category, images) sont eager-loadées

## Référence

Voir le fichier `spec.instructions.md` section "Backend Repository Pattern" pour plus de détails sur l'architecture attendue.
