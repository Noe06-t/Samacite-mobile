# Prompt de design pour Google Stitch — SamaCité

Ce document contient le prompt à utiliser dans Google Stitch pour générer les maquettes de refonte UI de l'application SamaCité, en conservant la palette de couleurs actuelle et en modernisant le style visuel.

---

## Contexte global (à mettre en tête du prompt)

```
Je conçois les maquettes d'une application mobile de signalement citoyen appelée "SamaCité" (Dakar, Sénégal — signaler des problèmes urbains : nids-de-poule, fuites d'eau, éclairage défaillant, etc.).

DIRECTIVE DE DESIGN GÉNÉRALE :
- Garder impérativement cette palette de couleurs existante (ne pas la changer) :
  • Primaire / Orange : #FFA000 (texte noir dessus)
  • Secondaire / Vert : #007A3F (texte blanc dessus)
  • Fond : #FFFFFF
  • Danger / Rouge : #EA0707
  • Statut "En cours" : bleu translucide #0023D1
  • Statut "Résolu" : vert translucide #34C759
  • Statut "En attente" : orange translucide #FFA000
- Style voulu : moderne, dynamique, chaleureux, avec dégradés doux (vert #007A3F→#00A854 pour les headers "signalements/notifications", orange #FFA000→#FF8F00 pour les headers "profil"), coins arrondis généreux (16-24px), ombres légères, cartes blanches épurées.
- Priorité absolue : légèreté visuelle et rapidité perçue de chargement (peu d'éléments lourds, skeletons/placeholders simples, pas de surcharge graphique).
- Typographie : police système claire et moderne (type Roboto/Inter), hiérarchie forte entre titres et texte secondaire (gris #00000089 / #00000054).
- Mobile first, format portrait, Material 3.
```

---

## Écran par écran

**1. Splash Screen** — Fond blanc, logo SamaCité centré, nom de l'app en vert gras, slogan "Signaler. Suivre. Améliorer." en gris clair, loader orange discret en bas. Doit paraître instantané et épuré.

**2. Onboarding (6 slides)** — Carousel plein écran avec illustrations de la ville (plage, nid-de-poule, fuite, éclairage, parcelle), titre + description courte par slide, indicateurs de progression en points, boutons "Passer" (texte) et "Suivant/Commencer" (bouton orange plein, coins arrondis).

**3. Connexion** — Logo en haut, champ email/téléphone, champ mot de passe, lien "Mot de passe oublié", bouton principal orange plein largeur, lien "Créer un compte" en bas, fond blanc épuré.

**4. Inscription** — Même esprit que Connexion : champs prénom/nom, téléphone (+221), email optionnel, mot de passe + confirmation, case à cocher conditions, bouton orange plein largeur.

**5. Accueil (Home)** — AppBar dégradé vert avec icône notification (badge rouge compteur), message de bienvenue personnalisé + slogan, carousel d'images auto-défilant, deux grandes cartes d'action en dégradé ("Nouveau signalement" / "Mes signalements") avec icônes et coins très arrondis.

**6. Navigation principale** — Bottom navigation bar à 4 onglets (Accueil, Signalements, Carte, Profil), coins arrondis en haut, légère ombre flottante, icône active colorée + label.

**7. Prise de photo (avant signalement)** — Écran caméra/aperçu photo, boutons "Prendre une photo" / "Choisir depuis la galerie", état "Analyse IA en cours..." avec loader animé élégant.

**8. Création de signalement** — Aperçu photo en haut (coins arrondis), champ titre, menu déroulant catégorie (avec icônes par catégorie), description (pré-remplie, modifiable), bloc localisation avec statut GPS (icône + adresse détectée, bouton réessayer si erreur), bouton "Créer le signalement" orange plein largeur en bas.

**9. Liste des signalements** — Liste scrollable de cartes : image à gauche/au-dessus, titre, description tronquée, badges statut colorés (pending/in_progress/resolved), petites icônes like/commentaires avec compteurs, date. Bouton filtre en haut (icône avec badge si filtre actif) ouvrant une bottom sheet de filtres.

**10. Mes signalements** — Même design que la liste générale mais filtré sur l'utilisateur, header personnalisé avec dégradé léger.

**11. Détail d'un signalement** — Image principale plein largeur (zoomable au clic), titre, badge statut, catégorie, adresse + mini-carte ou bouton "Voir sur la carte", description complète, bouton like/unlike avec compteur animé, section commentaires (liste + champ d'ajout), bouton supprimer rouge (si propriétaire, avec dialogue de confirmation).

**12. Carte interactive** — Carte plein écran (type OpenStreetMap) centrée sur Dakar, marqueurs colorés selon le statut du signalement, clic sur un marqueur → mini-popup aperçu puis accès au détail.

**13. Profil** — Header dégradé vert avec avatar rond (initiales ou photo), nom + email/téléphone, cartes d'information (nom, email, téléphone), section paramètres (Modifier le profil, Changer le mot de passe, Notifications) sous forme de liste à icônes, carte de déconnexion rouge en bas avec confirmation.

**14. Modifier le profil** — AppBar dégradé orange, avatar avec bouton caméra en overlay, champs nom/prénom/email/téléphone, boutons Enregistrer (orange) / Annuler.

**15. Changer le mot de passe** — AppBar dégradé orange, carte d'info bleue explicative, champs mot de passe actuel/nouveau/confirmation, bouton valider orange.

**16. Notifications** — AppBar dégradé vert, liste de notifications (icône type + texte + date), état vide illustré si aucune notification, clic → renvoie au signalement concerné.

---

## À faire ensuite

La refonte du logo sera traitée séparément, une fois les maquettes d'écrans validées sur Stitch.
