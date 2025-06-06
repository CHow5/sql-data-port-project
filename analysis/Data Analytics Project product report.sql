-- Product Report to consolidate key customer metrics and behaviors
CREATE VIEW dbo.product_report AS

------------------------------------------------------------------------------

-- Gather important fields, ie order information, product information
WITH base_query AS(
SELECT 
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_products p ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
),

-- aggregate on product-level(total orders, products, customers, sales, quantity, last sales date, and lifespan (in months)
product_aggregation AS (
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan,
	MAX(order_date) AS last_sale_date,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT product_key) AS total_products,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity,0)),1) AS avg_selling_price
	FROM base_query
GROUP BY 
	product_key,
	product_name,
	category,
	subcategory,
	cost
)

-- Segment products in (high, mid, low) performing categories with customer segments
-- Calculate KPIs (recency (months), avg order revenue, avg monthly revenue)
SELECT
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
CASE 
	WHEN total_sales > 50000 THEN 'High-Performer'
	WHEN total_sales >= 10000 THEN 'Mid-Range'
	ELSE 'Low-Performer'
END AS product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
avg_selling_price,
CASE 
	WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
END AS Customer_segments,
DATEDIFF(month,last_sale_date, GETDATE()) AS recency,
-- average order revenue
CASE 
	WHEN total_orders = 0 THEN 0
	ELSE total_sales / total_orders 
END AS avg_order_revenue,
-- average monthly revenue
CASE 
	WHEN lifespan = 0 THEN total_sales
	ELSE total_sales / lifespan 
END AS avg_monthly_revenue
FROM product_aggregation