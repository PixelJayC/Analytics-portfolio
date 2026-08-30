
SELECT
    c.customer_unique_id,
    DATE_TRUNC('month',MIN(o.order_purchase_timestamp)) AS first_order_month
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id;