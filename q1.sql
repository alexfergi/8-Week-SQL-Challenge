-- What is the total amount each customer spent at the restaurant?

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
