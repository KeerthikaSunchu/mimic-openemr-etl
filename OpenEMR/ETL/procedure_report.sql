-- Create a temporary table for year difference calculation
CREATE TEMPORARY TABLE IF NOT EXISTS openemr.temp_patient_year_diff AS
SELECT 
    subject_id,
    anchor_year - ((SUBSTRING_INDEX(anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(anchor_year_group, ' - ', 1)) / 2) AS year_diff
FROM 
    mimiciv.patients;

-- Create an index on the temporary table
CREATE INDEX idx_temp_patient_year_diff ON openemr.temp_patient_year_diff (subject_id);
----
CREATE TABLE IF NOT EXISTS openemr.temp_labevents AS 
SELECT 
charttime,
storetime,
comments,
flag,
ref_range_lower,
valuenum,
valueuom,
itemid,
subject_id,
labevent_id 
FROM
mimiciv.labevents;

CREATE INDEX idx_procedure_order_id ON openemr.procedure_order (procedure_order_id);
CREATE INDEX idx_temp_labevents_id ON openemr.temp_labevents (labevent_id);

CREATE TABLE IF NOT EXISTS openemr.temp_admissions AS 
SELECT *
FROM
mimiciv.admissions;

create index idx_admissions_hadm_id on openemr.temp_admissions (hadm_id);
-- Main query to insert into procedure_report
create table openemr.temp_procedure_report AS 
SELECT 
    UNHEX(UUID()) as `uuid`,
    po.procedure_order_id AS procedure_order_id,
    po.date_ordered AS date_collected,
    po.date_collected AS date_report,
    LEFT(le.comments, 255) AS report_notes,
    'final' AS report_status,
    'reviewed' AS review_status
FROM 
    openemr.temp_labevents le
JOIN 
    openemr.procedure_order po ON le.labevent_id = po.procedure_order_id;

-- Drop the temporary table after use
DROP TEMPORARY TABLE IF EXISTS mimiciv.temp_patient_year_diff;
