INSERT INTO openemr.form_vitals (
    uuid, 
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
    1 AS activity,
    STR_TO_DATE(
        CONCAT(
            ((SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2),
            '-',
            MONTH(omr.chartdate),
            '-',
            DAY(omr.chartdate)
        ),
        '%Y-%m-%d'
    ) AS date,
    omr.subject_id AS pid,
    SUBSTRING_INDEX(MAX(CASE WHEN omr.result_name = 'Blood Pressure' THEN omr.result_value END), '/', 1) AS bps,
    SUBSTRING_INDEX(MAX(CASE WHEN omr.result_name = 'Blood Pressure' THEN omr.result_value END), '/', -1) AS bpd,
    MAX(CASE WHEN omr.result_name = 'Weight (Lbs)' THEN omr.result_value END) AS weight,
    MAX(CASE WHEN omr.result_name = 'Height (Inches)' THEN omr.result_value END) AS height,
    MAX(CASE WHEN omr.result_name = 'BMI (kg/m2)' THEN omr.result_value END) AS bmi
FROM mimiciv.omr omr
JOIN mimiciv.patients p ON omr.subject_id = p.subject_id
WHERE omr.subject_id = '10000117'
GROUP BY omr.subject_id, omr.chartdate
HAVING COUNT(DISTINCT CASE WHEN omr.result_name IN ('Blood Pressure', 'Weight (Lbs)', 'Height (Inches)', 'BMI (kg/m2)') THEN omr.result_name END) = 4
ORDER BY omr.chartdate ASC
LIMIT 1;
