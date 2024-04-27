INSERT INTO openemr.form_encounter (
    `uuid`, 
    facility,
    encounter_type_code,
    encounter_type_description,
    provider_id,
    date,
    discharge_disposition,
    date_end,
    encounter,
    pid,
    reason,
    onset_date,
    pc_catid,
    billing_facility,
    facility_id,
    referral_source
)
SELECT 
    UNHEX(UUID()) as `uuid`,
    'Your Clinic Name Here' AS facility,
    CASE 
        WHEN adm.admission_type = 'AMBULATORY OBSERVATION' THEN 'visit-after-hours'
        WHEN adm.admission_type = 'DIRECT EMER.' THEN 'new-patient'
        WHEN adm.admission_type = 'DIRECT OBSERVATION' THEN 'office-visit'
        WHEN adm.admission_type = 'ELECTIVE' THEN 'postoperative-follow-up'
        WHEN adm.admission_type = 'EU OBSERVATION' THEN 'visit-after-hours-not-night'
        WHEN adm.admission_type = 'EW EMER.' THEN 'new-patient'
        WHEN adm.admission_type = 'OBSERVATION ADMIT' THEN 'weekend-visit'
        WHEN adm.admission_type = 'SURGICAL SAME DAY ADMISSION' THEN 'established-patient-30-39'
        WHEN adm.admission_type = 'URGENT' THEN 'established-patient'
        -- Add additional mappings if necessary
        -- No ELSE clause, leaving encounter_type_description as NULL if no match
    END AS encounter_type_code,
    CASE 
        WHEN adm.admission_type = 'AMBULATORY OBSERVATION' THEN 'Visit out of hours'
        WHEN adm.admission_type = 'DIRECT EMER.' THEN 'Evaluation and management of new patient in office or outpatient facility'
        WHEN adm.admission_type = 'DIRECT OBSERVATION' THEN 'Office visit for pediatric care and assessment'
        WHEN adm.admission_type = 'ELECTIVE' THEN 'Postoperative follow-up visit'
        WHEN adm.admission_type = 'EU OBSERVATION' THEN 'Out of Hours visit (Not Night)'
        WHEN adm.admission_type = 'EW EMER.' THEN 'Evaluation and management of new patient in office or outpatient facility'
        WHEN adm.admission_type = 'OBSERVATION ADMIT' THEN 'Weekend Visit'
        WHEN adm.admission_type = 'SURGICAL SAME DAY ADMISSION' THEN 'Established Patient - 30-39 Minutes'
        WHEN adm.admission_type = 'URGENT' THEN 'Evaluation and management of established patient in office or outpatient facility'
        -- Add additional mappings if necessary
        -- No ELSE clause, leaving encounter_type_description as NULL if no match
    END AS encounter_type_description,
    1 AS provider_id,  -- Assuming a default or fallback value
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
    CASE 
        WHEN adm.discharge_location = 'HOME' THEN 'home'
        WHEN adm.discharge_location = 'HOME HEALTH CARE' THEN 'home-hospice'
        WHEN adm.discharge_location = 'SKILLED NURSING FACILITY' THEN 'snf'
        WHEN adm.discharge_location = 'REHAB' THEN 'rehab'
        WHEN adm.discharge_location = 'CHRONIC/LONG TERM ACUTE CARE' THEN 'long'
        WHEN adm.discharge_location = 'HOSPICE' THEN 'hosp'
        WHEN adm.discharge_location = 'AGAINST ADVICE' THEN 'aadvice'
        WHEN adm.discharge_location = 'DIED' THEN 'exp'
        WHEN adm.discharge_location = 'PSYCH FACILITY' THEN 'psy'
        WHEN adm.discharge_location = 'ACUTE HOSPITAL' THEN 'comm-hospital'
        WHEN adm.discharge_location IS NULL OR adm.discharge_location = '' THEN 'oth'
        ELSE 'oth' -- For any other value that does not match the list
    END AS discharge_disposition,
    STR_TO_DATE(
        CONCAT(
            YEAR(adm.dischtime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(adm.dischtime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(adm.dischtime) = 2 AND DAY(adm.dischtime) = 29 AND 
                          ((YEAR(adm.dischtime) % 4 != 0) OR 
                           (YEAR(adm.dischtime) % 100 = 0 AND YEAR(adm.dischtime) % 400 != 0))
                     THEN 28
                     ELSE DAY(adm.dischtime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(adm.dischtime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date_end,               
    adm.hadm_id AS encounter,
    p.subject_id AS pid,
    (SELECT eventtype FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1) AS reason,
    STR_TO_DATE(
        CONCAT(
            YEAR((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1)) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1)), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1)) = 2 AND DAY((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1)) = 29 AND 
                          ((YEAR((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1)) % 4 != 0) OR 
                           (YEAR((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1)) % 100 = 0 AND YEAR((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1)) % 400 != 0))
                     THEN 28
                     ELSE DAY((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1))
                 END, 2, '0'),
            ' ',
            DATE_FORMAT((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1), '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS onset_date,
    10 AS pc_catid,
    3 AS billing_facility,
    3 AS facility_id,  -- Using a subquery to ensure a value is always provided
    '' AS referral_source  -- Providing a default value
FROM mimiciv.patients p
JOIN mimiciv.admissions adm ON p.subject_id = adm.subject_id
;
