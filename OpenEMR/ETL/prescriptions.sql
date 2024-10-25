-- Modify the prescriptions table column
ALTER TABLE openemr.prescriptions 
MODIFY `txDate` DATE DEFAULT NULL;

-- Set SQL mode to allow non-aggregated column selection in the presence of GROUP BY
SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- Create a temporary table for patients with year difference calculation
CREATE TABLE IF NOT EXISTS openemr.temp_patient_year_diff AS
SELECT 
    subject_id,
    anchor_year - ((SUBSTRING_INDEX(anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(anchor_year_group, ' - ', 1)) / 2) AS year_diff
FROM 
    mimiciv.patients;

CREATE INDEX idx_temp_patient_year_diff_subject_id ON openemr.temp_patient_year_diff (subject_id);

-- Create a temporary table for rxnorm_ndc with indexing
CREATE TABLE openemr.temp_rxnorm_ndc AS
SELECT 
    rxn.ATV,
    rxn.RXCUI
FROM 
    openemr.rxnorm_ndc rxn;

CREATE INDEX idx_temp_rxnorm_ndc_atv ON openemr.temp_rxnorm_ndc (ATV);

    -- namrata query
    CREATE TABLE openemr.temp_pharmacy AS
SELECT 
 phar.fill_quantity AS refills,
 phar.hadm_id AS encounter,
 phar.medication AS drug,
 phar.subject_id AS patient_id,
       STR_TO_DATE(
        CONCAT(
            YEAR(phar.entertime) - pyd.year_diff,
            '-',
            LPAD(MONTH(phar.entertime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(phar.entertime) = 2 AND DAY(phar.entertime) = 29 
                     THEN 28
                     ELSE DAY(phar.entertime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(phar.entertime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date_added,
    STR_TO_DATE(
        CONCAT(
            YEAR(phar.verifiedtime) - pyd.year_diff,
            '-',
            LPAD(MONTH(phar.verifiedtime), 2, '0'),
            '-',
            LPAD(
                CASE 
                    WHEN MONTH(phar.verifiedtime) = 2 AND DAY(phar.verifiedtime) = 29 
                    THEN 28
                    ELSE DAY(phar.verifiedtime)
                END, 
                2, '0'
            ),
            ' ',
            DATE_FORMAT(phar.verifiedtime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date_modified,
    MIN(DATE(STR_TO_DATE(
        CONCAT(
            YEAR(phar.starttime) - pyd.year_diff,
            '-',
            LPAD(MONTH(phar.starttime), 2, '0'),
            '-',
            LPAD(
                CASE 
                    WHEN MONTH(phar.starttime) = 2 AND DAY(phar.starttime) = 29 
                    THEN 28
                    ELSE DAY(phar.starttime)
                END, 
                2, '0'
            ),
            ' ',
            DATE_FORMAT(phar.starttime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ))) AS start_date,
    MAX(DATE(STR_TO_DATE(
        CONCAT(
            YEAR(phar.stoptime) - pyd.year_diff,
            '-',
            LPAD(MONTH(phar.stoptime), 2, '0'),
            '-',
            LPAD(
                CASE 
                    WHEN MONTH(phar.stoptime) = 2 AND DAY(phar.stoptime) = 29 
                    THEN 28
                    ELSE DAY(phar.stoptime)
                END, 
                2, '0'
            ),
            ' ',
            DATE_FORMAT(phar.stoptime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ))) AS end_date
FROM mimiciv.pharmacy phar
JOIN openemr.temp_patient_year_diff pyd ON phar.subject_id = pyd.subject_id 	
-- WHERE phar.hadm_id IN ('21523262','21410553')
  GROUP BY phar.poe_id, phar.medication, phar.entertime;
   
CREATE INDEX idx_temp_pharmacy_subject_id ON openemr.temp_pharmacy (subject_id);
CREATE INDEX idx_temp_pharmacy_hadm_id ON openemr.temp_pharmacy (hadm_id);
CREATE INDEX idx_temp_pharmacy_medication ON openemr.temp_pharmacy (medication);


    -- Create a temporary table for prescriptions with indexing
CREATE TABLE openemr.temp_prescriptions AS
SELECT 
    subject_id,
    hadm_id,
    dose_val_rx,
    dose_unit_rx,
    route,
    ndc
FROM 
    mimiciv.prescriptions presc;

CREATE INDEX idx_temp_prescriptions_subject_id ON openemr.temp_prescriptions (subject_id);
CREATE INDEX idx_temp_prescriptions_hadm_id ON openemr.temp_prescriptions (hadm_id);

 -- temp drugs table with id query
   DROP TABLE temp_drugs;
 
 CREATE TABLE openemr.temp_drugs AS 
  SELECT
  DISTINCT phar.medication AS drug_name
  FROM mimiciv.pharmacy phar;
  
  ALTER TABLE temp_drugs
ADD COLUMN drug_id INT AUTO_INCREMENT PRIMARY KEY;

CREATE INDEX idx_temp_drugs_id ON openemr.temp_drugs (drug_id);
  
    -- actual query namrata
 
 SELECT 
 UNHEX(UUID()) AS `uuid`,
 1 AS provider_id,
 temp_phar.date_added
 temp_phar.fill_quantity AS refills,
 temp_phar.hadm_id AS encounter,
 temp_phar.medication AS drug,
 td.drug_id AS drug_id,
 temp_phar.subject_id AS patient_id,
 temp_phar.date_modified
 SUBSTRING_INDEX(CONCAT(presc.dose_val_rx, ' ', presc.dose_unit_rx),'-', -1)  AS dosage,
 ROUND(
        CASE 
            WHEN presc.form_val_disp RLIKE '^[0-9.]+$' 
            THEN SUBSTRING_INDEX(presc.form_val_disp,'-', -1)
            ELSE 0
        END
    , 2) AS quantity,     
rxn.RXCUI AS rxnorm_drugcode,
temp_phar.start_date
temp_phar.end_date
presc.route AS route,
' ' AS usage_category_title,
' ' AS request_intent_title,
1 AS medication,
1 AS created_by,
1 AS updated_by
FROM openemr.temp_pharmacy temp_phar
JOIN openemr.temp_prescriptions presc 
	ON phar.`subject_id` = presc.subject_id
	AND phar.hadm_id = presc.hadm_id
	AND phar.poe_id = presc.poe_id
JOIN openemr.temp_drugs td
	ON td.drug_name = phar.medication
LEFT JOIN openemr.temp_rxnorm_ndc rxn 
	ON rxn.ATV COLLATE utf8mb4_unicode_ci = presc.ndc COLLATE utf8mb4_unicode_ci
WHERE phar.hadm_id IN ('21523262','21410553');

-- namrata end 
-- Main query--  
-- 
-- CREATE TABLE IF NOT EXISTS openemr.temp_prescriptions_updated AS
-- SELECT
--     UNHEX(UUID()) AS `uuid`,
--     1 AS provider_id,
--     phar.date_added,
--     fill_quantity AS refills,
--     phar.hadm_id AS encounter,
--     phar.medication AS drug,
--     (SELECT IFNULL(MAX(drug_id), 0) + 1 FROM openemr.drugs) AS drug_id,
--     phar.subject_id AS patient_id,
--     phar.date_modified,
--     presc.dosage,
--     ROUND(SUM(
--         CASE 
--             WHEN presc.form_val_disp RLIKE '^[0-9.]+$' 
--             THEN CAST(presc.form_val_disp AS DOUBLE)
--             ELSE 0
--         END
--     ), 2) AS quantity,
--     GROUP_CONCAT(DISTINCT rxn.RXCUI ORDER BY rxn.RXCUI) AS rxnorm_drugcode,
--     phar.start_date,
--     phar.end_date,
--     presc.route AS route,
--     ' ' AS usage_category_title,
--     ' ' AS request_intent_title,
--     1 AS medication,
--     1 AS created_by,
--     1 AS updated_by
-- FROM
--     openemr.temp_pharmacy phar
-- JOIN
--     openemr.temp_prescriptions presc ON phar.subject_id = presc.subject_id AND phar.hadm_id = presc.hadm_id
-- LEFT JOIN
--     openemr.temp_rxnorm_ndc rxn ON rxn.ATV COLLATE utf8mb4_unicode_ci = presc.ndc COLLATE utf8mb4_unicode_ci
-- LEFT JOIN
--     openemr.temp_drugs d ON phar.medication COLLATE utf8mb4_unicode_ci = d.name COLLATE utf8mb4_unicode_ci
-- GROUP BY
--     phar.medication,
--     CONCAT(presc.dose_val_rx, ' ', presc.dose_unit_rx),
--     DATE(phar.entertime),
--     rxn.RXCUI;

-- Clean up temporary tables
DROP TABLE IF EXISTS mimiciv.temp_patient_year_diff;
DROP TABLE IF EXISTS mimiciv.temp_pharmacy;
DROP TABLE IF EXISTS mimiciv.temp_prescriptions;
DROP TABLE IF EXISTS mimiciv.temp_rxnorm_ndc;
DROP TABLE IF EXISTS mimiciv.temp_drugs;
