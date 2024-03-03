INSERT INTO oemr_mohith.form_vitals (
    uuid, 
    user, 
    groupname, 
    activity, 
    date, 
    pid, 
    bps, 
    bpd, 
    weight, 
    height, 
    BMI
)
SELECT 
    UUID_TO_BIN(UUID()) AS uuid,
    'Kslmohith@06' AS user,
    'Default' AS groupname,
    1 AS activity,
    -- Calculation for the date goes here, adjusted as per your requirements
    STR_TO_DATE(
        CONCAT(
            ((SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2),
            '-',
            MONTH(ec.chartdate),
            '-',
            DAY(ec.chartdate)
        ),
        '%Y-%m-%d'
    ) AS date,
    ec.subject_id AS pid,
    SUBSTRING_INDEX(ec.systolic_bp, '/', 1) AS bps,
    SUBSTRING_INDEX(ec.diastolic_bp, '/', -1) AS bpd,
    ec.weight AS weight,
    ec.height AS height,
    ec.bmi AS BMI
FROM (
    SELECT
        omr.subject_id,
        omr.chartdate,
        MAX(CASE WHEN omr.result_name = 'Blood Pressure' THEN omr.result_value ELSE NULL END) AS systolic_bp,
        MAX(CASE WHEN omr.result_name = 'Blood Pressure' THEN omr.result_value ELSE NULL END) AS diastolic_bp,
        MAX(CASE WHEN omr.result_name = 'Weight (Lbs)' THEN omr.result_value ELSE NULL END) AS weight,
        MAX(CASE WHEN omr.result_name = 'Height (Inches)' THEN omr.result_value ELSE NULL END) AS height,
        MAX(CASE WHEN omr.result_name = 'BMI (kg/m2)' THEN omr.result_value ELSE NULL END) AS bmi
    FROM mimiciv.omr
    WHERE omr.subject_id = 10000117
    GROUP BY omr.subject_id, omr.chartdate
    HAVING COUNT(DISTINCT CASE WHEN omr.result_name IN ('Blood Pressure', 'Weight (Lbs)', 'Height (Inches)', 'BMI (kg/m2)') THEN omr.result_name END) = 4
) AS ec
JOIN mimiciv.patients p ON ec.subject_id = p.subject_id
-- Ensuring we're getting the earliest complete set
JOIN (
    SELECT 
        subject_id, 
        MIN(chartdate) AS min_chartdate 
    FROM (
        SELECT
            omr.subject_id,
            omr.chartdate
        FROM mimiciv.omr
        WHERE omr.subject_id = 10000117
        GROUP BY omr.subject_id, omr.chartdate
        HAVING COUNT(DISTINCT CASE WHEN omr.result_name IN ('Blood Pressure', 'Weight (Lbs)', 'Height (Inches)', 'BMI (kg/m2)') THEN omr.result_name END) = 4
    ) AS valid_dates
    GROUP BY subject_id
) AS min_dates ON ec.subject_id = min_dates.subject_id AND ec.chartdate = min_dates.min_chartdate;
