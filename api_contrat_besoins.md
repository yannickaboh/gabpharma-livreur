# Besoins API — App Mobile Livreur Gab'Pharma

**Date :** 28 août 2026
**Auteur :** étude comparative Claude Code, sur le même modèle que `C:\Users\24174\StudioProjects\gabpharma_patient\api_contrat_besoins.md` (14 juillet 2026), à partir de :
- `C:\Users\24174\Documents\projets\django projects\gabpharma\documentation\api_contrat.md` (contrat API mobile, §5 API Livreur + §6 API transversale) ;
- lecture directe du code Django : `apps/api/mobile_courier.py`, `apps/api/mobile_shared.py`, `apps/api/mobile_auth.py`, `apps/api/urls.py`, `apps/accounts/models.py` (`ProfessionalApplication`, `CourierVerification`, `CourierDocument`), `apps/payments/models.py` (`CourierAccount`, `CourierLedgerEntry`, `CourierSettlement`), `apps/accounts/forms.py` (`ZONE_CHOICES`) ;
- `documentation/dash_livreur.md`, `documentation/mobile_livreur.md`, `documentation/decisions.md` §7.5, `documentation/api_besoins_patient_evolutions_20260823.md`, `documentation/cadrage_suivi_temps_reel_livreur.md` (projet Django) ;
- les 18 écrans Flutter Livreur construits dans ce dépôt (`lib/src/*.dart`), tous validés visuellement sur le S8 au 28 août 2026, en mode démonstration statique (voir `CLAUDE.md`).

**Règle de méthode, identique au document Patient : rien de ce qui existe côté mobile n'est remis en cause.** Ce document part des 18 écrans Flutter tels qu'ils sont et identifie, pour chacun, ce que le backend fournit déjà tel quel, ce qu'il faut ajuster côté payload, et ce qui manque complètement.

**Différence de contexte importante avec le document Patient :** au 14 juillet 2026, le backend Patient avait plusieurs trous francs (inscription, mot de passe oublié, détail pharmacie...). Au 28 août 2026, **le backend Livreur MVP est déclaré fonctionnellement complet côté web** (`dash_livreur.md` : « Oui, dans la limite du MVP défini », 10/10 onglets) et le dossier documentaire (`CourierVerification`/`CourierDocument`) a même été construit entre-temps (13 août 2026) — avec une complexité que l'écran Flutter actuel ne reflète pas encore. Le vrai trou n'était donc pas « le backend n'existe pas », mais « le backend existe côté web/Staff, sans jamais avoir été exposé au mobile ».

**Mise à jour du 28 août 2026, le jour même :** ce trou est comblé. Les 4 endpoints proposés en §3.1 (`GET /mobile/courier/verification/`, `.../identity-type/`, `.../documents/`, `.../submit/`) ont été implémentés côté Django séance tenante — réutilisent intégralement `CourierVerification`/`CourierDocument` existants, **aucun nouveau modèle, aucune migration**. Décision produit tranchée au passage : le document « Assurance » de l'écran 14 actuel est **retiré** au branchement (pas de catégorie backend pour lui, seulement identité + permis). Tests : `apps/api/tests.py::MobileCourierApiTests` (+3 tests dédiés à la vérification), suite complète `apps.api` (70 tests) au vert, `manage.py check` et `makemigrations --check --dry-run` propres. Voir `documentation/api_contrat.md` §5 (côté dépôt Django) pour le contrat exact des 4 endpoints. **Reste à faire : uniquement le câblage Flutter de l'écran 14** (voir §2 et §7 ci-dessous, désormais sans dépendance backend).

---

## 1. Synthèse (vue d'ensemble)

