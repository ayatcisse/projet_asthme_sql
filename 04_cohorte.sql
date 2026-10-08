-- Niveau 4 : cohorte pédiatrique d'asthme
-- Définition : enfant de moins de 18 ans à la date de son premier diagnostic J45
 
-- Date du premier diagnostic d'asthme par patient
WITH first_dx AS(
	SELECT MIN(diagnosis_date) AS first_dx_date, patient_id
	FROM v_diagnoses_clean
	WHERE diagnosis_code LIKE 'J45%'
	GROUP BY patient_id
)
SELECT * FROM first_dx;

-- Effectif de la cohorte (moins de 18 ans au premier diagnostic)
WITH first_dx AS (
    SELECT MIN(diagnosis_date) AS first_dx_date, patient_id
    FROM v_diagnoses_clean
    WHERE diagnosis_code LIKE 'J45%'
    GROUP BY patient_id
)
SELECT COUNT(*) AS nb_patients
FROM first_dx
INNER JOIN v_patients_clean AS p ON first_dx.patient_id = p.patient_id
WHERE (julianday(first_dx.first_dx_date) - julianday(p.birth_date)) / 365.25 < 18;

-- -- Cohorte avec tranche d'âge au premier diagnostic (343 patients)
WITH first_dx AS (
    SELECT MIN(diagnosis_date) AS first_dx_date, patient_id
    FROM v_diagnoses_clean
    WHERE diagnosis_code LIKE 'J45%'
    GROUP BY patient_id
)
SELECT first_dx.patient_id,
       CASE
           WHEN (julianday(first_dx_date) - julianday(birth_date)) / 365.25 < 6  THEN '0-5'
           WHEN (julianday(first_dx_date) - julianday(birth_date)) / 365.25 < 12 THEN '6-11'
           ELSE '12-17'
       END AS age_group
FROM first_dx
INNER JOIN v_patients_clean AS p ON first_dx.patient_id = p.patient_id
WHERE (julianday(first_dx_date) - julianday(birth_date)) / 365.25 < 18;
	
