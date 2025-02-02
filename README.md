# Zomato_project_sql

# SQL Project: Data Analysis for Zomato - A Food Delivery Company

## Overview

This project demonstrates my SQL problem-solving skills through the analysis of data for Zomato, a popular food delivery company in India. The project involves setting up the database, importing data, handling null values, and solving a variety of business problems using complex SQL queries.

## Project Structure

- **Database Setup:** Creation of the `zomato_db` database and the required tables.
- **Data Import:** Inserting sample data into the tables.
- **Data Cleaning:** Handling null values and ensuring data integrity.
- **Business Problems:** Solving 20 specific business problems using SQL queries.


## Database Setup
```sql
CREATE DATABASE zomato_db;
```

### 1. Dropping Existing Tables
```sql
DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS riders;

-- 2. Creating Tables
CREATE TABLE restaurants (
    restaurant_id SERIAL PRIMARY KEY,
    restaurant_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    opening_hours VARCHAR(50)
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    reg_date DATE
);

CREATE TABLE riders (
    rider_id SERIAL PRIMARY KEY,
    rider_name VARCHAR(100) NOT NULL,
    sign_up DATE
);

CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    order_item VARCHAR(255),
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    order_status VARCHAR(20) DEFAULT 'Pending',
    total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

CREATE TABLE deliveries (
    delivery_id SERIAL PRIMARY KEY,
    order_id INT,
    delivery_status VARCHAR(20) DEFAULT 'Pending',
    delivery_time TIME,
    rider_id INT,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
);
```

## Data Import

## Data Cleaning and Handling Null Values

Before performing analysis, I ensured that the data was clean and free from null values where necessary. For instance:

```sql
UPDATE orders
SET total_amount = COALESCE(total_amount, 0);
```

## Business Problems Solved

### 1. Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" in the last 1 year.

```sql
WITH CTE AS(
SELECT 
    c.customer_id, 
    c.customer_name, 
    o.order_item, 
    COUNT(*) AS total_orders,
    DENSE_RANK() OVER(ORDER BY COUNT(*) DESC)rnk
FROM 
    customers c 
JOIN 
    orders o 
ON 
    c.customer_id = o.customer_id
WHERE 
    o.order_date >= DATE_SUB('2024-09-02', INTERVAL 1 YEAR) -- DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR) AS LastYearDate;
    AND c.customer_name = 'Arjun Mehta'
GROUP BY 
    c.customer_id, c.customer_name, o.order_item)
	SELECT customer_id, customer_name, order_item, total_orders 
	FROM CTE
		WHERE rnk <=5;
```

### 2. Popular Time Slots
-- Question: Identify the time slots during which the most orders are placed. based on 2-hour intervals.

**Approach 1:**

```sql
-- Approach 1
SELECT  
	FLOOR(HOUR(order_time)/2)*2 AS start_time,
	FLOOR(HOUR(order_time)/2)*2 +2 AS end_time,
	COUNT(*) AS total_order
FROM orders 
	GROUP BY start_time, end_time
	ORDER BY total_order DESC;
```

**Approach 2:**

```sql
SELECT
    CASE
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
    END AS time_slot,
    COUNT(order_id) AS order_count
FROM Orders
GROUP BY time_slot
ORDER BY order_count DESC;
```

### 3. Order Value Analysis
-- Question: Find the average order value per customer who has placed more than 750 orders.
-- Return customer_name, and aov(average order value)

```sql
SELECT 
    c.customer_name, ROUND(AVG(o.total_amount),2)AS average_order_value
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
HAVING COUNT(o.order_id) > 750;
```

### 4. High-Value Customers
-- Question: List the customers who have spent more than 100K in total on food orders.
-- return customer_name, and customer_id!

```sql
SELECT 
    c.customer_name, SUM(o.total_amount)AS total_order_value
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
HAVING SUM(o.total_amount) >= 100000
ORDER BY total_order_value DESC;
```

### 5. Orders Without Delivery
-- Question: Write a query to find orders that were placed but not delivered. 
-- Return each restuarant name, city and number of not delivered orders 

