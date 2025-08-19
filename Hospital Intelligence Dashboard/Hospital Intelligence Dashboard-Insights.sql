------------------------------------------------------------------------------------------------------------------------------------------------
-- Q1
SELECT EXTRACT(YEAR FROM start) AS year, Count(*) AS encounters
FROM encounters
GROUP BY EXTRACT(YEAR FROM start);
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q2
WITH count_per_year AS (
SELECT EXTRACT(YEAR FROM start) AS year, Count(*) AS total_encounters
FROM encounters
GROUP BY EXTRACT(YEAR FROM start))

SELECT c.year AS year, e.encounterclass, Count(*) AS encounters, ROUND(COUNT(*) * 100.0 / c.total_encounters, 2) AS percentage
FROM encounters AS e 
JOIN count_per_year AS c 
ON EXTRACT(YEAR FROM e.start) = c.year
GROUP BY c.year, c.total_encounters, e.encounterclass
ORDER BY c.year
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q3
WITH hours_per_encounter AS (
SELECT EXTRACT(YEAR FROM start) AS year, EXTRACT(EPOCH FROM (stop::timestamp - start::timestamp)) / 3600 AS hour_difference
FROM encounters),

count_per_year AS (
SELECT EXTRACT(YEAR FROM start) AS year, COUNT(*) AS total_encounters
FROM encounters
GROUP BY EXTRACT(YEAR FROM start)),

total_stay AS (
SELECT *,
 CASE
  WHEN (hpe.hour_difference >= 24) THEN 'Long Stay'
  ELSE 'Short Stay'
 END AS stay_type
FROM hours_per_encounter AS hpe)

SELECT ts.year, ts.stay_type, COUNT(*), ROUND(COUNT(*) * 100.0 / c.total_encounters, 2) AS percentage
FROM total_stay AS ts
JOIN count_per_year AS c
ON ts.year = c.year
GROUP BY ts.year, ts.stay_type, c.total_encounters
ORDER BY ts.year
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q4
WITH total_encounters AS (
SELECT COUNT(*) AS total_encounters
FROM encounters),

null_payers AS (
SELECT COUNT(*) AS total_null_encounters
FROM encounters
WHERE payer = '' OR payer IS NULL
)

SELECT te.total_encounters, np.total_null_encounters, ROUND(np.total_null_encounters * 100.0 / te.total_encounters, 2) AS percentage
from total_encounters AS te, null_payers AS np
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q5
SELECT code, AVG(base_cost) AS avg_base_cost, count(*) AS total_count
FROM procedures
GROUP BY code
ORDER BY total_count DESC
LIMIT 10
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q6
SELECT code, AVG(base_cost) AS avg_base_cost, count(*) AS total_count
FROM procedures
GROUP BY code
ORDER BY avg_base_cost DESC
LIMIT 10
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q7
SELECT p.id, SUM(e.total_claim_cost) AS total_cost, 
Count(*) AS total_claims, ROUND(AVG(e.total_claim_cost), 2) AS avg_claim_cost
FROM payers AS p
JOIN encounters AS e
ON p.id = e.payer
GROUP BY p.id
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q8
SELECT EXTRACT(YEAR from start) AS year, EXTRACT(QUARTER FROM start) AS quarter, count(distinct(patient)) AS distinct_patients
FROM encounters
GROUP BY EXTRACT(YEAR from start), EXTRACT(QUARTER FROM start)
-----------------------------------------------------------------------------------------------------------------------------------------------
-- Q9
WITH previous_encounters AS (
  SELECT 
    patient,
    start AS cur_start,
    stop AS cur_stop,
    LAG(stop) OVER (PARTITION BY patient ORDER BY start) AS prev_stop
  FROM encounters
)

SELECT COUNT(DISTINCT patient) AS num_of_readmitted_patients
FROM previous_encounters
WHERE prev_stop IS NOT NULL
AND DATE_PART('day', cur_start - prev_stop) <= 30
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q10
WITH previous_encounters AS (
  SELECT 
    patient,
    start AS cur_start,
    stop AS cur_stop,
    LAG(stop) OVER (PARTITION BY patient ORDER BY start) AS prev_stop
  FROM encounters
)

SELECT patient, count(*)
FROM previous_encounters
WHERE prev_stop IS NOT NULL
AND DATE_PART('day', cur_start - prev_stop) <= 30
GROUP BY patient
ORDER BY count DESC
LIMIT 5
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q11
SELECT patient, MIN(start) AS first_admitted, MAX(start) AS latest_admitted, (MAX(start)::date - MIN(start)::date) AS days_between 
FROM encounters
GROUP BY patient 
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q12
SELECT 
  patient,
  SUM (CASE WHEN encounterclass = 'ambulatory' THEN 1 ELSE 0 END) AS ambulatory,
  SUM (CASE  WHEN encounterclass = 'wellness' THEN 1  ELSE 0  END) AS wellness,
  SUM (CASE WHEN encounterclass = 'inpatient' THEN 1  ELSE 0 END) AS inpatient,
  SUM (CASE WHEN encounterclass = 'outpatient' THEN 1 ELSE 0 END) AS outpatient,
  SUM (CASE WHEN encounterclass = 'emergency' THEN 1 ELSE 0 END) AS emergency,
  SUM (CASE WHEN encounterclass = 'urgentcare' THEN 1 ELSE 0 END) AS urgentcare
FROM encounters
GROUP BY patient;
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q13
WITH patient_latest AS (
  SELECT patient, MAX(start) AS latest_start
  FROM encounters
  GROUP BY patient
),

encounters_with_row AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY patient ORDER BY start DESC, id DESC) AS rn
  FROM encounters
)

SELECT e.*
FROM patient_latest AS pl
JOIN encounters_with_row AS e
ON pl.patient = e.patient
WHERE e.rn = 1;
------------------------------------------------------------------------------------------------------------------------------------------------
-- Q14
WITH patient_age_bracket AS (
  SELECT id AS patient, DATE_PART('year', AGE(CURRENT_DATE, birthdate)) AS age,
  CASE
      WHEN date_part('year',age(birthdate)) <= 20 THEN '0-20'
      WHEN date_part('year',age(birthdate)) <= 40 THEN '21-40'
      WHEN date_part('year',age(birthdate)) <= 60 THEN '41-60'
      WHEN date_part('year',age(birthdate)) <= 80 THEN '61-80'
      WHEN date_part('year',age(birthdate)) <= 100 THEN '81-100'
      ELSE '100+'
    END AS age_bracket
  FROM patients
),

count_by_age_bracket AS (
SELECT pab.age_bracket, e.reasondescription, count(*) AS diagnosis_count 
FROM patient_age_bracket AS pab
JOIN encounters AS e 
ON pab.patient=e.patient
WHERE e.reasondescription IS NOT NULL
GROUP BY pab.age_bracket, e.reasondescription
),

max_counts AS (
  SELECT age_bracket, MAX(diagnosis_count) AS max_count
  FROM count_by_age_bracket
  GROUP BY age_bracket
)

SELECT c.age_bracket, c.reasondescription, c.diagnosis_count
FROM count_by_age_bracket AS c
JOIN max_counts AS m
ON c.age_bracket = m.age_bracket AND c.diagnosis_count = m.max_count
------------------------------------------------------------------------------------------------------------------------------------------------
