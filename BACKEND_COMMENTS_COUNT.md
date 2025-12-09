# Modification Backend - Ajout du nombre de commentaires

## 📋 Contexte

L'application mobile affiche maintenant le nombre de commentaires pour chaque signalement. Le modèle Flutter `ReportModel` a été mis à jour pour inclure le champ `commentsCount`.

## ✅ Ce qui a été fait côté mobile

```dart
// lib/core/models/report_model.dart
@JsonKey(name: 'comments_count') @Default(0) int commentsCount,
```

```dart
// lib/features/reports/pages/report_list_page.dart (ligne 355)
_buildStatBadge(
  Icons.comment,
  report.commentsCount.toString(), // ✅ Affiche maintenant le nombre réel
  const Color(0xFF007A3F),
),
```

## 🔧 Modifications requises côté Backend Laravel

### 1. Dans les ReportResource (ou ReportController)

Ajouter le compteur de commentaires dans la réponse API :

```php
// app/Http/Resources/ReportResource.php

public function toArray($request)
{
    return [
        'id' => $this->id,
        'title' => $this->title,
        'description' => $this->description,
        'status' => $this->status,
        'category_id' => $this->category_id,
        'user_id' => $this->user_id,
        
        // Relations
        'user' => new UserResource($this->whenLoaded('user')),
        'category' => new CategoryResource($this->whenLoaded('category')),
        'location' => new LocationResource($this->whenLoaded('location')),
        'images' => $this->images,
        
        // Compteurs
        'likes_count' => $this->likes_count ?? $this->likes()->count(),
        'is_liked' => $this->is_liked ?? false,
        'comments_count' => $this->comments_count ?? $this->comments()->count(), // ✅ AJOUTER CECI
        
        // Timestamps
        'created_at' => $this->created_at?->toISOString(),
        'updated_at' => $this->updated_at?->toISOString(),
    ];
}
```

### 2. Dans le ReportRepository (optimisation)

Pour éviter les requêtes N+1, ajouter le compteur dans les requêtes :

```php
// app/Repositories/Eloquent/EloquentReportRepository.php

public function paginateWithFilters(array $filters = [], int $perPage = 15)
{
    $query = Report::query()
        ->with(['user', 'category', 'location', 'images'])
        ->withCount(['likes', 'comments']) // ✅ AJOUTER 'comments'
        ->when($filters['status'] ?? null, fn($q, $status) => $q->where('status', $status))
        ->when($filters['category_id'] ?? null, fn($q, $id) => $q->where('category_id', $id))
        ->when($filters['user_id'] ?? null, fn($q, $id) => $q->where('user_id', $id))
        ->latest();
    
    return $query->paginate($perPage);
}

public function findWithRelations(int $id): ?Report
{
    return Report::query()
        ->with(['user', 'category', 'location', 'images'])
        ->withCount(['likes', 'comments']) // ✅ AJOUTER 'comments'
        ->find($id);
}
```

### 3. Vérifier la relation dans le modèle Report

Assurer que la relation `comments` existe :

```php
// app/Models/Report.php

public function comments()
{
    return $this->hasMany(Comment::class);
}
```

## 📡 Endpoints concernés

Ces endpoints doivent maintenant retourner `comments_count` :

- `GET /api/reports` - Liste paginée
- `GET /api/reports/{id}` - Détail d'un signalement
- `POST /api/reports` - Création (retourne le signalement créé)
- `PUT /api/reports/{id}` - Mise à jour (retourne le signalement modifié)

## 🧪 Test de l'API

### Exemple de réponse attendue

```json
{
  "success": true,
  "message": "Signalement récupéré avec succès",
  "data": {
    "id": 3,
    "title": "Dépôts d'ordures dans le marché",
    "description": "Ceci dure depuis 2 semaines...",
    "status": "En attente",
    "latitude": 14.74160680,
    "longitude": -17.46292580,
    "user_id": 6,
    "category_id": 4,
    "likes_count": 2,
    "is_liked": true,
    "comments_count": 5,  // ✅ CE CHAMP DOIT ÊTRE PRÉSENT
    "user": { ... },
    "category": { ... },
    "images": [ ... ],
    "created_at": "2025-12-07T16:45:27.000000Z",
    "updated_at": "2025-12-07T16:53:31.000000Z"
  }
}
```

## ⚡ Performance

L'utilisation de `withCount(['comments'])` génère une seule requête optimisée :

```sql
SELECT reports.*, 
       (SELECT COUNT(*) FROM comments WHERE comments.report_id = reports.id) as comments_count
FROM reports
```

Au lieu de N requêtes séparées pour chaque signalement.

## ✅ Checklist Backend

- [x] Ajouter `comments_count` dans `ReportResource` ✅ **FAIT**
- [x] Ajouter `->withCount(['comments'])` dans les requêtes du repository ✅ **FAIT**
- [x] Vérifier que la relation `comments()` existe dans le modèle `Report` ✅ **FAIT**
- [x] Tester l'endpoint `GET /api/reports` ✅ **FAIT**
- [x] Tester l'endpoint `GET /api/reports/{id}` ✅ **FAIT**
- [ ] Vérifier que le compteur s'incrémente lors de l'ajout d'un commentaire
- [ ] Vérifier que le compteur se décrémente lors de la suppression d'un commentaire

## 🎉 Statut de l'implémentation

### Backend : ✅ TERMINÉ (09/12/2025)

Le champ `comments_count` est maintenant retourné automatiquement dans tous les endpoints :

- ✅ `GET /api/reports` - Liste paginée
- ✅ `GET /api/reports/{id}` - Détail d'un signalement
- ✅ `POST /api/reports` - Création (retourne le signalement créé)
- ✅ `PUT /api/reports/{id}` - Mise à jour (retourne le signalement modifié)

### Frontend : ✅ PRÊT

Le modèle Flutter est déjà configuré pour recevoir et afficher le compteur :
- Champ `commentsCount` ajouté au `ReportModel`
- Badge de commentaires dans la liste des signalements
- Synchronisation automatique avec l'API

## 🔗 Relation avec d'autres fonctionnalités

Le compteur de commentaires fonctionne de la même manière que `likes_count` qui est déjà implémenté. Suivre le même pattern pour la cohérence.

---

**Date de création** : 09/12/2025  
**Date d'implémentation backend** : 09/12/2025 ✅  
**Priorité** : Moyenne (fonctionnalité UI)  
**Statut** : ✅ **IMPLÉMENTÉ ET FONCTIONNEL**
