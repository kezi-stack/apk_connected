# Pulseboard

Application Flutter full-stack de certification : authentification JWT, donnees REST, persistance locale et mode hors-ligne.

## Fonctionnalites

- Login JWT, logout et creation de profil via DummyJSON.
- Trois ecrans de donnees : Catalogue produits, Brief articles, Equipe.
- Cache local Hive pour les trois ressources.
- Si l'API est indisponible, les dernieres donnees cachees sont affichees avec un message utilisateur explicite.
- Intercepteur Dio : injection automatique du Bearer token et nettoyage de session sur HTTP 401.
- Etats de chargement et d'erreur visibles dans l'interface.

## Architecture

```text
lib/
  data/
    api_client.dart       Client Dio et intercepteur JWT
    local_store.dart      Abstraction Hive pour session et cache
    repositories.dart     AuthRepository et CatalogRepository
  domain/
    models.dart            Modeles Product, Article et Person
  main.dart                Presentation, navigation et etats UI
```

Le pattern Repository isole les appels REST et la strategie offline du widget tree. Les modeles du domaine ne dependent pas de Dio ou de Hive.

## API

Backend public utilise : [DummyJSON](https://dummyjson.com).

- `POST /auth/login`
- `POST /users/add`
- `GET /products?limit=12`
- `GET /posts?limit=12`
- `GET /users?limit=12`

Identifiants de demo : `emilys` / `emilyspass`.

## Lancer le projet

```bash
flutter pub get
flutter run
```

Pour le web :

```bash
flutter run -d chrome
```

## Verification

```bash
flutter test
flutter analyze
flutter build web
```

Les tests unitaires couvrent les contrats de mapping des trois ressources du repository : produits, articles et utilisateurs.
