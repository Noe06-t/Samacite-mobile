# 🔧 FIX BACKEND - Filtres Status Non Appliqués

## 🚨 Problème Détecté

Le mobile envoie correctement les filtres :
```
Query Parameters: {
  page: 1,
  per_page: 15,
  filter[status]: En attente,  ← Bien envoyé
  include: user,category,images
}
```

**Mais** le backend renvoie toujours les mêmes 4 signalements (tous "En attente") peu importe le filtre demandé ("Résolu", "En cours", etc.).

## 📝 Solution Laravel

### 1. Vérifier `app/Repositories/Eloquent/EloquentReportRepository.php`

Le repository doit avoir une méthode `paginateWithFilters()` qui applique réellement les filtres :

```php
<?php

namespace App\Repositories\Eloquent;

use App\Models\Report;
use App\Repositories\ReportRepositoryInterface;
use Illuminate\Pagination\LengthAwarePaginator;

class EloquentReportRepository implements ReportRepositoryInterface
{
    public function paginateWithFilters(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = Report::query();
        
        // 🔥 IMPORTANT : Appliquer le filtre status
        if (isset($filters['status']) && !empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }
        
        // Filtre catégorie
        if (isset($filters['category_id']) && !empty($filters['category_id'])) {
            $query->where('category_id', $filters['category_id']);
        }
        
        // Filtre utilisateur (pour "Mes signalements")
        if (isset($filters['user_id']) && !empty($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }
        
        // Recherche textuelle
        if (isset($filters['search']) && !empty($filters['search'])) {
            $searchTerm = $filters['search'];
            $query->where(function($q) use ($searchTerm) {
                $q->where('title', 'LIKE', "%{$searchTerm}%")
                  ->orWhere('description', 'LIKE', "%{$searchTerm}%");
            });
        }
        
        // Filtre par dates
        if (isset($filters['start_date']) && !empty($filters['start_date'])) {
            $query->whereDate('created_at', '>=', $filters['start_date']);
        }
        if (isset($filters['end_date']) && !empty($filters['end_date'])) {
            $query->whereDate('created_at', '<=', $filters['end_date']);
        }
        
        // Eager-loading (éviter N+1)
        $query->with(['user', 'category', 'images']);
        
        // Trier par date décroissante
        $query->orderBy('created_at', 'desc');
        
        return $query->paginate($perPage);
    }
}
```

### 2. Vérifier `app/Http/Controllers/ReportController.php`

Le contrôleur doit **extraire correctement** les filtres de la requête :

```php
<?php

namespace App\Http\Controllers;

use App\Repositories\ReportRepositoryInterface;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    protected $reportRepository;

    public function __construct(ReportRepositoryInterface $reportRepository)
    {
        $this->reportRepository = $reportRepository;
    }

    public function index(Request $request)
    {
        // 🔥 IMPORTANT : Extraire les filtres correctement
        $filters = [
            'status' => $request->input('filter.status'), // filter[status] → filter.status
            'category_id' => $request->input('filter.category_id'),
            'user_id' => $request->input('user_id'),
            'search' => $request->input('search'),
            'start_date' => $request->input('filter.start_date'),
            'end_date' => $request->input('filter.end_date'),
        ];
        
        // Nettoyer les valeurs nulles
        $filters = array_filter($filters, fn($value) => !is_null($value) && $value !== '');
        
        $perPage = $request->input('per_page', 15);
        
        $reports = $this->reportRepository->paginateWithFilters($filters, $perPage);
        
        return response()->json([
            'success' => true,
            'message' => 'Signalements récupérés avec succès',
            'data' => [
                'data' => $reports->items(),
                'current_page' => $reports->currentPage(),
                'last_page' => $reports->lastPage(),
                'per_page' => $reports->perPage(),
                'total' => $reports->total(),
            ]
        ]);
    }
}
```

### 3. Vérifier le Binding dans `app/Providers/AppServiceProvider.php`

```php
<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Repositories\ReportRepositoryInterface;
use App\Repositories\Eloquent\EloquentReportRepository;

class AppServiceProvider extends ServiceProvider
{
    public function register()
    {
        // Binding Repository Pattern
        $this->app->bind(
            ReportRepositoryInterface::class,
            EloquentReportRepository::class
        );
    }
}
```

## 🧪 Test Backend

Tester avec **Postman** ou **curl** :

```bash
# Test 1 : Sans filtre
curl -X GET "http://192.168.1.7:8000/api/reports?page=1&per_page=15&include=user,category,images" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test 2 : Filtre "En attente"
curl -X GET "http://192.168.1.7:8000/api/reports?page=1&per_page=15&filter[status]=En%20attente&include=user,category,images" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test 3 : Filtre "Résolu"
curl -X GET "http://192.168.1.7:8000/api/reports?page=1&per_page=15&filter[status]=Résolu&include=user,category,images" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test 4 : Filtre "En cours"
curl -X GET "http://192.168.1.7:8000/api/reports?page=1&per_page=15&filter[status]=En%20cours&include=user,category,images" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Résultat attendu** : Chaque requête doit renvoyer des signalements avec le status correspondant uniquement.

## 📊 Vérification Base de Données

Vérifier qu'il existe des signalements avec différents status :

```sql
SELECT id, title, status FROM reports;
```

Si tous les signalements ont le status "En attente", créer des signalements de test avec différents status :

```sql
-- Créer un signalement "En cours"
INSERT INTO reports (title, description, status, user_id, category_id, latitude, longitude, created_at, updated_at)
VALUES ('Test En cours', 'Description test', 'En cours', 10, 3, 14.739909, -17.464313, NOW(), NOW());

-- Créer un signalement "Résolu"
INSERT INTO reports (title, description, status, user_id, category_id, latitude, longitude, created_at, updated_at)
VALUES ('Test Résolu', 'Description test', 'Résolu', 10, 3, 14.739909, -17.464313, NOW(), NOW());
```

## ✅ Checklist de Vérification

- [ ] `EloquentReportRepository::paginateWithFilters()` applique `where('status', $status)`
- [ ] `ReportController::index()` extrait `$request->input('filter.status')`
- [ ] Repository binding dans `AppServiceProvider`
- [ ] La base de données contient des signalements avec différents status
- [ ] Test avec Postman confirme que les filtres fonctionnent
- [ ] Le mobile reçoit les bons résultats filtrés

## 🎯 Résultat Attendu

Après correction, le mobile devrait recevoir :
- **Filtre "En attente"** → Uniquement signalements avec `status: En attente`
- **Filtre "Résolu"** → Uniquement signalements avec `status: Résolu`
- **Filtre "En cours"** → Uniquement signalements avec `status: En cours`
- **Sans filtre** → Tous les signalements

---

**Note** : Le mobile est 100% correct, le problème est uniquement backend !
