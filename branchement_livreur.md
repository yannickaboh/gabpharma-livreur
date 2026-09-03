# Gab'Pharma Livreur — suivi du branchement API réelle

**Créé le :** 28 août 2026
**But :** suivre, module par module, le passage du mode démonstration (`AppConfig.demoMode`) au vrai backend Django (`/api/v1/...`), sur le même modèle que `C:\Users\24174\StudioProjects\gabpharma_patient\branchement_patient.md`. Cocher au fur et à mesure, ne pas re-décider l'ordre sans raison (voir `api_contrat_besoins.md` §7 pour l'ordre recommandé).

## Déjà branché et vérifié (28 août 2026, sur S8 physique + backend local `:8004`)

- [x] Connexion (`POST /mobile/auth/login/`)
- [x] Vérification 2FA (`POST /mobile/auth/verify-2fa/`) — succès **et** échec réels testés (code expiré renvoyant "Code invalide ou expiré." affiché tel quel dans l'UI)
- [x] Renvoi du code (`POST /mobile/auth/resend-2fa/`) — testé, nouveau `challenge_id` reçu et utilisé pour la vérification suivante
- [x] Restauration de session (`GET /mobile/auth/me/`) — testée en relançant l'app après connexion (« Session retrouvée... », navigation directe vers `/home` sans repasser par le login)
- [x] Déconnexion — testée : efface le jeton stocké (`flutter_secure_storage`), confirmé en relançant l'app après déconnexion (retour à un formulaire de connexion vide, aucun appel réseau à `/me/`, cohérent avec `AuthSession.restoreSession()` qui ne fait rien si aucun jeton n'est stocké)
- [x] Mot de passe oublié (`password-reset/`, `.../verify/`, `.../confirm/`) — testé isolément le 3 septembre 2026 sur S8 : les 3 étapes réelles (demande → code reçu par e-mail via MailHog → nouveau mot de passe) ont abouti à l'écran "Félicitations !", puis reconnexion réussie avec le nouveau mot de passe confirmée en base (`POST /mobile/auth/login/` → 200).

**Identifiant de test utilisé :** `livreur@gabpharma.ga` (compte `ProfessionalApplication` actif, zone `libreville`, `vehicle_type=motorbike`). **Mot de passe changé le 3 septembre 2026** via le flux "Mot de passe oublié" testé ci-dessus : `Livreur2026.` → `NouveauPass2026` — à utiliser pour les prochaines sessions de vérification.

**Piège rencontré en testant ce module :** le clavier prédictif Samsung (même famille de bug que celui documenté le 28 août pour l'OTP) fait échouer les `adb shell input keyevent 67` (backspace) de façon incohérente sur les champs de mot de passe classiques (pas seulement les cases OTP) — un texte tapé deux fois de suite dans le même champ ne se vide pas complètement avec des backspace répétés. Solution qui fonctionne de façon fiable : ne jamais essayer de corriger un champ pollué en place ; relancer l'app (`am force-stop` + `am start`) pour repartir d'un formulaire vierge plutôt que de perdre du temps à déboguer le clavier. Egalement confirmé : sur l'écran "Récupération" (`PasswordResetScreen`), les bounds `uiautomator` des champs `EditText` se décalent fortement selon que le clavier est ouvert/fermé et selon quel champ a le focus — toujours re-dumper juste avant chaque tap plutôt que de réutiliser des coordonnées mémorisées d'un écran similaire.

## Écart corrigé au passage : champ "Matricule" → "Identifiant"

Comme documenté dans `api_contrat_besoins.md` §6.1 : le backend n'a aucun concept de matricule (`identifier` accepte e-mail, téléphone ou nom d'utilisateur). Le champ de `LoginScreen` a été renommé et son placeholder corrigé ; même correction apportée à l'étape 1 de `PasswordResetScreen`. Le texte "envoyé par SMS" (écrans 03 et 04, tous deux faux — le canal réel est l'e-mail) a été corrigé en "envoyé par e-mail" au passage.

## Bugs trouvés et corrigés en branchant ce premier lot

