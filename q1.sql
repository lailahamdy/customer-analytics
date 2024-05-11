select * from tableretail

/*Top Selling Products
Monthly Revenue Trend
Customer Spending Behavior
Geographical Analysis
Average Order Value (AOV)
Returning Customers Analysis
Product Performance Over Time
Average Purchase Frequency
Price Distribution Analysis
Largest Orders by Quantity*/

--Top Selling Products

--overall
SELECT stockcode, total_quantity
FROM (
    SELECT stockcode, SUM(quantity) AS total_quantity, RANK() OVER (ORDER BY SUM(quantity) DESC) AS quantity_rank
    FROM tableretail
    GROUP BY stockcode
) WHERE quantity_rank <= 5;

--top 5 in each year
SELECT stockcode, total_quantity, invoice_year
FROM (
    SELECT stockcode, 
           SUM(quantity) AS total_quantity, 
           EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_year,
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) ORDER BY SUM(quantity) DESC) AS quantity_rank
    FROM tableretail
    GROUP BY stockcode, EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))
) WHERE quantity_rank <= 5;

SELECT DISTINCT EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_year
FROM tableretail;

SELECT DISTINCT EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_month,
                EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS invoice_year
FROM tableretail
order by invoice_year, invoice_month; --we have data from 12-2010 and the entirity of 2011


SELECT STOCKCODE, SUM(QUANTITY) AS Total_Quantity_Sold
FROM tableretail
GROUP BY STOCKCODE
ORDER BY Total_Quantity_Sold DESC
LIMIT 5;

select * from tableretail

SELECT Average_Order_Value,
       invoice_rank
FROM (
    SELECT INVOICE,
           AVG(PRICE * QUANTITY) AS Average_Order_Value,
           RANK() OVER (ORDER BY AVG(PRICE * QUANTITY) DESC) AS invoice_rank
    FROM tableretail
    GROUP BY INVOICE
) WHERE invoice_rank <= 5;

SELECT AVG(PRICE * QUANTITY) AS Average_Order_Value
FROM tableretail;

--Average Order Value & Average Revenue per user
SELECT 
    SUM(revenue) AS Total_Revenue,
    COUNT(DISTINCT invoice) AS Number_of_Orders,
    SUM(revenue) / COUNT(DISTINCT invoice) AS Average_Order_Value
FROM (
    SELECT 
        INVOICE,
        SUM(PRICE * QUANTITY) AS revenue
    FROM tableretail
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
    GROUP BY customer_id
); 


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



--Top 5 Customers based on total spendings
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

--Month to month & quarter to quarter revenue change
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

---number of unique customers per month
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
    
---customer growth rate    
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

