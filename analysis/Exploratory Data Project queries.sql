-- Database Exploration

-- Exploring all of the objects in the database
SELECT * FROM INFORMATION_SCHEMA.TABLES

-- Exploring all columns in database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS

------------------------------------------------

-- Table Exploration
-- Countries sold in
SELECT DISTINCT country FROM dbo.dim_customers;

-- The major product divisions
SELECT DISTINCT category, subcategory, product_name
FROM dbo.dim_products
ORDER BY 1, 2, 3;

------------------------------------------------

-- Date Exploration
-- Earliest and latest dated orders
SELECT 
	MIN(order_date) AS oldest_order,
	MAX(order_date) AS youngest_order,
	DATEDIFF(year, MIN(order_date), MAX(order_date)) AS order_range_years
FROM dbo.fact_sales;

-- Customer base age differences
SELECT
	MIN(birthdate) AS oldest_customer,
	DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
	MAX(birthdate) AS youngest_customer,
	DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
FROM dbo.dim_customers;

------------------------------------------------

-- Measure Exploration Report
SELECT 'Total Sales' AS measure_name, SUM(f.sales_amount) AS measure_value
FROM dbo.fact_sales f
UNION ALL
SELECT 'Total Quantity', SUM(f.quantity)
FROM dbo.fact_sales f
UNION ALL
SELECT 'Average Price', AVG(f.price)
FROM dbo.fact_sales f
UNION ALL
SELECT 'Total Nr. Orders', COUNT(f.order_number) 
FROM dbo.fact_sales f
UNION ALL
SELECT 'Total Nr. Products', COUNT(p.product_name) 
FROM dbo.dim_products p
UNION ALL
SELECT 'Total Nr. Products', COUNT(c.customer_key)
FROM dbo.dim_customers c;

------------------------------------------------

-- Magnitude Analysis
-- Total Sales by Country
SELECT 
	c.country AS country,
	sum(f.sales_amount) AS total_sales
FROM dbo.dim_customers c
INNER JOIN dbo.fact_sales f ON c.customer_key = f.customer_key
WHERE c.country != 'n/a'
GROUP BY country
ORDER BY total_sales DESC;

-- Total Customers by countries
SELECT
country,
COUNT(DISTINCT customer_key) AS total_customers
FROM dbo.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Total customers by gender
SELECT
gender,
COUNT(customer_key) AS total_customers
FROM dbo.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Total Products by category
SELECT
category,
COUNT(product_key) AS total_product
FROM dbo.dim_products
GROUP BY category
ORDER BY total_product DESC;

-- Average cost by category
SELECT
category,
AVG(cost) AS average_cost
FROM dbo.dim_products
GROUP BY category
ORDER BY average_cost DESC;

-- Average price by category
SELECT
p.category,
AVG(price) AS average_price
FROM dbo.dim_products AS p
LEFT JOIN dbo.fact_sales f ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY average_price DESC;

-- Total revenue by category
SELECT
p.category,
SUM(sales_amount) AS total_revenue
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_products p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Total revenue by customer
SELECT
c.customer_key,
c.first_name,
c.last_name,
SUM(sales_amount) AS total_revenue
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_customers c ON f.customer_key = c.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC;

-- Distribution of items sold by countries
SELECT
c.country,
SUM(f.quantity) AS total_sold_items
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_customers c ON f.customer_key = c.customer_key
GROUP BY 
country
ORDER BY total_sold_items DESC;

------------------------------------------------

-- Ranking Analysis
-- Top 5 products by revenue
SELECT TOP 5
p.product_name,
SUM(f.sales_amount) AS total_sales
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_products p ON f.product_key = p.product_key
GROUP BY product_name
ORDER BY total_sales DESC;


SELECT *  -- Example of windows function version
FROM (
	SELECT
	p.product_name,
	SUM(f.sales_amount) AS total_revenue,
	ROW_NUMBER() OVER ( ORDER BY SUM(f.sales_amount) DESC) AS rank_products
	FROM dbo.fact_sales f
	LEFT JOIN dbo.dim_products p ON f.product_key = p.product_key
	GROUP BY product_name)t
WHERE rank_products <= 5;

-- 5 Worst performing products by revenue
SELECT TOP 5
p.product_name,
SUM(f.sales_amount) AS total_sales
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_products p ON f.product_key = p.product_key
GROUP BY product_name
ORDER BY total_sales;

-- Top 5 subcategories by revenue
SELECT TOP 5
p.subcategory,
SUM(f.sales_amount) AS total_sales
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_products p ON f.product_key = p.product_key
GROUP BY subcategory
ORDER BY total_sales DESC;

-- 5 worst performing sub categories by revenue
SELECT TOP 5
p.subcategory,
SUM(f.sales_amount) AS total_sales
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_products p ON f.product_key = p.product_key
GROUP BY subcategory
ORDER BY total_sales;

-- Top 10 customers by highest revenue
SELECT TOP 10
c.customer_key,
c.first_name,
c.last_name,
SUM(sales_amount) AS total_revenue
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_customers c ON f.customer_key = c.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC;

-- 3 customers with fewest orders placed
SELECT TOP 3
c.customer_key,
c.first_name,
c.last_name,
COUNT(DISTINCT order_number) AS total_orders
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_customers c ON f.customer_key = c.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_orders;