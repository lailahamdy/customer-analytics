WITH cte AS (
    SELECT 
        CUST_ID,
        CASE
            WHEN LEAD(CALENDAR_DT) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) IS NULL THEN 1
            ELSE ABS(CALENDAR_DT - LEAD(CALENDAR_DT) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT))
        END AS MaxConscDays
    FROM 
        customerdata
)
SELECT 
    CUST_ID,
    MAX(MaxConscDays) AS MaxConsecutiveDays
FROM 
    cte
GROUP BY 
    CUST_ID
ORDER BY
      CUST_ID;
  

WITH cte AS (
    SELECT 
        CUST_ID,
        CASE
            SUM (LEAD(EXTRACT(DAY FROM CALENDAR_DT)) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT)-EXTRACT(DAY FROM CALENDAR_DT) IS NULL THEN 1
            ELSE ABS(EXTRACT(DAY FROM CALENDAR_DT) - LEAD(EXTRACT(DAY FROM CALENDAR_DT)) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT))
        END AS MaxConscDays
    FROM 
        customerdata
)
SELECT 
    CUST_ID,
    MAX(MaxConscDays) AS MaxConsecutiveDays
FROM 
    cte
GROUP BY 
    CUST_ID
ORDER BY
    CUST_ID;

select * from customerdata where cust_id = 66688 order by calendar_dt

WITH cte AS (
    SELECT 
        CUST_ID,
        CALENDAR_DT,
        AMT_LE,
        CASE 
            WHEN AMT_LE > 0 THEN 
                CASE 
                    WHEN LEAD(CALENDAR_DT) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) = CALENDAR_DT + 1 THEN 1
                    ELSE 0
                END
            ELSE 0
        END AS is_consecutive
    FROM 
        customerdata
)
SELECT 
    CUST_ID,
    MAX(SUM(is_consecutive)) AS MaxConsecutiveDays
FROM 
    cte
GROUP BY 
    CUST_ID
ORDER BY
    CUST_ID;


WITH CTE1 AS (
        SELECT CUST_ID, CALENDAR_DT, 
        EXTRACT(DAY FROM CALENDAR_DT) AS CURRDAY,
        LEAD(EXTRACT(DAY FROM CALENDAR_DT)) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) AS NEXTDAY    
        FROM CUSTOMERDATA  
),
CTE2 AS (
    SELECT 
        CUST_ID,
        CALENDAR_DT,
        SUM(CASE WHEN CURRDAY - NEXTDAY = 1 THEN 1
                    ELSE 0 END)
          OVER(PARTITION BY CUST_ID order by CALENDAR_DT) as CONSECUTIVE_DAYS
    FROM 
        CTE1
)
SELECT 
    CUST_ID,
    MAX(CONSECUTIVE_DAYS) AS MAXCONSECUTIVEDAYS
FROM 
    CTE2
GROUP BY 
    CUST_ID
ORDER BY
    CUST_ID;
    
    
WITH CTE1 AS (
    SELECT 
        CUST_ID, 
        CALENDAR_DT, 
        EXTRACT(DAY FROM CALENDAR_DT) AS CURRDAY,
        LEAD(EXTRACT(DAY FROM CALENDAR_DT)) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) AS NEXTDAY    
    FROM 
        CUSTOMERDATA  
),
CTE2 AS (
    SELECT 
        CUST_ID,
        CALENDAR_DT,
        SUM(
            CASE 
                WHEN NEXTDAY - CURRDAY = 1 THEN 1
                ELSE 0 
            END
        ) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) as CONSECUTIVE_DAYS
    FROM 
        CTE1
)
SELECT 
    CUST_ID,
    MAX(CONSECUTIVE_DAYS) AS MAXCONSECUTIVEDAYS
FROM 
    CTE2
GROUP BY 
    CUST_ID
ORDER BY
    CUST_ID;



----------------b
SELECT
    CUST_ID,
    CALENDAR_DT,
    AMT_LE,
    SUM(AMT_LE) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) AS cumulative_sum,
    
FROM
    customerdata;


WITH CustomerCumulativeSum AS (
    SELECT
        CUST_ID,
        CALENDAR_DT,
        AMT_LE,
        SUM(AMT_LE) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) AS cumulative_sum
    FROM
        customerdata
),  THRESH AS (
SELECT
    CUST_ID,
    COUNT(*) AS transc_to_reach_threshold
FROM
    CustomerCumulativeSum
WHERE
    cumulative_sum >= 250
GROUP BY
    CUST_ID
ORDER BY
    CUST_ID)
SELECT ROUND(avg(transc_to_reach_threshold),2) from thresh;