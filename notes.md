## Niveau 0

* Exploration des 5 tables avant nettoyage : 2 500 patients, 2 095 diagnostics, 807 traitements,
  332 hospitalisations, 9 079 consultations.

## Niveau 1

* La répartition par sexe donnait 8 valeurs au lieu de 2 : c'est ce qui m'a mis sur la piste du niveau 2.

## Niveau 2 : contrôle qualité

9 types d'anomalies repérés (récapitulatif dans la requête Q11 de 02\_qualite.sql).

patients

* 5 dates de naissance après la fin de la période (2025-12-31)
* 30 sexes mal codés, 6 écritures (f, m, Féminin, femme, Homme, masculin)
* pas de valeur vide, doublons non testables

diagnoses

* 14 codes CIM-10 mal formatés (espaces, minuscules, point absent)
* 3 diagnostics datés avant la naissance, liés aux dates de naissance aberrantes
* pas de doublon, pas d'orphelin

treatments

* 40 end\_date vides (traitement en cours ou fin inconnue), conservées
* 15 doublons exacts en trop
* 8 end\_date antérieures à start\_date

hospitalizations

* 6 sorties antérieures à l'admission

visits

* 12 doublons exacts en trop
* 6 consultations de patients inexistants

## Choix de nettoyage

* Date de référence = fin des données (2025-12-31), pas la date du jour
* Doublons : je garde la ligne avec le plus petit identifiant
* Un patient exclu emporte ses lignes dans les autres tables
* Après nettoyage : 2495 patients, 2092 diagnoses, 784 treatments,
  325 hospitalizations, 9053 visits

## Niveau 3 : jointures

* 381 patients ont un diagnostic d'asthme (J45). 379 ont au moins un traitement, 2 n'en ont aucun.
* Je joins toujours sur patient\_id et j'utilise les vues propres, pas les tables brutes.

## Niveau 4 : cohorte

* Critère : moins de 18 ans à la date du premier diagnostic J45.
* 381 patients asthmatiques, dont 343 dans la cohorte pédiatrique :
  143 de 0 à 5 ans, 147 de 6 à 11 ans, 53 de 12 à 17 ans.
* Premier diagnostic calculé dans une CTE, pour garder la requête lisible.
