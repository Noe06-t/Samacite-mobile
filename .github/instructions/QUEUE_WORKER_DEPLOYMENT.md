# Guide de déploiement - Queue Worker

## 🎯 Objectif

Configurer le queue worker pour traiter automatiquement les notifications et autres jobs asynchrones.

## ⚠️ Important

**Sans queue worker actif, aucune notification ne sera envoyée !**

Les événements suivants nécessitent le queue worker :
- ✉️ Notifications de signalement créé
- 💬 Notifications de commentaire
- 👍 Notifications de like
- 🔄 Notifications de changement de statut
- 🖼️ Traitement d'images (compression, thumbnails)

---

## 🔧 Configuration sur le serveur 192.168.1.17:8000

### Option 1 : Lancement manuel (test)

```bash
cd /path/to/samacite
php artisan queue:work --tries=3 --timeout=3600
```

### Option 2 : Avec systemd (recommandé pour production)

#### 1. Créer le fichier de service

```bash
sudo nano /etc/systemd/system/samacite-queue.service
```

Contenu :
```ini
[Unit]
Description=SamaCité Queue Worker
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/samacite
ExecStart=/usr/bin/php /var/www/samacite/artisan queue:work --sleep=3 --tries=3 --max-time=3600
Restart=always
RestartSec=10

StandardOutput=append:/var/www/samacite/storage/logs/queue-worker.log
StandardError=append:/var/www/samacite/storage/logs/queue-worker-error.log

[Install]
WantedBy=multi-user.target
```

#### 2. Activer le service

```bash
sudo systemctl daemon-reload
sudo systemctl enable samacite-queue
sudo systemctl start samacite-queue
```

#### 3. Commandes utiles

```bash
# Vérifier le statut
sudo systemctl status samacite-queue

# Arrêter le worker
sudo systemctl stop samacite-queue

# Redémarrer le worker (après déploiement)
sudo systemctl restart samacite-queue

# Voir les logs en temps réel
sudo journalctl -u samacite-queue -f

# Voir les logs d'erreur
tail -f /var/www/samacite/storage/logs/queue-worker-error.log
```

---

## 📊 Monitoring

### Vérifier les jobs en attente

```bash
php artisan queue:work --once  # Traiter 1 job pour tester
php artisan queue:failed       # Jobs échoués
php artisan queue:retry all    # Retenter les jobs échoués
```

### Vérifier dans la base de données

```sql
-- Jobs en attente
SELECT COUNT(*) FROM jobs;

-- Jobs échoués
SELECT * FROM failed_jobs ORDER BY failed_at DESC LIMIT 10;

-- Notifications récentes
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 20;
```

---

## 🚨 Dépannage

### Le worker ne démarre pas

1. Vérifier les permissions :
```bash
sudo chown -R www-data:www-data /var/www/samacite/storage
sudo chmod -R 775 /var/www/samacite/storage
```

2. Vérifier la connexion Redis/Base de données

3. Vérifier les logs :
```bash
tail -f storage/logs/laravel.log
```

### Jobs qui échouent

```bash
# Voir les détails
php artisan queue:failed

# Retenter un job spécifique
php artisan queue:retry {id}

# Retenter tous
php artisan queue:retry all

# Supprimer les jobs échoués
php artisan queue:flush
```

### Redémarrage après changement de code

⚠️ **Important** : Le worker garde le code en mémoire !

Après chaque déploiement :
```bash
sudo systemctl restart samacite-queue
```

Ou avec Supervisor :
```bash
sudo supervisorctl restart samacite-worker:*
```

---

## 📈 Performance

Pour traiter plus de jobs simultanément, augmenter le nombre de workers :

```bash
# Avec systemd (éditer le fichier .service)
sudo nano /etc/systemd/system/samacite-queue.service
# Impossible de lancer plusieurs instances avec systemd simple

# Mieux : utiliser Supervisor avec plusieurs workers
```

### Configuration Supervisor (alternatif)

```ini
[program:samacite-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/samacite/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
user=www-data
numprocs=4  # 4 workers parallèles
redirect_stderr=true
stdout_logfile=/var/www/samacite/storage/logs/worker.log
```

---

## ✅ Checklist de déploiement

- [ ] Queue worker configuré (systemd ou Supervisor)
- [ ] Service activé au démarrage
- [ ] Logs accessible et surveillés
- [ ] Test de notification effectué
- [ ] Monitoring en place (optionnel : Laravel Horizon)
- [ ] Processus documenté pour l'équipe

---

## 📞 Support

En cas de problème :
1. Vérifier `systemctl status samacite-queue`
2. Consulter les logs `storage/logs/laravel.log`
3. Tester manuellement `php artisan queue:work --once`
4. Contacter l'équipe backend