```sql
-- Approach 1
SELECT 
    r.restaurant_name,
    r.city,
    COUNT(o.order_id) not_delivered_order
FROM
    orders o
        LEFT JOIN
    restaurants r ON r.restaurant_id = o.restaurant_id
        LEFT JOIN
    deliveries d ON d.order_id = o.order_id
WHERE
    d.delivery_id IS NULL
GROUP BY r.restaurant_name , r.city
ORDER BY not_delivered_order DESC;

-- Approach 2
SELECT 
	r.restaurant_name,
	COUNT(*)
FROM orders as o
LEFT JOIN 
restaurants as r
ON r.restaurant_id = o.restaurant_id
WHERE 
	o.order_id NOT IN (SELECT order_id FROM deliveries)
GROUP BY 1
ORDER BY 2 DESC
```


### 6. Restaurant Revenue Ranking: 
-- Rank restaurants by their total revenue from the last year, including their name, 
-- total revenue, and rank within their city.

```sql
WITH CTE AS (
	SELECT 
		r.restaurant_name, r.city , 
	    SUM(o.total_amount)revenue,
		DENSE_RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount)DESC)rnk
	FROM orders o 
	   JOIN 
			restaurants r ON o.restaurant_id = r.restaurant_id
	   WHERE 
			o.order_date >= DATE_SUB('2024-09-02', INTERVAL 1 YEAR) -- We lso use current_date() here to make it dynamic
	   GROUP BY  
			r.restaurant_name, r.city)
 SELECT  city, restaurant_name, revenue FROM CTE WHERE rnk = 1;

```

### 7. Most Popular Dish by City: 
-- Identify the most popular dish in each city based on the number of orders.

```sql
WITH CTE AS (
	SELECT 
		o.order_item as dish, 
		r.city, 
        COUNT(o.order_id)order_count,
	    DENSE_RANK() OVER(PARTITION BY r.city ORDER BY COUNT(o.order_id)DESC)rnk
	FROM orders o 
		JOIN restaurants r 
			ON o.restaurant_id = r.restaurant_id
		GROUP BY dish, city)
  SELECT city, dish, order_count FROM CTE WHERE rnk = 1;
```

### 8. Customer Churn: 
-- Find customers who haven’t placed an order in 2024 but did in 2023.

```sql
SELECT * FROM orders;

SELECT DISTINCT customer_id FROM orders WHERE YEAR(order_date)='2023' AND customer_id NOT IN 
(SELECT DISTINCT customer_id FROM orders WHERE YEAR(order_date)='2024');
```

### 9. Cancellation Rate Comparison: 
-- Calculate and compare the order cancellation rate for each restaurant between the 
-- current year and the previous year.

```sql
WITH cancel_rate_23 AS(
	SELECT 
		o.restaurant_id,
		COUNT(o.order_id)total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
	FROM orders o
		LEFT JOIN 
			deliveries d ON o.order_id = d.order_id
		WHERE 
			YEAR(order_date)='2023'
		GROUP BY 
			restaurant_id),
cancel_rate_24 AS(
	SELECT 
		o.restaurant_id,
		COUNT(o.order_id)total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
	FROM orders o
		LEFT JOIN 
			deliveries d ON o.order_id = d.order_id
		WHERE 
			YEAR(order_date)='2024'
		GROUP BY 
			restaurant_id),

last_year_data AS (		
	SELECT 
		restaurant_id, total_orders, not_delivered, 
		CONCAT(ROUND(not_delivered/total_orders*100,2),'%') AS not_delivered_p 
    FROM 
		cancel_rate_23
	ORDER BY restaurant_id),
    
current_year_data AS (
	SELECT 
		restaurant_id, total_orders, not_delivered, 
		CONCAT(ROUND(not_delivered/total_orders*100,2),'%') AS not_delivered_p
	FROM cancel_rate_24
		ORDER BY restaurant_id )

SELECT 
    c.restaurant_id,
    c.not_delivered_p AS current_yr_not_delivered,
    l.not_delivered_p AS last_yr_not_delivered
FROM
    current_year_data AS c
        JOIN
    last_year_data AS l ON c.restaurant_id = l.restaurant_id;
```

### 10. Rider Average Delivery Time: 
-- Determine each rider's average delivery time.

```sql
WITH CTE AS(
	SELECT o.order_id, o.order_time, d.delivery_time,
	CASE 
		  WHEN delivery_time < order_time 
		  THEN TIMESTAMPDIFF(MINUTE, o.order_time, ADDTIME(delivery_time, '24:00:00'))
		  ELSE TIMESTAMPDIFF(MINUTE, o.order_time, delivery_time) 
		  END AS minutes_difference,
		  d.rider_id
	FROM orders as o JOIN deliveries d ON o.order_id = d.order_id)
SELECT rider_id, ROUND(AVG(minutes_difference),2)as average_delivery_time FROM CTE 
GROUP BY rider_id;

```

