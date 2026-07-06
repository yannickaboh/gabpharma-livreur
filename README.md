# Gab'Pharma Livreur

Application Flutter Android opérationnelle destinée aux livreurs Gab'Pharma.

## Démarrage

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/mobile/v1
```

Le projet démarre en mode démonstration. Les affectations, transitions de course,
OTP et calculs du ledger devront exclusivement être exécutés par l'API Django.

## Socle livré

- thème Gab'Pharma Material 3 optimisé pour les actions terrain ;
- splash, connexion et vérification 2FA ;
- navigation Accueil, Courses, Historique, Revenus, Profil ;
- accès aux 18 interfaces prévues dans `documentation/mobile_livreur.md` ;
- course active multi-étapes et signalement d'incident ;
- client HTTP natif configurable par `API_BASE_URL` ;
- test widget de démarrage.
