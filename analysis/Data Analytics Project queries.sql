-- Aggregating data over time
-- Split aggregated data by month and year
SELECT 
	DATETRUNC(month, order_date) AS order_date,
	COUNT(DISTINCT customer_key) total_customers,
	SUM(quantity) as total_quantity
FROM dbo.fact_sales f
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date);

------------------------------------------------------------------------------

-- Cumulative Analysis
-- total sales per month and running total of sales over time.
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER (ORDER BY order_date) AS moving_average --added to the end
FROM
(
	SELECT 
		DATETRUNC(YEAR, order_date) AS order_date,
		SUM(sales_amount) AS total_sales,
		AVG(price) AS avg_price
	FROM dbo.fact_sales f
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(year, order_date)
) t;

------------------------------------------------------------------------------

-- Performance Analysis
-- Analysis of yearly performance of products through sales comparison of both average sales performance and previous years sales
WITH yearly_product_sales AS (
SELECT 
	YEAR(f.order_date) AS order_year,
	p.product_name,
	sum(f.sales_amount) AS current_sales
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_products p ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY year(f.order_date),
p.product_name
)

SELECT
	order_year,
	product_name,
	current_sales,
	-- Average sales performance
	AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
	current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
	CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
		ELSE 'Avg'
	END avg_change,
	-- Year Over Year Analysis
	LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS py_sales,
	current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py,
	CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increasing'
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decreasing'
		ELSE 'No change' 
	END py_change
FROM yearly_product_sales
ORDER BY product_name, order_year;

-- Part-to-Whole
-- Categories contributing the most overall sales
WITH category_sales AS (
SELECT 
	category,
	SUM(sales_amount) AS total_sales --Can change to a number of different measures.
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_products p ON f.product_key = p.product_key
GROUP BY category
)
SELECT
	category,
	total_sales,
	SUM(total_sales) OVER() AS overall_sales,
	CONCAT(ROUND((CAST (total_sales AS FLOAT)/SUM(total_sales) OVER())*100,2),'%') AS precent_of_total
FROM category_sales
ORDER BY total_sales DESC;

-- Data Segmentation
-- Segmenting products into cost ranges and counting how many products fall into each segment
WITH product_segments AS (
SELECT 
	product_key,
	Product_name,
	cost,
	CASE WHEN cost < 100 THEN 'Below 100'
		WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		ELSE 'Above 1000'
	END AS cost_range
FROM dbo.dim_products p
)
SELECT
	cost_range,
	COUNT(product_key) AS total_product
FROM product_segments
GROUP BY cost_range
ORDER BY total_product DESC;

-- Grouping customers into 3(vip,reg,new) segments based on spending behavior
-- VIP = 12+ months history, > 5k spending
-- Regular = 12+ months history, <= 5k spending
-- New = <12 months history
WITH customer_spending AS (
SELECT 
	c.customer_key AS customer_key,
	SUM(f.sales_amount) AS total_spending,
	MIN(order_date) first_order,
	MAX(order_date) last_order,
	DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)

SELECT
	customer_segments,
	COUNT(customer_key) AS total_customers
FROM (
SELECT
customer_key,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
	WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
	ELSE 'New'
END AS Customer_segments
FROM customer_spending ) t
GROUP BY customer_segments
ORDER BY total_customers DESC;