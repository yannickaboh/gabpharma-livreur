# Gab'Pharma Livreur — suivi d'implémentation Flutter

**Dernière mise à jour :** 20 juillet 2026
**Mode actuel :** démonstration statique (`AppConfig.demoMode`), aucune connexion à l'API mobile Django. **Lots 1, 2 et 3 terminés et validés** (13 des 18 écrans). Lot 4 reste à construire.

## Projet

Application Flutter Android **opérationnelle** destinée aux **livreurs** Gab'Pharma (distincte de l'app Patient). Elle sert à :
- recevoir et suivre les courses de livraison de médicaments affectées par le Staff (pas d'auto-attribution : le livreur consulte les courses disponibles mais l'affectation reste manuelle) ;
- exécuter une course du début à la fin (collecte en pharmacie → trajet → remise au patient avec confirmation par code OTP) ;
- gérer sa disponibilité (en ligne/hors ligne, zones géographiques couvertes), ses documents administratifs, ses revenus (répartition plateforme/livreur), l'historique de ses courses, ses notifications et le support.

Le ton visuel est **"fiabilité opérationnelle"** : palette vert profond (`#006A35`), gros boutons pleine largeur (min 56px), forte lisibilité pensée pour un usage en extérieur/à bout de bras pendant la conduite. Voir `stitch_gab_pharma_livreur_app/gab_pharma_livreur_design_system/DESIGN.md` pour la charte complète (couleurs, typographie Inter, rayons, composants).

## Méthode de travail (à respecter pour chaque nouvel écran)

