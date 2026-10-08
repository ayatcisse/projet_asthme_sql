-- Niveau 0 : exploration des tables

-- Nombre de lignes par table
SELECT COUNT(*) FROM patients;
SELECT COUNT(*) FROM diagnoses;
SELECT COUNT(*) FROM treatments;
SELECT COUNT(*) FROM hospitalizations;
SELECT COUNT(*) FROM visits;

-- Aperçu de 10 lignes par table
SELECT * FROM patients LIMIT 10;
SELECT * FROM diagnoses LIMIT 10;
SELECT * FROM treatments LIMIT 10;
SELECT * FROM hospitalizations LIMIT 10;
SELECT * FROM visits LIMIT 10;

-- Codes de diagnostic distincts contenant 45 (asthme : J45)
SELECT DISTINCT diagnosis_code
FROM diagnoses
WHERE diagnosis_code LIKE '%45%';

-- Période couverte par les diagnostics
SELECT MIN(diagnosis_date), MAX(diagnosis_date)
FROM diagnoses;