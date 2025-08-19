-- ===========================================================================
-- SQL PROJECT: Retail Sales Analysis
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- STEP 0: Database and Table Setup
-- ---------------------------------------------------------------------------

-- Create the database and use it
CREATE DATABASE sql_project_1;
USE sql_project_1;

-- Create the retail_sale table
CREATE TABLE retail_sale (
    transactions_id INT PRIMARY KEY,
    sale_date DATE,
    sale_time TIME,
    customer_id INT,
    gender VARCHAR(20),
    age INT,
    category VARCHAR(20),
    quantiy INT,
    price_per_unit FLOAT,
    cogs FLOAT,
    total_sale FLOAT 
);

-- Data Cleaning: Remove NULL records
DELETE FROM retail_sale
WHERE sale_date IS NULL 
   OR transactions_id IS NULL
   OR sale_time IS NULL
   OR customer_id IS NULL
   OR gender IS NULL
   OR age IS NULL
   OR category IS NULL
   OR quantiy IS NULL
   OR price_per_unit IS NULL
   OR cogs IS NULL
   OR total_sale IS NULL;

SET SQL_SAFE_UPDATES = 0;

-- ===========================================================================
-- STEP 1: Business Questions
-- ===========================================================================

-- 1. Find the Peak Sale Hour
SELECT HOUR(sale_time) AS hourly, SUM(total_sale) AS sale
FROM retail_sale
GROUP BY hourly
ORDER BY sale DESC
LIMIT 1;

-- 2. Find the Profit by Category
SELECT category, SUM(total_sale - cogs) AS total_profit
FROM retail_sale
GROUP BY category
ORDER BY total_profit DESC;

-- 3. Total Profit in November 2022
SELECT category, SUM(total_sale - cogs) AS total_profit
FROM retail_sale
WHERE sale_date LIKE '2022-11-%'
GROUP BY category
ORDER BY total_profit DESC;

-- 4. Count of Loyal Customers (who bought all 3 categories)
SELECT COUNT(*) AS loyal_customer
FROM (
    SELECT customer_id
    FROM retail_sale
    GROUP BY customer_id  
    HAVING COUNT(DISTINCT category) = 3
) AS t;

-- 5. For each customer, calculate: Last purchase date (Recency), Number of purchases (Frequency), Total amount spent (Monetary)
SELECT customer_id, 
       MAX(sale_date) AS last_purchase_date,
       COUNT(*) AS total_purchase,
       SUM(total_sale) AS total_spent
FROM retail_sale
GROUP BY customer_id;

-- 6. Customers who purchased in October but not in November
SELECT DISTINCT customer_id 
FROM retail_sale
WHERE sale_date LIKE '2022-10-%'
AND customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM retail_sale
    WHERE sale_date LIKE '2022-11-%'
);

-- 7. Check if Sales are Improving Month-over-Month
WITH ct AS (
    SELECT DATE_FORMAT(sale_date, '%Y-%M') AS monthly,
           SUM(total_sale) AS monthly_sale
    FROM retail_sale
    GROUP BY monthly
)
SELECT *
FROM (
    SELECT monthly, monthly_sale,
           LAG(monthly_sale) OVER(ORDER BY monthly) AS prev_month_sale
    FROM ct
) AS t
WHERE monthly_sale > prev_month_sale;

-- 8. Top Customers by Category
SELECT customer_id, category, total
FROM (
    SELECT customer_id, category,
           SUM(total_sale) AS total,
           RANK() OVER(PARTITION BY category ORDER BY SUM(total_sale) DESC) AS rn
    FROM retail_sale
    GROUP BY customer_id, category
) AS t
WHERE rn = 1;

-- 9. Identify Repeat Customers (purchased from multiple categories)
SELECT customer_id
FROM retail_sale
GROUP BY customer_id
HAVING COUNT(DISTINCT category) > 1;

-- 10. Find Pairs of Categories Bought Together in the Same Transaction
SELECT a.category, b.category, COUNT(*) AS times_bought_together
FROM retail_sale a 
JOIN retail_sale b 
  ON a.category > b.category
 AND a.transactions_id = b.transactions_id
GROUP BY a.category, b.category
ORDER BY times_bought_together DESC;

