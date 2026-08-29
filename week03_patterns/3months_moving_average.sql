WITH monthly_revenue AS(
    SELECT
        DATE_TRUNC('month',order_purchase_timestamp) AS order_month,
        SUM(i.price + i.freight_value) AS revenue
    FROM orders o
    INNER JOIN items i
    ON o.order_id = i.order_id
    GROUP BY order_month
    ORDER BY DATE_TRUNC('month',order_purchase_timestamp) ASC
)

SELECT
    order_month AS OrderMonth,
    ROUND(revenue,2) AS Revenue,
    ROUND(SUM(revenue) OVER(ORDER BY order_month ASC),2) AS RunningTotals,
    ROUND(AVG(revenue) OVER(ORDER BY order_month ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS MovingAverage
FROM monthly_revenue;