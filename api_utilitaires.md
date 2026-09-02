# APIs et services utilitaires — App Mobile Livreur Gab'Pharma

**Date :** 28 août 2026
**Rôle du document :** lister, en dehors de l'API métier Django déjà couverte par `api_contrat_besoins.md`, les **services tiers externes** (clés API, comptes fournisseurs) et **paquets techniques** dont l'app mobile Livreur aura besoin pour passer du mode démonstration (`AppConfig.demoMode`) à une app réellement opérationnelle. Pour chacun : état actuel, procédure d'acquisition, procédure d'intégration.

**Méthode :** ce document s'appuie sur l'équivalent patient (`C:\Users\24174\StudioProjects\gabpharma_patient\api_utilitaires.md`, 14 juillet 2026) mais **n'en est pas une simple copie renommée** — l'app Livreur a des besoins propres (position temps réel en tournée, règlement des soldes, dossier documentaire), et le backend a nettement avancé depuis le 14 juillet (notamment le push FCM, entièrement livré côté Django le 23 août 2026 — voir `documentation/api_besoins_patient_evolutions_20260823.md` côté projet Django). Chaque point ci-dessous a été vérifié en lisant le code backend réel (`apps/api/mobile_courier.py`, `apps/api/mobile_shared.py`, `apps/accounts/models.py`, `apps/payments/models.py`), pas deviné depuis l'app Flutter.

---

## 1. Notifications push — Firebase Cloud Messaging (FCM)

**Libellé :** notifications reçues même app fermée (nouvelle course disponible, changement de statut de course, incident résolu).

**État actuel — bien plus avancé que chez Patient à l'écriture de son propre document :** contrairement à l'app Patient (où FCM était listé « hors contrat » le 14 juillet), **le backend est entièrement prêt côté Livreur depuis le 23 août 2026** :
- Projet Firebase `gabpharma-fcm` déjà créé (voir `documentation/firebase_fcm.md` côté projet Django), compte de service généré et câblé (`FIREBASE_ADMIN_CREDENTIALS_JSON` en `.env`, chargé via `python-dotenv`).
- Modèle `apps/notifications/models.py::Device` générique Patient/Livreur (`app` vaut `Device.App.COURIER` pour un compte livreur — voir `_DEVICE_APP_BY_ROLE` dans `apps/api/mobile_shared.py`).
- Endpoints déjà exposés et fonctionnels pour les **deux rôles** (`IsMobileUser`, pas une garde patient uniquement) :
  - `POST /mobile/devices/` — enregistre/replace un token (`push_token`, `platform`, `device_label`).
  - `POST /mobile/devices/unregister/` — désactive un appareil.
  - `GET /mobile/profile/devices/` — liste les appareils enregistrés du compte connecté.
- Déclencheurs déjà branchés côté service Django : changement de statut de **livraison** (`apps/deliveries/services.py::_record_status`), donc directement pertinent pour le livreur (`assigned`→`picked_up`→…), en plus des commandes et du support.
- `send_push_to_user()` est *best-effort* : un échec d'envoi ne casse jamais la transaction métier, et un token que FCM signale `UnregisteredError` est désactivé automatiquement.

**Il ne reste donc que le côté Flutter à faire** — aucun nouveau compte, aucune nouvelle clé à demander.

**Procédure d'acquisition (déjà faite pour le projet, à réutiliser) :**
1. Utiliser le projet Firebase existant `gabpharma-fcm` (ne pas en recréer un) — demander l'accès si besoin.
2. Ajouter une application Android **Livreur** distincte de l'app Patient dans ce même projet Firebase (package `ga.gabpharma.gabpharma_livreur`, déjà visible dans les commandes ADB du projet) → télécharger un `google-services.json` **spécifique à ce package**, différent de celui de l'app Patient.

