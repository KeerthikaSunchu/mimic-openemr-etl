-- Create an index on the temporary table
CREATE INDEX idx_procedure_report_id ON openemr.procedure_report (procedure_order_id);

CREATE TABLE IF NOT EXISTS openemr.temp_labevents AS 
SELECT 
labevent_id,
charttime,
storetime,
comments,
flag,
ref_range_lower,
ref_range_upper,
valuenum,
valueuom,
itemid,
subject_id
FROM
mimiciv.labevents;

-- Main query to insert into procedure_result
create table openemr.temp_procedure_result AS 
SELECT    
    UNHEX(UUID()) as `uuid`,
    rp.date_collected AS `date`,
    COALESCE(LEFT(le.comments, 255), '') AS result_text,
    IF(le.flag IS NULL OR le.flag = '', 'normal', le.flag) AS abnormal,
    CONCAT(IFNULL(le.ref_range_lower,''), '-', IFNULL(le.ref_range_upper,'')) AS `range`,
    IFNULL(le.valuenum, 'default_value') AS result,
    IFNULL(le.valueuom, 'default_unit') AS units,
    rp.procedure_report_id AS procedure_report_id,
    'final' AS result_status,
    le.itemid AS result_code
FROM 
    openemr.temp_labevents le
JOIN 
    openemr.procedure_report rp ON le.labevent_id = rp.procedure_order_id;

