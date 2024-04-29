ALTER TABLE openemr.prescriptions 
MODIFY `txDate` DATE DEFAULT NULL;

SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

INSERT INTO openemr.prescriptions (
    uuid,
    provider_id,
    date_added,
    refills,
    encounter,
    drug,
    drug_id,
    patient_id,
    date_modified,
    dosage,
    quantity,
    rxnorm_drugcode,
    start_date,
    end_date,
    route, 
    usage_category_title,
    request_intent_title,
    medication,
    created_by,
    updated_by
)
SELECT
    UNHEX(UUID()) as `uuid`,
    1 AS provider_id,
    STR_TO_DATE(
        CONCAT(
            YEAR(phar.entertime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
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
    SUM(phar.fill_quantity) AS refills,
    phar.hadm_id AS encounter,
    phar.medication AS drug,
    (SELECT IFNULL(MAX(drug_id), 0) + 1 FROM openemr.drugs) AS drug_id,
    phar.subject_id AS patient_id,
    STR_TO_DATE(
        CONCAT(
            YEAR(phar.verifiedtime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(phar.verifiedtime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(phar.verifiedtime) = 2 AND DAY(phar.verifiedtime) = 29 
                     THEN 28
                     ELSE DAY(phar.verifiedtime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(phar.verifiedtime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date_modified,
    GROUP_CONCAT(DISTINCT CONCAT(presc.dose_val_rx, ' ', presc.dose_unit_rx) ORDER BY presc.dose_val_rx) AS dosage,
    ROUND(SUM(presc.form_val_disp), 2) AS quantity,
    GROUP_CONCAT(DISTINCT rxn.RXCUI ORDER BY rxn.RXCUI) AS rxnorm_drugcode,
    MIN(DATE(STR_TO_DATE(
        CONCAT(
            YEAR(phar.starttime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(phar.starttime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(phar.starttime) = 2 AND DAY(phar.starttime) = 29 
                     THEN 28
                     ELSE DAY(phar.starttime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(phar.starttime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ))) AS start_date,
    MAX(DATE(STR_TO_DATE(
        CONCAT(
            YEAR(phar.stoptime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(phar.stoptime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(phar.stoptime) = 2 AND DAY(phar.stoptime) = 29 
                     THEN 28
                     ELSE DAY(phar.stoptime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(phar.stoptime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ))) AS end_date,
    presc.route AS route,
    ' ' AS usage_category_title,
    ' ' AS request_intent_title,
    1 AS medication,
    1 AS created_by,
    1 AS updated_by
FROM
    mimiciv.pharmacy phar
JOIN
    mimiciv.prescriptions presc ON phar.subject_id = presc.subject_id AND phar.hadm_id = presc.hadm_id
JOIN
    mimiciv.admissions adm ON adm.subject_id = phar.subject_id
JOIN
    mimiciv.patients p ON adm.subject_id = p.subject_id
LEFT JOIN
    openemr.rxnorm_ndc rxn ON rxn.ATV COLLATE utf8mb4_unicode_ci = presc.ndc COLLATE utf8mb4_unicode_ci
LEFT JOIN
    openemr.drugs d ON phar.medication COLLATE utf8mb4_unicode_ci = d.name COLLATE utf8mb4_unicode_ci
GROUP BY
    phar.medication,
    CONCAT(presc.dose_val_rx, ' ', presc.dose_unit_rx),
    DATE(phar.entertime),
    rxn.RXCUI;


