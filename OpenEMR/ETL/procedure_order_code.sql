CREATE TABLE openemr.temp_procedure_order_code AS
SELECT
    po.procedure_order_id AS procedure_order_id,
    (SELECT COALESCE(MAX(poc.procedure_order_seq), 0) + 1 FROM openemr.procedure_order_code poc WHERE poc.procedure_order_id = po.procedure_order_id) AS procedure_order_seq,
    pr.result_code AS procedure_code,
    pt.name AS procedure_name,
    '1' AS procedure_source,
    pr.result_text AS diagnoses,
    '0' AS do_not_send,
    po.procedure_order_type AS procedure_order_title,
    po.procedure_order_type AS procedure_type,
    '' AS transport
FROM
    openemr.procedure_order po
JOIN openemr.procedure_report rp ON po.procedure_order_id = rp.procedure_order_id
JOIN openemr.procedure_result pr ON pr.procedure_report_id = rp.procedure_report_id
JOIN openemr.procedure_type pt ON pr.result_code = pt.procedure_code
LEFT JOIN openemr.procedure_order_code poc ON po.procedure_order_id = poc.procedure_order_id
GROUP BY
    po.procedure_order_id,
    pr.result_code,
    pt.name,
    pr.result_text,
    po.procedure_order_type;


-- for loading procedures

CREATE TABLE openemr.temp_procedures_icd AS 
SELECT 
icd_version,
icd_code,
hadm_id,
subject_id
FROM
mimiciv.procedures_icd;

CREATE INDEX idx_temp_procedures_icd_subject_id ON openemr.temp_procedures_icd (subject_id);
CREATE INDEX idx_temp_procedures_icd_hadm_id ON openemr.temp_procedures_icd (hadm_id);
CREATE INDEX idx_temp_procedures_icd_code ON openemr.temp_procedures_icd (icd_code);
CREATE INDEX idx_temp_procedures_icd_version ON openemr.temp_procedures_icd (icd_version);



CREATE TABLE openemr.temp_d_icd_procedures AS 
SELECT 
long_title,
icd_code,
icd_version
FROM
mimiciv.d_icd_procedures;

CREATE INDEX idx_temp_d_icd_procedures_icd_version ON openemr.temp_d_icd_procedures (icd_version);
CREATE INDEX idx_temp_d_icd_procedures_icd_code ON openemr.temp_d_icd_procedures (icd_code);


CREATE TABLE openemr.temp_procedure_order_code2 AS
SELECT
    po.procedure_order_id,
    COALESCE(MAX(poc.procedure_order_seq), 0) + 1 AS procedure_order_seq,
    CONCAT('ICD', tpi.icd_version, ':', tpi.icd_code) AS procedure_code,
    dip.long_title AS procedure_name,
    '1' AS procedure_source,
    po.order_diagnosis AS diagnoses,
    '0' AS do_not_send,
    po.procedure_order_type AS procedure_order_title,
    po.procedure_order_type AS procedure_type,
    '' AS transport
FROM
    openemr.procedure_order po
JOIN openemr.temp_procedures_icd tpi ON po.encounter_id = tpi.hadm_id
JOIN openemr.temp_d_icd_procedures dip ON tpi.icd_code = dip.icd_code AND tpi.icd_version = dip.icd_version
LEFT JOIN openemr.procedure_order_code poc ON po.procedure_order_id = poc.procedure_order_id
WHERE
    tpi.subject_id = po.patient_id
GROUP BY
    po.procedure_order_id,
    tpi.icd_version,
    tpi.icd_code,
    dip.long_title,
    po.order_diagnosis,
    po.procedure_order_type
HAVING NOT EXISTS (
    SELECT 1
    FROM openemr.procedure_order_code poc2
    WHERE poc2.procedure_order_id = po.procedure_order_id
    AND poc2.procedure_order_seq = COALESCE(MAX(poc.procedure_order_seq), 0) + 1
);