**Procédure d'intégration :**
- Ajouter `firebase_core` et `firebase_messaging` à `pubspec.yaml`.
- Placer `google-services.json` dans `android/app/` (déjà présent un fichier `google-services.json` dans le dépôt d'après le commit « Ajoute la config Firebase » du 20 juillet — **vérifier qu'il correspond bien au bon projet/package avant de s'en resservir**, il a pu être ajouté pour une autre raison que le push).
- Appliquer le plugin Gradle Google Services (`android/build.gradle` + `android/app/build.gradle`).
- Initialiser Firebase dans `main()`, demander la permission de notification (Android 13+), récupérer le token FCM de l'appareil et l'envoyer à `POST /mobile/devices/` juste après une connexion réussie (et à chaque démarrage si le token a changé — FCM peut le renouveler).
- Appeler `POST /mobile/devices/unregister/` à la déconnexion pour ne pas continuer à notifier un appareil qui s'est déconnecté.
- Gérer la réception au premier plan (`FirebaseMessaging.onMessage`) et le clic sur la notification (navigation vers Courses/Historique/Revenus selon `target_type`/`target_id`, déjà présents dans le payload `GET /mobile/notifications/`).
- Remplacer alors le texte honnête actuel de l'écran 15 (flux tiré uniquement à l'ouverture de l'app) — mais garder à l'esprit que le flux agrégé (`GET /mobile/notifications/`) reste la source de vérité pour l'historique ; FCM n'apporte que le **temps réel app fermée**, pas un nouveau contenu.

---

## 2. Cartographie — mêmes options que côté Patient, mais enjeu plus fort ici

### 2.1 Option recommandée : OpenStreetMap + `flutter_map` (gratuit, sans clé)

**Description :** décision déjà actée côté web (`documentation/vitrine.md`) et recommandée côté Patient. **À reproduire côté Livreur pour la même raison de cohérence**, sauf si le produit veut explicitement l'expérience Google Maps native.

**Enjeu spécifique Livreur :** l'écran 09 (Carte et navigation) est un outil de travail utilisé en déplacement, pas un simple affichage informatif comme côté Patient — la fluidité et la fiabilité du rendu carte comptent plus ici. `flutter_map` reste néanmoins largement suffisant pour un usage MVP (itinéraire + marqueurs pharmacie/patient), sans les frais Google.

**Procédure d'acquisition :** aucune, mêmes conditions d'attribution obligatoire OSM que côté Patient/web.

**Procédure d'intégration :**
- `flutter_map` + `latlong2` dans `pubspec.yaml`.
- Remplacer le `CustomPainter` illustratif actuel de l'écran 09 (`NavigationMapScreen`, marqué comme carte simplifiée dans `CLAUDE.md`) et de l'écran 13 (`AvailabilityScreen`, `_ZoneMapPainter`) par un vrai `FlutterMap`.
- Coordonnées pharmacie déjà présentes côté backend (`_pharmacy_payload` n'inclut aujourd'hui ni `latitude` ni `longitude` dans `mobile_courier.py` — **à ajouter**, voir `api_contrat_besoins.md` §4 ; elles existent déjà sur le modèle `Pharmacy` et sont déjà exposées côté API Patient depuis le 14 juillet). Position du patient : toujours du texte libre (`delivery_address`), pas de coordonnées — même limite que côté Patient.

### 2.2 Option alternative : Google Maps SDK natif

Identique à ce que documente l'app Patient (§3.2 de son propre `api_utilitaires.md`) : compte de facturation Google Cloud obligatoire, clé à restreindre par empreinte SHA-1. **Une clé Google Maps API est déjà provisionnée et préparée côté app Livreur** (voir `CLAUDE.md` du projet, section Lot 2 : clé injectée via `android/local.properties` → `build.gradle.kts` → `AndroidManifest.xml`, package et SHA-1 debug déjà communiqués), mais **le paquet `google_maps_flutter` n'a jamais été ajouté à `pubspec.yaml`** — la clé attend une décision, pas prête à l'usage telle quelle.

### 2.3 Bouton « Ouvrir la navigation » (sans clé, quelle que soit l'option ci-dessus)

**Description :** ouvrir l'app de navigation du téléphone (Google Maps, Waze...) pré-remplie avec l'itinéraire — exactement ce que prévoit `mobile_livreur.md` §3 pour l'écran 9 (« bouton ouvrir l'application de navigation du téléphone »).