| Domaine | État |
|---|---|
| Connexion + 2FA | ⚠️ Prêt côté API, mais écran Flutter incompatible — le champ « Matricule » n'existe pas côté backend |
| Récupération mot de passe | ✅ Prêt (générique Patient/Livreur depuis le 14 juillet) |
| Accueil opérationnel (résumé) | ⚠️ Partiel — pas de compteur « aujourd'hui », pas d'alerte document réelle |
| Courses disponibles / détail | ⚠️ Prêt pour l'essentiel, coordonnées pharmacie désormais exposées (28 août) — reste à corriger distance/temps encore inventés côté Flutter |
| Course active (collecte → remise OTP) | ✅ Prêt à 90 % — écart de modélisation : « Client absent » traité comme un incident générique alors que le backend a un flux dédié à double confirmation |
| Carte et navigation | ⚠️ Illustratif honnête aujourd'hui, cohérent avec l'absence de position temps réel côté backend (cadrée, non construite) |
| Signalement d'incident | ⚠️ Prêt, mais taxonomie des types à réconcilier |
| Historique | ⚠️ Prêt, mais le filtre Flutter (3 statuts) ne couvre pas exactement les 3 statuts réels de fin de course |
| Revenus et ledger | ⚠️ Solde et écritures prêts, **mais** aucun agrégat quotidien/hebdomadaire ni répartition espèces/électronique côté API — recalcul Flutter nécessaire |
| Zones et disponibilité | ✅ Bien aligné — **sauf** la liste de zones elle-même (4 zones inventées vs 4 zones réelles, aucune en commun sauf Akanda/Owendo) |
| Documents | ✅ **Comblé le 28 août 2026** — 4 endpoints mobiles ajoutés (`/mobile/courier/verification/...`), aucun nouveau modèle. Reste seulement le branchement Flutter (retirer le document « Assurance » de l'écran 14, brancher les 3 écrans restants) |
| Notifications | ⚠️ Flux agrégé prêt, mais seulement 3 types d'événements réels (course dispo, statut, incident résolu) — nos notifications « Document validé » et « Versement reçu » n'ont aucune source |
| Centre d'aide / tickets / conversation | ✅ Prêt, taxonomie de catégories à réconcilier (même travail que côté Patient) |
| Profil et sécurité | ✅ Identité/mot de passe prêts. Véhicule en lecture seule déjà cohérent avec notre écran (modification réservée au Staff) |

---

## 2. Écran par écran

### Lot 1 — Authentification

| Écran | Endpoints nécessaires | État |
|---|---|---|
| 01 Splash / restauration de session | `GET /mobile/auth/me/` | ✅ Prêt |
| 02 Connexion Livreur | `POST /mobile/auth/login/` | ⚠️ **Prêt côté API, incompatible côté Flutter.** Le champ `identifier` accepte e-mail, nom d'utilisateur **ou téléphone normalisé** (`MobileLoginSerializer.validate`, `apps/api/mobile_auth.py`) — **il n'existe aucun concept de « matricule » dans le modèle `User`**. L'écran actuel (`LoginScreen`) affiche un champ « Matricule » avec placeholder « Ex: GP-2024-88 », qui ne correspond à rien côté backend. Voir §6 pour la décision à trancher (renommer le champ vs. ajouter un vrai matricule backend). |
| 03 Vérification 2FA | `POST /mobile/auth/verify-2fa/`, `POST /mobile/auth/resend-2fa/` | ✅ Prêt. Code à 6 chiffres, cohérent avec l'app (décision actée dans `CLAUDE.md` : 6 chiffres partout, y compris la remise de commande) |
| 04 Récupération du mot de passe | `POST /mobile/auth/password-reset/`, `.../verify/`, `.../confirm/` | ✅ Prêt depuis le 14 juillet 2026, générique Patient/Livreur (`MOBILE_ALLOWED_ROLES`) |

### Lot 2 — Exécution opérationnelle

| Écran | Endpoints nécessaires | État |
|---|---|---|
| 05 Accueil opérationnel | `GET /mobile/courier/summary/` | ⚠️ **Partiel.** Le payload réel (`counts.completed`) est un **total cumulé depuis toujours**, pas un compteur « aujourd'hui » — l'écran Flutter affiche « 08 · Courses terminées · Aujourd'hui », qui n'a pas d'équivalent serveur. L'« alerte document » affichée sur cet écran (« Votre document expire dans X jours ») n'a aucune source : `CourierDocument.expires_at` existe en base mais n'est lu nulle part côté backend aujourd'hui (`dash_livreur.md` §7, confirmé explicitement « non lu »), et le résumé mobile n'expose de toute façon aucun champ document (voir §14 plus bas). |
| 06 Courses disponibles | `GET /mobile/courier/deliveries/available/` | ⚠️ Prêt pour la liste elle-même (lecture seule, bandeau « affectation manuelle par le Staff » déjà cohérent avec la doc produit). Coordonnées pharmacie désormais exposées (§3.4, fait le 28 août) — **reste à corriger côté Flutter** : chaque carte affiche encore une distance fixe inventée (« 2.4 km », « 5.1 km »...) sans le signaler honnêtement (seul endroit de l'app dans ce cas, cf. `CLAUDE.md` « Honnêteté plutôt que fausse fonctionnalité ») ; au branchement, soit calculer une vraie distance (nécessite la position du livreur, voir §3 de `api_utilitaires.md`), soit retirer la puce distance en attendant. |
| 07 Détail d'une course disponible | Dérivé du même payload que l'écran 06 (pas d'endpoint dédié nécessaire — la liste contient déjà `pharmacy`/`order`/`zone`) | ✅ Bon alignement pour l'essentiel : le payload ne renvoie pas l'identité/le téléphone du patient tant que la course n'est pas affectée (`include_patient=False` par défaut) — exactement ce que fait déjà l'écran Flutter en floutant la destination. Même écart distance/temps estimé que l'écran 06 (« 1.2 km », « 5 min » inventés) à corriger au branchement. |
| 08 Course active | `GET .../deliveries/<id>/`, `.../pickup/`, `.../start/`, `.../resend-proof/`, `.../complete/`, `.../patient-absence/`, `.../incidents/` | ⚠️ **Prêt à 90 %, un écart de modélisation important.** Notre `IncidentScreen` propose « Client absent » comme un type d'incident générique parmi d'autres — le backend a un **flux entièrement séparé et plus strict** : `POST .../patient-absence/`, qui exige `contact_attempts_confirmed` (deux appels confirmés) et `wait_confirmed` (dix minutes d'attente), fait passer la course à `returning`, invalide l'OTP et engage un retour obligatoire à la pharmacie — ce n'est **pas** un simple signalement, c'est une transition de course à part entière avec ses propres règles. Voir §6 et §11. Le code OTP à 6 chiffres est déjà cohérent (`proof_code`, regex `^\d{6}$`). |
| 09 Carte et navigation | Pas d'endpoint dédié aujourd'hui | ⚠️ Cohérent avec l'état actuel honnête (`CustomPainter` illustratif, FAB de recentrage « indisponible en démonstration ») — la position temps réel du livreur est **cadrée mais non implémentée** ni côté backend ni côté Flutter (`documentation/cadrage_suivi_temps_reel_livreur.md`, voir `api_utilitaires.md` §3). Aucune régression à corriger ici, juste un chantier futur en attente de décision produit. |

### Lot 3 — Activité, revenus et disponibilité

| Écran | Endpoints nécessaires | État |
|---|---|---|
| 10 Signalement d'incident | `POST /mobile/courier/deliveries/<id>/incidents/` | ⚠️ Prêt, mais taxonomie à réconcilier (voir §11) et « Client absent » à retirer de cette liste générique (voir écran 08). Pas d'endpoint pour **lister** les incidents d'un livreur tous statuts confondus — notre écran affiche une liste « Incidents ouverts » qui n'a pas de source directe (voir §3.2). |
| 11 Historique | `GET /mobile/courier/deliveries/history/` | ⚠️ Prêt et paginé (20/page), couvre `delivered`/`returned`/`cancelled`. **Mais** le filtre Flutter actuel (Tout/Livré/Annulé, 3 valeurs) ne distingue pas `returned` (retour à la pharmacie après absence patient) de `cancelled` — un retour se retrouverait aujourd'hui mal classé ou invisible selon le mapping choisi. Voir §11. |
| 12 Revenus et ledger | `GET /mobile/courier/ledger/` | ⚠️ Solde courant et 50 dernières écritures prêts. **Aucun agrégat par période côté API** : pas de champ « total du jour »/« total de la semaine », pas de répartition espèces/électronique déjà calculée. Notre écran (onglets Quotidien/Hebdomadaire, bento Espèces/Électronique) devra soit recalculer ces agrégats côté Flutter à partir des `entry_type`/`created_at` des écritures reçues, soit s'appuyer sur un nouvel endpoint d'agrégation — voir §3.3 et §6. |
| 13 Zones et disponibilité | `GET`/`PATCH /mobile/courier/availability/` | ⚠️ Très bon alignement fonctionnel (le PATCH ne modifie que `is_available_for_delivery`, jamais les zones elles-mêmes — cohérent avec le bouton honnête « Mettre à jour ma zone » qui ne fait jamais aboutir le changement dans notre app). **Mais la liste de zones est entièrement à revoir** : le backend n'a que 4 zones plates (`libreville`/`owendo`/`akanda`/`bikele`, `ZONE_CHOICES`), alors que notre écran propose « Libreville Centre », « Akanda », « Owendo », « SNI/Angondjé » — Bikélé est totalement absent, et les 3 autres libellés ne correspondent pas exactement aux codes réels (même écart que celui déjà documenté côté Patient pour le sélecteur de commune au Checkout). |
| 14 Documents | `GET /mobile/courier/verification/`, `POST .../identity-type/`, `POST .../documents/`, `POST .../submit/` | ✅ **Prêt depuis le 28 août 2026** (voir §3.1) — le modèle `CourierVerification`/`CourierDocument` existait déjà côté Staff/web depuis le 13 août, seuls les 4 endpoints mobiles manquaient, désormais ajoutés sans nouveau modèle ni migration. **Écart à corriger uniquement côté Flutter au branchement** : notre écran affiche 3 documents (CNI/Passeport, Permis de conduire, Assurance) — le backend n'a que 2 catégories (`identity`, `driving_license`, chacune en recto/verso ou page d'identité pour un passeport). Décision actée : retirer « Assurance » de l'écran plutôt que d'ajouter une catégorie backend pour elle. |

### Lot 4 — Communication et compte

| Écran | Endpoints nécessaires | État |
|---|---|---|
| 15 Notifications | `GET /mobile/notifications/` | ⚠️ **Partiel.** Le flux agrégé livreur (`_courier_notifications`, `apps/api/mobile_shared.py`) ne produit que 3 types d'événements : course `awaiting_assignment` compatible disponible (si en ligne), changement de statut d'une course affectée (`DeliveryStatusHistory`), incident résolu. **Nos notifications « Document validé » et « Versement reçu » (écran 15 actuel) n'ont aucune source côté backend** — ni les documents (pas de mobile Documents, voir écran 14), ni les règlements (`CourierSettlement` n'alimente pas ce flux). Voir §4 et §6. |
| 16 Centre Support | `GET /mobile/support/categories/`, `GET/POST /mobile/support/tickets/` | ✅ Prêt. La catégorie `delivery` existe déjà nativement et correspond bien au rôle. Réconciliation de taxonomie nécessaire (Livraison/Compte/Paiement côté Flutter vs 7 valeurs réelles côté Django, voir §11 — même travail que documenté côté Patient). |
| 17 Conversation Support | `GET /mobile/support/tickets/<id>/`, `POST .../reply/` | ✅ Prêt, identique au comportement déjà validé côté Patient (notes internes Staff jamais exposées, pièce jointe facultative en `multipart/form-data`). |
| 18 Profil et sécurité | `GET/PATCH /mobile/profile/`, `POST /mobile/profile/password/` | ✅ Prêt pour identité, téléphone, mot de passe. Le champ « Véhicule » (lecture seule dans notre app, dialogue « à modifier auprès du Staff ») est déjà exactement cohérent avec la réalité : `vehicle_type` est exposé en lecture via `/summary/` et `/availability/`, mais **aucune route ne permet de le modifier depuis le mobile** — bon alignement, rien à changer. Bonus disponible mais non utilisé par notre écran : `POST /mobile/profile/deactivate/` (désactivation réversible du compte, réactivation à la reconnexion) — voir §6. |

---

## 3. Endpoints à créer (contrat proposé)

### 3.1 Documents livreur mobile (écran 14) — ✅ implémenté le 28 août 2026

Contrairement à toutes les autres lacunes listées ici, celle-ci n'exigeait **aucun nouveau modèle Django** — `CourierVerification`/`CourierDocument` existent, sont testés et utilisés par le Staff depuis le 13 août 2026 (`apps/accounts/models.py`, service `apps/accounts/courier_verification.py`). Il ne manquait que la **surface API mobile**, sur le même principe que ce qui a été fait pour « Mon assurance » côté Patient (modèle déjà là, juste réexposé) — **les 4 endpoints ci-dessous sont désormais en place, testés (3 tests dédiés + suite `apps.api` complète au vert), sans migration.**

```
GET /mobile/courier/verification/
```
Réponse proposée, à partir de `verification_progress()`/`required_document_slots()` déjà écrits côté service :
```json
{
  "identity_document_type": "cni",
  "identity_document_type_label": "Carte nationale d'identité",
  "status": "changes_requested",
  "status_label": "Modifications demandées",
  "is_complete": true,
  "progress_percent": 75,
  "required_slots": [
    {"category": "identity", "category_label": "Identité", "side": "front", "side_label": "Recto"},
    {"category": "identity", "category_label": "Identité", "side": "back", "side_label": "Verso"},
    {"category": "driving_license", "category_label": "Permis de conduire", "side": "front", "side_label": "Recto"},
    {"category": "driving_license", "category_label": "Permis de conduire", "side": "back", "side_label": "Verso"}
  ],
  "documents": [
    {
      "id": 12,
      "category": "identity",
      "side": "front",
      "status": "approved",
      "rejection_reason": "",
      "expires_at": null,
      "has_pending_replacement": false,
      "submitted_at": "2026-08-01T09:00:00Z",
      "reviewed_at": "2026-08-02T10:00:00Z"
    }
  ]
}
```

```
POST /mobile/courier/verification/identity-type/
```
Body : `{"identity_document_type": "cni"}` — équivalent mobile du choix de type de pièce dans l'assistant web (`CourierVerification.identity_document_type`), recalcule `required_document_slots()`.

```
POST /mobile/courier/verification/documents/
```
`multipart/form-data` : `category`, `side`, `file`. Effet identique au re-dépôt web (`review_courier_document`) : si un fichier existe déjà et est approuvé, le nouveau va dans `pending_file` sans écraser la pièce validée ; sinon il remplace directement `file` et repasse `status` à `pending`.

```
POST /mobile/courier/verification/submit/
```
Body vide. Équivalent du bouton web « Soumettre mon dossier » — passe `CourierVerification.status` à `pending_review`, uniquement si `is_complete` (une pièce présente par emplacement requis, approuvée ou non).

**Écart de contenu, tranché le 28 août 2026 (voir §6) :** notre écran 14 actuel affiche un 3ᵉ document « Assurance » (statut Refusé avec motif, bouton « Remplacer le document ») qui **n'a aucune existence côté backend**. Décision actée : le retirer de l'écran Flutter au moment du branchement réel plutôt que d'ajouter une catégorie backend `INSURANCE` — aligné strictement sur `CourierDocument.Category` = identité/permis uniquement. L'écran gardera CNI/Passeport et Permis de conduire, avec le vrai découpage recto/verso (ou page d'identité pour un passeport) plutôt que la validation combinée actuelle par document.

### 3.2 Liste des incidents du livreur (écran 10, section « Incidents ouverts »)

Aucune route ne liste aujourd'hui tous les incidents d'un livreur, tous statuts confondus — seul `include_incidents=True` sur le détail/l'actif d'**une** course donnée renvoie ses incidents. Deux options, à l'image de l'historique financier Patient :

**Option A (minimal, recommandée) :** reconstruire côté Flutter à partir de `GET /mobile/courier/deliveries/active/` (qui inclut déjà `incidents` par défaut) et de l'historique — les incidents « ouverts » sur des courses déjà terminées n'ont de toute façon pas grand sens (un incident bloquant sur une course livrée devrait être résolu). Suffisant si l'écran 10 ne doit montrer que les incidents de la course active.

**Option B :** nouvel endpoint agrégé si le produit veut vraiment une vue transverse (ex. plusieurs courses actives dans une version future à plusieurs livraisons simultanées) :
```
GET /mobile/courier/incidents/
```
Réponse paginée, filtrable par `status`, réutilisant `_incident_payload` déjà écrit dans `mobile_courier.py`.

**Tranché le 28 août 2026 : Option A retenue** — un livreur n'a qu'une seule course active en MVP (`decisions.md` : « une seule course active par livreur »), donc une vue transverse multi-courses n'apporte rien tant que cette contrainte MVP reste vraie. Rien à construire côté backend ; l'écran 10 se limite aux incidents de la course active (`GET /mobile/courier/deliveries/active/`, déjà `include_incidents=True`) au branchement.

### 3.3 Agrégats de revenus par période (écran 12)

Le ledger actuel (`GET /mobile/courier/ledger/`) renvoie un solde et jusqu'à 50 écritures brutes, sans aucun regroupement.

**Option A (recommandée, minimal) :** calculer les agrégats **côté Flutter** à partir des écritures déjà reçues (`created_at`, `entry_type`, `amount_fcfa`) — filtrer par jour/semaine courante, sommer par `entry_type` pour distinguer espèces (`cod_commission`) vs électronique (`electronic_earning`) vs indemnités de retour (`return_earning`). Fonctionne tant que la pagination à 50 entrées suffit à couvrir une semaine d'activité pilote — à revoir si le volume grossit.

**Option B :** nouvel endpoint d'agrégation dédié :
```
GET /mobile/courier/ledger/summary/?period=daily|weekly
```
Réponse : totaux déjà calculés côté serveur (`total_fcfa`, `cash_fcfa`, `electronic_fcfa`, `courses_count`) pour la période demandée.

**Tranché le 28 août 2026 : Option A retenue**, cohérente avec le choix déjà fait côté Patient pour l'historique financier (reconstruire depuis l'existant plutôt que multiplier les endpoints) — à réévaluer seulement si le calcul côté client devient trop coûteux pour l'app. Rien à construire côté backend ; les onglets Quotidien/Hebdomadaire de l'écran 12 se calculent au branchement depuis les écritures déjà renvoyées par `GET /mobile/courier/ledger/`.

### 3.4 Coordonnées pharmacie sur les payloads livreur (écrans 06, 07, 09) — ✅ fait le 28 août 2026

`_pharmacy_payload()` dans `apps/api/mobile_courier.py` expose désormais `latitude`/`longitude` (mêmes champs que côté API Patient), en plus de `id`/`name`/`zone`/`zone_label`/`address`/`phone` :
```json
{"id": 3, "name": "Pharmacie du Centre", "zone": "libreville", "latitude": 0.4162, "longitude": 9.4673, ...}
```
`null` si la pharmacie n'a pas de coordonnées renseignées. **Contrairement au Patient, pas de calcul de distance côté serveur** (`?lat=&lng=`/`distance_km` n'existent que côté API Patient) — le livreur reçoit les coordonnées brutes, à afficher sur une carte ou à combiner avec sa propre position (si retenue, voir §3 de `api_utilitaires.md`) pour calculer une distance côté Flutter. Testé (`MobileCourierApiTests`, suite `apps.api` 70/70 au vert), aucune migration.

---

## 4. Évolutions de payloads existants (pas de nouveau modèle)

| Endpoint | Évolution | Pourquoi |
|---|---|---|
| `GET /mobile/courier/summary/` → `counts` | ajouter `completed_today` (comptage filtré sur `delivered_at__date=today`) | Écran 05 affiche « Courses terminées · Aujourd'hui », le backend ne renvoie qu'un total cumulé |
| `GET /mobile/courier/summary/` | ajouter un bloc `verification` (statut global + `is_complete`) une fois §3.1 construit | Permettrait une vraie alerte documentaire sur l'écran 05, au lieu du texte statique actuel |
| ~~`apps/api/mobile_courier.py::_pharmacy_payload`~~ | ~~ajouter `latitude`/`longitude`~~ | ✅ Fait le 28 août 2026 (§3.4) — écrans 06, 07, 09 |
| `GET /mobile/notifications/` (branche livreur) | envisager d'ajouter un événement « document » (validation/refus de pièce) une fois §3.1 construit, et un événement « règlement » à partir de `CourierSettlement` | Comble l'écart des notifications « Document validé »/« Versement reçu » (écran 15) — dépend entièrement de §3.1 pour la partie document |

---

## 5. Modèles Django à ajouter ou mettre à jour

**Bonne nouvelle : contrairement au document Patient (qui listait plusieurs modèles manquants), aucun nouveau modèle n'est strictement nécessaire côté Livreur.** Le seul vrai trou (§3.1, Documents) est déjà entièrement modélisé — il ne manque que la couche API. Les seules évolutions de modèle envisageables sont optionnelles :

| Modèle | Évolution envisagée | Nécessité |
|---|---|---|
| ~~`accounts.CourierDocument.Category`~~ | ~~ajouter `INSURANCE`~~ | **Tranché le 28 août 2026 : non retenu.** Le document « Assurance » est retiré de l'écran Flutter au lieu de créer une catégorie backend pour une donnée de démo (voir §3.1/§6.3) |
| `support.SupportTicket.Category` | envisager d'ajouter une valeur plus proche de « Compte » livreur si besoin, ou documenter le remappage | Optionnel — décision déjà en suspens côté Patient pour un sujet symétrique (`medication`), même logique ici |

Aucune migration destructive envisagée dans les deux cas — un choix d'énumération supplémentaire, sans impact sur les données existantes.

---

## 6. Décisions produit — toutes tranchées le 28 août 2026

Les 7 points ci-dessous étaient ouverts à la rédaction initiale de ce document ; ils ont tous été tranchés le jour même (dans le sens de la recommandation à chaque fois, aucune objection soulevée), pour que le branchement Flutter puisse démarrer sans blocage de décision. Conservés ici à titre de traçabilité — **à ne pas rouvrir sans raison nouvelle**, sur le même principe que `documentation/decisions.md` côté backend.

1. ~~**Champ « Matricule » de l'écran 02**~~ — **tranché : remplacé par « Identifiant ».** Le backend n'a pas de concept de matricule (identifiant = e-mail, nom d'utilisateur ou téléphone, `MobileLoginSerializer`) ; aucun champ `matricule` ne sera ajouté côté `User`. À faire au branchement : renommer le champ Flutter, accepter e-mail/téléphone/nom d'utilisateur, retirer le placeholder « Ex: GP-2024-88 ».
2. ~~**« Client absent » : incident générique ou flux dédié ?**~~ — **tranché : flux dédié.** Retiré de la liste de types d'incident de l'écran 10/08 ; obtient son propre parcours au branchement (`POST .../patient-absence/`, double confirmation obligatoire — deux appels + dix minutes d'attente —, état `returning`), plutôt qu'un signalement générique qui ne reflèterait pas la règle métier réelle.
3. ~~**Document « Assurance » du dossier livreur (écran 14)**~~ — **tranché : retiré.** Aligné sur le backend réel (identité + permis uniquement), sur le même principe que « note du livreur » retirée côté Patient faute de modèle réel.
4. ~~**Agrégats de revenus (écran 12)**~~ — **tranché : Option A** (recalcul côté Flutter depuis `GET /mobile/courier/ledger/`, voir §3.3). Aucun nouvel endpoint.
5. ~~**Liste des incidents (écran 10)**~~ — **tranché : Option A** (dérivée de la course active, voir §3.2). Aucun nouvel endpoint.
6. ~~**Zones réelles (écran 13)**~~ — **tranché : remplacer les 4 zones inventées par les 4 zones réelles** (Libreville/Owendo/Akanda/Bikélé) au branchement. Pas une décision produit à proprement parler, plutôt une correction technique actée en même temps que les autres points.
7. ~~**Notifications « Document validé »/« Versement reçu » (écran 15)**~~ — **tranché : retirées** de l'écran au branchement, tant que les événements « document » et « règlement » ne sont pas ajoutés au flux agrégé côté backend (`_courier_notifications`, voir §4) — cohérent avec la décision déjà prise côté Patient pour « Offres » (retirer plutôt qu'inventer un contenu). À reconstruire plus tard si ces événements backend sont un jour ajoutés.

---

## 7. Ordre de branchement recommandé côté Flutter Livreur

Aligné sur `api_contrat.md` §10 (déjà écrit pour un contexte Patient+Livreur mêlés) mais réordonné pour suivre les 4 lots déjà construits côté Flutter Livreur :

1. **Auth + 2FA + mot de passe oublié** (déjà prêt côté backend) — stockage sécurisé des tokens (`flutter_secure_storage`), et **corriger le champ Matricule → Identifiant en même temps** (décision §6.1), puisque le branchement échouerait silencieusement sinon.
2. **Accueil, Courses disponibles, Détail course** — prêt pour l'essentiel ; coordonnées pharmacie déjà exposées (§3.4, fait) — brancher une vraie distance seulement une fois la position du livreur disponible côté Flutter, sinon retirer honnêtement les chips distance/temps de ces écrans en attendant.
3. **Course active** — prêt à 90 %, **séparer le flux « Client absent » du signalement d'incident générique** (§6.2) avant de brancher l'écran 08/10 fidèlement.
4. **Carte et navigation** — rien à brancher tant que la position temps réel n'est pas retenue (décision distincte, voir `api_utilitaires.md` §3) ; ajouter seulement le bouton « ouvrir la navigation externe » (sans dépendance backend).
5. **Historique** — prêt, corriger le mapping des 3 filtres pour couvrir `returned` correctement (§11) en même temps.
6. **Revenus et ledger** — Option A actée (§3.3/§6.4) : brancher les onglets Quotidien/Hebdomadaire avec un recalcul Flutter des écritures du ledger.
7. **Zones et disponibilité** — remplacer la liste de zones par les 4 zones réelles (§6.6) au branchement, le `GET`/`PATCH` lui-même est déjà prêt tel quel.
8. **Documents** — backend prêt depuis le 28 août 2026 (§3.1) ; brancher l'écran 14 en retirant le document « Assurance » (§6.3 tranché) et en adoptant le vrai découpage recto/verso par pièce.
9. **Notifications** — brancher le flux agrégé existant tel quel (course dispo/statut/incident résolu), retirer « Document validé »/« Versement reçu » de l'écran (§6.7 tranché).
10. **Centre d'aide, tickets, conversation support** — prêt, réconcilier la taxonomie de catégories (§11) avant de brancher le formulaire de création de ticket.
11. **Profil et sécurité** — prêt tel quel pour identité/mot de passe ; envisager d'exposer `POST /mobile/profile/deactivate/` dans une future itération de l'écran 18 (non demandé aujourd'hui par le mockup, mais déjà disponible côté API sans coût supplémentaire).

---

## 8. Annexe — réconciliation des énumérations Flutter ↔ Django

### Zones géographiques

Flutter (`AvailabilityScreen`, 4 zones) : « Libreville Centre », « Akanda », « Owendo », « SNI/Angondjé ».

Django (`ZONE_CHOICES`, `apps/accounts/forms.py`, 4 valeurs) : `libreville` (Libreville), `owendo` (Owendo), `akanda` (Akanda), `bikele` (Bikélé).

Remappage proposé : correspondance directe pour Akanda/Owendo ; « Libreville Centre » → `libreville` (le backend n'a pas de sous-découpage de commune) ; « SNI/Angondjé » → à retirer, remplacer par `bikele` (Bikélé), absent aujourd'hui de l'écran Flutter. Même écart de fond que celui déjà documenté côté Patient pour le sélecteur de commune au Checkout (Bikélé manquant des deux côtés de la plateforme mobile).

### Types d'incident

Flutter (`IncidentScreen`, 4 valeurs) : Accident, Panne véhicule, Client absent, Problème pharmacie.

Django (`DeliveryIncident.Type`, 7 valeurs) : `delay`, `recipient_unreachable`, `patient_absent`, `wrong_address`, `vehicle`, `package`, `other`.

Remappage proposé (après retrait de « Client absent », voir §6.2, qui utilise son propre flux dédié) :
- **Accident** → `vehicle` (le plus proche) ou `other` si l'accident n'implique pas le véhicule lui-même
- **Panne véhicule** → `vehicle`
- **Problème pharmacie** → `other` (aucune valeur backend ne couvre spécifiquement un souci côté officine)
- Valeurs backend sans équivalent Flutter aujourd'hui, à ajouter à l'écran : **Retard** (`delay`), **Destinataire injoignable** (`recipient_unreachable`), **Mauvaise adresse** (`wrong_address`), **Colis endommagé/problème** (`package`)

### Sévérités d'incident

Flutter (`IncidentScreen`) : Faible, Moyenne, Critique — Django (`DeliveryIncident.Severity`) : `low`, `medium`, `high`. **Déjà parfaitement aligné 1:1**, aucun travail nécessaire au-delà du mapping trivial des libellés.

### Statuts de livraison (fin de course)

Flutter (`DeliveryHistory`, filtres Tout/Livré/Annulé, 3 valeurs visibles) — Django (`Delivery.Status`, valeurs de fin) : `delivered`, `returned`, `cancelled`.

Remappage proposé : **Livré** → `delivered` ; **Annulé** → `cancelled` ; **manque un 3ᵉ filtre « Retourné »** → `returned` (retour à la pharmacie après absence patient confirmée), aujourd'hui invisible ou mal classé dans l'historique Flutter selon l'implémentation exacte du filtre « Tout » vs les 2 autres.

### Code de preuve de remise (OTP)

Flutter : 6 chiffres partout (décision actée dans `CLAUDE.md`, y compris l'écran 08). Django : `proof_code`, `RegexField(regex=r"^\d{6}$")`. **Déjà parfaitement aligné**, aucun travail nécessaire — bon exemple d'une décision produit prise par avance qui s'avère correspondre exactement à la réalité backend.

### Catégories de support

Flutter (écran 16, 3 boutons) : Livraison, Compte, Paiement.

Django (`SupportTicket.Category`, 7 valeurs) : `general`, `account`, `order`, `delivery`, `payment`, `pharmacy`, `other`.

Remappage proposé : **Livraison** → `delivery` (correspondance directe, contrairement à Patient où ce mapping demandait un choix) ; **Compte** → `account` ; **Paiement** → `payment` — les 3 boutons Livreur ont chacun un équivalent exact, **meilleur alignement que côté Patient** où « Médicaments » n'avait pas de correspondance directe.
