Create database sql_project_DB; 
Use sql_project_DB;

--Q1)Find monthly sales?
select year(sale_date) as year,
month(sale_date) as month,
sum(total_sale) as monthly_sales
From Retail_sales
Group by year(sale_date),month(sale_date)
order by year,month ;

--Q2)Identify repeated customers?
SELECT customer_id,
COUNT(*) AS purchase_count
FROM retail_sales
GROUP BY customer_id
HAVING COUNT(*) > 1
order by Customer_id;

--Q3)Calculate cumulative (running) total sales by date.?
SELECT sale_date,
SUM(total_sale) AS daily_sales,
SUM(SUM(total_sale)) OVER (
ORDER BY sale_date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM retail_sales
GROUP BY sale_date
ORDER BY sale_date;

--Q4)Find sales distribution by age group (18–25, 26–35, 36–50, 50+).
SELECT 
CASE 
WHEN age BETWEEN 18 AND 25 THEN '18-25'
WHEN age BETWEEN 26 AND 35 THEN '26-35'
WHEN age BETWEEN 36 AND 50 THEN '36-50'
ELSE '50+'
END AS age_group,
COUNT(*) AS total_transactions,
SUM(total_sale) AS total_sales,
AVG(total_sale) AS avg_sales
FROM retail_sales
GROUP BY 
CASE 
WHEN age BETWEEN 18 AND 25 THEN '18-25'
WHEN age BETWEEN 26 AND 35 THEN '26-35'
WHEN age BETWEEN 36 AND 50 THEN '36-50'
ELSE '50+'
END
ORDER BY age_group;

--Q5)Rank customers based on total purchase amount?
SELECT customer_id,
SUM(total_sale) AS total_spent,
RANK() OVER (ORDER BY SUM(total_sale) DESC) AS customer_rank
FROM retail_sales
GROUP BY customer_id;

--Q6)Find percentage contribution of each category to total sales?
SELECT category,
SUM(total_sale) AS category_sales,
ROUND(
100.0 * SUM(total_sale) / SUM(SUM(total_sale)) OVER (),2) AS percentage_contribution
FROM retail_sales
GROUP BY category
ORDER BY percentage_contribution DESC;

--Q7)Find month-over-month sales growth?
WITH monthly_sales AS (
SELECT FORMAT(sale_date, 'yyyy-MM') AS month,
SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY FORMAT(sale_date, 'yyyy-MM'))
SELECT month,total_sales,
LAG(total_sales) OVER (ORDER BY month) AS previous_month_sales,
ROUND((total_sales - LAG(total_sales) OVER (ORDER BY month)) * 100.0 /
LAG(total_sales) OVER (ORDER BY month),2) AS mom_growth_percentage
FROM monthly_sales
ORDER BY month;

--Q8)Detect customers who have not purchased from the last 6 months? 
SELECT customer_id,
MAX(sale_date) AS last_purchase_date
FROM retail_sales
GROUP BY customer_id
HAVING MAX(sale_date) < DATEADD(MONTH, -6, GETDATE())
order by Customer_id;

--9)Calculate Customer Lifetime value?
SELECT customer_id,
SUM(total_sale) AS customer_lifetime_value
FROM retail_sales
GROUP BY customer_id
ORDER BY customer_lifetime_value DESC;

--10)Perform RFM analysis?
WITH rfm_base AS (
SELECT customer_id,
MAX(sale_date) AS last_purchase_date,
COUNT(*) AS frequency,
SUM(total_sale) AS monetary,
DATEDIFF(DAY, MAX(sale_date), GETDATE()) AS recency
FROM retail_sales
GROUP BY customer_id)
SELECT *
FROM rfm_base;

--11)Find seasonal sales trend?
SELECT YEAR(sale_date) AS year,
MONTH(sale_date) AS month,
SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY YEAR(sale_date), MONTH(sale_date)
ORDER BY year, month;

