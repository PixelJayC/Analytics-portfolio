WITH cust_metrics AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(i.price + i.freight_value) AS total_revenue
    FROM orders o
    INNER JOIN items i
    ON o.order_id = i.order_id
    INNER JOIN customers c
    ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),

    cust_deciles AS (
    SELECT
        customer_unique_id,
        order_count,
        total_revenue,
        NTILE(10) OVER (ORDER BY total_revenue DESC) AS decile,
        PERCENT_RANK() OVER (ORDER BY total_revenue DESC) as pct_rank
    FROM cust_metrics
    )


SELECT
    decile,
    COUNT(customer_unique_id) AS CustomerCount,
    ROUND(SUM(total_revenue),2) AS TotalRevenue,
    ROUND(AVG(order_count),2) AS AverageOrderCount
FROM cust_deciles
GROUP BY decile
ORDER BY decile ASC;

