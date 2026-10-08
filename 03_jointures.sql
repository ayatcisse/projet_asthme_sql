-- Niveau 3 : jointures, sur les vues propres
 
-- Patients asthmatiques et leurs traitements
SELECT DISTINCT d.patient_id, t.treatment
FROM v_diagnoses_clean AS d
INNER JOIN v_treatments_clean AS t ON d.patient_id = t.patient_id
WHERE d.diagnosis_code LIKE 'J45%';
 
-- Patients asthmatiques sans aucun traitement
SELECT DISTINCT d.patient_id
FROM v_diagnoses_clean AS d
LEFT JOIN v_treatments_clean AS t ON d.patient_id = t.patient_id
WHERE d.diagnosis_code LIKE 'J45%'
  AND t.treatment_id IS NULL;
 