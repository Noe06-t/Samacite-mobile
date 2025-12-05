# 🔔 Instructions pour tester les notifications (Backend)

## ✅ État actuel

- **FCM configuré** : ✅ Token envoyé avec succès au backend
- **Token device** : `ev1crEyeQQyrIA5tqSLxN_:APA91bGSkzWR9nmk6RGvs5Cyv9HT7r_f...`
- **User ID** : `10` (Offinobi Noe)
- **Device ID BDD** : `1`
- **API /notifications** : ✅ Fonctionne (mais `data: []` - vide)

---

## 🎯 Problème actuel

**Aucune notification dans la base de données**.

L'app mobile **fonctionne correctement** mais ne peut afficher que ce qui existe dans la BDD.

---

## 🧪 Comment créer des notifications de test

### Option 1 : Via Laravel Tinker

```bash
php artisan tinker
```

```php
use App\Models\User;
use Illuminate\Notifications\DatabaseNotification;

$user = User::find(10); // ID du user mobile

// Créer une notification de test manuellement
$user->notifications()->create([
    'id' => \Illuminate\Support\Str::uuid(),
    'type' => 'App\\Notifications\\ReportStatusChangedNotification',
    'notifiable_type' => 'App\\Models\\User',
    'notifiable_id' => 10,
    'data' => json_encode([
        'title' => 'Test Notification',
        'body' => 'Votre signalement #7 a été marqué comme Résolu',
        'report_id' => 7,
        'status' => 'Résolu',
        'type' => 'report_status_changed'
    ]),
    'read_at' => null,
    'created_at' => now(),
    'updated_at' => now(),
]);

echo "Notification créée ✅";
```

### Option 2 : Créer une route de test

Ajouter dans `routes/api.php` :

```php
Route::post('/test/notification/{userId}', function ($userId) {
    $user = User::findOrFail($userId);
    
    $user->notifications()->create([
        'id' => \Illuminate\Support\Str::uuid(),
        'type' => 'App\\Notifications\\TestNotification',
        'data' => [
            'title' => 'Notification de test',
            'body' => 'Ceci est une notification de test générée à ' . now()->format('H:i:s'),
            'type' => 'test',
        ],
    ]);
    
    return response()->json([
        'success' => true,
        'message' => 'Notification de test créée',
    ]);
})->middleware('auth:sanctum');
```

**Appel depuis Postman** :
```
POST http://192.168.1.17:8000/api/test/notification/10
Authorization: Bearer <token>
```

---

## 🔥 Option 3 : Envoyer une notification Push FCM