1. **`api_client.dart` ne fixait jamais `Content-Length`** (même bug que documenté dans `branchement_patient.md`, corrigé indépendamment ici) — `dart:io` basculait en `Transfer-Encoding: chunked`, rejeté par le serveur de dev Django (wsgiref). Fix : encoder le corps en bytes UTF-8 et fixer `request.headers.contentLength` explicitement avant `request.add(...)`, préventivement appliqué dès la réécriture du client plutôt que découvert après coup.
2. **`AppConfig.apiBaseUrl` avait une valeur par défaut fausse** (`http://10.0.2.2:8000/api/mobile/v1`, pensée pour un émulateur Android avec un chemin d'API inversé) — remplacée par `http://127.0.0.1:8004/api/v1` (S8 physique via `adb reverse`, chemin conforme au contrat réel `/api/v1/mobile/...`).
3. **`flutter_secure_storage: ^11.0.0` (dernière version ajoutée automatiquement par `flutter pub add`) exige `compileSdk 37`**, codé en dur dans le `build.gradle` du plugin lui-même — une plateforme Android en préversion (`android-37.0`, nommage non standard) qui a fait échouer `assembleDebug` avec une erreur Gradle masquée par un wrapper de tâche renvoyant malgré tout un code de sortie 0 (**le rapport de tâche en arrière-plan a donc affiché "terminé" alors que le build avait réellement échoué** — piège à retenir : toujours relire le log réel de `flutter build`, pas seulement le code de sortie du wrapper, avant de considérer un APK à jour). Fix : rétrogradé vers `flutter_secure_storage: 9.2.4` (`compileSdk 34`, déjà installé, aucune fonctionnalité perdue pour le simple usage `read`/`write`/`delete` de ce projet).

## Méthode de vérification pour chaque module

Identique à celle du projet Patient :

1. Brancher le code Flutter sur l'endpoint réel (remplacer `AuthSession`/données locales par un appel `ApiClient`).
2. Rebuild l'APK debug : `flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8004/api/v1 --dart-define=DEMO_MODE=false`
3. `adb -s <device-id> reverse tcp:8004 tcp:8004` (le tunnel ne survit pas à une reconnexion USB ni à un `adb kill-server` — à refaire si le S8 se déconnecte, fréquent sur cette machine, voir `CLAUDE.md`).
4. Installer et tester sur le S8 physique.
5. Vérifier le log du serveur Django (`tail -f` sur le fichier de sortie du `runserver` lancé en arrière-plan) pour confirmer un `200`/`201` et pas une erreur silencieuse côté client — **toujours lire le log serveur, pas seulement l'écran**, comme le montre le cas du code OTP expiré ci-dessus (l'UI a correctement affiché l'erreur réelle, mais seul le log confirme que c'était bien un `400` serveur et pas un bug client).
6. Pour un code OTP : le récupérer depuis MailHog (`curl -s http://127.0.0.1:8025/api/v2/messages?limit=1`, déjà utilisé par la session Patient) plutôt que de deviner — **agir vite une fois le code récupéré, il expire en 5 minutes** (`MOBILE_CHALLENGE_MAX_AGE_SECONDS`), un cycle de saisie manuelle via `adb shell input tap` trop lent (dumps `uiautomator` répétés, device qui se déconnecte) peut largement dépasser ce délai — vécu deux fois pendant cette session avant réussite.
7. Cocher la case ci-dessus une fois vérifié.

## Ordre convenu pour la suite

Aligné sur `api_contrat_besoins.md` §7 :

1. [x] **Auth + 2FA + restauration de session** — voir ci-dessus.
2. [x] **Mot de passe oublié** — voir ci-dessus.
3. [x] **Accueil, Courses disponibles, Détail course** — voir §3 ci-dessous.
4. [x] **Course active et signalement d'incident** — voir §4 ci-dessous.
5. [ ] Carte et navigation — bouton « ouvrir navigation externe » uniquement (pas de position temps réel, hors contrat).
6. [ ] Historique — corriger le mapping des filtres pour couvrir `returned`.
7. [ ] Revenus et ledger — agrégats recalculés côté Flutter (Option A actée).
8. [ ] Zones et disponibilité — remplacer les 4 zones inventées par les 4 zones réelles (Bikélé manquant).
9. [ ] Documents — backend prêt depuis le 28 août 2026 (voir `api_contrat_besoins.md` §3.1), retirer le document « Assurance » de l'écran au branchement.
10. [ ] Notifications — retirer "Document validé"/"Versement reçu" (aucune source backend).
11. [ ] Centre d'aide, tickets, conversation support.
12. [ ] Profil et sécurité.