### 11. Monthly Restaurant Growth Ratio: 
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining

```sql
WITH CTE AS(
	SELECT 
		o.restaurant_id, 
		DATE_FORMAT(o.order_date, '%m/%Y') AS month_year,
		COUNT(o.order_id)curr_mon_order,
		LAG(COUNT(o.order_id)) OVER(PARTITION BY o.restaurant_id ORDER BY DATE_FORMAT(o.order_date, '%m/%Y'))last_mon_order
	FROM orders o
		JOIN deliveries d  ON o.order_id = d.order_id
		WHERE d.delivery_status = 'Delivered' AND YEAR(o.order_date) <>'2024'
		GROUP BY o.restaurant_id, month_year
)
SELECT restaurant_id, month_year, CONCAT(ROUND((curr_mon_order - last_mon_order)/last_mon_order*100,2),'%') AS monthly_growth
FROM CTE;
-- In this query I've took only for year 2023 for MOM change because we have data of 2024 for 1st month(jan) only 
```

### 12. Customer Segmentation: 
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending 
-- compared to the average order value (AOV). If a customer's total spending exceeds the AOV, 
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's 
-- total number of orders and total revenue

```sql
WITH CTE AS(
	SELECT customer_id, SUM(total_amount)total_spend,
    COUNT(order_id) total_orders,
	CASE
		WHEN SUM(total_amount) >(SELECT AVG(total_amount) FROM orders)
		THEN 'Gold' ELSE 'Silver'
		END AS cust_category
	FROM orders 
	GROUP BY customer_id )
SELECT cust_category, SUM(total_spend)as total_rev, SUM(total_orders)total_orders FROM CTE
GROUP BY cust_category;
```

### 13. Rider Monthly Earnings: 
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.

```sql
SELECT d.rider_id, 
	SUM(o.total_amount)tot,
    SUM(o.total_amount)*0.08 AS rider_earning,
	MONTH(o.order_date)mon, YEAR(o.order_date)yr
FROM orders o
	JOIN deliveries d 
	ON o.order_id = d.order_id
	GROUP BY 
		d.rider_id, MONTH(o.order_date), YEAR(o.order_date);
```

### 14. Rider Ratings Analysis: 
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
-- riders receive this rating based on delivery time.
-- If orders are delivered less than 15 minutes of order received time the rider get 5 star rating,
-- if they deliver 15 and 20 minute they get 4 star rating 
-- if they deliver after 20 minute they get 3 star rating.

```sql
WITH CTE AS(
	SELECT o.order_id, o.order_time, d.delivery_time,
		CASE 
			  WHEN delivery_time < order_time 
			  THEN TIMESTAMPDIFF(MINUTE, o.order_time, ADDTIME(delivery_time, '24:00:00'))
			  ELSE TIMESTAMPDIFF(MINUTE, o.order_time, delivery_time) 
			  END AS minutes_difference,
			  d.rider_id
	FROM orders as o JOIN deliveries d ON o.order_id = d.order_id
),CTE2 AS(
SELECT rider_id, minutes_difference,
	CASE
		WHEN minutes_difference < 15 THEN '5 star'
        WHEN minutes_difference BETWEEN 15 AND 20 THEN '4 star'
        ELSE '3 star'
        END AS rider_rating 
	FROM CTE)
SELECT rider_id, rider_rating, COUNT(*)rating_count FROM CTE2 GROUP BY rider_id, rider_rating
ORDER BY rider_id;
WITH CTE AS(
	SELECT o.order_id, o.order_time, d.delivery_time,
		CASE 
			  WHEN delivery_time < order_time 
			  THEN TIMESTAMPDIFF(MINUTE, o.order_time, ADDTIME(delivery_time, '24:00:00'))
			  ELSE TIMESTAMPDIFF(MINUTE, o.order_time, delivery_time) 
			  END AS minutes_difference,
			  d.rider_id
	FROM orders as o JOIN deliveries d ON o.order_id = d.order_id
),CTE2 AS(
SELECT rider_id, minutes_difference,
	CASE
		WHEN minutes_difference < 15 THEN '5 star'
        WHEN minutes_difference BETWEEN 15 AND 20 THEN '4 star'
        ELSE '3 star'
        END AS rider_rating 
	FROM CTE)
SELECT rider_id, rider_rating, COUNT(*)rating_count FROM CTE2 GROUP BY rider_id, rider_rating
ORDER BY rider_id;

```

