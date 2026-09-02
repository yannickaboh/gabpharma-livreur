# Gab'Pharma Livreur — suivi du branchement API réelle

**Créé le :** 28 août 2026
**But :** suivre, module par module, le passage du mode démonstration (`AppConfig.demoMode`) au vrai backend Django (`/api/v1/...`), sur le même modèle que `C:\Users\24174\StudioProjects\gabpharma_patient\branchement_patient.md`. Cocher au fur et à mesure, ne pas re-décider l'ordre sans raison (voir `api_contrat_besoins.md` §7 pour l'ordre recommandé).

## Déjà branché et vérifié (28 août 2026, sur S8 physique + backend local `:8004`)

- [x] Connexion (`POST /mobile/auth/login/`)
- [x] Vérification 2FA (`POST /mobile/auth/verify-2fa/`) — succès **et** échec réels testés (code expiré renvoyant "Code invalide ou expiré." affiché tel quel dans l'UI)
- [x] Renvoi du code (`POST /mobile/auth/resend-2fa/`) — testé, nouveau `challenge_id` reçu et utilisé pour la vérification suivante
- [x] Restauration de session (`GET /mobile/auth/me/`) — testée en relançant l'app après connexion (« Session retrouvée... », navigation directe vers `/home` sans repasser par le login)
- [x] Déconnexion — testée : efface le jeton stocké (`flutter_secure_storage`), confirmé en relançant l'app après déconnexion (retour à un formulaire de connexion vide, aucun appel réseau à `/me/`, cohérent avec `AuthSession.restoreSession()` qui ne fait rien si aucun jeton n'est stocké)
- [ ] Mot de passe oublié (`password-reset/`, `.../verify/`, `.../confirm/`) — câblé côté Flutter (`AuthSession.requestPasswordReset/verifyPasswordReset/confirmPasswordReset`), **non re-testé sur device** cette session (mécaniquement identique au flux 2FA déjà validé, mais pas de vérification physique indépendante à ce jour)

**Identifiant de test utilisé :** `livreur@gabpharma.ga` / `Livreur2026.` (compte `ProfessionalApplication` actif, zone `libreville`, `vehicle_type=motorbike`, recréé en base locale pour ce test — mot de passe à retenir pour les prochaines sessions de vérification).

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
2. [ ] Mot de passe oublié — à re-tester isolément sur device (câblé, non vérifié séparément).
3. [ ] Accueil, Courses disponibles, Détail course — nécessite d'abord de décider du sort des chips distance/temps inventées (`api_contrat_besoins.md` §6, non tranché : retirer ou calculer réellement une fois la géolocalisation livreur disponible).
4. [ ] Course active — séparer le flux « Client absent » du signalement d'incident générique avant de brancher.
5. [ ] Carte et navigation — bouton « ouvrir navigation externe » uniquement (pas de position temps réel, hors contrat).
6. [ ] Historique — corriger le mapping des filtres pour couvrir `returned`.
7. [ ] Revenus et ledger — agrégats recalculés côté Flutter (Option A actée).
8. [ ] Zones et disponibilité — remplacer les 4 zones inventées par les 4 zones réelles (Bikélé manquant).
9. [ ] Documents — backend prêt depuis le 28 août 2026 (voir `api_contrat_besoins.md` §3.1), retirer le document « Assurance » de l'écran au branchement.
10. [ ] Notifications — retirer "Document validé"/"Versement reçu" (aucune source backend).
11. [ ] Centre d'aide, tickets, conversation support.
12. [ ] Profil et sécurité.

## Rappel d'environnement pour reprendre cette session de branchement

- Backend local lancé via `python manage.py runserver 127.0.0.1:8004` (Django 4.2.29, dev DB SQLite `db.sqlite3` du dépôt `django projects\gabpharma`) — a tourné en arrière-plan tout au long de cette session, à relancer si arrêté.
- MailHog déjà en cours d'exécution sur cette machine (`127.0.0.1:1025` SMTP, `127.0.0.1:8025` API/Web) — c'est la source des codes OTP réels en local, pas de vrai e-mail envoyé.
- `adb reverse tcp:8004 tcp:8004` à refaire à chaque nouvelle connexion USB du S8 (voir §6 ci-dessus et `CLAUDE.md` du projet pour l'historique des déconnexions fréquentes de cet appareil).
