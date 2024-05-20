INSERT INTO openemr.form_vitals (
    `uuid`, 
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
    UNHEX(UUID()) as `uuid`,
    'admin' AS user,
    'Default' AS groupname,
    1 AS activity,
    STR_TO_DATE(
        CONCAT(
            YEAR(omr.chartdate) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(omr.chartdate), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(omr.chartdate) = 2 AND DAY(omr.chartdate) = 29 
                     THEN 28
                     ELSE DAY(omr.chartdate)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(omr.chartdate, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date,
    omr.subject_id AS pid,
    SUBSTRING_INDEX(MAX(CASE WHEN omr.result_name = 'Blood Pressure' THEN omr.result_value END), '/', 1) AS bps,
    SUBSTRING_INDEX(MAX(CASE WHEN omr.result_name = 'Blood Pressure' THEN omr.result_value END), '/', -1) AS bpd,
    MAX(
    CASE 
        WHEN omr.result_name = 'Weight (Lbs)' 
        THEN LEAST(CAST(omr.result_value AS DECIMAL(12,6)), 999999.999999)
    END
	) AS weight,
    MAX(CASE WHEN omr.result_name = 'Height (Inches)' THEN omr.result_value END) AS height,
    MAX(CASE WHEN omr.result_name = 'BMI (kg/m2)' THEN omr.result_value END) AS bmi
FROM mimiciv.omr omr
JOIN mimiciv.patients p ON omr.subject_id = p.subject_id
INNER JOIN mimiciv.admissions adm ON p.subject_id = adm.subject_id
GROUP BY omr.subject_id, omr.chartdate
;
