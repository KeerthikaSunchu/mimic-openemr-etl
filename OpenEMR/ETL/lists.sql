INSERT INTO openemr.lists (
    `uuid`,
    date,
    type,
    occurrence,
    classification,
    activity,
    user,
    subtype,
    pid, 
    external_id, 
    title, 
    diagnosis,
    verification,
    modifydate,
    reaction
)
SELECT
    UNHEX(UUID()) as `uuid`,
    STR_TO_DATE(
        CONCAT(
            YEAR(adm.admittime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(adm.admittime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(adm.admittime) = 2 AND DAY(adm.admittime) = 29 AND 
                          ((YEAR(adm.admittime) % 4 != 0) OR 
                           (YEAR(adm.admittime) % 100 = 0 AND YEAR(adm.admittime) % 400 != 0))
                     THEN 28
                     ELSE DAY(adm.admittime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(adm.admittime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date,
    'medical_problem' AS type,
    1 AS occurrence,
    0 AS classification,
    1 AS activity,
    'admin' AS user,
    'diagnosis' AS subtype,
    di.subject_id AS pid,
    di.hadm_id AS external_id,
    did.long_title AS title,
    CONCAT('ICD', di.icd_version, ':', di.icd_code) AS diagnosis,
    'confirmed' AS verification,
    STR_TO_DATE(
        CONCAT(
            YEAR(adm.admittime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(adm.admittime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(adm.admittime) = 2 AND DAY(adm.admittime) = 29 AND 
                          ((YEAR(adm.admittime) % 4 != 0) OR 
                           (YEAR(adm.admittime) % 100 = 0 AND YEAR(adm.admittime) % 400 != 0))
                     THEN 28
                     ELSE DAY(adm.admittime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(adm.admittime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS modifydate,
    'unassigned' AS reaction
FROM
    mimiciv.diagnoses_icd di
JOIN
    mimiciv.d_icd_diagnoses did ON di.icd_code = did.icd_code
JOIN
    mimiciv.admissions adm ON di.hadm_id = adm.hadm_id
JOIN
    mimiciv.patients p ON adm.subject_id = p.subject_id
;
