# Cohorte pédiatrique d'asthme : contrôle qualité et construction de cohorte en SQL

Projet personnel d'analyse de données de santé visant à mettre en pratique et démontrer
mes compétences en contrôle qualité, structuration des données et construction de cohortes
en SQL, dans une logique proche des bases médico-administratives de santé.

Les données sont entièrement synthétiques. Elles ne reproduisent pas le SNDS et aucune
conclusion clinique ne doit en être tirée.

## Données

Cinq tables SQLite (schéma dans `schema.sql`) : `patients`, `diagnoses`, `treatments`,
`hospitalizations`, `visits`. 2 500 patients. Les codes CIM-10 (asthme : J45.x) et ATC (classe R03)
sont réels. Des anomalies de qualité ont été injectées volontairement dans les données.

## Contenu du dépôt

```
schema.sql           schéma des tables
generate_data.py     génération des données synthétiques (graine fixe : 42)
00_explorer.sql          niveau 0 : exploration des tables
01_filtres_agregats.sql  niveau 1 : filtres et agrégats
02_qualite.sql       détection des 9 types d'anomalies, tableau récapitulatif, vues *_clean
03_jointures.sql     patients asthmatiques et traitements, patients sans traitement
04_cohorte.sql       premier diagnostic d'asthme, âge, tranche d'âge
notes.md             résultats par niveau, choix de nettoyage, difficultés
data/                données synthétiques au format CSV
```

Pour reproduire : `python generate_data.py` crée `asthme.db`, puis j'exécute les fichiers `.sql`
dans l'ordre avec DB Browser for SQLite. Les vues créées dans `02_qualite.sql` sont utilisées par
`03_jointures.sql` et `04_cohorte.sql`.

## Démarche et résultats

**1. Contrôle qualité.** J'ai trouvé 9 types d'anomalies, 136 lignes concernées au total
(valeurs manquantes, doublons, dates incohérentes, naissances après la fin de la période, sexe codé de
6 façons différentes, codes CIM-10 mal formatés, consultations de patients inexistants). Elles sont
regroupées dans un tableau récapitulatif (`UNION ALL`), puis corrigées ou exclues dans des vues
`v_*_clean`, sans toucher aux tables d'origine. Après nettoyage : 2 495 patients, 2 092 diagnostics,
784 traitements, 325 hospitalisations, 9 053 consultations. Les 20 écritures distinctes de codes
de diagnostic sont ramenées à 10 codes.

**2. Jointures.** 381 patients ont au moins un diagnostic d'asthme (J45.x). Parmi eux, 379 ont au
moins un traitement enregistré et 2 n'en ont aucun.

**3. Cohorte pédiatrique.** Critère : moins de 18 ans à la date du premier diagnostic d'asthme.
343 patients : 143 de 0 à 5 ans, 147 de 6 à 11 ans, 53 de 12 à 17 ans.

## Choix méthodologiques

- **Date de référence** pour repérer les naissances "dans le futur" : la fin de la période des données
  (2025-12-31), et non la date du jour. Avec la date du jour, je ne trouvais qu'1 anomalie sur 5.
- **Doublons** : je regroupe sur les colonnes métier, sans l'identifiant technique, et je garde la ligne
  au plus petit identifiant de chaque groupe.
- **Dates de fin de traitement manquantes** (40 lignes) : je les conserve, car le traitement peut être en
  cours ou sa fin inconnue. Je n'en calcule pas de durée dans ce projet.
- **Codes CIM-10** : normalisés (majuscules, sans espace, point après le 3e caractère) avant tout filtre sur J45.
- **Lignes invalides** (fin avant début, sortie avant admission, naissance après 2025-12-31, consultations
  sans patient) : exclues des vues. Un patient exclu emporte ses diagnostics, traitements,
  hospitalisations et consultations.
- **Âge au diagnostic** : (date du premier diagnostic - date de naissance) / 365,25, avec des seuils
  ordonnés dans un `CASE WHEN` pour les tranches d'âge.

## Limites

- Données fictives : aucune portée clinique.
- Le projet s'arrête à la cohorte. Je n'ai pas construit de variables dérivées (durées de traitement,
  groupes de traitement), de table analytique ni d'analyse statistique.
- La cohorte est définie par le diagnostic uniquement. Je n'ai pas comparé avec une cohorte définie par
  les traitements (par exemple le salbutamol), qui donnerait probablement un autre effectif. C'est un point
  délicat des algorithmes d'identification sur de vraies données.
- Je ne compare pas les traitements entre eux : les groupes ne seraient pas comparables au départ
  (biais d'indication).

## Usage de l'IA

Usage de l’IA

Le projet a été réalisé avec l’aide de Claude (Anthropic). Le jeu de données synthétique et la liste des exercices ont été préparés avec cet outil.

Toutes les requêtes SQL ont été écrites et réalisées par moi-même. L’IA a ponctuellement été utilisée comme outil de vérification lorsque nécessaire.