Pour chaque écran du dossier `stitch_gab_pharma_livreur_app/<NN_nom_ecran>/` :
1. Lire ce présent fichier (`CLAUDE.md`) pour le rôle fonctionnel et les états attendus de l'écran — **il n'existe pas de `maquette_mobile_livreur.md` séparé** dans ce projet (contrairement à l'app Patient) ; ce fichier en tient lieu. Le `README.md` du projet référence un fichier `documentation/mobile_livreur.md` qui **n'existe pas** dans le dépôt — ignorer cette mention obsolète.
2. Ouvrir `screen.png` (source de vérité visuelle) ET `code.html` (valeurs exactes : couleurs, radius, paddings, tailles, textes).
3. Si l'image et le code divergent, privilégier l'image et signaler l'écart à l'utilisateur.
4. Implémenter en Flutter/Material 3, tester sur le Samsung Galaxy S8 via ADB, et **attendre la validation visuelle de l'utilisateur avant de passer à l'écran suivant**.
5. Toujours dire en une phrase ce qui a été implémenté et les écarts assumés par rapport au mockup (pas de fausse fonctionnalité ni de New devinette).
6. Après capture d'écran ADB, toujours vérifier qu'il n'y a pas d'overflow (bande jaune/noire "RenderFlex overflowed") avant de considérer l'écran validé — plusieurs ont été corrigés a posteriori sur cette base (AppBar titre, cases OTP, panneaux flottants carte).

## État d'avancement des 18 écrans

Légende : `[x]` terminé et validé · `[~]` esquisse existante à reprendre selon le mockup · `[ ]` non construit.

### Lot 1 — Authentification (4 écrans) — **terminé et validé**
- [x] 01 Splash / restauration de session (`SplashScreen`) — texte de statut dynamique, halo décoratif, bandeau "Mode Hors Ligne" avec bouton "Réessayer" basé sur une vraie détection de connectivité (`InternetAddress.lookup`), footer version. Bug de centrage corrigé (le `Stack` se rétrécissait à la largeur de son contenu au lieu de remplir l'écran — fix via `SizedBox.expand`).
- [x] 02 Connexion Livreur (`LoginScreen`) — champ Matricule (placeholder "Ex: GP-2024-88"), mot de passe avec toggle visibilité, validation de formulaire réelle (`Form`/`TextFormField`), état de chargement sur le bouton, badge "Serveur Opérationnel" à point pulsant, dialogue de contact support (numéro démo).
- [x] 03 Vérification 2FA (`VerifyScreen`) — 6 cases OTP pilotées par un pavé numérique custom intégré (redimensionné pour tenir sans scroll), minuteur de renvoi, état d'erreur avec animation shake. Code démo : `123456`.
- [x] 04 Récupération de mot de passe (`PasswordResetScreen`) — parcours 3 étapes (identifiant → OTP 6 chiffres → nouveau mot de passe avec règle "8 caractères + 1 chiffre") → écran "Félicitations !".

### Lot 2 — Cœur opérationnel : courses et livraison (5 écrans) — **terminé et validé**
- [x] 05 Accueil Opérationnel (`CourierHome`, onglet Accueil) — header partagé (`_HomeHeader`) avec toggle en ligne/hors ligne, carte course active complète (badge, client, ETA, bouton "Démarrer l'itinéraire"), stats bento, alertes (document + mise à jour app), aperçu "Zone Actuelle" (dégradé + badge densité).
- [x] 06 Courses disponibles (`AvailableDeliveries`, onglet Courses) — réutilise `_HomeHeader`, bandeau "Affectation manuelle par le Staff", cartes complètes (quartier, distance, revenu estimé, statut "En attente"), état vide disponible mais non simultané avec la liste (contrairement au mockup qui montre les deux à la fois à titre de démonstration).
- [x] 07 Détail course disponible (`AvailableCourseDetailScreen`) — bannière "En attente d'affectation", carte pharmacie avec chips distance/temps, zone de livraison floutée (dégradé + badge + avertissement), détail financier (Frais/Commission/Part livreur), tags contraintes, bouton "Postuler" qui soumet une vraie demande (snackbar + retour liste) plutôt qu'une affectation instantanée fictive.
- [x] 08 Course active (`ActiveDeliveryScreen`) — timeline visuelle à 4 points, carte client (nom + téléphone + bouton Appeler honnête via dialogue), carte itinéraire (ramassage/livraison + boutons Navigation/Appeler), confirmation de remise par OTP **6 chiffres** (décision utilisateur : cohérence avec 03/04 plutôt que les 4 chiffres du mockup), état "Livré" final.
- [x] 09 Carte et navigation (`NavigationMapScreen`) — carte simplifiée dessinée en `CustomPainter` (fond illustratif, pas de SDK), panneau stats (temps/distance), panneau patient flottant (appeler + retour), FAB de recentrage honnête (message "indisponible en démonstration"). Clé Google Maps préparée dans le manifeste (voir plus bas) pour le jour où le SDK sera branché.

**Décisions actées pendant les lots 1-2 (ne pas re-demander) :**
- **Code OTP à 6 chiffres partout**, y compris l'écran 08 (remise de commande) où le mockup en montrait 4 — tranché par l'utilisateur pour la cohérence avec le vrai backend Django, comme sur l'app Patient.
- **Bordures d'input visibles** (`GabColors.outlineVariant` au repos, `primary` au focus, `danger` en erreur) ajoutées à `lib/src/core/theme.dart`, alignées sur l'app Patient — le thème livreur n'avait initialement aucune bordure (`BorderSide.none`), corrigé sur retour utilisateur.
- **Header partagé `_HomeHeader`** (icône livraison + titre + toggle "EN LIGNE"/"HORS LIGNE") dans `courier_shell.dart`, réutilisé entre les onglets Accueil et Courses ; à réutiliser aussi pour Historique/Revenus/Profil si leurs mockups (lot 3/4) le confirment.
- **Cohérence des données de la course active** : pharmacie "Pharmacie du Bord de Mer", patiente "Mme. Obiang" (+241 07 00 00 00), destination "Quartier Louis, Libreville / Rue 12.045", ETA "12 min" — alignés entre les écrans 05, 08 et 09 plutôt que de copier les identités différentes utilisées par les mockups Stitch (qui divergent entre eux d'un écran à l'autre).
- **Clé Google Maps API** : injectée via `android/local.properties` (`mapsApiKey`, gitignoré) → `android/app/build.gradle.kts` (`manifestPlaceholders`) → `AndroidManifest.xml` (`com.google.android.geo.API_KEY`), à l'identique de l'app Patient. Package `ga.gabpharma.gabpharma_livreur` et SHA-1 du keystore debug (`B6:58:7D:8B:84:83:4B:7D:C0:B7:34:57:AD:70:3B:52:6B:7D:B1:63`, partagé par toutes les apps Flutter debug de cette machine) déjà communiqués à l'utilisateur pour restreindre la clé côté Google Cloud Console. Le SDK `google_maps_flutter` lui-même n'est pas encore ajouté au `pubspec.yaml`.

### Lot 3 — Incidents, historique, revenus, disponibilité (4 écrans) — **terminé et validé**
- [x] 10 Signalement d'incident (`IncidentScreen`) — sélecteur de sévérité à 3 boutons colorés (Faible/Moyenne/Critique, remplace le dropdown initial), dropdown Type d'incident, description, liste "Incidents ouverts" avec badge de comptage et statuts colorés (Signalé rouge / En résolution ambre), dialogue de détail au tap.
- [x] 11 Historique des courses (`DeliveryHistory`, onglet Historique) — stats bento (Total Courses / Ce Mois), carte "Revenus Totaux" en vert clair, filtres pills (Tout/Livré/Annulé) réellement fonctionnels, groupement par date (Aujourd'hui/Hier), pill "Juin 2026" honnête (snackbar plutôt qu'un vrai sélecteur de mois — pas assez de données de démo pour un historique multi-mois).
- [x] 12 Revenus et ledger (`EarningsScreen`, onglet Revenus) — carte solde vert primary + badge "À reverser à Gab'Pharma", onglets Quotidien/Hebdomadaire **réellement fonctionnels** (deux jeux de données démo distincts pour les agrégats ; la liste des 3 courses récentes reste identique entre les deux onglets — les entrées "récentes" sont indépendantes de la période agrégée, seuls les totaux changent), bento Espèces/Électronique, section "Détails des gains (60/40)" avec icône info → dialogue explicatif, 3 cartes de course avec badge méthode de paiement (Espèces/Airtel Money) et split 60/40 par course, bouton "Demander un virement" honnête (snackbar, pas de faux succès).
- [x] 13 Zones et disponibilité (`AvailabilityScreen`, route `/availability`) — toggle "Statut Actuel" avec badge coloré (vert "EN LIGNE" / rouge "HORS LIGNE") synchronisé avec le badge de l'AppBar, 4 zones à cocher (Libreville Centre, Akanda, Owendo, SNI/Angondjé) en multi-sélection réelle, carte illustrative en `CustomPainter` (`_ZoneMapPainter`, même approche que l'écran 09) avec boutons zoom +/- honnêtes, bouton "Mettre à jour ma zone" qui envoie une vraie demande simulée (délai + snackbar) sans jamais faire aboutir le changement de zone en démo — cohérent avec le texte d'avertissement du mockup ("validation sous ~5 min").

**Décision actée pendant le lot 3 (ne pas re-demander) :**
- **Distinction "zones couvertes" vs "zone active validée"** (écran 13) : les cases à cocher représentent l'intention du livreur (zones qu'il souhaite couvrir), tandis que le badge "verified" + la pill sur la carte représentent la zone actuellement approuvée par le support logistique. Les deux ne se synchronisent jamais automatiquement en mode démo (pas de vraie validation) — décision prise pour rester honnête plutôt que de faire semblant qu'une nouvelle zone est activée instantanément.

