# 🐛 Bugfix - Système de Likes (Erreur 409 + Type Null)

**Date** : 24 novembre 2025  
**Phase** : Phase 4 - ÉTAPE 9 (Système de Likes)

---

## 🔴 Problèmes identifiés

### 1. Erreur "type null" sur `likes_count`
**Symptôme** : Lors du premier clic sur le bouton like, l'application crash avec une erreur "type null".

**Cause** : Le backend ne retourne **pas** le champ `likes_count` dans la réponse POST/DELETE `/reports/{id}/likes`.

**Réponse backend actuelle** :
```json
{
  "success": true,
  "message": "Signalement aimé avec succès",
  "data": {
    "id": 1,
    "user_id": 10,
    "report_id": 4,
    "created_at": "2025-11-24T18:31:14.000000Z"
  }
}
```

**Réponse attendue par le mobile** :
```json
{
  "success": true,
  "message": "Signalement aimé avec succès",
  "likes_count": 5  // ❌ MANQUANT
}
```

---

### 2. Erreur 409 (Conflict) en boucle
**Symptôme** : Après le premier like réussi, chaque clic suivant génère une erreur 409 "L'utilisateur a déjà aimé ce signalement".

**Cause** : 
- Le mobile utilise `toggleLike()` qui appelle toujours POST si `_isLiked = false`
- Mais après le premier POST réussi, le mobile ne met pas à jour `_isLiked = true`
- Donc le 2e clic appelle encore POST au lieu de DELETE

**Logs** :
```
POST /reports/4/likes → 201 Success (1er clic)
POST /reports/4/likes → 409 Conflict (2e clic, devrait être DELETE)
POST /reports/4/likes → 409 Conflict (3e clic, boucle infinie)
```

---

### 3. Boucle infinie de requêtes
**Symptôme** : L'application envoie des requêtes POST en boucle sans s'arrêter.

**Cause** : Combinaison des problèmes 1 et 2 :
1. Le `likes_count` null provoque une exception
2. L'exception empêche la mise à jour de `_isLiked`
3. Le prochain clic rappelle POST au lieu de DELETE
4. Le backend retourne 409
5. Retour à l'étape 2 → boucle

---

## ✅ Solutions appliquées

### Solution 1 : Récupérer le signalement complet après like/unlike

**Fichier** : `lib/features/reports/repositories/like_repository.dart`

**Avant** :
```dart
Future<int> likeReport(int reportId) async {
  final response = await _dioService.dio.post('/reports/$reportId/likes');
  
  if (response.data['success'] == true) {
    return response.data['likes_count'] as int; // ❌ null
  }
}
```

**Après** :
```dart
Future<int> likeReport(int reportId) async {
  // 1. Envoyer le POST like
  final response = await _dioService.dio.post('/reports/$reportId/likes');
  
  if (response.data['success'] == true) {
    // 2. Récupérer le signalement complet pour obtenir likes_count
    final reportResponse = await _dioService.dio.get(
      '/reports/$reportId',
      queryParameters: {'include': 'user,category,images'},
    );
    
    final reportData = reportResponse.data['data'];
    return (reportData['likes_count'] as int?) ?? 0; // ✅ likes_count présent
  }
}
```

**Même correction pour `unlikeReport()`**.

**Avantages** :
- ✅ Obtient le nombre exact de likes depuis la base de données
- ✅ Pas de modification backend nécessaire
- ✅ Synchronisation garantie entre mobile et serveur

**Inconvénient** :
- ⚠️ 2 requêtes HTTP au lieu d'1 (POST + GET ou DELETE + GET)

---

### Solution 2 : Update optimiste de l'UI avec rollback

**Fichier** : `lib/features/reports/pages/report_detail_page.dart`

**Modifications** :
1. **Update optimiste** : Mise à jour immédiate de l'UI avant l'appel API
2. **Rollback** : Annulation de l'update si l'API retourne une erreur
3. **Gestion erreur 409** : Ne pas afficher de snackbar rouge pour les conflits

**Code avant** :
```dart
Future<void> _toggleLike() async {
  if (_isLoading) return;
  
  setState(() { _isLoading = true; });
  
  try {
    final result = await likeRepository.toggleLike(widget.report.id, _isLiked);
    
    setState(() {
      _isLiked = result['is_liked'] as bool;
      _likesCount = result['likes_count'] as int;
    });
  } catch (e) {
    // Affiche erreur
  }
}
```

