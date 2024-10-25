--Procedure_order_1st_query
-- Create a temporary table for year difference calculation
CREATE TEMPORARY TABLE IF NOT EXISTS mimiciv.temp_patient_year_diff AS
SELECT 
    subject_id,
    anchor_year - ((SUBSTRING_INDEX(anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(anchor_year_group, ' - ', 1)) / 2) AS year_diff
FROM 
    mimiciv.patients;

-- Create an index on the temporary table
CREATE INDEX idx_temp_patient_year_diff ON mimiciv.temp_patient_year_diff (subject_id);

-- Create a temporary table for diagnoses
CREATE TEMPORARY TABLE IF NOT EXISTS mimiciv.temp_diagnoses AS
    SELECT 
        hadm_id, 
        GROUP_CONCAT(CONCAT('ICD', icd_version, ':', icd_code) SEPARATOR '; ') AS diagnosis_codes
    FROM 
        mimiciv.diagnoses_icd
    GROUP BY 
        hadm_id;
        
CREATE INDEX idx_temp_diagnoses ON mimiciv.temp_diagnoses (hadm_id);

-- Main query
INSERT INTO openemr.procedure_order (
    uuid,
    procedure_order_id,
    patient_id, 
    encounter_id, 
    provider_id, 
    date_ordered, 
    date_collected, 
    order_status, 
    order_priority,
    order_diagnosis,
    procedure_order_type
)
SELECT    
    UNHEX(UUID()) as `uuid`,
    l.labevent_id AS procedure_order_id,
    pyd.subject_id as patient_id,
    adm.hadm_id as encounter_id,
    1 AS provider_id,
    STR_TO_DATE(
        CONCAT(
            YEAR(l.charttime) - pyd.year_diff,
            '-',
            LPAD(MONTH(l.charttime), 2, '0'),
            '-',
            LPAD(
                CASE 
                    WHEN MONTH(l.charttime) = 2 AND DAY(l.charttime) = 29 THEN 28
                    ELSE DAY(l.charttime)
                END, 
                2, '0'
            ),
            ' ',
            DATE_FORMAT(l.charttime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date_ordered,
    STR_TO_DATE(
        CONCAT(
            YEAR(l.storetime) - pyd.year_diff,
            '-',
            LPAD(MONTH(l.storetime), 2, '0'),
            '-',
            LPAD(
                CASE 
                    WHEN MONTH(l.storetime) = 2 AND DAY(l.storetime) = 29 THEN 28
                    ELSE DAY(l.storetime)
                END, 
                2, '0'
            ),
            ' ',
            DATE_FORMAT(l.storetime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date_collected,
    'complete' as order_status,
    'normal' as order_priority,
    d.diagnosis_codes AS order_diagnosis,
    'laboratory_test' AS procedure_order_type
FROM 
    mimiciv.temp_patient_year_diff pyd
JOIN 
    mimiciv.admissions adm ON pyd.subject_id = adm.subject_id
JOIN 
    mimiciv.labevents l ON adm.hadm_id = l.hadm_id
LEFT JOIN
    mimiciv.temp_diagnoses d ON adm.hadm_id = d.hadm_id;

-- Drop the temporary table after use
DROP TEMPORARY TABLE IF EXISTS mimiciv.temp_patient_year_diff;
DROP TEMPORARY TABLE IF EXISTS mimiciv.temp_diagnoses;

-- DROP TEMPORARY TABLE IF EXISTS mimiciv.temp_procedure_order;


CREATE INDEX idx_temp_patient_year_diff_1 ON mimiciv.temp_procedure_order (subject_id);
CREATE INDEX idx_temp_diagnoses_1 ON mimiciv.temp_procedure_order (hadm_id);
INSERT INTO openemr.procedure_order (
    uuid,
    procedure_order_id,
    patient_id, 
    encounter_id, 
    provider_id, 
    date_ordered, 
    date_collected, 
    order_status, 
    order_priority,
    order_diagnosis,
    procedure_order_type
)
select 
    uuid,
    procedure_order_id,
    patient_id, 
    encounter_id, 
    provider_id, 
    date_ordered, 
    date_collected, 
    order_status, 
    order_priority,
    order_diagnosis,
    procedure_order_type
 From mimiciv.temp_procedure_order
 LIMIT 10000000;

--Procedure_order_2nd_query
-- Create a temporary table for year difference calculation
CREATE TEMPORARY TABLE IF NOT EXISTS mimiciv.temp_patient_year_diff AS
SELECT 
    subject_id,
    anchor_year - ((SUBSTRING_INDEX(anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(anchor_year_group, ' - ', 1)) / 2) AS year_diff
FROM 
    mimiciv.patients;

-- Create an index on the temporary table
CREATE INDEX idx_temp_patient_year_diff ON mimiciv.temp_patient_year_diff (subject_id);

-- Create a temporary table for diagnoses
CREATE TEMPORARY TABLE IF NOT EXISTS mimiciv.temp_diagnoses AS
    SELECT 
        hadm_id, 
        GROUP_CONCAT(CONCAT('ICD', icd_version, ':', icd_code) SEPARATOR '; ') AS diagnosis_codes
    FROM 
        mimiciv.diagnoses_icd
    GROUP BY 
        hadm_id;
        
CREATE INDEX idx_temp_diagnoses ON mimiciv.temp_diagnoses (hadm_id);

-- for loading procedures
CREATE temporary table if not exists mimiciv.temp_procedures_icd as
select 
subject_id,
hadm_id,
chartdate,
icd_code
from
mimiciv.procedures_icd; 

INSERT INTO openemr.procedure_order(
    uuid,
    patient_id, 
    encounter_id, 
    provider_id, 
    date_ordered, 
    date_collected, 
    order_status, 
    order_priority,
    order_diagnosis,
    procedure_order_type
)
SELECT    
    UNHEX(UUID()) as `uuid`,
    pi.subject_id as patient_id,
    pi.hadm_id as encounter_id,
    1 AS provider_id,
    DATE(STR_TO_DATE(
        CONCAT(
            YEAR(pi.chartdate) - pyd.year_diff,
            '-',
            LPAD(MONTH(pi.chartdate), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(pi.chartdate) = 2 AND DAY(pi.chartdate) = 29 
                     THEN 28
                     ELSE DAY(pi.chartdate)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(pi.chartdate, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    )) AS date_ordered,
    DATE(STR_TO_DATE(
        CONCAT(
            YEAR(pi.chartdate) - pyd.year_diff,
            '-',
            LPAD(MONTH(pi.chartdate), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(pi.chartdate) = 2 AND DAY(pi.chartdate) = 29 
                     THEN 28
                     ELSE DAY(pi.chartdate)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(pi.chartdate, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    )) AS date_collected,
    'complete' as order_status,
    'normal' as order_priority,
     d.diagnosis_codes AS order_diagnosis,
     'procedure' AS procedure_order_type
FROM 
    mimiciv.temp_procedures_icd pi
JOIN 
    mimiciv.admissions adm ON pi.hadm_id = adm.hadm_id 
JOIN 
    mimiciv.temp_patient_year_diff pyd ON adm.subject_id = pyd.subject_id 
LEFT JOIN
    mimiciv.temp_diagnoses d ON adm.hadm_id = d.hadm_id;
;
  