### Lot 4 — Documents, notifications, support, compte (5 écrans)
- [ ] 14 Documents et dossier — route `/documents` en placeholder. Le mockup attend une progression de dossier ("Complété à 65%") et des statuts par document distincts : Validé / En attente de vérification / Refusé (avec motif et bouton "Remplacer le document").
- [ ] 15 Notifications — route `/notifications` en placeholder. Le mockup attend un groupement par jour, un bouton "Tout lire", des cartes lues/non lues (pastille + bordure colorée), liées à des courses/documents/versements concrets.
- [ ] 16 Centre support — route `/support` en placeholder avec juste un bouton vers la conversation. Le mockup attend 3 catégories rapides (Livraison/Compte/Paiement), une recherche de ticket, et une liste de tickets avec statuts (En cours/Retard/Terminé) et un FAB "Créer un ticket".
- [ ] 17 Conversation Support — route `/support-thread` en placeholder. Le mockup attend un vrai fil de discussion (bulles agent/livreur, horodatage, accusés de lecture, pièce jointe image, suggestions de réponse rapide) lié au ticket ouvert.
- [ ] 18 Profil et sécurité — **deux surfaces à réconcilier** : l'onglet Profil (`CourierProfile`) a déjà une esquisse (identité, liste de liens vers les écrans de ce lot, déconnexion), mais la route `/security` séparée (accessible depuis cette liste) est un placeholder. Le mockup 18 ("Mon Profil") semble correspondre à l'écran d'onglet lui-même (photo, identité, véhicule, sécurité, confidentialité, déconnexion) plutôt qu'à un sous-écran séparé — **à clarifier avec l'utilisateur** : fusionner `/security` dans l'onglet Profil, ou garder les deux avec des rôles différents (ex. onglet = profil résumé, `/security` = changement de mot de passe dédié) ?

## Principes hérités de l'app Patient (mêmes conventions attendues ici, sauf indication contraire)

