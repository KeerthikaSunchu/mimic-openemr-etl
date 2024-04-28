INSERT INTO openemr.procedure_result (
    uuid,
    date, 
    result_text, 
    abnormal, 
    `range`, 
    result, 
    units, 
    procedure_report_id,
    result_status,
    result_code
    
)
SELECT    
    UNHEX(UUID()) as `uuid`,
    STR_TO_DATE(
        CONCAT(
            YEAR(le.storetime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(le.storetime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(le.storetime) = 2 AND DAY(le.storetime) = 29 AND 
                          ((YEAR(le.storetime) % 4 != 0) OR 
                           (YEAR(le.storetime) % 100 = 0 AND YEAR(le.storetime) % 400 != 0))
                     THEN 28
                     ELSE DAY(le.storetime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(le.storetime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date,
    COALESCE(LEFT(le.comments, 255), '') AS result_text,
    IF(le.flag IS NULL OR le.flag = '', 'normal', le.flag) AS abnormal,
    CONCAT(IFNULL(le.ref_range_lower,''), '-', IFNULL(le.ref_range_upper,'')) AS `range`,
    IFNULL(le.valuenum, 'default_value') AS result,
    IFNULL(le.valueuom, 'default_unit') AS units,
    rp.procedure_report_id AS procedure_report_id,
    'final' AS result_status,
    le.itemid AS result_code
FROM 
    mimiciv.patients p
JOIN 
    mimiciv.labevents le ON p.subject_id = le.subject_id
JOIN 
    mimiciv.admissions adm ON p.subject_id = adm.subject_id
JOIN 
    openemr.procedure_report rp ON le.labevent_id = rp.procedure_order_id
WHERE 
    p.subject_id = '10000764';