**Procédure d'intégration :** `url_launcher`, `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>`. Écran 09 actuel (`NavigationMapScreen`) a déjà un FAB de recentrage honnête (« indisponible en démonstration ») — le bouton « ouvrir navigation externe » est un complément à ajouter au moment du branchement, pas un remplacement de la carte in-app.

---

## 3. Géolocalisation temps réel du livreur — spécifique à cette app, pas encore cadré côté produit

**Libellé :** transmettre la position GPS du livreur pendant une course active, pour que le patient (dans son app) voie où en est sa livraison.

**Différence importante avec le besoin « géolocalisation » côté Patient :** l'app Patient a besoin de la position de **l'utilisateur lui-même**, ponctuellement, pour trier des pharmacies par proximité — déjà largement construit côté backend (`?lat=&lng=`, distance Haversine, implémenté le 23 août 2026). L'app **Livreur**, elle, doit **émettre en continu** sa propre position pendant une tournée pour que quelqu'un d'autre (le patient) la consulte — un besoin technique très différent (permission arrière-plan, ping périodique, coût batterie réel).

**État actuel : cadré, rien d'implémenté.** Voir `documentation/cadrage_suivi_temps_reel_livreur.md` (23 août 2026, côté projet Django) — ce document pose explicitement les questions à trancher avant d'écrire la moindre ligne de code, il ne recommande pas de foncer. Points clés à connaître avant d'engager quoi que ce soit :
- **Aucun modèle ni endpoint n'existe encore** — recommandation du cadrage : pas de nouveau modèle `DeliveryPosition`, juste 3 champs (`last_known_latitude`/`longitude`/`updated_at`) directement sur `Delivery`, écrits par un futur `POST /mobile/courier/deliveries/<id>/position/` (proposé, non construit).
- **Fréquence de ping non tranchée** — recommandation du cadrage pour un premier jet : 30-60 secondes, uniquement pendant `assigned`/`picked_up`/`in_transit`, jamais en dehors d'une course (question de batterie **et** de confidentialité du livreur lui-même).
- **Décision produit préalable requise** (§3 du cadrage) : le pilote a-t-il vraiment besoin d'une carte temps réel façon VTC, ou le statut + ETA actuels suffisent-ils ? Rien dans le suivi produit ne signale que c'est un point de friction réel aujourd'hui.
- Le cadrage identifie lui-même l'app Livreur comme **la partie coûteuse** du chantier (🔴), bien plus que le backend (🟡) ou l'app Patient (🟡 — juste un point sur une carte déjà utilisée ailleurs).

**Procédure d'acquisition :** aucune — capacité de l'appareil, pas un service à souscrire.

**Procédure d'intégration (si le feu vert produit est donné) :**
- Paquet Flutter `geolocator`, en mode **arrière-plan** cette fois (pas juste premier plan comme suffirait côté Patient) — implique `ACCESS_BACKGROUND_LOCATION` sur Android, une review Play Store potentiellement plus stricte, et un texte de permission qui explique clairement pourquoi (uniquement pendant une course active).
- Envoi silencieux et non bloquant : un échec réseau pendant une tournée ne doit jamais interrompre le flux métier (collecte/remise restent possibles même sans réseau, la position est secondaire).
- **Recommandation : ne pas démarrer ce chantier avant confirmation produit explicite** (point 1 du cadrage), et avant d'avoir une estimation réelle — pas seulement théorique — de la consommation batterie sur une tournée de plusieurs heures.

---

## 4. Règlement des soldes livreurs (Mobile Money / virement) — distinct d'eBilling

