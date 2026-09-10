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
| Connexion + 2FA | ✅ **Branché et vérifié le 28 août 2026** — champ « Matricule » → « Identifiant » corrigé |
| Récupération mot de passe | ✅ **Branché et vérifié isolément le 3 septembre 2026** |
| Accueil opérationnel (résumé) | ✅ **Branché et vérifié le 3 septembre 2026** |
| Courses disponibles / détail | ✅ **Branché et vérifié le 3 septembre 2026** — distance/temps retirés, « postuler » corrigé en honnête (aucun endpoint de candidature n'existe) |
| Course active (collecte → remise OTP) | ✅ **Branché et vérifié le 3 septembre 2026** — « Client absent » a son propre parcours dédié (`.../patient-absence/`), distinct du signalement générique |
| Carte et navigation | ✅ **Branché et vérifié le 10 septembre 2026** — vrai SDK Google Maps, marker pharmacie (coordonnées réelles) + marker/recentrage sur la vraie position GPS du livreur. Pas de marker destination (`delivery_address` sans coordonnées), pas de temps estimé (aucune API de routage) |
| Signalement d'incident | ✅ **Branché et vérifié le 3 septembre 2026** — taxonomie remplacée par les 6 valeurs réelles du backend (hors « Client absent ») |
| Historique | ✅ **Branché et vérifié le 8 septembre 2026** — filtre passé à 4 valeurs (dont `returned`) |
| Revenus et ledger | ✅ **Branché et vérifié le 8 septembre 2026** — agrégats quotidien/hebdomadaire recalculés côté Flutter (Option A). Bento redéfini par signe ("Dû à Gab'Pharma"/"Dû par Gab'Pharma") plutôt que "Espèces/Électronique" : le ledger réel n'expose ni pharmacie, ni code de course, ni split 60/40 par écriture |
| Zones et disponibilité | ✅ **Branché et vérifié le 8 septembre 2026** — 4 zones réelles (Bikélé inclus), badge "Zone assignée" piloté par `coverage_zones` |
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
| 05 Accueil opérationnel | `GET /mobile/courier/summary/`, `GET /mobile/courier/deliveries/active/` | ✅ **Branché et vérifié le 3 septembre 2026.** Compteur « Courses terminées » relabellisé (retrait de « Aujourd'hui », `counts.completed` est cumulatif) ; alerte document factice retirée (pas de source backend tant que §3.1 côté mobile n'est pas branché côté Flutter, voir écran 14) ; carte « Course active » alimentée par `GET .../deliveries/active/` avec statut réel au lieu d'un faux temps estimé ; « Zone actuelle » alimentée par les vraies `coverage_zones`. |
| 06 Courses disponibles | `GET /mobile/courier/deliveries/available/` | ✅ **Branché et vérifié le 3 septembre 2026.** Chip distance retirée (aucune coordonnée/position livreur exposée pour calculer quoi que ce soit d'honnête) ; « Revenu estimé » remplacé par « Part livreur est. » sourcée sur `courier_share_fcfa`. |
| 07 Détail d'une course disponible | Dérivé du même payload que l'écran 06 (pas d'endpoint dédié — confirmé : `GET .../deliveries/<id>/` est filtré `courier=request.user` et 404 sur une course non affectée) | ✅ **Branché et vérifié le 3 septembre 2026.** Section « Contraintes & notes » et chips distance/temps retirées (aucun champ backend). **Écart de fond découvert en branchant : aucun endpoint ne permet à un livreur de « postuler » à une course** — le bouton, qui affichait une fausse confirmation locale sans appel réseau, a été corrigé en dialogue honnête. |
| 08 Course active | `GET .../deliveries/<id>/`, `.../pickup/`, `.../start/`, `.../resend-proof/`, `.../complete/`, `.../patient-absence/`, `.../incidents/` | ✅ **Branché et vérifié le 3 septembre 2026.** `ActiveDeliveryScreen` réécrit en état-machine pilotée par `delivery.status`. « Client absent » a désormais son propre bouton et sa propre feuille modale (double confirmation + description → `.../patient-absence/`), distincte du bouton « Signaler un problème » générique — voir `branchement_livreur.md` §4. Champ « Nom du destinataire » ajouté (obligatoire côté backend, absent du mockup). Chip « X min restantes » retirée, remplacée par un badge honnête basé sur le vrai `delivery_deadline`/`is_late`. |
| 09 Carte et navigation | Pas d'endpoint dédié — utilise les coordonnées pharmacie déjà exposées (§3.4) et la position GPS locale du livreur (déjà collectée depuis le 4 septembre pour le ping `.../position/`) | ✅ **Branché et vérifié le 10 septembre 2026.** SDK `google_maps_flutter` remplace le `CustomPainter` illustratif. Marker pharmacie sur ses vraies coordonnées (`null` si absentes) ; marker + recentrage réels sur la position GPS du livreur (`Geolocator`, même mécanisme que le ping de position de l'écran 08). Deux écarts assumés par rapport au mockup : aucun marker destination (`order.delivery_address` est un texte libre, sans coordonnées côté API — contrairement à la pharmacie) ; panneau « Temps estimé/Distance » refondu en « Distance pharmacie » (vol d'oiseau, uniquement avant collecte) / « Statut » (réel) — aucune API de routage/trafic branchée pour un temps honnête. Voir `branchement_livreur.md` §10. |

### Lot 3 — Activité, revenus et disponibilité

| Écran | Endpoints nécessaires | État |
|---|---|---|
| 10 Signalement d'incident | `POST /mobile/courier/deliveries/<id>/incidents/` | ✅ **Branché et vérifié le 3 septembre 2026.** « Client absent » retiré de la liste (flux dédié, écran 08). Taxonomie remplacée par les 6 valeurs et libellés réels du backend plutôt qu'un remappage approximatif des anciens libellés. « Incidents ouverts » dérivée de `GET .../deliveries/active/` (Option A, §3.2), rechargée après chaque soumission. |
| 11 Historique | `GET /mobile/courier/deliveries/history/` | ✅ **Branché et vérifié le 8 septembre 2026.** Filtre Flutter passé à 4 valeurs (Tout/Livré/Retourné/Annulé) pour distinguer `returned` (retour à la pharmacie après absence patient) de `cancelled`. Stats "Total Courses"/"Ce Mois"/"Revenus Totaux" recalculées côté Flutter depuis l'historique complet (paginé, toutes les pages accumulées côté client). Voir `branchement_livreur.md` §8. |
| 12 Revenus et ledger | `GET /mobile/courier/ledger/` | ✅ **Branché et vérifié le 8 septembre 2026.** Agrégats quotidien/hebdomadaire recalculés côté Flutter (Option A, §3.3). **Écart de fond découvert en branchant : le ledger réel ne porte pas de notion « espèces/électronique »** — `entry_type` (`cod_commission`/`electronic_earning`/`return_earning`) journalise une dette de commission ou une part due, jamais un « gain espèces » directement, et `_ledger_payload` n'expose ni pharmacie, ni code de course, ni split 60/40 par écriture. Le bento a été redéfini honnêtement par signe (« Dû à Gab'Pharma » / « Dû par Gab'Pharma ») et la liste « Détails des gains (60/40) » renommée « Mouvements du compte », reconstruite avec les seules données réellement disponibles (`entry_type_label`, `reason`, `created_at`, montant signé). Voir `branchement_livreur.md` §9. |
| 13 Zones et disponibilité | `GET`/`PATCH /mobile/courier/availability/` | ✅ **Branché et vérifié le 8 septembre 2026.** Liste de zones remplacée par les 4 zones réelles (`libreville`/`owendo`/`akanda`/`bikele`), Bikélé désormais présent. Le PATCH ne modifiant que `is_available_for_delivery` (jamais les zones), les cases à cocher restent une intention locale jamais envoyée — badge "Zone assignée" piloté par les vraies `coverage_zones` reçues en `GET`, bouton "Mettre à jour ma zone" honnête inchangé. Voir `branchement_livreur.md` §7. |
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
3. ~~**Course active**~~ — **fait le 3 septembre 2026** : flux « Client absent » séparé du signalement d'incident générique (§6.2), écrans 08/10 branchés fidèlement.
4. ~~**Carte et navigation**~~ — **fait le 10 septembre 2026** : cette section recommandait initialement (28 août) un simple bouton « ouvrir la navigation externe », faute de position temps réel côté backend. Cette dernière a été implémentée le 4 septembre 2026 (voir `branchement_livreur.md` §5) ; le 7-8 septembre 2026, décision produit actée pour une navigation interne avec un vrai SDK Google Maps (`google_maps_flutter`) plutôt qu'un renvoi vers une app externe — branché et vérifié sur S8, voir `branchement_livreur.md` §10.
5. ~~**Historique**~~ — **fait le 8 septembre 2026** : filtre passé à 4 valeurs pour couvrir `returned` correctement, stats recalculées côté Flutter.
6. ~~**Revenus et ledger**~~ — **fait le 8 septembre 2026** : onglets Quotidien/Hebdomadaire branchés avec un recalcul Flutter des écritures du ledger (Option A, §3.3/§6.4) ; bento redéfini par signe plutôt que « espèces/électronique », le ledger réel n'exposant pas cette distinction par écriture.
7. ~~**Zones et disponibilité**~~ — **fait le 8 septembre 2026** : liste de zones remplacée par les 4 zones réelles (§6.6), le `GET`/`PATCH` lui-même était déjà prêt tel quel.
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
