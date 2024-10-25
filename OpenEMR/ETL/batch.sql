
DELIMITER //
 
CREATE PROCEDURE openemr.BatchInsertProcedureOrders()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
 
    REPEAT
        -- Insert data in batches
        INSERT INTO openemr.procedure_order (
			UUID,
			procedure_order_id,
			patient_id, 
			encounter_id, 
			provider_id, 
			date_ordered, 
			date_collected, 
			order_status, 
			order_priority,
			order_diagnosis,
			procedure_order_type)
        SELECT UUID,
			procedure_order_id,
			patient_id, 
			encounter_id, 
			provider_id, 
			date_ordered, 
			date_collected, 
			order_status, 
			order_priority,
			order_diagnosis,
			procedure_order_type
        FROM mimiciv.temp_procedure_order
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 61000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
 
END //
 
DELIMITER ;

DELIMITER //
 
CREATE PROCEDURE openemr.BatchInsertProcedureReports()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
 
    REPEAT
        -- Insert data in batches
        INSERT INTO openemr.procedure_report (
			UUID,
			procedure_order_id,
			date_collected, 
            date_report,
            report_notes,
            report_status,
            review_status
            )
        SELECT UUID,
			procedure_order_id,
			date_collected, 
            date_report,
            report_notes,
            report_status,
            review_status
        FROM openemr.temp_procedure_report
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 61000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
 
END //
 
DELIMITER ;




DELIMITER //

CREATE PROCEDURE openemr.BatchInsertProcedureResults()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
 
    REPEAT
        -- Insert data in batches
        INSERT INTO openemr.procedure_result (
			UUID,
            `date`, 
            result_text,  
            abnormal, 
            `range`, 
            result, 
            units, 
            procedure_report_id,
            result_status,
            result_code)
        SELECT UUID,
            `date`, 
            result_text,  
            abnormal, 
            `range`, 
            result, 
            units, 
            procedure_report_id,
            result_status,
            result_code
        FROM openemr.temp_procedure_result
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 61000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
 
END //
 
DELIMITER ;




DELIMITER //

CREATE PROCEDURE openemr.BatchInsertProcedureOrderCode1()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
 
    REPEAT
        -- Insert data in batches
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
			transport)
        SELECT
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
        FROM openemr.temp_procedure_order_code
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 61000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
 
END //
 
DELIMITER //

CREATE PROCEDURE openemr.BatchInsertProcedureOrderCode2()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 175000000;
    DECLARE done INT DEFAULT FALSE;
    
    SET AUTOCOMMIT = 0;
    SET unique_checks=0;
    SET FOREIGN_KEY_CHECKS=0;
 
    REPEAT
        -- Insert data in batches
        INSERT IGNORE INTO openemr.procedure_order_code (
			procedure_order_id,
			procedure_order_seq,
			procedure_code,
			procedure_name,
			procedure_source,
			diagnoses,
			do_not_send,
			procedure_order_title,
			procedure_type,
			transport)
        SELECT
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
        FROM openemr.temp_procedure_order_code2
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 250000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
    
    SET AUTOCOMMIT = 1;
    SET unique_checks=1;
    SET FOREIGN_KEY_CHECKS=1;
 
END //
 
DELIMITER ;

-- Improved Parallel Insertion (Saptarshi)
-- DELIMITER //
-- 
-- CREATE PROCEDURE openemr.BatchInsertProcedureOrderCode2Parallel(
--     IN start_id BIGINT,
--     IN end_id BIGINT
-- )
-- proc_label:BEGIN
--     DECLARE batch_size INT DEFAULT 50000; -- Adjusted batch size for smaller dataset
--     DECLARE current_id BIGINT DEFAULT start_id;
--     DECLARE done INT DEFAULT FALSE;
--     DECLARE start_time TIMESTAMP;
--     DECLARE batch_start_time TIMESTAMP;
--     DECLARE end_time TIMESTAMP;
--     DECLARE elapsed_time INT;
--     DECLARE batch_elapsed_time INT;
--     DECLARE rows_affected INT;
--     DECLARE total_rows_affected BIGINT DEFAULT 0;
--     DECLARE progress_counter INT DEFAULT 0;
--     
--     SET AUTOCOMMIT = 0;
--     SET unique_checks=0;
--     SET FOREIGN_KEY_CHECKS=0;
-- 
--     SET start_time = CURRENT_TIMESTAMP;
-- 
--     -- Log the start of the procedure
--     SELECT CONCAT('Starting batch insert from ID ', start_id, ' to ', end_id) AS Status;
-- 
--     REPEAT
--         SET batch_start_time = CURRENT_TIMESTAMP;
--         
--         -- Insert data in batches
--         INSERT IGNORE INTO openemr.procedure_order_code (
--             procedure_order_id,
--             procedure_order_seq,
--             procedure_code,
--             procedure_name,
--             procedure_source,
--             diagnoses,
--             do_not_send,
--             procedure_order_title,
--             procedure_type,
--             transport)
--         SELECT
--             procedure_order_id,
--             procedure_order_seq,
--             procedure_code,
--             procedure_name,
--             procedure_source,
--             diagnoses,
--             do_not_send,
--             procedure_order_title,
--             procedure_type,
--             transport
--         FROM openemr.temp_procedure_order_code2
--         WHERE procedure_order_id BETWEEN current_id AND LEAST(current_id + batch_size - 1, end_id)
--         ORDER BY procedure_order_id, procedure_order_seq;
-- 
--         -- Get number of affected (inserted) rows
--         SET rows_affected = ROW_COUNT();
--         SET total_rows_affected = total_rows_affected + rows_affected;
-- 
--         SET current_id = LEAST(current_id + batch_size, end_id + 1);
--         
--         -- Commit each batch
--         COMMIT;
--  
--         -- Check if we're done
--         IF current_id > end_id THEN
--             SET done = TRUE;
--         END IF;
--  
--         -- Log progress every 500,000 rows
--         SET progress_counter = progress_counter + 1;
--         IF progress_counter >= 10 OR done = TRUE THEN
--             SET end_time = CURRENT_TIMESTAMP;
--             SET elapsed_time = TIMESTAMPDIFF(SECOND, start_time, end_time);
--             SET batch_elapsed_time = TIMESTAMPDIFF(SECOND, batch_start_time, end_time);
--             SELECT CONCAT('Processed up to id ', current_id - 1, 
--                           '. Rows inserted: ', rows_affected, 
--                           '. Total rows inserted: ', total_rows_affected,
--                           '. Batch time: ', batch_elapsed_time, ' seconds',
--                           '. Total time: ', elapsed_time, ' seconds') AS Progress;
--             SET progress_counter = 0;
--         END IF;
-- 
--     UNTIL done END REPEAT;
--     
--     SET AUTOCOMMIT = 1;
--     SET unique_checks=1;
--     SET FOREIGN_KEY_CHECKS=1;
--  
--     -- Log total time and rows
--     SET end_time = CURRENT_TIMESTAMP;
--     SET elapsed_time = TIMESTAMPDIFF(SECOND, start_time, end_time);
--     SELECT CONCAT('Total elapsed time: ', elapsed_time, ' seconds. ',
--                   'Total rows inserted: ', total_rows_affected) AS FinalStatus;
-- 
-- END //
-- 
-- DELIMITER ;


