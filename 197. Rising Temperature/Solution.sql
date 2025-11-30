/*
 * Problem: Rising Temperature
 * Goal: Find IDs where the temperature is higher than the previous day.
 * * Approach: 
 * We use a SELF JOIN to compare the table with itself.
 * 'w1' represents the current day, and 'w2' represents the previous day.
 */

SELECT 
    w1.id
FROM 
    Weather w1
JOIN 
    Weather w2 
    -- Logic: The difference between Today (w1) and Yesterday (w2) must be exactly 1 day.
    ON DATEDIFF(w1.recordDate, w2.recordDate) = 1
WHERE 
    w1.temperature > w2.temperature;
