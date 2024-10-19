-- B. Runner and Customer Experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
    DATEPART(WEEK, registration_date) AS week,
    COUNT(*) AS runners_registered
FROM runners
GROUP BY DATEPART(WEEK, registration_date);
/* week runners_registered
   1        1
   2        2
   3        1   */

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH time_taken_cte AS (
    SELECT
        c.order_id,
        c.order_time,
        r.pickup_time,
        DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS pickup_minutes
    FROM runner_orders r
    JOIN customer_orders c
        ON r.order_id = c.order_id
    WHERE cancellation IS NULL
    GROUP BY c.order_id, c.order_time, r.pickup_time
)
SELECT AVG(pickup_minutes) AS avg_pickup_minutes
FROM time_taken_cte; -- 16 minutes

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH pizza_cte AS (
    SELECT
        c.order_id,
        COUNT(c.pizza_id) AS pizza_count,
        c.order_time,
        r.pickup_time,
        DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS prep_minutes
    FROM runner_orders r
    JOIN customer_orders c
        ON r.order_id = c.order_id
    WHERE cancellation IS NULL
   GROUP BY c.order_id, c.order_time, r.pickup_time
)
SELECT
    pizza_count,
    AVG(prep_minutes) AS avg_prep_time
FROM pizza_cte pc
GROUP BY pizza_count;
/*  pizza_count avg_prep_time
    1               12
    2               18
    3               30        */

-- 4. What was the average distance travelled for each customer?
SELECT
    c.customer_id,
    ROUND(AVG(r.distance),2) AS avg_distance
FROM runner_orders r
JOIN customer_orders c
    ON r.order_id = c.order_id
GROUP BY c.customer_id;
/*  customer_id avg_distance
    101             20
    102             16.73
    103             23.4
    104             10
    105             25      */

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
    MAX(duration) - MIN(duration) AS delivery_diff
FROM runner_orders
WHERE cancellation IS NULL; -- 30 minutes

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
    r.runner_id,
    c.order_id,
    COUNT(c.order_id) AS pizza_count,
    r.distance,
    ROUND(r.duration/60.0, 2) AS duration,
    ROUND((r.distance/r.duration * 60), 1) AS avg_speed
FROM runner_orders AS r
JOIN customer_orders AS c
  ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY r.runner_id, c.order_id, r.distance, r.duration
ORDER BY pizza_count;
/*
runner_id	order_id	pizza_count	distance	duration	avg_speed
1	1	1	20	    0.53	37.5
1	2	1	20	    0.45	44.4
2	7	1	25	    0.42	60
2	8	1	23.4	0.25	93.6
3	5	1	10	    0.25	40
1	3	2	13.4	0.33	40.2
1	10	2	10	    0.17	60
2	4	3	23.4	0.67	35.1                    */

-- 7. What is the successful delivery percentage for each runner?
SELECT
    runner_id,
    ROUND(100 * SUM(
        CASE WHEN distance IS NULL THEN 0
        ELSE 1 END) / COUNT(*), 2) AS success_pct
FROM runner_orders
GROUP BY runner_id;
/* runner_id success_pct
    1	        100
    2	        75
    3	        50      */
