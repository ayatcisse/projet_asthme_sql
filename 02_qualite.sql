-- Niveau 2 : contrôle qualité sur asthme.db (données synthétiques)

-- Q10 : table patients
-- Date de référence = fin de la période des données (2025-12-31), pas la date du jour
SELECT COUNT(*) AS nb
FROM patients
WHERE birth_date > '2025-12-31';

-- Sexe : autre chose que F ou M
SELECT sex, COUNT(*) AS nb
FROM patients
WHERE sex NOT IN ('F', 'M')
GROUP BY sex
ORDER BY nb DESC;

SELECT COUNT(*) AS nb
FROM patients
WHERE birth_date IS NULL OR sex IS NULL;

-- Q10 : table diagnoses
-- Code valide = lettre, 2 chiffres, point, 1 chiffre (ex. J45.9)
SELECT COUNT(*) AS nb
FROM diagnoses
WHERE diagnosis_code NOT GLOB '[A-Z][0-9][0-9].[0-9]';

-- Diagnostic daté avant la naissance
SELECT d.diagnosis_id, d.patient_id, d.diagnosis_date, p.birth_date
FROM diagnoses AS d
INNER JOIN patients AS p ON d.patient_id = p.patient_id
WHERE d.diagnosis_date < p.birth_date;

SELECT patient_id, diagnosis_date, diagnosis_code, COUNT(*) AS nb
FROM diagnoses
GROUP BY patient_id, diagnosis_date, diagnosis_code
HAVING nb > 1;

SELECT d.diagnosis_id, d.patient_id
FROM diagnoses AS d
LEFT JOIN patients AS p ON d.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Q10 : table treatments
-- end_date vide : traitement en cours ou fin inconnue, je garde ces lignes
SELECT COUNT(*) AS nb
FROM treatments
WHERE end_date IS NULL;

-- Doublons : nb - 1 = lignes en trop dans chaque groupe
SELECT SUM(nb - 1) AS lignes_en_trop
FROM (
    SELECT COUNT(*) AS nb
    FROM treatments
    GROUP BY patient_id, atc_code, treatment, start_date, end_date
    HAVING COUNT(*) > 1
);

SELECT COUNT(*) AS nb
FROM treatments
WHERE end_date < start_date;

SELECT t.treatment_id, t.patient_id
FROM treatments AS t
LEFT JOIN patients AS p ON t.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Q10 : table hospitalizations
SELECT COUNT(*) AS nb
FROM hospitalizations
WHERE discharge_date < admission_date;

SELECT h.hospitalization_id, h.patient_id
FROM hospitalizations AS h
LEFT JOIN patients AS p ON h.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Q10 : table visits
SELECT SUM(nb - 1) AS lignes_en_trop
FROM (
    SELECT COUNT(*) AS nb
    FROM visits
    GROUP BY patient_id, visit_date, visit_type
    HAVING COUNT(*) > 1
);

-- Orphelines : le test porte sur p, la table de droite du LEFT JOIN
SELECT COUNT(*) AS nb
FROM visits AS v
LEFT JOIN patients AS p ON v.patient_id = p.patient_id
WHERE p.patient_id IS NULL;


-- Q11 : récapitulatif des 9 anomalies
SELECT 1 AS no, 'treatments' AS table_name, 'end_date manquante' AS anomalie, COUNT(*) AS nb_lignes
FROM treatments WHERE end_date IS NULL
UNION ALL
SELECT 2, 'treatments', 'doublons exacts (lignes en trop)', SUM(nb - 1)
FROM (SELECT COUNT(*) AS nb FROM treatments
      GROUP BY patient_id, atc_code, treatment, start_date, end_date HAVING COUNT(*) > 1)
UNION ALL
SELECT 3, 'visits', 'doublons exacts (lignes en trop)', SUM(nb - 1)
FROM (SELECT COUNT(*) AS nb FROM visits
      GROUP BY patient_id, visit_date, visit_type HAVING COUNT(*) > 1)
