WITH first_order AS (
    SELECT
        c.customer_unique_id,
        FIRST_VALUE(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS first_order_month,
        MIN(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS min_order_month
    FROM orders o
    INNER JOIN customers c
    ON o.customer_id = c.customer_id
)

SELECT
    *
FROM first_order;