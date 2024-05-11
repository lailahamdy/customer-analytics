WITH customers_query AS (
    SELECT 
        distinct customer_id,
        ceil(months_between(SYSDATE,MAX(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) OVER(Partition by customer_id))) as Recency
        FROM tableretail)
SELECT 
    customer_id, 
    recency
FROM 
    customers_query
ORDER BY customer_id;


WITH recency_query AS (
    SELECT 
        customer_id,
        CEIL(MONTHS_BETWEEN(SYSDATE, MAX(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))) OVER (PARTITION BY customer_id)) as Recency
    FROM 
        tableretail
    GROUP BY 
        customer_id
),
orders_last_quarter_query AS (
    SELECT 
        customer_id,
        COUNT(*) AS num_orders_last_quarter
    FROM 
        tableretail
    WHERE 
        TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI') >= TRUNC(ADD_MONTHS(TRUNC(SYSDATE, 'Q'), -3))
        AND TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI') < TRUNC(SYSDATE, 'Q')
    GROUP BY 
        customer_id
)
SELECT 
    r.customer_id, 
    r.Recency,
    COALESCE(o.num_orders_last_quarter, 0) AS num_orders_last_quarter
FROM 
    recency_query r
LEFT JOIN 
    orders_last_quarter_query o ON r.customer_id = o.customer_id
ORDER BY 
    r.customer_id;


WITH customers_query AS (
    SELECT 
        customer_id,
        CEIL(MONTHS_BETWEEN(SYSDATE, MAX(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))) OVER (PARTITION BY customer_id)) as recency,
        COUNT(CASE WHEN EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011 THEN invoice END) OVER (PARTITION BY customer_id) as frequency
    FROM 
        tableretail
)
SELECT 
    customer_id, 
    recency,
    frequency
FROM 
    customers_query
ORDER BY 
    customer_id;



WITH customers_query AS (
    SELECT 
        customer_id,
        CEIL(MONTHS_BETWEEN(SYSDATE, MAX(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))) OVER (PARTITION BY customer_id)) as recency,
         frequency from (SELECT customer_id, COUNT(invoice) as frequency FROM tableretail WHERE EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011 group by customer_id) 
    FROM 
        tableretail
    WHERE 
        EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011
)
SELECT 
    customer_id, 
    recency,
    frequency
FROM 
    customers_query c
ORDER BY 
    customer_id;


WITH customers_query AS (
    SELECT 
        customer_id,
        CEIL(MONTHS_BETWEEN(SYSDATE, MAX(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))) OVER (PARTITION BY customer_id)) as recency,
        frequency
    FROM (
        SELECT 
            customer_id,
            COUNT(distinct invoice) as frequency 
        FROM 
            tableretail 
        WHERE 
            EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011 
        GROUP BY 
            customer_id
    )
)
SELECT 
    customer_id, 
    recency,
    frequency
FROM 
    customers_query
ORDER BY 
    customer_id;

--

WITH customers_query AS (
    SELECT 
        customer_id,
        recency,
        frequency
    FROM (
        SELECT 
            customer_id,
            CEIL(months_between(SYSDATE,MAX(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) OVER(Partition by customer_id))) as recency,
            COUNT(distinct invoice) as frequency 
        FROM 
            tableretail 
        WHERE 
            EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011 
        GROUP BY 
            customer_id
    ) subquery_alias
)
SELECT 
    customer_id, 
    recency,
    frequency
FROM 
    customers_query
