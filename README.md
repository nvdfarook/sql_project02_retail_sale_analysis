# sql_project02_retail_sale_analysis

# 🛒 Retail Sale Analysis using SQL  

This project dives deep into **advanced real-world retail business problems** and solves them using SQL.  
I worked with a `retail_sale` dataset to uncover **customer behavior, sales performance, and profitability insights** through **25 case-study-driven SQL queries**.  

---

## 📊 Project Objectives
- Solve **25 advanced real-world SQL problems** inspired by business case studies  
- Strengthen SQL skills with hands-on analysis of sales & customer data  
- Translate business challenges into SQL queries and insights  
- Build a **portfolio-ready project** for Data Analytics and Business Intelligence  

---

## 📂 Dataset Used
The dataset `retail_sale` contains transactional-level retail sales information.  
Key columns include:  

- `transaction_id` – Unique ID for each purchase  
- `customer_id` – Unique customer identifier  
- `sale_date` – Date of the transaction  
- `category` – Product category purchased  
- `cogs` – Cost of goods sold  
- `total_sale` – Total sales revenue from the transaction  
- `gender` – Gender of the customer  
- `age` – Age of the customer  

---

## ❓ Advanced Business Problems Solved
Below are the **25 real-world business case studies** I answered using SQL:  

1. **Top Categories by Revenue** – Identify which product categories generate the highest sales revenue.  
2. **Top Customers by Spending** – Find customers who contributed the most revenue to the business.  
3. **Monthly Sales Trend** – Track how overall sales change month by month.  
4. **Peak Sales by Hour/Shift** – Analyze which hours or shifts (morning, afternoon, evening) see maximum sales.  
5. **Age Group Contribution** – Segment customers by age groups and calculate their contribution to revenue.  
6. **Gender-wise Sales Comparison** – Compare total sales between male and female customers.  
7. **Repeat Customer Analysis** – Calculate what % of customers made repeat purchases.  
8. **Customer Retention Rate** – Find the % of customers who purchased in the previous month and returned in the current month.  
9. **Average Revenue per Customer** – Measure average spend per customer to gauge customer value.  
10. **Category-wise Profit Margin %** – For each product category, calculate how efficiently it converts sales into profit.  
11. **Category Contribution to Total Profit %** – Determine how much each category contributes to overall business profit.  
12. **Monthly Profit Growth Trend** – Track how profit changes month over month.  
13. **High-Value Transactions** – Identify transactions where profit exceeded a defined threshold.  
14. **Customer Lifetime Value (Basic)** – Calculate total revenue contributed by each customer across all purchases.  
15. **Best Month for Sales** – Find which month generated the highest revenue.  
16. **Worst Performing Category** – Identify the category with the lowest sales and profit contribution.  
17. **Average Basket Size (Revenue per Transaction)** – Calculate the average sales value per transaction.  
18. **Discount Effectiveness** – Estimate the impact of discounts by comparing sales vs cost (when total_sale > cogs).  
19. **New vs Returning Customers (Monthly)** – Compare the count of new customers vs repeat customers each month.  
20. **Churn Analysis** – Identify customers who purchased in the past but did not return in the most recent month.  
21. **Sales Contribution by Department** – Break down sales based on different departments or product groups.  
22. **Top 5 Cities/Regions by Sales (if data available)** – Rank regions contributing the most to revenue.  
23. **Customer Purchase Frequency** – Find customers with the highest number of repeat transactions.  
24. **Sales Variance (Month over Month)** – Measure % increase or decrease in sales compared to the previous month.  
25. **Customer Segmentation (RFM Basics)** – Categorize customers into groups (High-value, Medium, Low) based on Recency, Frequency, and Monetary value.  

---

## 🛠 SQL Concepts Covered
- **Data Cleaning & Formatting** (`DATE_FORMAT`, handling NULLs)  
- **Aggregation** (`SUM`, `AVG`, `COUNT`, `GROUP BY`)  
- **Joins** (self-joins for retention & repeat customer analysis)  
- **Window Functions** (`RANK`, `DENSE_RANK`, `ROW_NUMBER`, `LAG`, `LEAD`)  
- **Subqueries & CTEs** for advanced analysis  
- **Conditional Logic** (`CASE WHEN`)  
- **Retention, Churn & RFM Analysis** (advanced customer analytics)  

---

## 📌 Sample Query  

**Customer Retention Rate**  
```sql
WITH monthly_customers AS (
    SELECT DISTINCT 
           customer_id,
           DATE_FORMAT(sale_date, '%Y-%m-01') AS monthh
    FROM retail_sale
),
retention AS (
    SELECT 
        c1.monthh AS curr_month,
        COUNT(DISTINCT c1.customer_id) AS retained_customers,
        COUNT(DISTINCT c2.customer_id) AS prev_customers
    FROM monthly_customers c1
    JOIN monthly_customers c2
      ON c1.customer_id = c2.customer_id
     AND c1.monthh = DATE_ADD(c2.monthh, INTERVAL 1 MONTH)
    GROUP BY c1.monthh
)
SELECT 
    curr_month,
    retained_customers,
    prev_customers,
    ROUND(retained_customers / NULLIF(prev_customers, 0) * 100, 2) AS retention_percentage
FROM retention
ORDER BY curr_month;
