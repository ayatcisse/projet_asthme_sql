-- Projet : cohorte pédiatrique d'asthme (données synthétiques)
-- Schéma inspiré de la logique des bases médico-administratives (type SNDS),

DROP TABLE IF EXISTS visits;
DROP TABLE IF EXISTS hospitalizations;
DROP TABLE IF EXISTS treatments;
DROP TABLE IF EXISTS diagnoses;
DROP TABLE IF EXISTS patients;

CREATE TABLE patients (
    patient_id   INTEGER PRIMARY KEY,
    birth_date   TEXT NOT NULL,          -- format ISO AAAA-MM-JJ
    sex          TEXT                    -- 'F' / 'M' attendus
);

CREATE TABLE diagnoses (
    diagnosis_id    INTEGER PRIMARY KEY,
    patient_id      INTEGER NOT NULL,
    diagnosis_date  TEXT NOT NULL,
    diagnosis_code  TEXT NOT NULL        -- CIM-10, ex. J45.9
);

CREATE TABLE treatments (
    treatment_id  INTEGER PRIMARY KEY,
    patient_id    INTEGER NOT NULL,
    atc_code      TEXT NOT NULL,         -- classification ATC, ex. R03BA02
    treatment     TEXT NOT NULL,         -- nom de la molécule
    start_date    TEXT NOT NULL,
    end_date      TEXT
);

CREATE TABLE hospitalizations (
    hospitalization_id  INTEGER PRIMARY KEY,
    patient_id          INTEGER NOT NULL,
    admission_date      TEXT NOT NULL,
    discharge_date      TEXT,
    reason              TEXT NOT NULL
);

CREATE TABLE visits (
    visit_id    INTEGER PRIMARY KEY,
    patient_id  INTEGER NOT NULL,
    visit_date  TEXT NOT NULL,
    visit_type  TEXT NOT NULL            -- généraliste, pédiatre, pneumologue, urgences
);

CREATE INDEX idx_diag_patient  ON diagnoses(patient_id);
CREATE INDEX idx_treat_patient ON treatments(patient_id);
CREATE INDEX idx_hosp_patient  ON hospitalizations(patient_id);
CREATE INDEX idx_visit_patient ON visits(patient_id);