-- 11. Customer Lifetime Value (CLV) Approximation - How much total revenue (or profit) has each customer generated over their lifetime with the business, total orders,first and last order date
SELECT customer_id, 
       SUM(total_sale) AS total_revenue,
       COUNT(DISTINCT transactions_id) AS total_orders,
       MIN(sale_date) AS first_order,
       MAX(sale_date) AS last_order
FROM retail_sale
GROUP BY customer_id
ORDER BY total_revenue DESC;

-- 12.Profit Margin Analysis . Business use: See which products/categories are most profitable
SELECT category, 
       ROUND(SUM(total_sale),2) AS total_sales,
       ROUND(SUM(cogs),2) AS total_cost,
       ROUND(SUM(total_sale) - SUM(cogs),2) AS profit, 
       ROUND((SUM(total_sale) - SUM(cogs)) / SUM(total_sale) * 100 ,2) AS profit_percentage
FROM retail_sale
GROUP BY category
ORDER BY profit_percentage DESC;

-- 13. Cohort Analysis (Customer Retention by Month) 👉 Business use: How many new customers stay in later months?
WITH first_month AS (
    SELECT customer_id, MIN(DATE_FORMAT(sale_date,'%Y-%M')) AS cohort_month
    FROM retail_sale
    GROUP BY customer_id
),
monthly_customers AS (
    SELECT DISTINCT customer_id, DATE_FORMAT(sale_date,'%Y-%M') AS purchased_months
    FROM retail_sale
)
SELECT cohort_month, purchased_months, COUNT(customer_id) AS total_active_customers
FROM first_month 
JOIN monthly_customers USING(customer_id) 
GROUP BY cohort_month, purchased_months
ORDER BY cohort_month, purchased_months;

-- 14. High-Value vs Low-Value Customers (Top 10% vs Bottom 10%)
WITH ranked AS (
    SELECT customer_id, SUM(total_sale) AS total_spent,
           NTILE(10) OVER(ORDER BY SUM(total_sale) DESC) AS buc 
    FROM retail_sale
    GROUP BY customer_id
)
SELECT CASE
           WHEN buc = 1 THEN 'Top 10%'
           WHEN buc = 10 THEN 'Bottom 10%'
       END AS label,
       COUNT(customer_id) AS total_customers,
       ROUND(AVG(total_spent),2) AS avg_spent
FROM ranked
WHERE buc IN (1,10)
GROUP BY label;

-- 15. Divide Customers into Tiers (High, Medium, Low Value)
WITH divd AS (
    SELECT customer_id, SUM(total_sale) AS total_spent,
           NTILE(5) OVER(ORDER BY SUM(total_sale) DESC) AS buc 
    FROM retail_sale
    GROUP BY customer_id
)
SELECT CASE 
           WHEN buc = 1 THEN 'Top 20%'
           WHEN buc IN (2,3,4) THEN 'Middle 60%'
           WHEN buc = 5 THEN 'Bottom 20%'
       END AS tier,
       COUNT(*) AS total_customers,
       ROUND(AVG(total_spent),2) AS avgSpent
FROM divd 
GROUP BY tier;

-- 16. Monthly Sales Trend by Category (with Growth %) -- For each category and each month, calculate:Total sales , Month-over-month growth (%) compared to previous month

WITH ct AS (
    SELECT category, MONTH(sale_date) AS monthh, SUM(total_sale) AS total_sales
    FROM retail_sale
    GROUP BY category, MONTH(sale_date)
)
SELECT category, monthh, total_sales,
       LAG(total_sales) OVER(PARTITION BY category ORDER BY monthh) AS prev_month,
       total_sales - LAG(total_sales) OVER(PARTITION BY category ORDER BY monthh) AS difference,
       IFNULL(ROUND((total_sales - LAG(total_sales) OVER(PARTITION BY category ORDER BY monthh)) / 
                    LAG(total_sales) OVER(PARTITION BY category ORDER BY monthh) * 100,2),0) AS growth_percentage
FROM ct;

-- 17. Repeat Customers vs One-Time Customers
WITH cust AS (
    SELECT customer_id,
           CASE
               WHEN COUNT(transactions_id) = 1 THEN 'One-time'
               WHEN COUNT(transactions_id) > 1 THEN 'Repeated'
           END AS customer_type,
           SUM(total_sale) AS total_spent_per_customer
    FROM retail_sale
    GROUP BY customer_id
)
SELECT customer_type, COUNT(*) AS totalcount, AVG(total_spent_per_customer) AS avg_spending_per_type
FROM cust
GROUP BY customer_type;

