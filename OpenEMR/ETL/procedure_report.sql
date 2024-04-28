INSERT INTO openemr.procedure_report (
    uuid,
    procedure_order_id, 
    date_collected,
    date_report,
    report_notes,
    report_status,
    review_status
    )
SELECT 
    UNHEX(UUID()) as `uuid`,
    po.procedure_order_id AS procedure_order_id,
    STR_TO_DATE(
        CONCAT(
            YEAR(le.charttime) - 
            (
                p.anchor_year - 
                (
                    (SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2
                )
            ),
            '-',
            LPAD(MONTH(le.charttime), 2, '0'),
            '-',
            LPAD(CASE 
                     WHEN MONTH(le.charttime) = 2 AND DAY(le.charttime) = 29 AND 
                          ((YEAR(le.charttime) % 4 != 0) OR 
                           (YEAR(le.charttime) % 100 = 0 AND YEAR(le.charttime) % 400 != 0))
                     THEN 28
                     ELSE DAY(le.charttime)
                 END, 2, '0'),
            ' ',
            DATE_FORMAT(le.charttime, '%H:%i:%s')
        ),
        '%Y-%m-%d %H:%i:%s'
    ) AS date_collected,
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
    ) AS date_report,
    LEFT(le.comments, 255) AS report_notes,
    'final' AS report_status,
    'reviewed' AS review_status
FROM mimiciv.labevents le
JOIN mimiciv.patients p ON le.subject_id = p.subject_id
JOIN mimiciv.admissions adm ON p.subject_id = adm.subject_id
JOIN openemr.procedure_order po ON le.labevent_id = po.procedure_order_id
WHERE p.subject_id = '10000764';
