# 🧪 Test Notifications - Procédure Complète

## ✅ Prérequis vérifiés (Backend)
- ✅ CommentController dispatch `CommentCreated` (ligne 65)
- ✅ Listener `SendCommentNotification` enregistré
- ✅ Job `NotifyUserJob` fonctionnel
- ✅ 248 tests passés, 744 assertions ✅

---

## 🎯 Test en Conditions Réelles

### Étape 1 : Vérifier les comptes utilisateurs

**Compte A (Propriétaire)** :
- User ID: 10
- Téléphone: +221761234567
- Nom: Noe Offinobi

**Compte B (Commentateur)** :
- User ID: ? (DOIT être différent de 10)
- Téléphone: ? 
- Nom: ?

⚠️ **IMPORTANT** : Les 2 comptes doivent avoir des User ID différents !

---

### Étape 2 : Démarrer le Queue Worker (Backend)

Sur le serveur Laravel (192.168.1.17:8000) :
```bash
php artisan queue:work --stop-when-empty
```

✅ Devrait afficher :
```
[YYYY-MM-DD HH:MM:SS] Processing: App\Jobs\NotifyUserJob
[YYYY-MM-DD HH:MM:SS] Processed:  App\Jobs\NotifyUserJob
```

---

### Étape 3 : Préparer un signalement (Compte A)

1. **Connecte-toi avec Compte A** (User 10)
2. Crée un nouveau signalement OU note l'ID d'un signalement existant
3. **Note le numéro du signalement** : #______

---

### Étape 4 : Commenter avec un AUTRE compte (Compte B)

1. **Déconnecte-toi** de l'app mobile
2. **Connecte-toi avec Compte B** (User ID différent)
3. Va sur le signalement #______ (créé par Compte A)
4. Ajoute un commentaire : "Test notification système 🔔"
5. ✅ Commentaire publié

⏰ **Attends 5 secondes** (backend traite le job)

---

### Étape 5 : Vérifier la notification (Compte A)

1. **Déconnecte-toi** de Compte B
2. **Reconnecte-toi avec Compte A** (User 10)
3. ⏰ **Attends maximum 30 secondes** (polling automatique)
4. 👀 **Regarde le badge** 🔔 en haut à droite

**Résultat attendu** :
```
🔔 [1]  ← Badge avec le chiffre 1
```

---

### Étape 6 : Ouvrir les notifications

1. Clique sur le bouton 🔔 Notifications
2. Tu devrais voir :

```
┌─────────────────────────────────────────┐
│ 💬 NOUVEAU COMMENTAIRE     [ORANGE]    │
│ [Nom Compte B] a commenté votre        │
│ signalement                             │
│ Il y a quelques secondes                │
│                                          │
│ [Fond blanc = non lu]                   │
└─────────────────────────────────────────┘

[Anciennes notifications grisées en dessous]
```

---

### Étape 7 : Tester la navigation

1. **Clique sur la notification**
2. ✅ L'app t'emmène sur le détail du signalement #______
3. ✅ Tu vois le commentaire de Compte B
4. **Retourne aux notifications**
5. ✅ La notification est maintenant **grisée** (marquée comme lue)
6. ✅ Badge passe à **0**

---

## 📊 Checklist de Validation

### Backend
- [ ] Queue worker démarré (`php artisan queue:work`)
- [ ] Aucun failed_jobs dans la BDD

### Comptes Utilisateurs
- [ ] Compte A (User 10) existe
- [ ] Compte B (User ≠ 10) existe
- [ ] Signalement créé par Compte A

### Test Commentaire
- [ ] Commentaire ajouté par Compte B
- [ ] Backend a traité le job (visible dans queue:work logs)

### App Mobile (Compte A)
- [ ] Badge 🔔 affiche **1**
- [ ] Notification visible dans la liste
- [ ] Icône 💬 orange
- [ ] Texte : "[Nom B] a commenté votre signalement"
- [ ] Fond blanc (non lu)

### Navigation
- [ ] Clic notification → Détail signalement
- [ ] Commentaire visible dans le détail
- [ ] Retour → Notification grisée
- [ ] Badge passe à 0

---

## 🐛 Dépannage

### Badge reste à 0

**Causes possibles** :
1. Queue worker pas démarré → Démarre `php artisan queue:work`
2. Même user qui commente → Utilise 2 comptes différents
3. Polling pas encore passé → Attends 30s ou pull-to-refresh

**Solution** :
```bash
# Vérifier la table notifications
SELECT * FROM notifications WHERE notifiable_id = 10 ORDER BY created_at DESC LIMIT 5;
```

### Notification pas créée

**Vérifier les jobs** :
```bash
# Jobs en attente
SELECT * FROM jobs ORDER BY created_at DESC LIMIT 10;

# Jobs échoués
SELECT * FROM failed_jobs ORDER BY failed_at DESC LIMIT 10;
```

### Erreur dans les logs

```bash
tail -f storage/logs/laravel.log
```

---

## ✅ Résultat Final Attendu

```
✅ Backend : Job traité avec succès
✅ BDD : Notification créée pour User 10
✅ Mobile : Badge affiche 1
✅ Liste : Notification visible 💬 orange
✅ Navigation : Vers détail signalement
✅ Lecture : Notification grisée, badge = 0
```

---

## 🎉 Si tout fonctionne

**Phase 5 : Notifications = 100% COMPLÈTE** 🚀

Prochaine étape : **Phase 6 - Cache & Performance** ou **Phase 7 - Jobs Asynchrones**

---

## 📝 Notes de Test

Date : __________________
Testeur : __________________

**Compte A** :
- User ID : ______
- Téléphone : ______

**Compte B** :
- User ID : ______
- Téléphone : ______

**Signalement testé** : #______

**Résultat** :
- [ ] ✅ Fonctionne parfaitement
- [ ] ⚠️ Problème partiel : _________________
- [ ] ❌ Ne fonctionne pas : _________________

**Observations** :
_______________________________________
_______________________________________
_______________________________________
