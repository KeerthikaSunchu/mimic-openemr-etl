-- Create temporary table for form_vitals with indexing
CREATE TABLE IF NOT EXISTS openemr.temp_form_vitals AS
SELECT 
    fv.`date`, 
    fv.id, 
    fv.pid, 
    fv.user, 
    fv.groupname
FROM 
    openemr.form_vitals fv;

CREATE INDEX idx_temp_form_vitals_pid ON openemr.temp_form_vitals (pid);
CREATE INDEX idx_temp_form_vitals_date ON openemr.temp_form_vitals (`date`);

-- Insert into forms for displaying vitals
CREATE TABLE openemr.temp_formsV AS
SELECT
    fv.`date` AS `date`,
    (
        SELECT fe.encounter
        FROM openemr.form_encounter fe
        WHERE fe.pid = fv.pid
        AND fe.`date` <= fv.`date`
        ORDER BY fe.`date` DESC
        LIMIT 1
    ) AS encounter,
    'Vitals' AS form_name,
    fv.id AS form_id,
    fv.pid AS pid,
    fv.user AS user,
    fv.groupname AS groupname,
    1 AS authorized,
    'vitals' AS formdir,
    NULL AS therapy_group_id
FROM openemr.temp_form_vitals fv;



-- Create temporary table for form_encounter with indexing
CREATE TABLE IF NOT EXISTS openemr.temp_form_encounter AS
SELECT 
    fe.`date`, 
    fe.encounter, 
    fe.id, 
    fe.pid, 
    fe.provider_id 
FROM 
    openemr.form_encounter fe;

CREATE INDEX idx_temp_form_encounter_pid ON openemr.temp_form_encounter (pid);
CREATE INDEX idx_temp_form_encounter_encounter ON openemr.temp_form_encounter (encounter);

-- Insert into forms for displaying encounters
CREATE TABLE IF NOT EXISTS openemr.temp_formsE AS 
SELECT 
    fe.`date` AS `date`,
    fe.encounter AS encounter,
    'New Patient Encounter' AS form_name,
    fe.id AS form_id,
    fe.pid AS pid,
    'admin' AS user,
    'Default' AS groupname,
    1 AS authorized,
    0 AS deleted,
    'newpatient' AS formdir,
    NULL AS therapy_group_id,
    0 AS issue_id,
    fe.provider_id AS provider_id 
FROM openemr.temp_form_encounter fe;

-- Create temporary table for procedure_order with indexing



-- Insert into forms for displaying procedure orders
CREATE TABLE IF NOT EXISTS openemr.temp_formsPO AS
SELECT
    po.date_ordered AS date,
    po.encounter_id AS encounter,
    '' AS form_name,
    po.procedure_order_id AS form_id,
    po.patient_id AS pid,
    'admin' AS user,
    'Default' AS groupname,
    1 AS authorized,
    0 AS deleted,
    'procedure_order' AS formdir,
    NULL AS therapy_group_id,
    0 AS issue_id,
    po.provider_id AS provider_id
FROM openemr.temp_procedure_order po;

-- Create temporary table for form_clinical_notes with indexing
CREATE TABLE IF NOT EXISTS openemr.temp_form_clinical_notes AS
SELECT 
    fc.`date`, 
    fc.encounter, 
    fc.id, 
    fc.pid, 
    fc.user, 
    fc.groupname 
FROM 
    openemr.form_clinical_notes fc;

CREATE INDEX idx_temp_form_clinical_notes_pid ON openemr.temp_form_clinical_notes (pid);
CREATE INDEX idx_temp_form_clinical_notes_encounter ON openemr.temp_form_clinical_notes (encounter);

-- Insert into forms for displaying notes
CREATE TABLE IF NOT EXISTS openemr.temp_formsCN AS
SELECT
    fc.date AS date,
    fc.encounter AS encounter,
    'Clinical Notes Form' AS form_name,
    fc.id AS form_id,
    fc.pid AS pid,
    fc.user AS user,
    fc.groupname AS groupname,
    1 AS authorized,
    'clinical_notes' AS formdir,
    NULL AS therapy_group_id,
    1 AS provider_id
FROM openemr.temp_form_clinical_notes fc;

-- Clean up temporary tables
DROP TEMPORARY TABLE IF EXISTS mimiciv.temp_form_vitals;
DROP TEMPORARY TABLE IF EXISTS mimiciv.temp_form_encounter;
DROP TEMPORARY TABLE IF EXISTS mimiciv.temp_procedure_order;
DROP TEMPORARY TABLE IF EXISTS mimiciv.temp_form_clinical_notes;
