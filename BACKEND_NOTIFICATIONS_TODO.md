# 🔔 Backend Laravel - Implémentation des Notifications Automatiques

## ⚠️ Problème Actuel

Les classes de notifications existent dans `app/Notifications/` mais **ne sont jamais appelées**.
Les utilisateurs mobiles ne reçoivent AUCUNE notification automatique lors des événements importants.

---

## ✅ Ce qui existe déjà

### Notifications créées (mais non utilisées)
- ✅ `app/Notifications/ReportCreatedNotification.php`
- ✅ `app/Notifications/CommentNotification.php`
- ✅ `app/Notifications/StatusChangedNotification.php`
- ✅ `app/Notifications/ReportLikedNotification.php`
- ✅ `app/Notifications/GenericNotification.php`

### API fonctionnelle
- ✅ `GET /api/notifications` - Liste des notifications
- ✅ `GET /api/notifications/unread-count` - Compteur non lues
- ✅ `PATCH /api/notifications/{id}/read` - Marquer comme lu
- ✅ `DELETE /api/notifications/{id}` - Supprimer notification

### Mobile fonctionnel
- ✅ Polling automatique toutes les 30s
- ✅ Affichage des notifications
- ✅ Badge avec compteur
- ✅ Suppression, marquage lu/non-lu

---

## 🔧 À Implémenter

### 1. **Modification de `app/Observers/ReportObserver.php`**

**Fichier actuel :**
```php
<?php

namespace App\Observers;

use App\Models\Report;
use App\Services\CacheService;

class ReportObserver
{
    protected CacheService $cacheService;

    public function __construct(CacheService $cacheService)
    {
        $this->cacheService = $cacheService;
    }

    public function created(Report $report): void
    {
        $this->cacheService->invalidateReports();
        $this->cacheService->invalidateStats();
    }

    public function updated(Report $report): void
    {
        $this->cacheService->invalidateReports();
        $this->cacheService->invalidateStats();
    }

    // ... autres méthodes
}
```

**NOUVEAU CODE À UTILISER :**

```php
<?php

namespace App\Observers;

use App\Models\Report;
use App\Services\CacheService;
use App\Notifications\GenericNotification;

class ReportObserver
{
    protected CacheService $cacheService;

    public function __construct(CacheService $cacheService)
    {
        $this->cacheService = $cacheService;
    }

    /**
     * Handle the Report "created" event.
     */
    public function created(Report $report): void
    {
        $this->cacheService->invalidateReports();
        $this->cacheService->invalidateStats();
        
        // 🔔 NOTIFICATION : Signalement créé
        $report->user->notify(new GenericNotification(
            'Votre signalement a été créé avec succès',
            [
                'type' => 'report_created',
                'report_id' => $report->id,
            ]
        ));
    }

    /**
     * Handle the Report "updated" event.
     */
    public function updated(Report $report): void
    {
        $this->cacheService->invalidateReports();
        $this->cacheService->invalidateStats();
        
        // 🔔 NOTIFICATION : Changement de statut
        if ($report->isDirty('status')) {
            $oldStatus = $report->getOriginal('status');
            $newStatus = $report->status;
            
            $report->user->notify(new GenericNotification(
                "Le statut de votre signalement a changé de {$oldStatus} à {$newStatus}",
                [
                    'type' => 'status_changed',
                    'report_id' => $report->id,
                    'old_status' => $oldStatus,
                    'new_status' => $newStatus,
                ]
            ));
        }
    }

    /**
     * Handle the Report "deleted" event.
     */
    public function deleted(Report $report): void
    {
        $this->cacheService->invalidateReports();
        $this->cacheService->invalidateStats();
    }

    /**
     * Handle the Report "restored" event.
     */
    public function restored(Report $report): void
    {
        $this->cacheService->invalidateReports();
        $this->cacheService->invalidateStats();
    }

    /**
     * Handle the Report "force deleted" event.
     */
    public function forceDeleted(Report $report): void
    {
        $this->cacheService->invalidateReports();
        $this->cacheService->invalidateStats();
    }
}
```

---

### 2. **Créer `app/Observers/CommentObserver.php`**

Ce fichier n'existe probablement pas encore. Le créer :

```php
<?php

namespace App\Observers;

use App\Models\Comment;
use App\Notifications\GenericNotification;

class CommentObserver
{
    /**
     * Handle the Comment "created" event.
     */
    public function created(Comment $comment): void
    {
        // Récupérer le propriétaire du signalement
        $reportOwner = $comment->report->user;
        
        // Ne pas notifier si c'est l'auteur lui-même qui commente
        if ($comment->user_id === $reportOwner->id) {
            return;
        }
        
        // 🔔 NOTIFICATION : Nouveau commentaire
        $reportOwner->notify(new GenericNotification(
            'Un nouveau commentaire a été ajouté à votre signalement',
            [
                'type' => 'comment_created',
                'message' => 'Un nouveau commentaire a été ajouté à votre signalement',
                'report_id' => $comment->report_id,
                'comment_id' => $comment->id,
                'commenter' => $comment->user->nom . ' ' . $comment->user->prenom,
            ]
        ));
    }

    /**
     * Handle the Comment "deleted" event.
     */
    public function deleted(Comment $comment): void
    {
        // Optionnel : notifier si besoin
    }
}
```

**Ensuite, enregistrer l'observer dans `app/Providers/AppServiceProvider.php` :**

```php
use App\Models\Comment;
use App\Observers\CommentObserver;

public function boot(): void
{
    Comment::observe(CommentObserver::class);
    // Report::observe(ReportObserver::class); // Devrait déjà exister
}
```