## 3. Accueil, Courses disponibles, Détail course (3 septembre 2026)

Nouveau fichier `lib/src/core/courier_api.dart` : modèles (`Pharmacy`, `CourierDelivery`, `CourierAvailability`, `CourierSummary`) + `CourierApi` (`fetchSummary`, `setAvailable`, `fetchAvailableDeliveries`, `fetchActiveDeliveries`). `formatFcfa()` (séparateur `.` par milliers, déjà utilisé par les écrans démo) déplacé au niveau du fichier dans `courier_shell.dart` pour être réutilisable depuis `detail_screens.dart`.

- [x] **Statut en ligne/hors ligne** (`GET`/`PATCH /mobile/courier/availability/`) — remonté au niveau de `CourierShell` (avant : simple `bool` local jamais persisté). Chargé au démarrage, mise à jour optimiste avec correction si l'appel échoue. Testé : toggle réel confirmé en base (`PATCH` 200), et la liste des courses disponibles se revide/re-remplit automatiquement quand on repasse hors ligne/en ligne (le serveur renvoie `{"deliveries": []}` quand `is_available_for_delivery=false`, comportement déjà correct côté backend, aucune logique client supplémentaire nécessaire).
- [x] **Écran 05 Accueil** (`GET /mobile/courier/summary/`, `GET /mobile/courier/deliveries/active/`) — nom réel (`AuthSession.currentUser.fullName`/`.initials`), carte « Course active » alimentée par la première livraison active réelle (pharmacie, client, **statut réel** au lieu d'un faux « 12 min » — aucune donnée de temps estimé n'existe côté API livreur), stats « Courses terminées » (total réel, libellé « Aujourd'hui » retiré car le compteur backend est cumulatif) et « Solde » (`balance_fcfa` réel, libellé « à reverser »/« à recevoir » dérivé du signe). Alerte « Assurance véhicule expire dans 3 jours » **retirée** (aucune source backend tant que le dossier documentaire n'est pas branché côté mobile, voir item 9) ; carte « Mise à jour disponible » gardée telle quelle (purement informative sur la version de l'app, pas une donnée API). Carte « Zone actuelle » alimentée par les vraies zones couvertes (`coverage_zones`), le badge inventé « En zone de forte demande » retiré.
- [x] **Écran 06 Courses disponibles** (`GET /mobile/courier/deliveries/available/`) — liste réelle, skeleton/erreur/retry ajoutés. Chip « Distance » retirée (aucune coordonnée/position livreur exposée côté API livreur, contrairement au Patient) ; « Revenu estimé » remplacé par « Part livreur est. » sourcée sur `courier_share_fcfa` (montant réellement perçu par le livreur, pas le frais de livraison total).
- [x] **Écran 07 Détail course disponible** — reçoit l'`id` de la livraison via les arguments de route (`/available-detail`, sur le même modèle que `/support-thread`) et retrouve l'entrée correspondante dans la liste des courses disponibles (**aucun endpoint de détail dédié n'existe pour une course non affectée** — `GET /mobile/courier/deliveries/<id>/` est filtré `courier=request.user` et renverrait 404 tant que la course n'est pas affectée ; seule la liste expose ces courses). Gère honnêtement le cas où la course a disparu de la liste entre-temps (affectée à un autre livreur). Section « CONTRAINTES & NOTES » (chaîne du froid, colis fragile) et chips distance/temps **retirées en totalité** — aucun champ backend ne les modélise. **Découverte importante en branchant ce module : il n'existe aucun endpoint permettant à un livreur de « postuler » à une course — l'affectation est entièrement côté Staff.** Le bouton « Postuler pour cette course », qui affichait jusqu'ici une fausse confirmation (« Candidature envoyée... ») via un simple `SnackBar` local sans aucun appel réseau, a été corrigé en dialogue honnête (« La candidature en libre-service n'est pas encore disponible »), cohérent avec le principe d'honnêteté déjà appliqué ailleurs dans l'app.