**Libellé :** le versement hebdomadaire du solde `CourierAccount.balance_fcfa` (dans un sens ou dans l'autre selon `decisions.md` §7.5) entre Gab'Pharma et le livreur.

**Différence avec eBilling :** eBilling (documenté dans l'équivalent Patient, §1 de son `api_utilitaires.md`) sert à **encaisser** un paiement du patient. Ici il s'agit de l'inverse — **verser ou recevoir** un règlement lié au solde du livreur — un besoin métier différent, pas juste « eBilling côté livreur ».

**État actuel :** modèle `apps/payments/models.py::CourierSettlement` déjà construit et fonctionnel (`direction` : `to_platform`/`to_courier`, `method` : `cash`/`mobile_money`/`bank`/`other`, `external_reference` obligatoire) — mais **exclusivement piloté par le Staff** (`processed_by`), jamais par le livreur lui-même. C'est une décision produit délibérée (`dash_livreur.md` §5 : « Lecture seule côté livreur »), pas un manque technique.

**Conséquence pour l'app mobile :** **aucune intégration de passerelle de paiement sortant n'est nécessaire côté Flutter** pour l'instant — le bouton « Demander un virement » de l'écran 12 (Revenus) doit rester honnête (« indisponible en démonstration/en libre-service ») même après branchement réel à l'API, puisqu'aucune route mobile ne permet cette action aujourd'hui. Si le produit décide un jour d'un vrai self-service de demande de règlement, ce serait un nouvel endpoint à construire côté Django avant tout travail Flutter — à documenter dans `api_contrat_besoins.md` le jour où cette décision est prise, pas maintenant.

**Procédure d'acquisition/intégration :** sans objet tant que cette décision produit n'est pas prise.

---

## 5. E-mail transactionnel de production (partagé avec l'app Patient)

**Libellé :** envoi réel des e-mails de sécurité — codes 2FA, mot de passe, dossier documentaire (accusés de validation/refus de pièce), etc.

**Description :** exactement le même besoin que documenté côté Patient (`api_utilitaires.md` §5, `EMAIL_BACKEND` pointe vers MailHog en local aujourd'hui). C'est un réglage **transverse au backend**, pas par app mobile — le brancher profite aux deux apps en même temps, aucun travail Flutter Livreur spécifique.

**Procédure d'acquisition et d'intégration :** identiques à celles déjà documentées côté Patient — se référer à ce document plutôt que de dupliquer la procédure ici. Point de vigilance supplémentaire propre au livreur : les e-mails de revue de dossier documentaire (validation/refus de pièce `CourierDocument`) devront aussi partir en production une fois ce canal branché, si de telles notifications existent déjà côté service (à vérifier au moment du branchement des endpoints Documents, voir `api_contrat_besoins.md`).

---

## 6. SMS — décision déjà tranchée, rien à faire

**Libellé :** envoi de SMS (par exemple pour le code de remise ou une alerte de nouvelle course).

**État : décision produit actée le 13 août 2026, à ne pas rouvrir sans besoin fort et chiffré.** `documentation/decisions.md` (projet Django) : *« aucun fournisseur SMS ne sera intégré, pour ne pas engager de coût récurrent... Cette décision annule le prérequis pilote correspondant... et n'est pas un simple report : elle ne sera reconsidérée que si un besoin métier fort et chiffré se présente. »* Le 2FA reste e-mail uniquement (TOTP optionnel, réservé au Super Administrateur).

**Contrairement à l'app Patient** (où l'écran 17 affichait à tort « envoyé par SMS » alors que c'était un e-mail — écart explicitement signalé dans son propre `api_utilitaires.md` §6), **l'app Livreur ne semble pas avoir ce problème** : le texte actuel de l'écran 08 (« Nouveau code envoyé à la cliente (démonstration) ») ne mentionne aucun canal spécifique — rien à corriger de ce côté.

**Aucune action requise** de ce document pour l'app Livreur, au-delà de rester vigilant à ne jamais laisser un futur texte Flutter promettre un SMS qui ne sera jamais envoyé.

---

## 7. Paquets Flutter sans service externe

Aucun compte ni clé API nécessaire — seulement `pubspec.yaml` et, pour certains, une permission native. Débloquent des comportements aujourd'hui honnêtement affichés comme « indisponible en démonstration ».

| Besoin | Paquet Flutter | Écran(s) concerné(s) | Permissions natives | Dépendance backend |
|---|---|---|---|---|
| Stockage sécurisé des jetons JWT (`access`/`refresh`) | `flutter_secure_storage` | Toute l'app (post-connexion) | Aucune — Keystore Android | Aucune — `POST /mobile/auth/refresh/` déjà exposé et générique Patient/Livreur |
| Appel téléphonique réel (patiente, support) | `url_launcher` (`tel:`) | 08 (Course active), 16/17 (Support) | Aucune | Aucune |
| Ouverture app de navigation externe | `url_launcher` (voir §2.3) | 09 | Aucune | Coordonnées pharmacie à ajouter au payload (voir `api_contrat_besoins.md` §4) |
| Sélection/prise de photo (dossier documents, pièce jointe ticket) | `image_picker` ou `file_picker` | 14 (Documents), 16/17 (Support) | Caméra/stockage | **Bloquant** : aucun endpoint mobile Documents n'existe encore (voir `api_contrat_besoins.md` §3) — inutile de câbler la capture avant que le backend expose la route |
| Géolocalisation continue en tâche de fond | `geolocator` (mode arrière-plan) | 08, 09 | `ACCESS_BACKGROUND_LOCATION` | Voir §3 — décision produit non prise, backend non construit |
| Biométrie (déverrouillage rapide) | `local_auth` | Non promis aujourd'hui par l'écran 18 actuel | `USE_BIOMETRIC` | Aucune — capacité appareil pure, à n'ajouter que si le produit le demande explicitement (contrairement à l'app Patient, l'écran 18 Livreur actuel ne mentionne pas de biométrie dans son contenu réel) |

**Procédure d'acquisition :** aucune — dépendances open source [pub.dev](https://pub.dev).

**Procédure d'intégration commune :** ajouter la dépendance, `flutter pub get`, déclarer les permissions nécessaires, remplacer les `SnackBar`/dialogues « indisponible en démonstration » actuels par l'appel réel, écran par écran, **seulement quand le backend correspondant est prêt** (voir la colonne « Dépendance backend » — plusieurs de ces paquets seraient prématurés à intégrer aujourd'hui).

---

## 8. Optionnel — supervision et qualité

Mêmes recommandations que côté Patient (`api_utilitaires.md` §8) : Sentry ou Firebase Crashlytics pour le suivi de crash (Crashlytics devient un choix naturel une fois Firebase déjà en place pour le push, §1), Firebase Analytics en option pure, non demandé explicitement par le produit.

---

## 9. Récapitulatif — ce qu'il faut vraiment acquérir avant le lancement

| Service | Bloquant pour le lancement ? | Compte à créer | État |
|---|---|---|---|
| Firebase Cloud Messaging | Non bloquant — les notifications fonctionnent déjà en flux agrégé à l'ouverture | **Non — déjà fait** (projet `gabpharma-fcm` existant) | Backend 100 % prêt, reste l'intégration Flutter |
| E-mail transactionnel de production | **Oui** — sans lui, la 2FA et le dossier documentaire ne fonctionneront pas en vrai | Oui (partagé avec Patient) | Non fait |
| OpenStreetMap/`flutter_map` | Non bloquant — l'écran 09 fonctionne déjà en mode illustratif honnête | Non | Non intégré |
| Géolocalisation temps réel du livreur | Non — hors contrat actuel, décision produit non prise | Non (capacité appareil) | Cadré seulement, rien construit ni côté backend ni côté Flutter |
| Règlement des soldes livreurs (Mobile Money/virement) | Non — reste une action Staff par design | Sans objet | Fonctionnel côté Staff, volontairement absent du mobile |
| Google Maps SDK natif | Non — alternative optionnelle à OSM/Leaflet | Clé déjà provisionnée, paquet jamais ajouté | En attente de décision |
| SMS | Non — décision définitivement tranchée (aucun fournisseur) | Sans objet | Réglé, ne pas rouvrir |
| Sentry / Crashlytics | Non bloquant, recommandé | Oui | Non fait |