---

### 3. **Ajouter notifications pour les Likes**

**Option A : Créer `app/Observers/LikeObserver.php`**

```php
<?php

namespace App\Observers;

use App\Models\Like;
use App\Notifications\GenericNotification;

class LikeObserver
{
    /**
     * Handle the Like "created" event.
     */
    public function created(Like $like): void
    {
        // Récupérer le propriétaire du signalement
        $reportOwner = $like->report->user;
        
        // Ne pas notifier si c'est l'auteur lui-même qui like
        if ($like->user_id === $reportOwner->id) {
            return;
        }
        
        // 🔔 NOTIFICATION : Like reçu
        $reportOwner->notify(new GenericNotification(
            'Quelqu\'un a aimé votre signalement',
            [
                'type' => 'report_liked',
                'report_id' => $like->report_id,
                'like_id' => $like->id,
                'liker_name' => $like->user->nom . ' ' . $like->user->prenom,
                'liker_id' => $like->user_id,
            ]
        ));
    }
}
```

**Enregistrer dans `AppServiceProvider.php` :**

```php
use App\Models\Like;
use App\Observers\LikeObserver;

public function boot(): void
{
    Like::observe(LikeObserver::class);
}
```

**Option B : Ajouter directement dans `LikeController`**

Si tu préfères, ajouter après la création du like dans le controller :

```php
// Dans LikeController::store() après $like->save()
$like->report->user->notify(new GenericNotification(
    'Quelqu\'un a aimé votre signalement',
    [
        'type' => 'report_liked',
        'report_id' => $like->report_id,
        'like_id' => $like->id,
        'liker_name' => auth()->user()->nom . ' ' . auth()->user()->prenom,
        'liker_id' => auth()->id(),
    ]
));
```

---

## 🧪 Test des Notifications

### 1. Route de test existante

Il existe déjà une route de test :
```
POST /api/test/notification/{userId}
```

### 2. Test manuel avec Tinker

```bash
php artisan tinker
```

```php
// Créer une notification de test
$user = \App\Models\User::find(10);
$user->notify(new \App\Notifications\GenericNotification(
    'Test de notification',
    ['type' => 'test', 'message' => 'Ceci est un test']
));

// Vérifier
\App\Models\User::find(10)->notifications()->count();
```

### 3. Test réel

1. Créer un signalement depuis le mobile
2. Vérifier que la notification apparaît dans `/api/notifications`
3. Vérifier le badge mobile (compteur)

---

## 📊 Format des notifications attendu par le mobile

Le mobile s'attend à ce format dans `data` :

```json
{
  "type": "report_created|comment_created|status_changed|report_liked",
  "message": "Message descriptif",
  "report_id": 123,
  // ... autres données spécifiques
}
```

### Types de notifications supportés par le mobile :

| Type | Données requises | Événement |
|------|------------------|-----------|
| `report_created` | `report_id` | Création signalement |
| `comment_created` | `report_id`, `comment_id`, `commenter` | Nouveau commentaire |
| `status_changed` | `report_id`, `old_status`, `new_status` | Changement statut |
| `report_liked` | `report_id`, `like_id`, `liker_name`, `liker_id` | Like reçu |

---

## ✅ Checklist d'implémentation

- [ ] Modifier `app/Observers/ReportObserver.php`
- [ ] Créer `app/Observers/CommentObserver.php`
- [ ] Enregistrer `CommentObserver` dans `AppServiceProvider`
- [ ] Créer `app/Observers/LikeObserver.php` (ou modifier controller)
- [ ] Enregistrer `LikeObserver` dans `AppServiceProvider`
- [ ] Tester création de signalement → notification reçue
- [ ] Tester ajout de commentaire → notification reçue
- [ ] Tester changement de statut → notification reçue
- [ ] Tester like → notification reçue
- [ ] Vérifier que les notifications apparaissent sur mobile

---

## 🚀 Déploiement

Après modification :

```bash
# Vider le cache Laravel
php artisan cache:clear
php artisan config:clear

# Redémarrer les workers si queues utilisées
php artisan queue:restart
```

---

## 📱 Côté Mobile (Déjà OK ✅)

Le mobile est **100% fonctionnel** :
- ✅ Polling automatique toutes les 30s
- ✅ Parsing robuste (gère double-encodage JSON)
- ✅ Affichage liste notifications
- ✅ Badge avec compteur non lues
- ✅ Suppression / Marquer comme lu
- ✅ Navigation vers signalement au clic

**Dès que le backend envoie les notifications, elles apparaîtront automatiquement sur mobile !** 🎉

---

## 🐛 Debugging

Si les notifications n'apparaissent pas :

1. Vérifier que les observers sont bien enregistrés :
```bash
php artisan tinker
```
```php
// Devrait afficher les observers
app(\Illuminate\Events\Dispatcher::class)->getListeners('eloquent.created: App\Models\Report');
```

2. Vérifier la création manuelle :
```php
$user = \App\Models\User::find(10);
$user->notify(new \App\Notifications\GenericNotification('Test', ['type' => 'test']));
\DB::table('notifications')->where('notifiable_id', 10)->count(); // Devrait augmenter
```

3. Logs Laravel :
```bash
tail -f storage/logs/laravel.log
```

---

**Résumé** : Le mobile attend juste que le backend envoie les notifications ! Dès que tu implémentes les Observers ci-dessus, tout fonctionnera automatiquement. 🚀
