# Cohorte pédiatrique d'asthme : SQL et Python sur données synthétiques

> Squelette à compléter **par toi, avec tes mots et tes vrais résultats**. Les parties entre crochets
> sont à remplacer. Supprime ce bloc quand tout est rempli.

## Contexte

[2 à 3 phrases : pourquoi ce projet. Exemple de ton honnête : projet personnel pour pratiquer la
construction de cohortes et de tables analytiques à partir de données de santé, dans une logique
proche des bases médico-administratives (type SNDS). Ne dis pas que tu as travaillé sur le SNDS.]

**Les données sont entièrement synthétiques.** Elles ne reproduisent pas le SNDS et aucune conclusion
clinique ne doit en être tirée.

## Données

Cinq tables (voir `schema.sql`) : `patients`, `diagnoses`, `treatments`, `hospitalizations`, `visits`.
Codes CIM-10 (asthme : J45.x) et ATC (classe R03) réels.
Des anomalies de qualité de données ont été injectées volontairement pour travailler le contrôle qualité.

## Reproduire

```bash
python generate_data.py      # génère asthme.db et data/*.csv (graine fixe : résultats identiques)
# exécuter les scripts de sql/ dans l'ordre
python analysis.py           # [adapte au nom réel de ton fichier]
```

## Démarche

1. **Contrôle qualité** : [nombre d'anomalies détectées, types, règles de nettoyage retenues]
2. **Définition de la cohorte** : [critères, effectif obtenu]
3. **Variables dérivées** : [liste]
4. **Table analytique** : [description, une ligne par patient]
5. **Analyse** : [méthodes utilisées]

## Résultats

[2 à 4 résultats chiffrés, avec les graphiques de `figures/`]

## Choix méthodologiques à justifier

- [Comment tu as géré les `end_date` manquantes, et pourquoi]
- [Quelle définition de cohorte tu as retenue (diagnostic ou traitement), et pourquoi]
- [Comment tu as traité les doublons]

## Limites

- Données fictives : aucune portée clinique.
- [Biais d'indication : les groupes de traitement ne sont pas comparables au départ, donc une
  différence de taux d'hospitalisation ne prouve aucun effet du traitement.]
- [Ce que tu ferais avec de vraies données : volumétrie, séries temporelles interrompues, essais émulés, etc.]

## Structure du dépôt

```
schema.sql          schéma des tables
generate_data.py    génération des données synthétiques
sql/                requêtes numérotées
analysis.py         analyses et figures
figures/            graphiques
notes.md            difficultés rencontrées, apprentissages
```