-- 18. Top 5 Category Pairs Frequently Bought Together
SELECT a.category, b.category, COUNT(*) 
FROM retail_sale a 
JOIN retail_sale b 
  ON a.transactions_id = b.transactions_id
 AND a.category > b.category
GROUP BY a.category, b.category 
ORDER BY COUNT(*) DESC
LIMIT 5;

-- 19. Find the Peak Sales Hour for Each Category
WITH hourly AS (
    SELECT HOUR(sale_time) AS hr, category, SUM(total_sale) AS total_sales,
           RANK() OVER(PARTITION BY category ORDER BY SUM(total_sale) DESC) AS rn
    FROM retail_sale
    GROUP BY hr, category
) 
SELECT hr, category, total_sales
FROM hourly
WHERE rn = 1;

-- 20. Which gender spends more on average per transaction in each category?
SELECT gender, category, avgsales
FROM (
    SELECT gender, category, AVG(total_sale) AS avgsales,
           RANK() OVER(PARTITION BY category ORDER BY AVG(total_sale) DESC) AS rn 
    FROM retail_sale
    GROUP BY gender, category
) AS t
WHERE rn = 1;

-- 21. Discount Effectiveness (Top Categories Where Discounts Boosted Sales) 
-- If cogs < total_sale, assume discount = total_sale - cogs.
-- Find the top 3 categories where discounts generated the highest increase in sales.

SELECT category, 	
       SUM(total_sale - cogs) AS discount,
       ROUND(SUM(total_sale - cogs) / SUM(total_sale) * 100, 2) AS discount_percentage
FROM retail_sale
WHERE cogs < total_sale
GROUP BY category
ORDER BY discount DESC
LIMIT 3;

-- 22. Customer Retention Rate (Month-over-Month) - find the percentage of customers who made at least one purchase in the previous month and returned in the current month
WITH monthly_customers AS (
    SELECT DISTINCT customer_id, DATE_FORMAT(sale_date, '%Y-%m-01') AS monthh
    FROM retail_sale
),
retention AS (
    SELECT c1.monthh AS curr_month,
           COUNT(DISTINCT c1.customer_id) AS retained_customers,
           COUNT(DISTINCT c2.customer_id) AS prev_customers
    FROM monthly_customers c1
    JOIN monthly_customers c2
      ON c1.customer_id = c2.customer_id
     AND c1.monthh = DATE_ADD(c2.monthh, INTERVAL 1 MONTH)
    GROUP BY c1.monthh
)
SELECT curr_month, retained_customers, prev_customers,
       ROUND(retained_customers / NULLIF(prev_customers, 0) * 100, 2) AS retention_percentage
FROM retention
ORDER BY curr_month;

-- 23. Top 5 Category Pairs with Transaction Percentage
WITH category_pair AS (
    SELECT a.category AS cat1, b.category AS cat2,
           COUNT(*) AS together_bought_pairCount
    FROM retail_sale a 
    JOIN retail_sale b 
      ON a.transactions_id = b.transactions_id
     AND a.category < b.category
    GROUP BY a.category, b.category
),
transactions AS (
    SELECT COUNT(DISTINCT transactions_id) AS total_tranx
    FROM retail_sale
)
SELECT cat1, cat2, together_bought_pairCount,
       ROUND(together_bought_pairCount / total_tranx * 100, 2) AS percentage
FROM category_pair, transactions
ORDER BY together_bought_pairCount DESC
LIMIT 5;

-- 24. Profit Contribution % (Share of Overall Profit by Category)
WITH cat_wise AS (
    SELECT category, SUM(total_sale - cogs) AS catg_sum
    FROM retail_sale
    GROUP BY category
)
SELECT category, 
       ROUND(catg_sum / (SELECT SUM(total_sale - cogs) FROM retail_sale) * 100,2) AS percentage
FROM cat_wise
ORDER BY percentage DESC;

-- 25. Profit Margin % (Within Each Category)
WITH cat_wise AS (
    SELECT category, SUM(total_sale) AS sale_total_per_cat, SUM(cogs) AS total_cogs 
    FROM retail_sale
    GROUP BY category
)
SELECT category, 
       ROUND((sale_total_per_cat - total_cogs) / sale_total_per_cat * 100 ,2) AS profit_margin
FROM cat_wise
ORDER BY profit_margin DESC;
