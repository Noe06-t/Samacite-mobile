---
applyTo: '**'
---

---

# spec.md — Spécifications complètes pour **SamaCité** concentrées sur l'application mobile 

## 0. Contraintes générales
* Mobile Flutter : **Utiliser Dio pour toutes les requêtes API**
* Faire du TDD  (Tests avant code)
* Les maquettes des interfaces mobiles sont dans le dossier `maquettes/`
* Utiliser des dépendances pour ne pas recreer la roue 
* Suivre la logique d'implémentation du backend Laravel (Repository):"## 📋 Index des Phases

1. [Phase 1 - Authentification & Autorisation](#phase-1---authentification--autorisation)
2. [Phase 2 - Gestion des Signalements (Reports)](#phase-2---gestion-des-signalements-reports)
3. [Phase 3 - Gestion des Catégories & Images](#phase-3---gestion-des-catégories--images)
4. [Phase 4 - Système de Commentaires](#phase-4---système-de-commentaires)
5. [Phase 5 - Notifications & Broadcasting](#phase-5---notifications--broadcasting)
6. [Phase 6 - Cache & Performance](#phase-6---cache--performance)
7. [Phase 7 - Jobs Asynchrones](#phase-7---jobs-asynchrones)
8. [Phase 8 - Statistiques & Analytics](#phase-8---statistiques--analytics)"


---

## 1. Vision & périmètre

SamaCité est une plateforme (mobile + backend + interface web d'administration) permettant aux citoyens de signaler des problèmes, aux autorités de suivre les signalements, et de gérer leur traitement.
Cette spécification couvre **Backend Laravel**, **Frontend React**, **Mobile Flutter**, **Axios**, **Sécurité**, **Couleurs**, **Performances**, **Rôles & permissions**.

---

# 2. Rôles & permissions (Spatie)

Deux rôles :

* **Admin**
* **Utilisateur**

Gérés via **spatie/laravel-permission**
Authentification via **Laravel Sanctum**.

### 2.1 Permissions

* `dashboard.access` — accès admin Web
* `user.view`, `user.manage`
* `report.create`, `report.view.own`, `report.view.any`
* `report.update`, `report.assign`, `report.change_state`
* `report.delete`
* `report.comment`
* `notification.send`
* `stats.view`
* `settings.manage`
* `file.upload`

### 2.2 Rôles

* **Admin** : toutes permissions
* **Utilisateur** : `report.create`, `report.view.own`, `report.comment`, `file.upload`

---

# 3. Architecture globale

### Backend Laravel

* Sanctum (auth), Spatie (permissions)
* Repository Pattern + Service Layer
* Cache Redis + Queues
* Broadcasting (Pusher/Redis)
* Storage S3/MinIO
* API REST + Laravel Resources

### Frontend React (Admin)

* **Axios**
* **React Query** pour caching + invalidation
* **Atomic Design**
* **Hooks + Context API**
* **Axios interceptors** pour token Sanctum
* Optimisation anti N+1 : endpoints optimisés côté backend

### Mobile Flutter

* Dio pour API
* Riverpod pour state
* Image picker + compression
* Notifications via FCM

---

# 4. Modèle de données (tables principales)

Tables : `users`, `reports`, `report_images`, `categories`, `comments`, `jobs`, `failed_jobs`, tables Spatie.

---

# 5. API REST (exemples)

* `POST /api/auth/login`
* `POST /api/reports`
* `GET /api/reports?include=user,images`
* `PATCH /api/reports/{id}/status`
* `DELETE /api/reports/{id}`

---

# 6. Backend — Repository Pattern

```
app/
 └── Repositories/
       ├── ReportRepositoryInterface.php
       ├── UserRepositoryInterface.php
       └── Eloquent/
             ├── EloquentReportRepository.php
             └── EloquentUserRepository.php
```

Chaque repository :

* `paginateWithFilters()`
* `findWithRelations()`
* `create()`, `update()`, `delete()`

Eager-loading **systématique** pour éviter N+1 (`with(['user','images'])`).

---

# 7. Cache & Queues (Redis)

### Cache

* Tagging : `Cache::tags(['reports'])`
* TTL : 1h pour stats, 60s pour listes

### Queues

* Jobs :

  * `ProcessReportImages`
  * `NotifyUserJob`
  * `AggregateStatsJob`
* Supervisé via `supervisor` ou Kubernetes

---

# 8. États des signalements (couleurs)

* **En cours** : `#0023D142`
* **Résolu** : `#34C75936`
* **En attente** : `#FFA00070`

---

# 9. Palette couleurs générale

* Bouton primaire : **#FFA000** (texte noir)
* Cadres & sections : **#007A3F** (texte blanc)
* Fond général : **#FFFFFF**
* Danger : **#EA0707** (texte blanc)

---

# 10. FRONTEND REACT — Architecture + Axios

---

## 10.1 Obligations du frontend (demandées)

* Hooks + Contexts
* Atomic design
* Axios pour toutes les requêtes
* Gestion globale du token (Sanctum)
* Aucune fuite N+1 → usage de `react-query` + endpoints backend optimisés
* Optimisation performances (memo, lazy, virtualized lists)

---

## 10.2 Setup Axios (axiosInstance)

Créer un fichier :
`src/api/axiosInstance.js`

```js
import axios from 'axios';

const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  withCredentials: true,
  headers: { 'Accept': 'application/json' }
});

// Interceptor pour inclure token Sanctum
axiosInstance.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Interceptor d’erreurs global
axiosInstance.interceptors.response.use(
  res => res,
  err => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);

export default axiosInstance;
```

---

## 10.3 Exemple d’un hook métier : useReports()

```js
import { useQuery, useMutation } from "@tanstack/react-query";
import axiosInstance from "../api/axiosInstance";

export const useReports = () => {
  const list = useQuery({
    queryKey: ['reports'],
    queryFn: async () => {
      const res = await axiosInstance.get("/reports?include=user,images");
      return res.data;
    }
  });

  const create = useMutation({
    mutationFn: async (payload) => {
      const res = await axiosInstance.post("/reports", payload);
      return res.data;
    }
  });

  return { list, create };
};
```

---

## 10.4 AuthContext avec Axios

```js
import { createContext, useState } from "react";
import axiosInstance from "../api/axiosInstance";

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);

  const login = async (credentials) => {
    const res = await axiosInstance.post("/auth/login", credentials);
    localStorage.setItem("token", res.data.token);
    setUser(res.data.user);
  };

  const logout = () => {
    localStorage.removeItem("token");
    setUser(null);
    axiosInstance.post("/auth/logout");
  };

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};
```

---

## 10.5 Structure Atomic Design

```
src/
 ├── components/
 │     ├── atoms/
 │     ├── molecules/
 │     ├── organisms/
 │     ├── templates/
 │     └── pages/
 ├── api/
 │     └── axiosInstance.js
 ├── hooks/
 ├── contexts/+
 └── utils/
```

---

# 11. Mobile Flutter

Pas modifié sauf précision : utiliser **Dio** (équivalent Axios pour Flutter).

---

# 12. Sécurité

* Sanctum + token Bearer
* Rate limiting
* Policies (Reports, Users)
* Validation forte
* Stockage protégé des fichiers
* HTTPS obligatoire

---

# 13. Performance

* Redis cache
* React Query cache côté frontend
* Axios + interceptors + retry optionnel
* Pagination sur toutes les listes
* Lazy load + split bundles
* Jobs asynchrones

---

# 14. Tests

* PHPUnit (Laravel)
* Jest (React)
* Widget tests (Flutter)
* E2E : Cypress

---

# 15. Déploiement

* Docker / Kubernetes
* CI/CD GitHub Actions
* Supervisor pour workers queues
* Reverse proxy : Nginx

---

# 16. Checklist

* [ ] Backend terminé (repos, services, API REST)
* [ ] Auth Sanctum + Spatie OK
* [ ] Admin React + Axios setup OK
* [ ] Mobile OK
* [ ] Redis cache + queues
* [ ] Tests

---

# 17. Conclusion

Cette version inclut **Axios** de manière officielle, structurée, et intégrée au workflow React via :

* Axios Instance
* Interceptors auth + errors
* Hooks API
* Context global Auth
* React Query pour caching
