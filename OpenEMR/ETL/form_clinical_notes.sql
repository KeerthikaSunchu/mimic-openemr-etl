INSERT INTO openemr.form_clinical_notes (
    uuid,
    form_id,
    date,
    pid,
    encounter,
    user, 
    description,
    activity,
    authorized,
    groupname,
    code,
    codetext,
    clinical_notes_type,
    note_related_to
)
SELECT    
    UNHEX(UUID()) as `uuid`,
    (SELECT IFNULL(MAX(form_id), 0) + 1 FROM openemr.form_clinical_notes) AS form_id,
    STR_TO_DATE(
        CONCAT(
            -- Adjusted year calculation
            YEAR(dn.storetime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',  -- Separator for date parts
            LPAD(MONTH(dn.storetime), 2, '0'),  -- Month part
            '-', 
            LPAD(CASE 
                     WHEN MONTH(dn.storetime) = 2 AND DAY(dn.storetime) = 29 AND 
                          ((YEAR(dn.storetime) % 4 != 0) OR 
                           (YEAR(dn.storetime) % 100 = 0 AND YEAR(dn.storetime) % 400 != 0))
                     THEN 28
                     ELSE DAY(dn.storetime)
                 END, 2, '0'),
            ' ',  -- Separator for date and time parts
            DATE_FORMAT(dn.storetime, '%H:%i:%s')  -- Time part
        ), 
        '%Y-%m-%d %H:%i:%s'
    ) AS date,
    dn.subject_id AS pid,
    dn.hadm_id AS encounter,
    'admin' AS user,
    dn.text AS description, 
    1 AS activity,
    1 AS authorized,
    'Default' AS groupname,
    'LOINC:18842-5' AS code,
    'Discharge Summary Note' AS codetext,
    'discharge_summary' AS clinical_notes_type,
    '[]' AS note_related_to
    
FROM
    openemr.discharge_notes dn
JOIN 
    mimiciv.patients p ON dn.subject_id = p.subject_id
JOIN 
    mimiciv.admissions adm ON p.subject_id = adm.subject_id
;
    
