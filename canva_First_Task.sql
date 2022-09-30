/* A view to separate data of the last 7 days from the rest of table */
WITH DESIGN_EXPORTED_LAST_7_DAYS AS (
  SELECT 
    * 
  FROM 
    DESIGN_EXPORTED 
  WHERE 
    (
      TO_TIMESTAMP(TIMESTAMP):: date BETWEEN CURRENT_DATE - 7 
      AND CURRENT_DATE
    ) 
    /*Where timestamp>= Extract(epoch from Now())-7*24*60*60 --If by the last 7 days you meant the last 7 24 hours */
    ) 
    
/* Here I first write a query to return user_id |last_design_category and then another query for user_id|decile and then inner join these two queries */  
SELECT 
  FQ.USER_ID, 
  FQ.DESIGN_CATEGORY as last_exported_design, 
  SQ.NTILE as decile 
FROM 
  (
    SELECT 
      USER_ID, 
      DESIGN_CATEGORY 
    FROM 
      (
        SELECT 
          USER_ID, 
          DESIGN_CATEGORY, 
          RANK () OVER (
            PARTITION BY USER_ID 
            ORDER BY 
              TIMESTAMP DESC
          ) TIME_RANK 
        FROM 
          DESIGN_EXPORTED_LAST_7_DAYS
      ) AS UDR 
    WHERE 
      TIME_RANK = 1
  ) AS FQ 
  INNER JOIN (
    SELECT 
      USER_ID, 
      NTILE(10) OVER(
        ORDER BY 
          NUM_DESIGNS
      ) 
    FROM 
      (
        SELECT 
          USER_ID, 
          COUNT(USER_ID) AS NUM_DESIGNS 
        FROM 
          DESIGN_EXPORTED_LAST_7_DAYS 
        GROUP BY 
          USER_ID
      ) AS UN
  ) AS SQ ON FQ.USER_ID = SQ.USER_ID 
ORDER BY 
  SQ.NTILE DESC
