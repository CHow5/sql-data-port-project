-- Customer Report to consolidate key customer metrics and behaviors
CREATE VIEW dbo.customer_report AS -- Create view for Easier Future Querying

------------------------------------------------------------------------------

-- Gather important fields, ie names, ages, transaction details
WITH base_query AS(
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(first_name, ' ', last_name) AS customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) AS age
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_customers c ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL
),

-- aggregate on customer-level(total orders, sales, quantity purchased,products, and lifespan (in months))
customer_aggregation AS (
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	SUM(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
	FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)

-- Segment customers in (VIP, Reg, New) categories and Age Groups
-- Calculate KPIs (recency (months), avg order value, avg monthly spending)
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
	WHEN age < 20 THEN 'Under 20'
	WHEN age BETWEEN 20 AND 29 THEN '20-29'
	WHEN age BETWEEN 30 AND 39 THEN '30-39'
	WHEN age BETWEEN 40 AND 49 THEN '40-49'
	ELSE '50 and Above'
END AS age_group,
CASE 
	WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
END AS Customer_segments,
DATEDIFF(month,last_order_date, GETDATE()) AS recency,
last_order_date,
total_orders,
total_sales,
total_products,
lifespan,
-- average order value
CASE 
	WHEN total_orders = 0 THEN 0
	ELSE total_sales / total_orders 
END AS avg_order_value,
-- average monthly spending
CASE 
	WHEN lifespan = 0 THEN total_sales
	ELSE total_sales / lifespan 
END AS avg_monthly_spend
FROM customer_aggregation