# Free Map Review

Applicazione Flutter cross-platform (iOS, Android, Web) per scoprire e recensire luoghi vegani e sanitari sulla mappa OpenStreetMap.

## Funzionalità

- Mappa interattiva OpenStreetMap con marker personalizzati per categoria (verde: vegan, blu: healthcare, arancione: generale)
- Ricerca luoghi via OSM Nominatim
- Aggiunta nuovi luoghi con geolocalizzazione GPS o selezione manuale
- Sistema di recensioni con votazione 1-5 stelle
- Modulo recensioni healthcare con disclaimer legale e campi specifici (pulizia, attenzione personale, tempo di attesa)
- Upload immagini con compressione locale e salvataggio su Supabase Storage
- Dark/Light mode automatico
- PWA installabile su Web con Service Worker offline

## Tecnologie

- Flutter 3.x
- flutter_map + OpenStreetMap
- Supabase (PostgreSQL + PostGIS, Storage, Auth)
- Riverpod 2.x
- go_router

## Setup

1. Sostituire le credenziali in `lib/config/constants.dart`:
   - `supabaseUrl`
   - `supabaseAnonKey`

2. Eseguire lo schema SQL in `supabase_schema.sql` nel Supabase SQL Editor

3. Installare dipendenze:
   ```bash
   flutter pub get
   ```

4. Eseguire l'app:
   ```bash
   flutter run
   ```

## Struttura progetto

```
lib/
  config/constants.dart
  main.dart
  models/          # Location, Review
  providers/       # Auth, Locations, Reviews
  services/        # Supabase, Image, Map
  screens/         # Map, Detail, AddReview, AddLocation
  widgets/         # CustomMapMarker, ReviewCard, ImageUploader
web/
  index.html
  manifest.json
  sw.js
supabase_schema.sql
```
