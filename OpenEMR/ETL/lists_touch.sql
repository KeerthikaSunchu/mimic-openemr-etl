INSERT INTO openemr.lists_touch (
    pid, 
    type, 
    date)
SELECT 
    pid, 
    type, 
    date
FROM openemr.lists
ON DUPLICATE KEY UPDATE
date = VALUES(date);
