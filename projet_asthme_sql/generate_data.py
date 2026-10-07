"""Génère un jeu de données synthétique pour le projet cohorte pédiatrique d'asthme.

Usage :
    python generate_data.py

Produit :
    asthme.db        base SQLite prête à l'emploi
    data/*.csv       les mêmes tables en CSV (pour PostgreSQL, pandas, etc.)

Toutes les données sont fictives. Le générateur est déterministe (graine fixe),
donc tout le monde obtient exactement les mêmes données.
"""

import csv
import random
import sqlite3
from datetime import date, timedelta
from pathlib import Path

SEED = 42
N_PATIENTS = 2500
REF_DATE = date(2025, 12, 31)        # date de fin de l'extraction
WINDOW_START = date(2019, 1, 1)
DX_LAST = date(2025, 6, 30)          # dernier diagnostic d'asthme possible

HERE = Path(__file__).parent
rng = random.Random(SEED)

# Codes ATC réels de la classe R03 (médicaments des syndromes obstructifs des voies aériennes)
SABA = [("R03AC02", "salbutamol")]
ICS = [("R03BA01", "béclométasone"), ("R03BA02", "budésonide"), ("R03BA05", "fluticasone")]
ICS_LABA = [("R03AK06", "salmétérol + fluticasone"), ("R03AK07", "formotérol + budésonide")]
LTRA = [("R03DC03", "montélukast")]

ASTHMA_CODES = [("J45.0", 0.25), ("J45.1", 0.20), ("J45.8", 0.10), ("J45.9", 0.45)]
OTHER_CODES = ["J20.9", "J06.9", "L20.9", "J30.4", "B34.9", "J21.9"]
OTHER_HOSP_REASONS = ["Appendicectomie", "Pneumonie", "Fracture", "Gastro-entérite", "Bronchiolite"]
VISIT_TYPES_ASTHMA = ["généraliste", "pédiatre", "pneumologue", "urgences"]
VISIT_TYPES_OTHER = ["généraliste", "pédiatre", "urgences"]


def rand_date(lo, hi):
    if lo > hi:
        lo, hi = hi, lo
    return lo + timedelta(days=rng.randint(0, (hi - lo).days))


def add_years(d, years):
    try:
        return d.replace(year=d.year + years)
    except ValueError:               # 29 février
        return d.replace(year=d.year + years, day=28)


def weighted(pairs):
    codes, weights = zip(*pairs)
    return rng.choices(codes, weights=weights)[0]


patients, diagnoses, treatments, hospitalizations, visits = [], [], [], [], []


def add_treatment(pid, atc, name, start, duration_days):
    end = min(start + timedelta(days=duration_days), REF_DATE)
    treatments.append([pid, atc, name, start.isoformat(), end.isoformat()])


def add_hosp(pid, admission, reason):
    stay = rng.randint(1, 7)
    discharge = min(admission + timedelta(days=stay), REF_DATE)
    hospitalizations.append([pid, admission.isoformat(), discharge.isoformat(), reason])


for pid in range(1, N_PATIENTS + 1):
    sex = rng.choice(["F", "M"])
    pediatric = rng.random() < 0.70
    if pediatric:
        birth = rand_date(date(2008, 1, 1), date(2025, 6, 30))
    else:
        birth = rand_date(date(1950, 1, 1), date(2007, 12, 31))
    patients.append([pid, birth.isoformat(), sex])

    # --- statut asthme -------------------------------------------------------
    p_asthma = 0.22 if pediatric else 0.06
    lo = max(WINDOW_START, add_years(birth, 2))
    asthma = rng.random() < p_asthma and lo <= DX_LAST
    severity = rng.choices(["leger", "modere", "severe"], weights=[55, 33, 12])[0]

    if asthma:
        dx_date = rand_date(lo, DX_LAST)
        diagnoses.append([pid, dx_date.isoformat(), weighted(ASTHMA_CODES)])
        for _ in range(rng.choices([0, 1, 2, 3], weights=[35, 30, 20, 15])[0]):
            later = rand_date(dx_date, REF_DATE)
            diagnoses.append([pid, later.isoformat(), weighted(ASTHMA_CODES)])
        if rng.random() < 0.25:                      # comorbidité allergique
            diagnoses.append([pid, rand_date(dx_date, REF_DATE).isoformat(), "J30.4"])

        # --- traitements selon la sévérité (variable cachée, non stockée) ----
        first_start = dx_date + timedelta(days=rng.randint(0, 30))
        if severity == "leger":
            group = "saba"
            atc, name = SABA[0]
            add_treatment(pid, atc, name, first_start, rng.randint(14, 120))
            if rng.random() < 0.40:
                group = "ics"
                atc, name = rng.choice(ICS)
                add_treatment(pid, atc, name, first_start + timedelta(days=rng.randint(0, 20)),
                              rng.randint(90, 540))
        elif severity == "modere":
            group = "ics"
            add_treatment(pid, *SABA[0], first_start, rng.randint(30, 200))
            atc, name = rng.choice(ICS)
            add_treatment(pid, atc, name, first_start, rng.randint(120, 600))
            if rng.random() < 0.40:
                add_treatment(pid, *LTRA[0], first_start + timedelta(days=rng.randint(10, 90)),
                              rng.randint(90, 400))
        else:
            group = "ics_laba"
            add_treatment(pid, *SABA[0], first_start, rng.randint(30, 200))
            atc, name = rng.choice(ICS_LABA)
            add_treatment(pid, atc, name, first_start, rng.randint(180, 720))

        # --- hospitalisations : le groupe de traitement influence le risque ---
        if rng.random() < 0.10:                       # hospitalisation avant traitement
            before = dx_date - timedelta(days=rng.randint(1, 180))
            if before >= WINDOW_START:
                add_hosp(pid, before, "Exacerbation d'asthme")
        p_after = {"saba": 0.28, "ics": 0.12, "ics_laba": 0.16}[group]
        for _ in range(2):                            # jusqu'à 2 hospitalisations après
            if rng.random() < p_after:
                after = rand_date(first_start + timedelta(days=15), REF_DATE)
                if after > first_start:
                    add_hosp(pid, after, "Exacerbation d'asthme")

        # --- consultations ---------------------------------------------------
        for _ in range(rng.randint(3, 12)):
            visits.append([pid, rand_date(max(WINDOW_START, dx_date - timedelta(days=60)), REF_DATE).isoformat(),
                           rng.choice(VISIT_TYPES_ASTHMA)])
    else:
        # patients sans asthme : bruit réaliste
        if rng.random() < 0.55:
            diagnoses.append([pid, rand_date(max(WINDOW_START, birth), REF_DATE).isoformat(),
                              rng.choice(OTHER_CODES)])
        # piège : quelques enfants non asthmatiques reçoivent une fois du salbutamol
        if pediatric and rng.random() < 0.08:
            start = rand_date(max(WINDOW_START, birth), REF_DATE - timedelta(days=30))
            add_treatment(pid, *SABA[0], start, rng.randint(7, 21))
        for _ in range(rng.randint(0, 6)):
            visits.append([pid, rand_date(max(WINDOW_START, birth), REF_DATE).isoformat(),
                           rng.choice(VISIT_TYPES_OTHER)])

    # hospitalisations hors asthme (tous profils)
    if rng.random() < 0.06:
        add_hosp(pid, rand_date(max(WINDOW_START, birth), REF_DATE - timedelta(days=10)),
                 rng.choice(OTHER_HOSP_REASONS))

