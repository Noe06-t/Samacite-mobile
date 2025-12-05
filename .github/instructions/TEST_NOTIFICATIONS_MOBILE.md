# 🧪 Test des Notifications - App Mobile

## 📋 Scénario de Test Complet

### Préparation
- ✅ App mobile installée et connectée (User ID: 10)
- ✅ Au moins 1 signalement créé par toi
- ✅ Backend Laravel fonctionnel (`http://192.168.1.17:8000`)

---

## 🎯 Test 1 : Notification de Commentaire

### Étapes :
1. **Note l'ID d'un de tes signalements** (ex: signalement #7)
2. **Demande à quelqu'un d'autre de commenter** ce signalement :
   - Soit via l'app mobile (autre utilisateur)
   - Soit via l'interface web admin
   - Soit via Postman :
   ```
   POST http://192.168.1.17:8000/api/reports/7/comments
   Authorization: Bearer <token_autre_user>
   Content-Type: application/json
   
   {
     "content": "Ceci est un test de notification 🧪"
   }
   ```

3. **Dans ton app mobile** :
   - Attends 30 secondes max (polling automatique)
   - Le badge 🔔 devrait afficher **1**
   - Clique sur le bouton Notifications
   
4. **Résultat attendu** :
   ```
   💬 NOUVEAU COMMENTAIRE           [Orange #FFA000]
   [Nom de l'auteur] a commenté votre signalement
   Il y a quelques secondes
   ```

5. **Clique sur la notification** :
   - ✅ Ouverture du détail du signalement #7
   - ✅ La notification devient grise (lue)
   - ✅ Badge passe à 0

---

## 🎯 Test 2 : Notification de Changement de Statut

### Étapes :
1. **Trouve un signalement "En attente"** que tu as créé
2. **Demande à un admin de changer le statut** :
   - Via interface web admin
   - Ou via Postman :
   ```
   PATCH http://192.168.1.17:8000/api/reports/7/status
   Authorization: Bearer <admin_token>
   Content-Type: application/json
   
   {
     "status": "Résolu"
   }
   ```

3. **Dans ton app mobile** :
   - Attends 30 secondes max
   - Badge 🔔 s'incrémente (+1)
   - Va dans Notifications
   
4. **Résultat attendu** :
   ```
   🔄 CHANGEMENT DE STATUT          [Bleu #0023D1]
   Votre signalement a été marqué comme Résolu
   Il y a quelques secondes
   ```

5. **Vérifie la navigation** :
   - Clique → Détail du signalement
   - Statut affiché : "Résolu" avec badge vert

---

## 🎯 Test 3 : Multiple Notifications

### Étapes :
1. **Créer plusieurs notifications d'affilée** :
   - Quelqu'un commente ton signalement #5
   - Admin change le statut du signalement #7
   - Quelqu'un commente ton signalement #3
   
2. **Dans ton app mobile** :
   - Badge devrait afficher **3**
   - Liste des notifications dans l'ordre chronologique (plus récent en haut)
   
3. **Teste "Marquer tout comme lu"** :
   - Bouton en haut de la liste
   - Toutes deviennent grises
   - Badge passe à 0

---

## 🎯 Test 4 : Rafraîchissement Manuel

### Étapes :
1. **Crée une notification** (commentaire ou statut)
2. **Avant les 30 secondes** :
   - Va dans l'écran Notifications
   - Pull-to-refresh (tire vers le bas)
   - La nouvelle notification apparaît immédiatement

---

## 🎯 Test 5 : Cas Limite - Like (Non implémenté)

### Étapes :
1. Demande à quelqu'un de **liker** un de tes signalements
2. **Résultat attendu** : ❌ **AUCUNE notification**
   - C'est normal ! Les notifications de like ne sont pas implémentées (Phase 5+)
   - Badge reste à 0

---

## ✅ Checklist Complète

### Notification de Commentaire
- [ ] Badge s'incrémente automatiquement
- [ ] Notification affichée avec icône 💬 orange
- [ ] Texte correct : "[Auteur] a commenté"
- [ ] Navigation vers détail signalement
- [ ] Marquer comme lu fonctionne
- [ ] Badge se décrémente

### Notification de Statut
- [ ] Badge s'incrémente
- [ ] Icône 🔄 bleue
- [ ] Texte correct : "marqué comme [Statut]"
- [ ] Navigation OK
- [ ] Lecture fonctionne

### Fonctionnalités Générales
- [ ] Polling 30s automatique
- [ ] Pull-to-refresh manuel
- [ ] Badge exact (nombre non lues)
- [ ] Ordre chronologique (récent → ancien)
- [ ] "Marquer tout comme lu"
- [ ] Pas de crash si liste vide
- [ ] Message "Aucune notification" si vide

---

## 🐛 Problèmes Possibles

### "Aucune notification" alors qu'il devrait y en avoir

**Diagnostic** :
```bash
# Sur le serveur backend, vérifie la BDD
SELECT * FROM notifications WHERE notifiable_id = 10 ORDER BY created_at DESC LIMIT 5;
```

**Solutions** :
1. Vérifie que les Events Laravel sont bien déclenchés
2. Check les logs Laravel : `storage/logs/laravel.log`
3. Vérifie que l'utilisateur qui commente ≠ propriétaire

---

### Badge ne s'actualise pas

**Solutions** :
1. Vérifie la connexion réseau
2. Regarde les logs Flutter : `flutter logs`
3. Force un refresh manuel (pull-to-refresh)
4. Redémarre l'app

---

### Notification s'affiche mais clic ne fait rien

**Diagnostic** :
- Check que `report_id` est bien dans les data de la notification
- Vérifie que le signalement existe toujours

---

## 📊 Résultat Final Attendu

Après tous les tests :
```
✅ Commentaires → Notification ✅
✅ Changement statut → Notification ✅
❌ Likes → Pas de notification (normal)
✅ Badge en temps réel ✅
✅ Navigation fonctionnelle ✅
✅ Marquage "lu" OK ✅
```

---

## 🎉 Si tout fonctionne

**Phase 5 : Notifications = 100% ✅**

Prochaine étape : **Phase 6 - Cache & Performance** 🚀

---

## 📝 Notes de Test

Date du test : __________________

Testeur : __________________

Résultats :
- Commentaire : ⬜ OK / ⬜ KO
- Statut : ⬜ OK / ⬜ KO
- Badge : ⬜ OK / ⬜ KO
- Navigation : ⬜ OK / ⬜ KO

Bugs trouvés :
_________________________________
_________________________________
_________________________________
