1. What is the total amount each customer spent at the restaurant?

SELECT 
    s.customer_id customer, SUM(m.price) amt_spent
FROM
    sales s
        JOIN
    menu m USING (product_id)
GROUP BY 1
ORDER BY 1;
