-- Loading data from mimiciv database to patient_data table of openemr database 

INSERT INTO openemr.patient_data (DOB, pid, deceased_date, language, status, race, ethnicity, sex) 
SELECT 
    -- Calculate the new DOB
    DATE_SUB(
        STR_TO_DATE(
            CONCAT(
                ((SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2) - p.anchor_age,
                '-',
                MONTH(adm.admittime),
                '-',
                CASE 
                    WHEN MONTH(adm.admittime) = 2 AND DAY(adm.admittime) = 29 AND 
                         ((YEAR(adm.admittime) % 4 != 0) OR 
                          (YEAR(adm.admittime) % 100 = 0 AND YEAR(adm.admittime) % 400 != 0))
                    THEN 28
                    ELSE DAY(adm.admittime)
                END
            ), 
            '%Y-%m-%d'
        ),
        INTERVAL 0 YEAR
    ) AS DOB,
    p.subject_id AS pid,
    -- Calculate the new deceased_date
    IF(p.dod IS NOT NULL,
        STR_TO_DATE(
            CONCAT(
                ((SUBSTRING_INDEX(p.anchor_year_group, ' - ', -1) + SUBSTRING_INDEX(p.anchor_year_group, ' - ', 1)) / 2),
                '-',
                MONTH(p.dod),
                '-',
                CASE 
                    WHEN MONTH(p.dod) = 2 AND DAY(p.dod) = 29 AND 
                         ((YEAR(p.dod) % 4 != 0) OR 
                          (YEAR(p.dod) % 100 = 0 AND YEAR(p.dod) % 400 != 0))
                    THEN 28
                    ELSE DAY(p.dod)
                END
            ),
            '%Y-%m-%d'
        ),
        NULL
    ) AS deceased_date,
    -- Language transformation
    CASE 
        WHEN adm.language = 'ENGLISH' THEN 'English'
        ELSE 'declne_to_specfy'
    END AS language,
    -- Marital Status transformation
    CASE 
        WHEN adm.marital_status = 'SINGLE' THEN 'Single'
        WHEN adm.marital_status = 'MARRIED' THEN 'Married'
        WHEN adm.marital_status = 'DIVORCED' THEN 'Divorced'
        WHEN adm.marital_status = 'WIDOWED' THEN 'Widowed'
        ELSE 'Unassigned'
    END AS status,
    -- Case statement for Race
    CASE
        WHEN adm.race = 'WHITE' THEN 'white'
        WHEN adm.race = 'BLACK/CARIBBEAN ISLAND' THEN 'black'
        WHEN adm.race = 'HISPANIC/LATINO - DOMINICAN' THEN 'dominican'
        WHEN adm.race = 'BLACK/AFRICAN AMERICAN' THEN 'black_or_afri_amer'
        WHEN adm.race = 'WHITE - OTHER EUROPEAN' THEN 'white'
        WHEN adm.race = 'BLACK/AFRICAN' THEN 'african'
        WHEN adm.race = 'BLACK/CAPE VERDEAN' THEN 'black'
        WHEN adm.race = 'ASIAN' THEN 'Asian'
        WHEN adm.race = 'HISPANIC/LATINO - MEXICAN' THEN 'mexican_american_indian'
        WHEN adm.race = 'WHITE - BRAZILIAN' THEN 'white'
        WHEN adm.race = 'WHITE - EASTERN EUROPEAN' THEN 'white'
        WHEN adm.race = 'WHITE - RUSSIAN' THEN 'white'
        WHEN adm.race = 'PORTUGUESE' THEN 'white'
        WHEN adm.race = 'ASIAN - CHINESE' THEN 'chinese'
        WHEN adm.race = 'ASIAN - SOUTH EAST ASIAN' THEN 'Asian'
        WHEN adm.race = 'PATIENT DECLINED TO ANSWER' THEN 'declne_to_specfy'
        WHEN adm.race = 'ASIAN - KOREAN' THEN 'korean'
        WHEN adm.race = 'ASIAN - ASIAN INDIAN' THEN 'asian_indian'
        WHEN adm.race = 'AMERICAN INDIAN/ALASKA NATIVE' THEN 'american_indian'
        WHEN adm.race = 'HISPANIC/LATINO - COLUMBIAN' THEN 'columbia'
        WHEN adm.race = 'SOUTH AMERICAN' THEN 'white'
        WHEN adm.race = 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' THEN 'native_hawaiian'
        ELSE 'declne_to_specfy'
    END AS race,
    -- Case statement for Ethnicity
    CASE
        WHEN adm.race LIKE '%HISPANIC%' OR adm.race LIKE '%LATINO%' THEN 'hisp_or_latin'
        ELSE 'not_hisp_or_latin'
    END AS ethnicity,
    -- Gender transformation
    CASE 
        WHEN p.gender = 'M' THEN 'Male'
        WHEN p.gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS sex
FROM mimiciv.patients p
INNER JOIN mimiciv.admissions adm ON p.subject_id = adm.subject_id;
 

UPDATE patient_data SET uuid = UNHEX(REPLACE(UUID(), '-', '')); 


