-- for loading lab items

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
    p.subject_id as patient_id,
    adm.hadm_id as encounter_id,
    1 AS provider_id,
    STR_TO_DATE(
        CONCAT(
            YEAR(l.charttime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(l.charttime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(l.charttime) = 2 AND DAY(l.charttime) = 29 
                     THEN 28
                     ELSE DAY(l.charttime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(l.charttime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date_ordered,
    STR_TO_DATE(
        CONCAT(
            YEAR(l.storetime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(l.storetime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(l.storetime) = 2 AND DAY(l.storetime) = 29
                     THEN 28
                     ELSE DAY(l.storetime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(l.storetime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date_collected,
    'complete' as order_status,
    'normal' as order_priority,
    (SELECT GROUP_CONCAT(CONCAT('ICD', di.icd_version, ':', di.icd_code) SEPARATOR '; ')
     FROM mimiciv.diagnoses_icd di
     WHERE di.hadm_id = adm.hadm_id
    ) AS order_diagnosis,
    'laboratory_test' AS procedure_order_type

FROM 
    mimiciv.patients p
JOIN 
    mimiciv.admissions adm ON p.subject_id = adm.subject_id
JOIN 
    mimiciv.labevents l ON adm.hadm_id = l.hadm_id
;


-- for loading procedures

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
            YEAR(pi.chartdate) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
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
            YEAR(pi.chartdate) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
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
    (SELECT GROUP_CONCAT(CONCAT('ICD', di.icd_version, ':', di.icd_code) SEPARATOR '; ')
     FROM mimiciv.diagnoses_icd di WHERE di.hadm_id = adm.hadm_id) AS order_diagnosis,
     'procedure' AS procedure_order_type
FROM 
    mimiciv.procedures_icd pi
JOIN 
    mimiciv.d_icd_procedures dip ON pi.icd_code = dip.icd_code 
JOIN 
    mimiciv.admissions adm ON pi.hadm_id = adm.hadm_id 
JOIN 
    mimiciv.patients p ON adm.subject_id = p.subject_id 
;