# ---------------------------------------------------------------------------
# Injection d'anomalies de qualité de données (voir anomalies_cles.md)
# ---------------------------------------------------------------------------
n_pat = len(patients)

# on retire d'abord les doublons accidentels dus au tirage aléatoire,
# pour que les seuls doublons restants soient ceux injectés volontairement
treatments = [list(t) for t in dict.fromkeys(tuple(t) for t in treatments)]
visits = [list(v) for v in dict.fromkeys(tuple(v) for v in visits)]

# 1. dates de fin de traitement manquantes
for row in rng.sample(treatments, 40):
    row[4] = None

# 2. doublons exacts
for row in rng.sample(treatments, 15):
    treatments.append(list(row))
for row in rng.sample(visits, 12):
    visits.append(list(row))

# 3. codes diagnostics mal formatés
for row in rng.sample([d for d in diagnoses if d[2].startswith("J45")], 14):
    row[2] = rng.choice([row[2].lower(), row[2].replace(".", ""), row[2] + " ", row[2].replace(".", " ")])

# 4. fin de traitement antérieure au début
for row in rng.sample([t for t in treatments if t[4] is not None], 8):
    row[3], row[4] = row[4], row[3]

# 5. sortie d'hospitalisation antérieure à l'admission
for row in rng.sample(hospitalizations, 6):
    row[1], row[2] = row[2], row[1]

# 6. dates de naissance incohérentes (dans le futur)
for row in rng.sample(patients, 5):
    row[1] = date(2026, rng.randint(1, 12), rng.randint(1, 28)).isoformat()

# 7. codage du sexe hétérogène
for row in rng.sample(patients, 30):
    row[2] = {"F": rng.choice(["f", "Féminin", "femme"]), "M": rng.choice(["m", "masculin", "Homme"])}[row[2]] \
        if row[2] in ("F", "M") else row[2]

# 8. lignes orphelines (patient inexistant)
for _ in range(6):
    visits.append([n_pat + rng.randint(1, 50), rand_date(WINDOW_START, REF_DATE).isoformat(), "généraliste"])

# ---------------------------------------------------------------------------
# Écriture : SQLite + CSV
# ---------------------------------------------------------------------------
db_path = HERE / "asthme.db"
if db_path.exists():
    db_path.unlink()
con = sqlite3.connect(db_path)
con.executescript((HERE / "schema.sql").read_text(encoding="utf-8"))

# mélange pour que les doublons ne soient pas côte à côte
for table_rows in (treatments, visits):
    rng.shuffle(table_rows)

con.executemany("INSERT INTO patients (patient_id, birth_date, sex) VALUES (?,?,?)", patients)
con.executemany("INSERT INTO diagnoses (patient_id, diagnosis_date, diagnosis_code) VALUES (?,?,?)", diagnoses)
con.executemany("INSERT INTO treatments (patient_id, atc_code, treatment, start_date, end_date) VALUES (?,?,?,?,?)",
                treatments)
con.executemany("INSERT INTO hospitalizations (patient_id, admission_date, discharge_date, reason) VALUES (?,?,?,?)",
                hospitalizations)
con.executemany("INSERT INTO visits (patient_id, visit_date, visit_type) VALUES (?,?,?)", visits)
con.commit()

(HERE / "data").mkdir(exist_ok=True)
for table in ("patients", "diagnoses", "treatments", "hospitalizations", "visits"):
    cur = con.execute(f"SELECT * FROM {table}")
    cols = [c[0] for c in cur.description]
    with open(HERE / "data" / f"{table}.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(cols)
        w.writerows(cur.fetchall())
    n = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    print(f"{table:18s} {n:6d} lignes")
con.close()
print(f"\nBase créée : {db_path}")