- **Honnêteté plutôt que fausse fonctionnalité** : si une action n'est pas réellement câblée (ex. affectation automatique, virement réel, appel téléphonique sans plugin télécom, carte réelle sans SDK, recentrage GPS), afficher un message clair (dialogue ou snackbar) plutôt que de simuler un faux résultat. Appliqué sur les écrans 07 (candidature), 08 et 09 (appel), 09 (recentrage).
- **Images distantes du mockup (photos IA Stitch)** : ne pas télécharger — remplacer par des dégradés de couleur + icônes Material cohérents avec la palette du projet (cartes/zones des écrans 05, 07, 09).
- **Cohérence des données de démo entre écrans** : les mêmes références de course (`GP-xxxx`), montants, identités et statuts doivent se retrouver à l'identique entre tous les écrans plutôt que copier des valeurs mockup incohérentes d'un écran à l'autre (voir décision actée ci-dessus pour la course active).
- **Mode démo** : `DemoBanner` piloté par `AppConfig.demoMode` (`lib/src/core/app_config.dart`), enveloppé dans un `SafeArea(bottom: false)` au niveau de `CourierShell` pour ne pas chevaucher la barre de statut.
- **`SimpleFeatureScreen`** (`lib/src/detail_screens.dart`) est le placeholder générique temporaire : à faire disparaître écran par écran au fur et à mesure (déjà retiré pour les routes `/password-reset`, `/available-detail`, `/map`), jusqu'à suppression complète une fois les 18 écrans construits.
- **Palette et thème** : `lib/src/core/theme.dart` (`GabColors.*`) reprend la charte de `gab_pharma_livreur_design_system/DESIGN.md` (vert `#006A35`, fond `#EDFDF4`, cartes 16px, bordures d'input `outlineVariant`/`primary`/`danger`) — vérifier à chaque écran que les couleurs d'état (bleu `routeBlue` "en cours", ambre `warning` "retard/attente", rouge `danger` "incident/refus/déconnexion") sont utilisées de façon cohérente avec les badges du mockup.
- **Code démo OTP** : 6 chiffres partout, y compris l'écran 08 (tranché avec l'utilisateur, voir Lot 2 ci-dessus).

## Tester sur le Samsung Galaxy S8 (ADB)

```powershell
adb devices                                    # vérifier que le S8 est détecté
cd C:\Users\24174\StudioProjects\gabpharma_livreur
flutter build apk --debug
adb -s <device-id> install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s <device-id> shell am force-stop ga.gabpharma.gabpharma_livreur
adb -s <device-id> shell am start -n ga.gabpharma.gabpharma_livreur/.MainActivity
```

Ou plus simple pour itérer avec hot reload :
```powershell
flutter run -d <device-id>
```

`<device-id>` confirmé en session : `988d55344b31384730` (peut changer si rebranché sur un autre port USB — relancer `adb devices` pour confirmer). Le S8 se déconnecte parfois de l'hôte ADB (ex. pendant un appel WhatsApp) ; relancer `adb kill-server && adb start-server` puis `adb devices` si besoin.

Pour scripter la navigation (connexion + 2FA) lors des tests, utiliser `adb shell uiautomator dump` pour retrouver les bounds exacts des boutons plutôt que d'estimer les coordonnées à l'œil — plusieurs taps ont échoué silencieusement à cause de coordonnées mal calculées après un changement de layout. Toujours préfixer les commandes manipulant des chemins `/sdcard/...` par `export MSYS_NO_PATHCONV=1` (Git Bash traduit sinon `/sdcard/...` en chemin Windows).

## Prochaine étape

Démarrer le Lot 4 par l'écran **14 Documents et dossier**, en suivant la méthode de travail ci-dessus : lire `stitch_gab_pharma_livreur_app/14_documents_et_dossier/screen.png` + `code.html`, comparer au placeholder `SimpleFeatureScreen` actuel sur la route `/documents`, puis proposer l'implémentation fidèle au mockup (progression de dossier "Complété à 65%", statuts par document Validé/En attente de vérification/Refusé avec motif et bouton "Remplacer le document") avant de passer à l'écran 15. Pour l'écran 18 (Profil et sécurité), penser à clarifier avec l'utilisateur la question de fusion `/security` ↔ onglet Profil notée dans le Lot 4 ci-dessus avant de l'implémenter.

## Notes de session (tests ADB)

Pendant les tests manuels sur le S8, plusieurs appels vidéo WhatsApp réels sont arrivés sur le téléphone de l'utilisateur (sans lien avec les taps ADB, pure coïncidence de timing) et ont pris le contrôle de l'écran — toujours interrompre immédiatement les tests et ne plus toucher au téléphone tant que l'utilisateur n'a pas confirmé avoir géré l'appel. Le S8 se déconnecte aussi de l'hôte ADB pendant ces appels ; redemander à l'utilisateur de vérifier le câble USB plutôt que de supposer une reconnexion automatique.