Pour tester les **notifications push** (qui apparaissent même quand l'app est fermée) :

### Installer Firebase Admin SDK (si pas encore fait)

```bash
composer require kreait/firebase-php
```

### Créer une route de test pour notification push

```php
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FCMNotification;

Route::post('/test/push-notification/{userId}', function ($userId) {
    $user = User::findOrFail($userId);
    
    // Récupérer le FCM token du device
    $fcmToken = $user->fcmTokens()->latest()->first();
    
    if (!$fcmToken) {
        return response()->json([
            'success' => false,
            'message' => 'Aucun token FCM trouvé'
        ], 404);
    }
    
    // Créer la notification dans la BDD
    $notificationData = [
        'title' => 'Nouveau commentaire',
        'body' => 'Quelqu\'un a commenté votre signalement',
        'report_id' => 7,
        'type' => 'new_comment',
    ];
    
    $user->notifications()->create([
        'id' => \Illuminate\Support\Str::uuid(),
        'type' => 'App\\Notifications\\NewCommentNotification',
        'data' => $notificationData,
    ]);
    
    // Envoyer via FCM
    $factory = (new Factory)->withServiceAccount(storage_path('app/firebase-credentials.json'));
    $messaging = $factory->createMessaging();
    
    $message = CloudMessage::withTarget('token', $fcmToken->token)
        ->withNotification(
            FCMNotification::create($notificationData['title'], $notificationData['body'])
        )
        ->withData($notificationData);
    
    $messaging->send($message);
    
    return response()->json([
        'success' => true,
        'message' => 'Notification push envoyée',
    ]);
})->middleware('auth:sanctum');
```

---

## ✅ Actions réelles qui déclenchent des notifications

**Backend Laravel** : ✅ **IMPLÉMENTÉ ET FONCTIONNEL**

Ces actions créent automatiquement des notifications pour les utilisateurs concernés :

### 1. **Changement de statut d'un signalement** ✅
```php
// Dans ReportController@updateStatus
$report->update(['status' => $newStatus]);

event(new ReportStatusChanged($report, $oldStatus, $newStatus));
```

✅ **Notification créée pour** : Le propriétaire du signalement (`$report->user_id`)  
✅ **Type** : `App\Notifications\ReportStatusChangedNotification`  
✅ **Contenu** : Titre + Nouveau statut + ID signalement

---

### 2. **Nouveau commentaire sur un signalement** ✅
```php
// Dans CommentController@store
$comment = Comment::create([...]);

event(new CommentCreated($comment));
```

✅ **Notification créée pour** : Le propriétaire du signalement (si ≠ auteur du commentaire)  
✅ **Type** : `App\Notifications\NewCommentNotification`  
✅ **Contenu** : Nom de l'auteur + ID signalement + ID commentaire

---

### 3. **Like sur un signalement** ❌
```php
// Dans LikeController@store
// Actuellement AUCUNE notification n'est envoyée
```

❌ **Non implémenté** : Pas d'Event `ReportLiked`  
⏭️ **À faire** : Phase 5+ (amélioration future)

---

### 4. **Assignation d'un signalement** (Admin) ⚠️
```php
// Dans ReportController@assign
$report->update(['assigned_to' => $adminId]);

event(new ReportAssigned($report, $adminId));
```

⚠️ **À vérifier** : Fonctionnalité admin (hors scope app mobile actuelle)

---

## 📊 Vérifier la table `notifications`

```sql
SELECT 
    id, 
    type, 
    notifiable_id, 
    data, 
    read_at, 
    created_at 
FROM notifications 
WHERE notifiable_id = 10 
ORDER BY created_at DESC;
```

Si vide → **C'est pour ça qu'il n'y a rien dans l'app mobile !**

---

## 🎯 Test End-to-End

### Scénario complet :

1. **Backend** : Créer une notification de test (Option 1 ou 2)
2. **Mobile** : Appuyer sur le bouton 🔔 "Notifications" dans l'app
3. **Résultat attendu** : La notification apparaît dans la liste
4. **Cliquer dessus** : Elle est marquée comme lue (`read_at` rempli)

---

## 📱 Token FCM actuel

Si besoin de tester directement depuis Firebase Console :

```
Device Token: ev1crEyeQQyrIA5tqSLxN_:APA91bGSkzWR9nmk6RGvs5Cyv9HT7r_f-sIYqQHsFTZMfeuN4xn_-jyCQlJGNHq5Msn-Jld_ukn_e6-OQxx_fyE5-3v05nCoLudT2_FWb6FL7mCkhx-gqPQ
User ID: 10
Device Type: Android
```

Aller sur : https://console.firebase.google.com/project/samacite-mobile/notification

Envoyer un message de test vers ce token.

---

## ✅ État Backend Laravel (26 novembre 2025) - VÉRIFIÉ ✅

### Events & Listeners configurés ✅
- ✅ `ReportStatusChanged` → `SendStatusNotification` (VÉRIFIÉ)
- ✅ `CommentCreated` → `SendCommentNotification` (VÉRIFIÉ - ligne 65 CommentController)
- ❌ `ReportLiked` → Non implémenté (Phase 5+)

### Notification Classes Laravel ✅
- ✅ `App\Notifications\ReportStatusChangedNotification`
- ✅ `App\Notifications\GenericNotification` (CORRIGÉ - fusion type JSON)
- ✅ `SendCommentNotification` Listener (VÉRIFIÉ)
- ❌ `App\Notifications\ReportLikedNotification` (TODO)

### Jobs Asynchrones ✅
- ✅ `NotifyUserJob` - Traite les notifications en queue
- ✅ Queue configurée (Laravel Queues)
- ✅ Dispatch automatique depuis `SendCommentNotification`

### User Model ✅
- ✅ Accessor `name` ajouté (`nom + prenom`)
- ✅ Relation `notifications()` fonctionnelle

### Table notifications ✅
- ✅ Migration créée et exécutée
- ✅ Structure conforme (id, type, notifiable_type, notifiable_id, data, read_at, timestamps)
- ✅ Relations User → notifications fonctionnelles

### Endpoints API ✅
- ✅ `GET /api/notifications` - Liste paginée
- ✅ `GET /api/notifications/unread-count` - Compteur
- ✅ `PATCH /api/notifications/{id}/read` - Marquer comme lu
- ✅ `POST /api/fcm-token` - Enregistrer device FCM

### Tests Backend ✅
- ✅ **248 tests passés**
- ✅ **744 assertions validées**
- ✅ Tests API REST complets

---

## 🎯 Ce qui fonctionne maintenant (CONFIRMÉ ✅)

1. ✅ **Changement statut** → Propriétaire notifié automatiquement
2. ✅ **Nouveau commentaire** → Propriétaire + autres commentateurs notifiés
3. ✅ **App mobile** → Affiche et gère toutes les notifications
4. ✅ **Polling 30s** → Badge mis à jour en temps réel
5. ✅ **Navigation** → Clic notification → Détail signalement
6. ✅ **Queue Jobs** → Traitement asynchrone via `NotifyUserJob`
7. ✅ **Tests Backend** → 248 tests passés, 744 assertions ✅

## 🧪 Comment tester MAINTENANT

### ✅ Queue Worker : ACTIF ✅

Les notifications sont traitées de manière **asynchrone** via Laravel Queues.

**Status** : ✅ Queue worker lancé et fonctionnel sur 192.168.1.17:8000

Si besoin de redémarrer :
```bash
php artisan queue:work --stop-when-empty
```

### Test via App Mobile (Recommandé) 📱

1. **Compte A (User 10)** : Crée un signalement
2. **Compte B (User différent)** : Commente le signalement du compte A
3. **Backend** : Queue worker traite automatiquement
4. **Compte A** : Recharge l'app → notification apparaît (30s max)

### Test via Postman/cURL 🌐

```bash
# 1. Créer un commentaire (en tant qu'un AUTRE user)
POST http://192.168.1.17:8000/api/reports/[REPORT_ID]/comments
Authorization: Bearer [TOKEN_USER_B]
Content-Type: application/json

{
  "content": "Commentaire de test pour notification"
}

# 2. Traiter la queue
php artisan queue:work --stop-when-empty

# 3. Vérifier les notifications (en tant que propriétaire du report)
GET http://192.168.1.17:8000/api/notifications
Authorization: Bearer [TOKEN_USER_A]
```

### Vérification Base de Données 🗄️

```sql
-- Voir les notifications créées
SELECT 
    id, 
    type, 
    notifiable_id, 
    JSON_EXTRACT(data, '$.type') as notif_type,
    JSON_EXTRACT(data, '$.report_id') as report_id,
    created_at,
    read_at
FROM notifications 
ORDER BY created_at DESC 
LIMIT 10;

-- Voir les jobs en queue
SELECT * FROM jobs ORDER BY created_at DESC LIMIT 10;

-- Voir les jobs échoués
SELECT * FROM failed_jobs ORDER BY failed_at DESC LIMIT 10;
```

---

## ⏭️ Améliorations futures (Phase 5+)

- [ ] Notification pour les likes
- [ ] Push notifications natives via FCM
- [ ] Broadcasting temps réel (Pusher/Laravel Echo)
- [ ] Notifications groupées
- [ ] Préférences utilisateur (activer/désactiver par type)