ORDER BY 
    customer_id;
    
    
    WITH customers_query AS (
    SELECT 
        customer_id,
        recency,
        frequency
    FROM (
        SELECT 
            customer_id,
            CEIL(months_between(SYSDATE, MAX(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')))) as recency,
            COUNT(distinct invoice) as frequency 
        FROM 
            tableretail 
        WHERE 
            EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011 
        GROUP BY 
            customer_id
    )
)
SELECT 
    customer_id, 
    recency,
    frequency
FROM 
    customers_query
ORDER BY 
    customer_id;
    
    
WITH customers_query AS (
    SELECT 
        customer_id,
        recency,
        frequency,
        monetary
    FROM (
        SELECT 
            customer_id,
            CEIL(months_between(SYSDATE, MAX(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')))) as recency,
            COUNT(distinct invoice) as frequency,
            ROUND(SUM(price * quantity),2) as monetary
        FROM 
            tableretail 
        WHERE 
            EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011 
        GROUP BY 
            customer_id
    ) subquery_alias
)
SELECT 
    customer_id, 
    recency,
    frequency,
    monetary,
    ntile(5) over(order by recency desc) as r_score,
    ntile(5) over(order by frequency) as f_score,
    ntile(5) over(order by monetary) as m_score,
    (ntile(5) over(order by frequency)+ntile(5) over(order by monetary))/2 as fm_score,
    CASE
          WHEN  (r_score= 5 AND  fm_score= 5) OR 
                     (r_score= 5 AND  fm_score= 4) OR
                     (r_score= 4 AND  fm_score= 5) THEN 'Champions'
                     
          WHEN (r_score = 5 AND fm_score = 3) OR
                    (r_score = 4 AND fm_score = 4) OR
                    (r_score = 3 AND fm_score = 5) OR
                    (r_score = 3 AND fm_score = 4) THEN 'Loyal Customers'
                    
          WHEN (r_score = 5 AND fm_score = 2) OR
                    (r_score = 4 AND fm_score = 2) OR
                    (r_score = 3 AND fm_score = 3) OR
                    (r_score = 4 AND fm_score = 3) THEN 'Potential Loyalists'
                    
          WHEN (r_score = 5 AND fm_score = 1) THEN 'Recent Customers'
          
          WHEN (r_score = 4 AND fm_score = 1) OR
                    (r_score = 3 AND fm_score = 1) THEN 'Promising'
                    
          WHEN (r_score = 3 AND fm_score = 2) OR
                    (r_score = 2 AND fm_score = 3) OR
                    (r_score = 2 AND fm_score = 2) THEN 'Customers Needing Attention'
                    
          WHEN (r_score = 2 AND fm_score = 5) OR
                     (r_score = 2 AND fm_score = 4) OR
                     (r_score = 1 AND fm_score = 3) THEN 'At Risk'
                    
          WHEN (r_score = 1 AND fm_score = 5) OR
                     (r_score = 1 AND fm_score = 4) THEN 'Can not lose them'
                    
          WHEN (r_score = 1 AND fm_score = 2) THEN 'Hibernating'
          
          WHEN (r_score = 1 AND fm_score = 1) THEN 'Lost'
          
          ELSE 'Unclassified'
        END AS customer_segment
    
FROM 
    customers_query
ORDER BY 
    customer_id;



WITH customers_query AS (
    SELECT 
        customer_id,
        recency,
        frequency,
        monetary,
        ntile(5) over(order by recency desc) as r_score,
        ntile(5) over(order by frequency) as f_score,
        ntile(5) over(order by monetary) as m_score,
        ceil((ntile(5) over(order by frequency)+ntile(5) over(order by monetary))/2) as fm_score
    FROM (
        SELECT 
            customer_id,
            CEIL(months_between(SYSDATE, MAX(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')))) as recency,
            COUNT(distinct invoice) as frequency,
            ROUND(SUM(price * quantity),2) as monetary
        FROM 
            tableretail 
        WHERE 
            EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011 
        GROUP BY 
            customer_id
    ) subquery_alias
)
SELECT 
    customer_id, 
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    fm_score,
    CASE
        WHEN (r_score = 5 AND fm_score = 5) OR 
             (r_score = 5 AND fm_score = 4) OR
             (r_score = 4 AND fm_score = 5) THEN 'Champions'
             
        WHEN (r_score = 5 AND fm_score = 3) OR
             (r_score = 4 AND fm_score = 4) OR
             (r_score = 3 AND fm_score = 5) OR
             (r_score = 3 AND fm_score = 4) THEN 'Loyal Customers'
             
        WHEN (r_score = 5 AND fm_score = 2) OR
             (r_score = 4 AND fm_score = 2) OR
             (r_score = 3 AND fm_score = 3) OR
             (r_score = 4 AND fm_score = 3) THEN 'Potential Loyalists'
             
        WHEN (r_score = 5 AND fm_score = 1) THEN 'Recent Customers'
        
        WHEN (r_score = 4 AND fm_score = 1) OR
             (r_score = 3 AND fm_score = 1) THEN 'Promising'
             
        WHEN (r_score = 3 AND fm_score = 2) OR
             (r_score = 2 AND fm_score = 3) OR
             (r_score = 2 AND fm_score = 2) THEN 'Customers Needing Attention'
             
        WHEN (r_score = 2 AND fm_score = 5) OR
             (r_score = 2 AND fm_score = 4) OR
             (r_score = 1 AND fm_score = 3) THEN 'At Risk'
             
        WHEN (r_score = 1 AND fm_score = 5) OR
             (r_score = 1 AND fm_score = 4) THEN 'Can not lose them'
             
        WHEN (r_score = 1 AND fm_score = 2) THEN 'Hibernating'
        
        WHEN (r_score = 1 AND fm_score = 1) THEN 'Lost'
        
        ELSE 'Unclassified'
    END AS customer_segment
FROM 
    customers_query
ORDER BY 
    customer_id;

