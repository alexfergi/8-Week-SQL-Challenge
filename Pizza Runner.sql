-- Using SQL Server Dialect
-- All tables were cleaned before proceeding with the challenge

-- A. PIZZA METRICS

-- 1. How many pizzas were ordered?
SELECT COUNT(pizza_id) AS total_pizzas_orders FROM customer_orders; -- 14

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_orders FROM customer_orders; -- 10

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(DISTINCT order_id) AS successful_deliveries
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;
/* Output
runner_id   successful_deliveries
----------- ---------------------
1           4
2           3
3           1 */

-- 4. How many of each type of pizza was delivered?
WITH cte AS (
SELECT
	c.pizza_id AS pizza_id, COUNT(*) AS cnt
FROM runner_orders r
JOIN customer_orders c
	ON r.order_id = c.order_id
WHERE r.distance <> 0
GROUP BY c.pizza_id
)
SELECT p.pizza_name, cnt
FROM cte c
JOIN pizza_names p ON p.pizza_id = c.pizza_id;
/* Output: 
pizza_name  cnt
Meatlovers	9
Vegetarian	3 */

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	c.customer_id,
	CAST(p.pizza_name AS varchar(100)) AS pizza_name,
	COUNT(*) AS cnt
FROM customer_orders c
JOIN pizza_names p
	ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, CAST(p.pizza_name AS varchar(100))
ORDER BY c.customer_id;
/* Output:
customer_id pizza_name cnt
101	Meatlovers	2
101	Vegetarian	1
102	Meatlovers	2
102	Vegetarian	1
103	Meatlovers	3
103	Vegetarian	1
104	Meatlovers	3
105	Vegetarian	1 */

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT
	MAX(cnt) AS max_pizzas
FROM (
	SELECT COUNT(c.pizza_id) AS cnt
	FROM runner_orders r
	JOIN customer_orders c
		ON r.order_id = c.order_id
	WHERE cancellation IS NULL
	GROUP BY r.order_id) sub; -- Output: 3

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	c.customer_id,
	SUM(CASE WHEN (exclusions IS NOT NULL OR extras IS NOT NULL) THEN 1 ELSE 0 END) AS with_change,
	SUM(CASE WHEN (exclusions IS NULL AND extras IS NULL) THEN 1 ELSE 0 END) AS without_change
FROM runner_orders r
JOIN customer_orders c
	ON r.order_id = c.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id;
/* Output:
customer_id with_change without_change
----------- ----------- --------------
101         0           2
102         0           3
103         3           0
104         2           1
105         1           0 */

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
	SUM(CASE
			WHEN (exclusions IS NOT NULL AND extras IS NOT NULL) THEN 1
			ELSE 0
		END) AS both_changes
FROM runner_orders r
JOIN customer_orders c
	ON r.order_id = c.order_id
WHERE cancellation IS NULL; -- 1 such pizza

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
	DATEPART(HOUR, order_time) AS hour,
	COUNT(pizza_id) AS pizza_ordered
FROM customer_orders
GROUP BY DATEPART(HOUR, order_time);
/*
hour        pizza_ordered
----------- -------------
11          1
13          3
18          3
19          1
21          3
23          3 */

-- 10. What was the volume of orders for each day of the week?
SELECT @@DATEFIRST; -- Default is set as 1 i.e. Monday
SELECT
	FORMAT(order_time, 'dddd') AS weekday,
	COUNT(*) AS pizza_cnt
FROM customer_orders
GROUP BY FORMAT(order_time, 'dddd');
/*
weekday pizza_cnt
Friday	1
Saturday	5
Thursday	3
Wednesday	5 */