**Vérifié sur S8 le 3 septembre 2026** : nom réel « Carine Mba » (jeu de démo `seed_demo_courier_carine_mba`), course active réelle (pharmacie « [Démo Carine] Pharmacie Mont-Bouët », client « Joël Mba », statut « En livraison »), solde réel « 1.600 FCFA à recevoir » (signe négatif du ledger correctement traduit), toggle en ligne/hors ligne avec effet réel confirmé en base et sur la liste des courses, 2 courses disponibles réelles affichées (zones `libreville`/`akanda`, correspondant aux `coverage_zones` du compte de test), détail financier exact (1 500 − 600 = 900 FCFA), dialogue honnête « Postuler » confirmé. Aucun overflow.

## 4. Course active et signalement d'incident (3 septembre 2026)

`courier_api.dart` complété : `DeliveryActions` (reflète les 6 booléens `can_pickup`/`can_start`/`can_resend_proof_code`/`can_complete`/`can_report_absence`/`can_report_incident` renvoyés par le backend), `DeliveryIncident`, `PatientAbsenceResult`, et `CourierDelivery` étendu (patient, adresse de livraison, échéance, `is_late`, incidents). `CourierApi` gagne `pickupDelivery`, `startDelivery`, `resendProofCode`, `completeDelivery`, `reportPatientAbsence`, `reportIncident`.

- [x] **Écran 08 Course active** (`ActiveDeliveryScreen`) — entièrement réécrit en état-machine pilotée par `delivery.status` réel (`assigned`/`picked_up`/`in_transit`/`returning`/`delivered`) au lieu d'un `int step` local :
  - Panneaux « Confirmer la collecte »/« Démarrer la livraison » branchés sur `.../pickup/` et `.../start/`.
  - Confirmation de remise : ajout d'un champ **« Nom du destinataire »** (obligatoire côté backend, absent du mockup — prérempli avec le nom du patient), OTP réel envoyé par e-mail à la collecte (`.../complete/`), erreur `invalid_proof_code` affichée inline (cohérent avec le pattern déjà utilisé pour le 2FA), « Renvoyer OTP » réel (`.../resend-proof/`).
  - **Décision du jour appliquée : « Client absent » a son propre bouton et son propre parcours** (bottom sheet dédié — deux cases à cocher **« J'ai appelé... »**/**« J'ai attendu dix minutes... »** + description, jamais un minuteur simulé puisque le backend lui-même ne fait que stocker ces deux confirmations comme des booléens, sans horodatage vérifié — voir `api_contrat_besoins.md` §6.2), visible uniquement si `actions.can_report_absence`. Soumission réelle vers `.../patient-absence/` : fait passer la course à `returning`, affiche un panneau honnête « Retour à la pharmacie en cours » (aucune action livreur possible ensuite, le retour n'est confirmé que côté Staff/web — `confirm_return_to_pharmacy` n'est pas exposé au mobile, décision non remise en cause).
  - Chip « X min restantes » (fausse précision) retirée, remplacée par un badge honnête basé sur le vrai `delivery_deadline` (« Limite HH:mm », rouge « En retard (limite HH:mm) » si `is_late`) — `is_late` n'est vrai côté backend que pour `assigned`/`picked_up`/`in_transit`, donc le badge redevient neutre automatiquement une fois en `returning`, sans logique client supplémentaire.
  - Pharmacie, adresse de livraison, nom/téléphone du patient : tous réels (`pharmacy.name`, `order.delivery_address` + `zone_label`, `order.patient`).
  - « Signaler un problème » visible uniquement si `actions.can_report_incident` (toujours vrai tant que la course n'est pas clôturée).
- [x] **Écran 10 Signalement d'incident** (`IncidentScreen`) — récupère la course active via `fetchActiveDeliveries()` (Option A actée, §3.2) plutôt qu'un identifiant passé en argument de route.
  - **« Client absent » retiré de la liste des types** (décision §6.2) ; les 6 types restants remplacés par les **valeurs et libellés réels du backend** (`delay`/`recipient_unreachable`/`wrong_address`/`vehicle`/`package`/`other`) plutôt qu'un remappage approximatif des 4 anciens libellés fictifs — plus honnête et évite toute perte d'information.
  - Sévérité déjà alignée 1:1 (`low`/`medium`/`high`), aucun changement nécessaire au-delà du mapping des codes.
  - Soumission réelle (`.../incidents/`), rechargement de la course active après succès pour que la section « Incidents ouverts » (dérivée de `delivery.incidents`, filtrée sur `status == 'open'`) reflète immédiatement le nouvel incident — compteur, icône par type, couleur par sévérité, horodatage relatif calculé côté Flutter depuis `created_at`.

**Bug d'overflow trouvé et corrigé en testant sur S8** : la feuille modale « Client absent » utilisait un `Column` non scrollable dans un `showModalBottomSheet` — clavier ouvert (description en cours de saisie), le contenu (titre + 2 cases + champ + bouton) dépassait l'espace disponible (`BOTTOM OVERFLOWED BY 71 PIXELS`). Fix : `Column` enveloppée dans un `SingleChildScrollView`. Deuxième overflow trouvé sur l'écran 10 : le `DropdownButtonFormField` du type d'incident débordait de 5,4 px à droite avec les libellés réels du backend, plus longs que les anciens libellés fictifs (ex. « Colis endommagé ou incomplet ») — fix : `isExpanded: true` + `overflow: TextOverflow.ellipsis` sur le texte de chaque item.

**Découverte importante, hors périmètre de ce module mais à traiter avant d'aller plus loin :** aucun rafraîchissement automatique du jeton d'accès n'est implémenté côté Flutter — `ACCESS_TOKEN_LIFETIME` est de 20 minutes côté Django (`gabpharma/settings.py`), et passé ce délai, **tout appel authentifié échoue** avec une erreur brute (« Le type de jeton fourni n'est pas valide ») affichée telle quelle dans un `SnackBar`, sans redirection vers l'écran de connexion. Repéré en testant ce module (le jeton de connexion de 23h01 a expiré avant la fin de la session de test à 23h23). Un jeton de rafraîchissement de 14 jours existe déjà côté backend (`REFRESH_TOKEN_LIFETIME`) mais n'est ni stocké ni utilisé côté `AuthSession`/`ApiClient` actuellement. **À corriger avant la mise en production réelle** (au minimum : intercepter les 401, tenter un rafraîchissement silencieux, sinon rediriger proprement vers `/login`) — non traité ici pour rester dans le périmètre du module 4, mais à remonter comme prochaine priorité technique transverse.

