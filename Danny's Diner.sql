-- 1. What is the total amount each customer spent at the restaurant?

SELECT
    sales.customer_id AS customer,
    SUM(menu.price) AS amt_spent
FROM sales LEFT JOIN menu USING (product_id)
GROUP BY 1
ORDER BY 1;

+--------+---------+
|customer|amt_spent|
+--------+---------+
|A       |76       |
|B       |74       |
|C       |36       |
+--------+---------+

-- 2. How many days has each customer visited the restaurant?

SELECT
    customer_id customer,
    COUNT(DISTINCT order_date) visits
FROM sales
GROUP BY 1
ORDER BY 1;

+--------+------+
|customer|visits|
+--------+------+
|A       |4     |
|B       |6     |
|C       |2     |
+--------+------+

-- 3. What was the first item from the menu purchased by each customer?

WITH ranked_orders AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
    FROM sales s LEFT JOIN menu m USING (product_id)
)

SELECT DISTINCT
    customer_id customer, product_name item
FROM ranked_orders
WHERE rnk = 1

+--------+-----+
|customer|item |
+--------+-----+
|A       |sushi|
|A       |curry|
|B       |curry|
|C       |ramen|
+--------+-----+

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

|Part 1|

SELECT
    product_name AS most_purchased_item,
    COUNT(*) AS order_count
FROM sales LEFT JOIN menu USING (product_id)
GROUP BY 1
ORDER BY COUNT(*) DESC
LIMIT 1

+-------------------+-----------+
|most_purchased_item|order_count|
+-------------------+-----------+
|ramen              |8          |
+-------------------+-----------+

|Part 2|

WITH cte1 AS (
    SELECT
        product_name
    FROM sales LEFT JOIN menu USING (product_id)
    GROUP BY 1
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
SELECT
    customer_id customer,
    COUNT(*) AS order_count
FROM sales LEFT JOIN menu USING (product_id)
WHERE product_name IN (SELECT * FROM cte1)
GROUP BY 1

+--------+-----------+
|customer|order_count|
+--------+-----------+
|A       |3          |
|B       |2          |
|C       |3          |
+--------+-----------+

-- 5. Which item was the most popular for each customer?

WITH cte AS (SELECT customer_id                                                         customer,
                    product_name                                                        item,
                    COUNT(*)                                                            order_count,
                    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) rnk
             FROM sales
                      LEFT JOIN menu USING (product_id)
             GROUP BY customer_id, product_name
             ORDER BY 1, 3 DESC)
SELECT
    customer, item, order_count
FROM
    cte
WHERE rnk = 1;

+--------+-----+-----------+
|customer|item |order_count|
+--------+-----+-----------+
|A       |ramen|3          |
|B       |curry|2          |
|B       |sushi|2          |
|B       |ramen|2          |
|C       |ramen|3          |
+--------+-----+-----------+

-- 6. Which item was purchased first by the customer after they became a member?

WITH first_order AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY customer_id ORDER BY order_date) rnk
    FROM sales s
        JOIN menu m USING (product_id)
        LEFT JOIN members mb USING (customer_id)
    WHERE DATEDIFF(order_date, join_date) >= 0
)
SELECT
    customer_id customer,
    product_name item,
    order_date,
    join_date member_since
FROM first_order
WHERE rnk = 1;

+--------+-----+----------+------------+
|customer|item |order_date|member_since|
+--------+-----+----------+------------+
|A       |curry|2021-01-07|2021-01-07  |
|B       |sushi|2021-01-11|2021-01-09  |
+--------+-----+----------+------------+

-- 7. Which item was purchased just before the customer became a member?

WITH pre_membership_orders AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY customer_id ORDER BY DATEDIFF(order_date, join_date) DESC) rnk
    FROM sales s
        JOIN menu m USING (product_id)
        LEFT JOIN members mb USING (customer_id)
    WHERE DATEDIFF(order_date, join_date) < 0
)
SELECT
    customer_id customer,
    product_name item,
    order_date,
    join_date member_since
FROM pre_membership_orders
WHERE rnk = 1;

+--------+-----+----------+------------+
|customer|item |order_date|member_since|
+--------+-----+----------+------------+
|A       |sushi|2021-01-01|2021-01-07  |
|A       |curry|2021-01-01|2021-01-07  |
|B       |sushi|2021-01-04|2021-01-09  |
+--------+-----+----------+------------+

-- 8. What is the total items and amount spent for each member before they became a member?

WITH pre_membership_orders AS (
    SELECT
        *
    FROM sales s
        JOIN menu m USING (product_id)
        LEFT JOIN members mb USING (customer_id)
    WHERE DATEDIFF(order_date, join_date) < 0
)
SELECT
    customer_id customer,
    COUNT(product_id) total_items,
    SUM(price) amt_spent
FROM
    pre_membership_orders
GROUP BY 1
ORDER BY 1;

+--------+-----------+---------+
|customer|total_items|amt_spent|
+--------+-----------+---------+
|A       |2          |25       |
|B       |3          |40       |
+--------+-----------+---------+

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
    customer_id customer,
    SUM(points) total_points
FROM (
    SELECT
        *,
        (IF(product_name = 'Sushi', price * 10 * 2, price * 10)) AS points
    FROM sales JOIN menu USING (product_id)
     ) subq
GROUP BY 1
ORDER BY 1;

+--------+------------+
|customer|total_points|
+--------+------------+
|A       |860         |
|B       |940         |
|C       |360         |
+--------+------------+

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
--    how many points do customer A and B have at the end of January?

WITH cte AS (
    SELECT
        *, (join_date + INTERVAL 6 DAY) AS program_end_date
    FROM members
), cte2 AS (
    SELECT
        *,
        (CASE
            WHEN DATEDIFF(order_date, program_end_date) > 0 AND product_name = 'Sushi' THEN price * 10 * 2
            WHEN DATEDIFF(order_date, program_end_date) > 0 AND product_name <> 'Sushi' THEN price * 10
            ELSE price * 10 * 2
        END) AS points
    FROM sales
        JOIN menu USING (product_id)
        JOIN cte USING (customer_id)
    WHERE order_date <= '2021-01-31' AND order_date >= join_date
)
SELECT
    customer_id customer,
    SUM(points) total_points
FROM cte2
GROUP BY 1
ORDER BY 1;

+--------+------------+
|customer|total_points|
+--------+------------+
|A       |1020        |
|B       |320         |
+--------+------------+