-- forms 1

DELIMITER //

CREATE PROCEDURE openemr.BatchInsertFormVitals()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
 
    REPEAT
        -- Insert data in batches
        INSERT INTO openemr.forms (
			`date`, 
			encounter, 
			form_name, 
			form_id, 
			pid, 
			USER, 
			groupname, 
			authorized, 
			formdir, 
			therapy_group_id)
        SELECT
			`date`, 
			encounter, 
			form_name, 
			form_id, 
			pid, 
			USER, 
			groupname, 
			authorized, 
			formdir, 
			therapy_group_id
        FROM openemr.temp_formsV
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 61000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
 
END //
 
DELIMITER //


CREATE PROCEDURE openemr.BatchInsertFormEncounters()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
 
    REPEAT
        -- Insert data in batches
        INSERT INTO openemr.forms(
			`date`,
			encounter,
			form_name,
			form_id,
			pid,
			USER,
			groupname,
			authorized,
			deleted,
			formdir,
			therapy_group_id,
			issue_id,
			provider_id)
        SELECT
			`date`,
			encounter,
			form_name,
			form_id,
			pid,
			USER,
			groupname,
			authorized,
			deleted,
			formdir,
			therapy_group_id,
			issue_id,
			provider_id
        FROM openemr.temp_formsE 
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 61000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
 
END //
 
DELIMITER //


CREATE PROCEDURE openemr.BatchInsertFormProcedureOrders()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
 
    REPEAT
        -- Insert data in batches
        INSERT INTO openemr.forms(
			`date`,
			encounter,
			form_name,
			form_id,
			pid,
			USER,
			groupname,
			authorized,
			deleted,
			formdir,
			therapy_group_id,
			issue_id,
			provider_id)
        SELECT
			`date`,
			encounter,
			form_name,
			form_id,
			pid,
			USER,
			groupname,
			authorized,
			deleted,
			formdir,
			therapy_group_id,
			issue_id,
			provider_id
        FROM openemr.temp_formsPO
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 62000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
 
END //
 
DELIMITER //

CREATE PROCEDURE openemr.BatchInsertFormDisplayNotes()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
 
    REPEAT
        -- Insert data in batches
        INSERT INTO openemr.forms(
			`date`, 
			encounter, 
			form_name, 
			form_id, 
			pid, 
			USER, 
			groupname, 
			authorized, 
			formdir, 
			therapy_group_id,
			provider_id
		)
        SELECT
			DATE, 
			encounter, 
			form_name, 
			form_id, 
			pid, 
			USER, 
			groupname, 
			authorized, 
			formdir, 
			therapy_group_id,
			provider_id
        FROM openemr.temp_formsCN
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 61000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
 
END //
 
DELIMITER ;


DELIMITER //

CREATE PROCEDURE openemr.BatchInsertPrescriptions()
BEGIN
    DECLARE batch_size INT DEFAULT 100000;
    DECLARE row_offset INT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
 
    REPEAT
        -- Insert data in batches
        INSERT INTO openemr.prescriptions(
			UUID,
			provider_id,
			date_added,
			refills,
			encounter,
			drug,
			drug_id,
			patient_id,
			date_modified,
			dosage,
			quantity,
			rxnorm_drugcode,
			start_date,
			end_date,
			route, 
			usage_category_title,
			request_intent_title,
			medication,
			created_by,
			updated_by
		)
        SELECT
			UUID,
			provider_id,
			date_added,
			refills,
			encounter,
			drug,
			drug_id,
			patient_id,
			date_modified,
			dosage,
			quantity,
			rxnorm_drugcode,
			start_date,
			end_date,
			route, 
			usage_category_title,
			request_intent_title,
			medication,
			created_by,
			updated_by
        FROM openemr.temp_prescriptions
        LIMIT row_offset, batch_size;

        SET row_offset = row_offset + batch_size;
        SELECT row_offset;
        -- Commit each batch
        COMMIT;
 
        -- Check if we're done
        IF row_offset > 61000000 THEN
            SET done = TRUE;
        END IF;
 
    UNTIL done END REPEAT;
 
END //
 
DELIMITER ;