--12)Identify peak sales hour?
SELECT DATEPART(HOUR, sale_time) AS sales_hour,
SUM(total_sale) AS total_sales,
COUNT(*) AS total_transactions
FROM retail_sales
GROUP BY DATEPART(HOUR, sale_time)
ORDER BY total_sales DESC;

--13)Calculate year-over-year growth?
WITH yearly_sales AS (
SELECT YEAR(sale_date) AS year,
SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY YEAR(sale_date))
SELECT year,total_sales,
LAG(total_sales) OVER (ORDER BY year) AS previous_year_sales,
ROUND((total_sales - LAG(total_sales) OVER (ORDER BY year)) * 100.0 /
LAG(total_sales) OVER (ORDER BY year),2) AS yoy_growth_percentage
FROM yearly_sales
ORDER BY year;

--14)Segment customers based on spending behaviour(Low,Medium,High)?
WITH customer_spending AS (
SELECT customer_id,
SUM(total_sale) AS total_spent
FROM retail_sales
GROUP BY customer_id)
SELECT customer_id,total_spent,
CASE 
WHEN total_spent < 5000 THEN 'Low'
WHEN total_spent BETWEEN 5000 AND 20000 THEN 'Medium'
ELSE 'High'
END AS spending_segment
FROM customer_spending
ORDER BY total_spent DESC;

--15)Calculate rolling 7 day average sales?
WITH daily_sales AS (
SELECT 
CAST(sale_date AS DATE) AS sale_date,
SUM(total_sale) AS daily_total
FROM retail_sales
GROUP BY CAST(sale_date AS DATE))
SELECT sale_date,daily_total,
ROUND(
AVG(daily_total) OVER (
ORDER BY sale_date
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS rolling_7_day_avg
FROM daily_sales
ORDER BY sale_date;

--16)Find top 5 customers per month based on revenue?
WITH monthly_customer_sales AS (
SELECT 
FORMAT(sale_date, 'yyyy-MM') AS month,customer_id,
SUM(total_sale) AS total_revenue
FROM retail_sales
GROUP BY FORMAT(sale_date, 'yyyy-MM'), customer_id),
ranked_customers AS (
SELECT *,
RANK() OVER (PARTITION BY month ORDER BY total_revenue DESC) AS rank_no
FROM monthly_customer_sales)
SELECT *
FROM ranked_customers
WHERE rank_no <= 5
ORDER BY month, rank_no;

--Q17)Find the Find the longest gap between two purchases for each customer?
WITH customer_gaps AS (
SELECT 
customer_id,sale_date,
LAG(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date) AS previous_purchase_date
FROM retail_sales)
SELECT customer_id,
MAX(DATEDIFF(DAY, previous_purchase_date, sale_date)) AS longest_gap_days
FROM customer_gaps
WHERE previous_purchase_date IS NOT NULL
GROUP BY customer_id
ORDER BY longest_gap_days DESC;

--18)Identify first purchase date and last purchase date per customer?
SELECT customer_id,
MIN(sale_date) AS first_purchase_date,
MAX(sale_date) AS last_purchase_date
FROM retail_sales
GROUP BY customer_id
ORDER BY customer_id;

--19)Identify churned customers?
SELECT customer_id,
MAX(sale_date) AS last_purchase_date
FROM retail_sales
GROUP BY customer_id
HAVING MAX(sale_date) < DATEADD(MONTH, -6, GETDATE());

--20)Compare weekday vs Weekend sales performance?
SELECT 
CASE 
WHEN DATENAME(WEEKDAY, sale_date) IN ('Saturday', 'Sunday') THEN 'Weekend'
ELSE 'Weekday'
END AS day_type,
COUNT(*) AS total_transactions,
SUM(total_sale) AS total_sales,
AVG(total_sale) AS avg_sales
FROM retail_sales
GROUP BY 
CASE 
WHEN DATENAME(WEEKDAY, sale_date) IN ('Saturday', 'Sunday') THEN 'Weekend'
ELSE 'Weekday'
END;