**Vérifié sur S8 le 3 septembre 2026** (jeu de démo `seed_demo_courier_carine_mba`, course active id 6) : erreur OTP réelle affichée (« Code de remise incorrect. »), flux « Client absent » complet (double confirmation + description → `POST .../patient-absence/` → transition réelle vers `returning` confirmée en base Django, incident `patient_absent`/`high`/`open` créé), panneau « Retour à la pharmacie en cours » avec vraie pharmacie, bouton « Client absent » disparaissant après la déclaration (`can_report_absence` redevenu faux). Signalement d'incident générique complet (`wrong_address`/`low` → `POST .../incidents/` → confirmé en base), liste « Incidents ouverts » passée de 2 à 3 en direct avec la vraie description et « À l'instant ». Aucun overflow après les deux corrections ci-dessus.

## Rappel d'environnement pour reprendre cette session de branchement

- Backend local lancé via `python manage.py runserver 127.0.0.1:8004` (Django 4.2.29, dev DB SQLite `db.sqlite3` du dépôt `django projects\gabpharma`) — a tourné en arrière-plan tout au long de cette session, à relancer si arrêté.
- MailHog déjà en cours d'exécution sur cette machine (`127.0.0.1:1025` SMTP, `127.0.0.1:8025` API/Web) — c'est la source des codes OTP réels en local, pas de vrai e-mail envoyé.
- `adb reverse tcp:8004 tcp:8004` à refaire à chaque nouvelle connexion USB du S8 (voir §6 ci-dessus et `CLAUDE.md` du projet pour l'historique des déconnexions fréquentes de cet appareil).
