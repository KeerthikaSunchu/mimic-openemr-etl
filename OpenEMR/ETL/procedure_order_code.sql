use openemr;
INSERT INTO openemr.procedure_order_code (
    procedure_order_id,
    procedure_order_seq,
    procedure_code,
    procedure_name,
    procedure_source,
    diagnoses,
    do_not_send,
    procedure_order_title,
    procedure_type,
    transport
)
SELECT
    po.procedure_order_id AS procedure_order_id,
    (SELECT COALESCE(MAX(poc.procedure_order_seq), 0) + 1 FROM procedure_order_code poc WHERE poc.procedure_order_id = po.procedure_order_id) AS procedure_order_seq,
    pr.result_code AS procedure_code,
    pt.name AS procedure_name,
    '1' AS procedure_source,
    pr.result_text AS diagnoses,
    '0' AS do_not_send,
    po.procedure_order_type AS procedure_order_title,
    po.procedure_order_type AS procedure_type,
    '' AS transport
FROM
    procedure_order po
JOIN procedure_report rp ON po.procedure_order_id = rp.procedure_order_id
JOIN procedure_result pr ON pr.procedure_report_id = rp.procedure_report_id
JOIN procedure_type pt ON pr.result_code = pt.procedure_code
LEFT JOIN procedure_order_code poc ON po.procedure_order_id = poc.procedure_order_id
GROUP BY
    po.procedure_order_id,
    pr.result_code,
    pt.name,
    pr.result_text,
    po.procedure_order_type;


-- for loading procedures

INSERT INTO openemr.procedure_order_code (
    procedure_order_id,
    procedure_order_seq,
    procedure_code,
    procedure_name,
    procedure_source,
    diagnoses,
    do_not_send,
    procedure_order_title,
    procedure_type,
    transport
)
SELECT
    po.procedure_order_id,
    COALESCE(MAX(poc.procedure_order_seq), 0) + 1 AS new_sequence,
    CONCAT('ICD', pi.icd_version, ':', pi.icd_code) AS procedure_code,
    dip.long_title AS procedure_name,
    '1' AS procedure_source,
    po.order_diagnosis AS diagnoses,
    '0' AS do_not_send,
    po.procedure_order_type AS procedure_order_title,
    po.procedure_order_type AS procedure_type,
    '' AS transport
FROM
    procedure_order po
JOIN mimiciv.procedures_icd pi ON po.encounter_id = pi.hadm_id
JOIN mimiciv.d_icd_procedures dip ON pi.icd_code = dip.icd_code AND pi.icd_version = dip.icd_version
LEFT JOIN procedure_order_code poc ON po.procedure_order_id = poc.procedure_order_id
WHERE
    pi.subject_id = po.patient_id
GROUP BY
    po.procedure_order_id,
    pi.icd_version,
    pi.icd_code,
    dip.long_title,
    po.order_diagnosis,
    po.procedure_order_type
HAVING NOT EXISTS (
    SELECT 1
    FROM procedure_order_code poc2
    WHERE poc2.procedure_order_id = po.procedure_order_id
    AND poc2.procedure_order_seq = COALESCE(MAX(poc.procedure_order_seq), 0) + 1
);
