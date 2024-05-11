---Laila Hamdy, Case Study Queries

---------q1 queries
--1 Top 5 selling products
--overall
SELECT stockcode, total_quantity
FROM (
    SELECT stockcode, SUM(quantity) AS total_quantity, RANK() OVER (ORDER BY SUM(quantity) DESC) AS quantity_rank
    FROM tableretail
    GROUP BY stockcode
) WHERE quantity_rank <= 5;

--top 5 stocks (products) in each year (12/2010 & entirity of 2011)
SELECT stockcode, total_quantity, invoice_year
FROM (
    SELECT stockcode, 
           SUM(quantity) AS total_quantity, 
           EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_year,
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) ORDER BY SUM(quantity) DESC) AS quantity_rank
    FROM tableretail
    GROUP BY stockcode, EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))
) WHERE quantity_rank <= 5;

--2 Average Order Value (AOV) & Average Revenue per User (ARPU) annualy (i.e for 2011)
SELECT 
    SUM(revenue) AS Total_Revenue,
    COUNT(DISTINCT invoice) AS Number_of_Orders,
    SUM(revenue) / COUNT(DISTINCT invoice) AS Average_Order_Value
FROM (
    SELECT 
        INVOICE,
        SUM(PRICE * QUANTITY) AS revenue
    FROM tableretail
    WHERE EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011
    GROUP BY INVOICE 
);

SELECT 
    SUM(revenue) AS Total_Revenue,
    COUNT(DISTINCT customer_id) AS Number_of_Users,
    SUM(revenue) / COUNT(DISTINCT customer_id) AS ARPU
FROM (
    SELECT 
        customer_id,
        SUM(PRICE * QUANTITY) AS revenue
    FROM tableretail
    WHERE EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011
    GROUP BY customer_id
);

--3 Top 5 Customers based on total spending
SELECT 
    CUSTOMER_ID,
    Total_Purchases,
    Total_Spending
FROM (
    SELECT 
        CUSTOMER_ID,
        COUNT(DISTINCT INVOICE) AS Total_Purchases,
        SUM(PRICE * QUANTITY) AS Total_Spending,
        RANK() OVER (ORDER BY SUM(PRICE * QUANTITY) DESC) AS Customer_Rank
    FROM tableretail
    GROUP BY CUSTOMER_ID
) WHERE Customer_Rank<=5;

--4 Month to month & quarter to quarter revenue change for 2011
WITH revenue_by_month AS (
    SELECT 
        EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_year,
        EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_month,
        SUM(PRICE * QUANTITY) AS monthly_revenue
    FROM tableretail
    GROUP BY EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')),
             EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))
)
SELECT 
    invoice_month, invoice_year, monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY invoice_year, invoice_month) AS previous_month_revenue,
    round((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY invoice_year, invoice_month)) /  LAG(monthly_revenue) OVER (ORDER BY invoice_year, invoice_month) *100,2) AS revenue_change
FROM revenue_by_month
ORDER BY invoice_year, invoice_month;


WITH revenue_by_quarter AS (
    SELECT 
        EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_year,
        CEIL(EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) / 3.0) AS invoice_quarter,
        SUM(PRICE * QUANTITY) AS quarterly_revenue
    FROM tableretail
    WHERE EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) = 2011
    GROUP BY EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')),
             CEIL(EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) / 3.0)
)
SELECT 
    invoice_year, 
    invoice_quarter, 
    quarterly_revenue,
    LAG(quarterly_revenue) OVER (ORDER BY invoice_year, invoice_quarter) AS previous_quarter_revenue,
    ROUND((quarterly_revenue - LAG(quarterly_revenue) OVER (ORDER BY invoice_year, invoice_quarter)) /  LAG(quarterly_revenue) OVER (ORDER BY invoice_year, invoice_quarter) * 100, 2) AS revenue_change
FROM revenue_by_quarter
ORDER BY invoice_year, invoice_quarter;

--5 Number of unique customers per month
SELECT 
    EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_year,
    EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_month,
    COUNT(DISTINCT customer_id) AS unique_customers_per_month
FROM 
    tableretail
GROUP BY 
    EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')),
    EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))
ORDER BY 
    invoice_year, 
    invoice_month;
    
--6 Customer growth rate    
WITH customer_counts AS (
    SELECT 
        EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_year,
        EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_month,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM 
        tableretail
    GROUP BY 
        EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')),
        EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))
)
SELECT 
    invoice_year,
    invoice_month,
    num_customers,
    LAG(num_customers) OVER (ORDER BY invoice_year, invoice_month) AS prev_num_customers,
    ROUND(((num_customers - LAG(num_customers) OVER (ORDER BY invoice_year, invoice_month)) / LAG(num_customers) OVER (ORDER BY invoice_year, invoice_month)) * 100, 2) AS customer_growth_rate
FROM 
    customer_counts
ORDER BY 
    invoice_year, 
    invoice_month;    

---------q2 query
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
        
        ELSE 'Other'
    END AS customer_segment
FROM 
    customers_query
ORDER BY 
    customer_id;

---------q3.a query
WITH ranked_dates AS (
    SELECT cust_id,
           calendar_dt,
           ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY calendar_dt) AS rn
    FROM customerdata
)
SELECT cust_id, 
       MAX(consecutive_days) AS max_consecutive_days
FROM (
    SELECT cust_id, 
           calendar_dt, 
           COUNT(*) OVER (PARTITION BY cust_id, calendar_dt - rn) AS consecutive_days
    FROM ranked_dates
)
GROUP BY cust_id;

---------q3.b query
WITH CustomerCumulativeSum AS (
    SELECT
        CUST_ID,
        CALENDAR_DT,
        AMT_LE,
        SUM(AMT_LE) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) AS cumulative_sum
    FROM
        customerdata
), THRESH AS (
    SELECT
        CUST_ID,
        cumulative_sum,
        COUNT(*) OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) AS transc_to_reach_threshold,
        ROW_NUMBER() OVER (PARTITION BY CUST_ID ORDER BY CALENDAR_DT) AS row_num
    FROM
        CustomerCumulativeSum
), MinThreshold AS (
    SELECT
        CUST_ID,
        MIN(row_num) AS min_transc_to_reach_threshold
    FROM
        THRESH
    WHERE
        cumulative_sum >= 250
    GROUP BY
        CUST_ID
)
SELECT 
    ROUND(AVG(min_transc_to_reach_threshold),2) AS avg_transc_to_reach_threshold
FROM 
    MinThreshold;
