use openemr;
-- to display vitals

INSERT INTO forms (
    date, 
    encounter, 
    form_name, 
    form_id, 
    pid, 
    user, 
    groupname, 
    authorized, 
    formdir, 
    therapy_group_id
)
SELECT
    fv.date AS date,
    (
        SELECT fe.encounter
        FROM form_encounter fe
        WHERE fe.pid = fv.pid
        AND fe.date <= fv.date
        ORDER BY fe.date DESC
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
FROM form_vitals fv;

-- to display encounters

INSERT INTO openemr.forms (
    date,
    encounter,
    form_name,
    form_id,
    pid,
    user,
    groupname,
    authorized,
    deleted,
    formdir,
    therapy_group_id,
    issue_id,
    provider_id
)
SELECT
    fe.date AS date,
    fe.encounter AS encounter,
    'New Patient Encounter' AS form_name, -- Name of the form, adjust as needed
    fe.id AS form_id, -- Assuming `id` from form_encounter is what you want to reference
    fe.pid AS pid,
    'admin' AS user, -- Replace 'default_user' with actual user ID/name if available
    'Default' AS groupname, -- Replace 'default' with actual groupname if available
    1 AS authorized, -- Assuming form should be marked as authorized
    0 AS deleted, -- Assuming form should not be marked as deleted
    'newpatient' AS formdir, -- The directory for new patient forms, adjust if necessary
    NULL AS therapy_group_id, -- Assuming not applicable; adjust as needed
    0 AS issue_id, -- Assuming not applicable; adjust as needed
    fe.provider_id AS provider_id 
FROM
    openemr.form_encounter fe;

-- to display procedure orders

INSERT INTO openemr.forms (
    date,
    encounter,
    form_name,
    form_id,
    pid,
    user,
    groupname,
    authorized,
    deleted,
    formdir,
    therapy_group_id,
    issue_id,
    provider_id
)
SELECT
    po.date_ordered AS date,
    po.encounter_id AS encounter,
    '' AS form_name,  -- Adjust form_name based on your requirements
    po.procedure_order_id AS form_id,
    po.patient_id AS pid,
    'admin' AS user,  -- Replace 'DefaultUser' with the actual default user if available
    'Default' AS groupname,  -- Replace 'Default' with the actual group name if available
    1 AS authorized,  -- Assuming the form should be authorized by default
    0 AS deleted,  -- Assuming the form is not deleted
    'procedure_order' AS formdir,  -- The directory name for procedure order forms
    NULL AS therapy_group_id,  -- Assuming not applicable to procedure orders
    0 AS issue_id,  -- Assuming not applicable to procedure orders
    po.provider_id AS provider_id
FROM
    openemr.procedure_order po;
    
-- to display notes

INSERT INTO forms (
    date, 
    encounter, 
    form_name, 
    form_id, 
    pid, 
    user, 
    groupname, 
    authorized, 
    formdir, 
    therapy_group_id,
    provider_id
)
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
FROM form_clinical_notes fc;

    
