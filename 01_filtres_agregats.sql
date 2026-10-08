-- Niveau 1 : filtres et agrégats

-- Nombre de patients nés après le 1er janvier 2010
SELECT COUNT(birth_date)
FROM patients
WHERE birth_date > '2010-01-01';

-- Nombre de diagnostics par code, du plus fréquent au moins fréquent
SELECT diagnosis_code, COUNT(diagnosis_code) AS nb
FROM diagnoses
GROUP BY diagnosis_code
ORDER BY nb DESC;

-- Nombre de consultations par type de consultation
SELECT visit_type, COUNT(visit_type) AS nb
FROM visits
GROUP BY visit_type
ORDER BY nb DESC;

-- Types de consultation ayant plus de 1 500 lignes
SELECT visit_type, COUNT(visit_type) AS nb
FROM visits
GROUP BY visit_type
HAVING COUNT(visit_type) > 1500;

-- Répartition des patients par sexe
SELECT sex, COUNT(sex) AS nb
FROM patients
GROUP BY sex;