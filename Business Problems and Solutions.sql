--                                                      EDA
SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM orders;
SELECT * FROM deliveries;
SELECT * FROM riders;

--                                                Handling NULL Values

SELECT COUNT(*) FROM customers
WHERE reg_date IS NULL;

SELECT COUNT(*) FROM restaurants
WHERE restaurant_name IS NULL OR city IS NULL OR opening_hours IS NULL;

SELECT * FROM orders 
WHERE order_item IS NULL 
OR order_date IS NULL 
OR order_time IS NULL 
OR order_status IS NULL 
OR total_amount IS NULL;

SELECT * FROM deliveries WHERE 
order_id IS NULL OR
delivery_status IS NULL OR
delivery_time IS NULL OR 
rider_id IS NULL;


--                ================                      Analysis                      ===============


-- Q1
-- Write a Query to find top 5 most frequently ordered dishes by customer called "Arjun Mehta" in last 1 year

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

-- In this I took hard coded date but we can also make it dynamic by using CURRENT_DATE

-- Q2 
-- Identify the time slot during the most order placed based on 2 hour Interval .

SELECT * FROM orders;
SELECT  
	FLOOR(HOUR(order_time)/2)*2 AS start_time,
	FLOOR(HOUR(order_time)/2)*2 +2 AS end_time,
	COUNT(*) AS total_order
FROM orders 
	GROUP BY start_time, end_time
	ORDER BY total_order DESC;

-- Q3 Order Value Analysis
-- Find the average order value per customer who placed more than 750 orders. 
-- Return the customer name and AOV .

SELECT 
    c.customer_name, ROUND(AVG(o.total_amount),2)AS average_order_value
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
HAVING COUNT(o.order_id) > 750;

-- Q4 High Value Customers
-- List the customers who spent more than 100K in total on food  orders 
-- return the customer name and customer id 

SELECT 
    c.customer_name, SUM(o.total_amount)AS total_order_value
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
HAVING SUM(o.total_amount) >= 100000
ORDER BY total_order_value DESC;

-- Q5) Order without delivery 
-- Write a query to find the order that were palced but not delivered
-- Return each resturant name, city, and number of not delivered order 

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

-- Q6) Restaurant revenue ranking
-- Rank restaurant by their total revenue from last year including their name,
-- total revenue and rank within their city 

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


-- Q7 Most popular dish by city
-- Idenify the most popular dish in the city based on number of orders.


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


-- Q8 Customer churn
-- Find the customer who have'nt palce an order in 2024 but in 2023

SELECT * FROM orders;

SELECT DISTINCT customer_id FROM orders WHERE YEAR(order_date)='2023' AND customer_id NOT IN 
(SELECT DISTINCT customer_id FROM orders WHERE YEAR(order_date)='2024');

-- Q9 cancellation rate comparision 
-- Calculate and compare the order cancellation rate for each restaurant between the 
-- current year and previous year

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

-- Q10 Rider average delivery time
-- Determine each rider average delivery time

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

-- Q11 Monthly restaurant growth ratio 
-- Calculate each restaurant growth ratio based on total no of delivered orders since it's joining

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


-- Q12 Customer Segmentation 
-- Compare segmentation : Segement customers into 'Gold' or 'Silver' groups based on their spending 
-- If the customer average order value (AOV). If the customer total spending exceeds AOV then lable it as Gold otherwise as Silver
-- WAQ to determine each segment total number of orders and total revenue

SELECT * FROM orders;
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

-- Q13 Rider monthly earning 
-- Calculate the each rider total monthly earning assuming that they are earning 8% of the order amount

SELECT d.rider_id, 
	SUM(o.total_amount)tot,
    SUM(o.total_amount)*0.08 AS rider_earning,
	MONTH(o.order_date)mon, YEAR(o.order_date)yr
FROM orders o
	JOIN deliveries d 
	ON o.order_id = d.order_id
	GROUP BY 
		d.rider_id, MONTH(o.order_date), YEAR(o.order_date);


-- Q14 Rider rating analysis
-- find the number of 5 star, 4 star, 3 star rating each for rider 
-- rider received this rating based on delivery time 
-- If delivery time less than 15  minutes of order receiving time the rider gets 5 star rating 
-- If  the delivery time is between 15 and 20 minutes the rider gets 4 star rating
-- >20 mins gets 3 star

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

-- Q15 Order frequency by day 
-- Analyse the order frequency per day of week and identify the peak day for each restaurant 
SELECT * FROM orders;

WITH CTE AS(
	SELECT r.restaurant_name, 
		COUNT(o.order_id)order_count, 
		DAYNAME(o.order_date)day_name,
		DENSE_RANK() OVER(PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC)rnk
	FROM orders o
		JOIN restaurants r ON o.restaurant_id = r.restaurant_id
		GROUP BY r.restaurant_name, DAYNAME(o.order_date)
)
SELECT restaurant_name, order_count, day_name 
FROM CTE WHERE rnk =1;

-- Q16 Calculate the customer life time value (CLV)
-- Calculate the total revenue genrated by each customer over all the orders

SELECT 
    c.customer_name, SUM(total_amount) CLV
FROM
    orders o
        JOIN
    customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_name;


-- Q17 Monthly sales trend 
-- Identify the sales trend by comparing each month total sales to the previous month. 

WITH CTE AS(
	SELECT 
		MONTH(order_date)mon, YEAR(order_date)yr, SUM(total_amount)curr_mon_rev,
		LAG(SUM(total_amount)) OVER(ORDER BY YEAR(order_date), MONTH(order_date))prev_mon_rev
	FROM orders 
		GROUP BY mon, yr)
SELECT 
	mon, yr, CONCAT(ROUND((curr_mon_rev - prev_mon_rev)/prev_mon_rev*100,2),'%') mom_growth 
FROM CTE;

-- Q18 Rider Efficiency 
-- Evaluate rider efficiency by determining average delivery time and identifying those with higest and lowest average

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
	
-- Q19 Order item popularity 
-- Track the popularity of specific order item and identify the seasonal demand spikes

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

-- Q20 City Ranking
-- Rank each  city based on revenue 

SELECT 
	r.city, SUM(o.total_amount)total_rev,
	RANK() OVER(ORDER BY SUM(o.total_amount)DESC)rnk
FROM orders o
	JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city;


-- Q21 Peak timing in different city
-- WAQ to find what is the peak time of ordering in different cities.

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