### 15. Order Frequency by Day: 
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.

```sql
SELECT * FROM
(
	SELECT 
		r.restaurant_name,
		-- o.order_date,
		TO_CHAR(o.order_date, 'Day') as day,
		COUNT(o.order_id) as total_orders,
		RANK() OVER(PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id)  DESC) as rank
	FROM orders as o
	JOIN
	restaurants as r
	ON o.restaurant_id = r.restaurant_id
	GROUP BY 1, 2
	ORDER BY 1, 3 DESC
	) as t1
WHERE rank = 1;
```

### 16. Customer Lifetime Value (CLV): 
-- Calculate the total revenue generated by each customer over all their orders.

```sql
SELECT 
    c.customer_name, SUM(total_amount) CLV
FROM
    orders o
        JOIN
    customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_name;
```

### 17. Monthly Sales Trends: 
-- Identify sales trends by comparing each month's total sales to the previous month.

```sql
WITH CTE AS(
	SELECT 
		MONTH(order_date)mon, YEAR(order_date)yr, SUM(total_amount)curr_mon_rev,
		LAG(SUM(total_amount)) OVER(ORDER BY YEAR(order_date), MONTH(order_date))prev_mon_rev
	FROM orders 
		GROUP BY mon, yr)
SELECT 
	mon, yr, CONCAT(ROUND((curr_mon_rev - prev_mon_rev)/prev_mon_rev*100,2),'%') mom_growth 
FROM CTE;
```

### 18. Rider Efficiency: 
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.

```sql
WITH CTE AS(
	SELECT o.order_id, o.order_time, d.delivery_time, d.rider_id, 
		CASE 
			  WHEN delivery_time < order_time 
			  THEN TIMESTAMPDIFF(MINUTE, o.order_time, ADDTIME(delivery_time, '24:00:00'))
			  ELSE TIMESTAMPDIFF(MINUTE, o.order_time, delivery_time) 
			  END AS delivered_order_time
	FROM orders o 
		JOIN deliveries d ON o.order_id = d.order_id
		WHERE d.delivery_status = 'Delivered'
),CTE2 AS(
SELECT 
	rider_id, ROUND(AVG(delivered_order_time),2)avg_delivery_time FROM CTE 
	GROUP BY rider_id
)
SELECT 
	 MIN(avg_delivery_time)min_avg_delivery_time, MAX(avg_delivery_time)max_avg_delivery_time
FROM CTE2;
```

### 19. Order Item Popularity: 
-- Track the popularity of specific order items over time and identify seasonal demand spikes.

```sql
SELECT 
    order_item, COUNT(*) diff_order_item_count,
    -- MONTH(order_date)mn, YEAR(order_date)yr,
    CASE 
		WHEN MONTH(order_date) IN(11,12,1,2) THEN 'Winter'
        WHEN MONTH(order_date) IN(3,4) THEN 'Spring'
		WHEN MONTH(order_date) IN(5,6,7,8) THEN 'Summer'
        ELSE 'Autumn'
	END AS seasons
FROM
    orders
GROUP BY seasons ,order_item
ORDER BY order_item, diff_order_item_count DESC;
```

### 20. Rank each city based on the total revenue for last year 2023
```sql
SELECT 
	r.city, SUM(o.total_amount)total_rev,
	RANK() OVER(ORDER BY SUM(o.total_amount)DESC)rnk
FROM orders o
	JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city;
```


### 21. Peak timing in different city
--   WAQ to find what is the peak time of ordering in different cities.
```sql
WITH CTE AS(
	SELECT 
		r.city, CONCAT(HOUR(o.order_time),' hrs')timing, COUNT(*)cnt,
		DENSE_RANK() OVER(PARTITION BY r.city ORDER BY CONCAT(HOUR(o.order_time),' hrs') DESC)rnk
	FROM orders o
		JOIN 
			restaurants r ON o.restaurant_id = r.restaurant_id
		GROUP BY 
			r.city, CONCAT(HOUR(o.order_time),' hrs')
)
SELECT 
	city, timing AS peak_order_timing FROM CTE WHERE rnk = 1

```
## Conclusion

This project highlights my ability to handle complex SQL queries and provides solutions to real-world business problems in the context of a food delivery service like Zomato. The approach taken here demonstrates a structured problem-solving methodology, data manipulation skills, and the ability to derive actionable insights from data.