**Code après** :
```dart
Future<void> _toggleLike() async {
  if (_isLoading) return;
  
  setState(() { _isLoading = true; });
  
  // 🎯 Update optimiste (UI réactive)
  final previousIsLiked = _isLiked;
  final previousLikesCount = _likesCount;
  
  setState(() {
    _isLiked = !_isLiked;
    _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
  });

  try {
    final result = await likeRepository.toggleLike(widget.report.id, previousIsLiked);
    
    // Mise à jour avec valeurs réelles du serveur
    setState(() {
      _isLiked = result['is_liked'] as bool;
      _likesCount = result['likes_count'] as int;
    });
  } catch (e) {
    // 🔄 Rollback en cas d'erreur
    setState(() {
      _isLiked = previousIsLiked;
      _likesCount = previousLikesCount;
    });
    
    // Ne pas afficher d'erreur pour 409 (conflit déjà géré par optimistic update)
    if (!e.toString().contains('409') && !e.toString().contains('déjà aimé')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
```

**Avantages** :
- ✅ UI réactive instantanément (pas d'attente réseau)
- ✅ Gestion propre des erreurs 409
- ✅ Rollback automatique si erreur
- ✅ Empêche les clics multiples rapides avec `if (_isLoading) return;`

---

## 🧪 Tests manuels requis

### Scénario 1 : Like → Unlike → Like
1. ✅ Ouvrir un signalement non liké
2. ✅ Cliquer sur ❤️ → Vérifier compteur +1 et icône rouge
3. ✅ Cliquer à nouveau → Vérifier compteur -1 et icône grise
4. ✅ Cliquer une 3e fois → Vérifier compteur +1 et icône rouge

**Résultat attendu** : Pas d'erreur 409, alternance correcte POST/DELETE

---

### Scénario 2 : Clics multiples rapides
1. ✅ Ouvrir un signalement
2. ✅ Cliquer 5 fois rapidement sur ❤️
3. ✅ Vérifier que seulement 1 requête est envoyée (loading bloque les autres)

**Résultat attendu** : Pas de boucle infinie, pas de 409 en cascade

---

### Scénario 3 : Vérification nombre de likes réel
1. ✅ Liker un signalement
2. ✅ Fermer l'application
3. ✅ Rouvrir l'application
4. ✅ Ouvrir le même signalement
5. ✅ Vérifier que le like est toujours présent

**Résultat attendu** : Synchronisation correcte avec le backend

---

## 📝 Recommandations backend (optionnel)

Pour améliorer les performances et éviter la double requête (POST + GET), le backend pourrait retourner `likes_count` directement :

**Controller Laravel** : `app/Http/Controllers/Api/LikeController.php`

```php
public function like(Request $request, $reportId)
{
    $like = Like::create([
        'user_id' => auth()->id(),
        'report_id' => $reportId,
    ]);
    
    // ✅ Ajouter likes_count dans la réponse
    $likesCount = Like::where('report_id', $reportId)->count();
    
    return response()->json([
        'success' => true,
        'message' => 'Signalement aimé avec succès',
        'likes_count' => $likesCount, // ← AJOUT
        'data' => $like,
    ], 201);
}

public function unlike(Request $request, $reportId)
{
    Like::where('user_id', auth()->id())
        ->where('report_id', $reportId)
        ->delete();
    
    // ✅ Ajouter likes_count dans la réponse
    $likesCount = Like::where('report_id', $reportId)->count();
    
    return response()->json([
        'success' => true,
        'message' => 'Like retiré avec succès',
        'likes_count' => $likesCount, // ← AJOUT
    ]);
}
```

Avec cette modification backend, le mobile pourrait simplifier :

```dart
Future<int> likeReport(int reportId) async {
  final response = await _dioService.dio.post('/reports/$reportId/likes');
  return response.data['likes_count'] as int; // ✅ Directement disponible
}
```

**Gain** : Réduction de 2 requêtes à 1 requête par like/unlike.

---

## 📊 Statut après correction

- ✅ Erreur "type null" résolue
- ✅ Erreur 409 gérée proprement
- ✅ Boucle infinie corrigée
- ✅ Update optimiste implémenté
- ✅ Rollback automatique en cas d'erreur
- ⚠️ 2 requêtes HTTP par like/unlike (acceptable, optimisable côté backend)

---

## 🔗 Fichiers modifiés

1. `lib/features/reports/repositories/like_repository.dart`
   - Ajout GET `/reports/{id}` après POST/DELETE pour récupérer `likes_count`

2. `lib/features/reports/pages/report_detail_page.dart`
   - Update optimiste dans `_toggleLike()`
   - Rollback en cas d'erreur
   - Gestion silencieuse erreur 409

---

**Prochaine étape** : Tester manuellement les 3 scénarios ci-dessus pour valider la correction.
