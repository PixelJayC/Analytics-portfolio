WITH month_rev AS(
    SELECT
        o.customer_id,
        DATE_TRUNC('month',o.order_purchase_timestamp) AS date_month,
        SUM(i.price + i.freight_value) AS MonthlyRevenue
        FROM orders o
        INNER JOIN items i
            ON o.order_id = i.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY customer_id, date_month
    ),

    rank_customers AS (
        SELECT
            customer_id,
            date_month,
            MonthlyRevenue,
            RANK() OVER(PARTITION BY date_month ORDER BY MonthlyRevenue DESC) AS rn
        FROM month_rev
    )

    SELECT
        customer_id,
        date_month,
        MonthlyRevenue
    FROM
    rank_customers
    WHERE rn = 1
    ORDER BY date_month ASC;