UNION ALL
SELECT 4, 'diagnoses', 'code CIM-10 mal formaté', COUNT(*)
FROM diagnoses WHERE diagnosis_code NOT GLOB '[A-Z][0-9][0-9].[0-9]'
UNION ALL
SELECT 5, 'treatments', 'end_date avant start_date', COUNT(*)
FROM treatments WHERE end_date < start_date
UNION ALL
SELECT 6, 'hospitalizations', 'discharge_date avant admission_date', COUNT(*)
FROM hospitalizations WHERE discharge_date < admission_date
UNION ALL
SELECT 7, 'patients', 'naissance après la fin de la période', COUNT(*)
FROM patients WHERE birth_date > '2025-12-31'
UNION ALL
SELECT 8, 'patients', 'codage du sexe hétérogène', COUNT(*)
FROM patients WHERE sex NOT IN ('F', 'M')
UNION ALL
SELECT 9, 'visits', 'patient inexistant', COUNT(*)
FROM visits AS v LEFT JOIN patients AS p ON v.patient_id = p.patient_id
WHERE p.patient_id IS NULL;


-- Q12 : vues propres
DROP VIEW IF EXISTS v_visits_clean;
DROP VIEW IF EXISTS v_hospitalizations_clean;
DROP VIEW IF EXISTS v_treatments_clean;
DROP VIEW IF EXISTS v_diagnoses_clean;
DROP VIEW IF EXISTS v_patients_clean;

-- Sexe ramené à F / M, naissances après 2025-12-31 exclues
CREATE VIEW v_patients_clean AS
SELECT
    patient_id,
    birth_date,
    CASE
        WHEN LOWER(TRIM(sex)) IN ('f', 'féminin', 'femme')  THEN 'F'
        WHEN LOWER(TRIM(sex)) IN ('m', 'masculin', 'homme') THEN 'M'
    END AS sex
FROM patients
WHERE birth_date <= '2025-12-31';

-- Code normalisé (sans espaces ni point, majuscules, puis point remis après le 3e caractère)
-- Les patients exclus ci-dessus emportent leurs diagnostics, dont ceux datés avant la naissance
CREATE VIEW v_diagnoses_clean AS
SELECT
    diagnosis_id,
    patient_id,
    diagnosis_date,
    SUBSTR(UPPER(REPLACE(REPLACE(TRIM(diagnosis_code), ' ', ''), '.', '')), 1, 3)
        || '.' ||
    SUBSTR(UPPER(REPLACE(REPLACE(TRIM(diagnosis_code), ' ', ''), '.', '')), 4) AS diagnosis_code
FROM diagnoses
WHERE patient_id IN (SELECT patient_id FROM v_patients_clean);

-- Doublons : je garde le plus petit treatment_id du groupe
-- Les end_date NULL sont conservées, la durée sera traitée au niveau 5
CREATE VIEW v_treatments_clean AS
SELECT *
FROM treatments
WHERE treatment_id IN (
        SELECT MIN(treatment_id)
        FROM treatments
        GROUP BY patient_id, atc_code, treatment, start_date, end_date
    )
  AND (end_date IS NULL OR end_date >= start_date)
  AND patient_id IN (SELECT patient_id FROM v_patients_clean);

CREATE VIEW v_hospitalizations_clean AS
SELECT *
FROM hospitalizations
WHERE (discharge_date IS NULL OR discharge_date >= admission_date)
  AND patient_id IN (SELECT patient_id FROM v_patients_clean);

-- Doublons et consultations de patients inexistants exclus
CREATE VIEW v_visits_clean AS
SELECT *
FROM visits
WHERE visit_id IN (
        SELECT MIN(visit_id)
        FROM visits
        GROUP BY patient_id, visit_date, visit_type
    )
  AND patient_id IN (SELECT patient_id FROM v_patients_clean);

-- Contrôle des vues
SELECT 'v_patients_clean' AS vue, COUNT(*) AS nb FROM v_patients_clean
UNION ALL SELECT 'v_diagnoses_clean', COUNT(*) FROM v_diagnoses_clean
UNION ALL SELECT 'v_treatments_clean', COUNT(*) FROM v_treatments_clean
UNION ALL SELECT 'v_hospitalizations_clean', COUNT(*) FROM v_hospitalizations_clean
UNION ALL SELECT 'v_visits_clean', COUNT(*) FROM v_visits_clean;
