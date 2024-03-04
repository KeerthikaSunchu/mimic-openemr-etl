INSERT INTO oemr_mohith.form_encounter (uuid, 
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
    facility_id,
    referral_source
)
SELECT 
    UUID_TO_BIN(UUID()) as uuid,
    'Mohith''s Clinic' AS facility,
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
            ((SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2),
            '-',
            MONTH(adm.admittime),
            '-',
            DAY(adm.admittime)
        ),
        '%Y-%m-%d'
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
            ((SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2),
            '-',
            MONTH(adm.dischtime),
            '-',
            DAY(adm.dischtime)
        ),
        '%Y-%m-%d'
    ) AS date_end,
    adm.hadm_id AS encounter,
    p.subject_id AS pid,
    (SELECT eventtype FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1) AS reason,
    STR_TO_DATE(
        CONCAT(
            ((SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2),
            '-',
            MONTH((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1)),
            '-',
            DAY((SELECT intime FROM mimiciv.transfers WHERE hadm_id = adm.hadm_id LIMIT 1))
        ),
        '%Y-%m-%d'
    ) AS onset_date,
    1 AS facility_id,  -- Using a subquery to ensure a value is always provided
    '' AS referral_source  -- Providing a default value
FROM mimiciv.patients p
JOIN mimiciv.admissions adm ON p.subject_id = adm.subject_id
WHERE p.subject_id = '10000117';
