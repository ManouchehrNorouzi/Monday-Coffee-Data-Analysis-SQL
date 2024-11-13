-- Monday Coffee -- Data Analysis 

SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM sales;

-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT	city_name,
	ROUND((population *0.25) /1000000, 2) AS Coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC;



-- -- Q.2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
WHERE 
    EXTRACT(YEAR FROM s.sale_date) = 2023
    AND EXTRACT(QUARTER FROM s.sale_date) = 4
    -- OR s.sale_date BETWEEN '2023-10-01' AND '2023-12-31'
GROUP BY ci.city_name
ORDER BY total_revenue DESC;



-- Q.3 Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    p.product_name, 
    COUNT(s.total) AS total_orders
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;



-- Q.4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
    ci.city_name,
    SUM(s.total) AS total_sales,
    COUNT(DISTINCT s.customer_id) AS customer_count,
    ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id), 2) AS average_sale_per_customer
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_sales DESC;



-- -- Q.5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)


SELECT 
    ci.city_name,
    ROUND((ci.population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM city ci
	JOIN customers c ON ci.city_id = c.city_id
	JOIN sales s ON s.customer_id = c.customer_id
WHERE s.sale_date IS NOT NULL 
GROUP BY ci.city_name, ci.population
ORDER BY ci.city_name;


-- -- Q6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

-- Response 1:
SELECT *
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS ranks
    FROM city ci
    JOIN customers c ON ci.city_id = c.city_id
    JOIN sales s ON s.customer_id = c.customer_id
    JOIN products p ON p.product_id = s.product_id
    GROUP BY 1, 2
    ORDER BY 1, 3
) AS t1
WHERE ranks <= 3;



-- Response 2:
WITH product_ranks AS (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS sale_count,
        DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS ranks
    FROM city ci
    JOIN customers c ON ci.city_id = c.city_id
    JOIN sales s ON s.customer_id = c.customer_id
    JOIN products p ON p.product_id = s.product_id
    GROUP BY ci.city_name, p.product_name
)

SELECT 
    city_name,
    product_name,
    sale_count,
    ranks
FROM product_ranks
WHERE ranks <= 3
ORDER BY city_name, ranks;


-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT ci.city_name,
	COUNT(DISTINCT(s.customer_id)) AS unique_customer_count
FROM city ci JOIN customers c ON ci.city_id= c.city_id
				JOIN sales s ON s.customer_id = c.customer_id
WHERE s.product_id  BETWEEN 1 AND 14 --IN (1, 2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY ci.city_name
ORDER BY ci.city_name, unique_customer_count



-- -- Q.8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

SELECT ci.city_name,
		ci.estimated_rent,
		COUNT(DISTINCT s.customer_id) as total_unique_customer,
		ROUND(SUM(s.total)::NUMERIC/COUNT(DISTINCT s.customer_id),2) AS average_sale_per_customer,
		ROUND(ci.estimated_rent::NUMERIC/ COUNT(DISTINCT s.customer_id), 2) AS average_rent_per_customer
FROM sales AS s
	JOIN customers AS c
		ON s.customer_id = c.customer_id
			JOIN city AS ci
				ON ci.city_id = c.city_id
GROUP BY ci.city_name, ci.estimated_rent
ORDER BY ci.city_name DESC;



-- Q.9 Monthly Sales Growth
-- Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city
select * from sales
select * from products
select * from city
select * from customers


WITH monthly_sales_growth AS (
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM s.sale_date) AS month,
		EXTRACT(YEAR FROM s.sale_date) AS year,
		SUM(s.total) AS total_sale,
		LAG(SUM(s.total), 1) OVER(PARTITION BY ci.city_name ORDER BY EXTRACT(YEAR FROM s.sale_date), EXTRACT(MONTH FROM s.sale_date)) AS last_month_sale
	FROM sales AS s
	JOIN customers AS c ON c.customer_id = s.customer_id
	JOIN city AS ci ON ci.city_id = c.city_id
	GROUP BY ci.city_name, EXTRACT(YEAR FROM s.sale_date), EXTRACT(MONTH FROM s.sale_date)
)
SELECT
	city_name,
	month,
	year,
	total_sale AS cr_month_sale,
	last_month_sale,
	ROUND(((total_sale - last_month_sale)::NUMERIC / last_month_sale)::NUMERIC * 100, 2) AS growth_ratio
FROM monthly_sales_growth
WHERE last_month_sale IS NOT NULL
ORDER BY city_name, year, month;



-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

SELECT 
	ci.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_customer,
	ci.estimated_rent AS total_rent,
	ROUND(SUM(s.total)::NUMERIC / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_customer,
	ROUND((ci.population * 0.25)::NUMERIC / 1000000, 3) AS estimated_coffee_consumer_in_millions,
	ROUND(ci.estimated_rent::NUMERIC / COUNT(DISTINCT s.customer_id), 2) AS avg_rent_per_customer
FROM sales AS s
	JOIN customers AS c ON s.customer_id = c.customer_id
		JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name, ci.estimated_rent, ci.population
ORDER BY total_revenue DESC;




/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.*/

