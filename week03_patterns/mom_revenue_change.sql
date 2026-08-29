WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month',o.order_purchase_timestamp) AS order_month,
        product_category_name AS product_category,
        SUM(i.price + i.freight_value) AS revenue
    FROM orders o
    INNER JOIN items i
    ON o.order_id = i.order_id
    INNER JOIN products p
    ON i.product_id = p.product_id
    GROUP BY product_category, order_month
    ORDER BY order_month ASC
),

    month_on_month AS (
    SELECT
        product_category,
        order_month AS curr_month,
        revenue AS curr_revenue,
        LAG(order_month) OVER(PARTITION BY product_category ORDER BY order_month) AS prev_month,
        ROUND(LAG(revenue) OVER (PARTITION BY product_category ORDER BY order_month),2) AS prev_revenue
    FROM monthly_revenue
    ORDER BY product_category
    )

SELECT
    product_category,
    curr_month AS CurrentMonth,
    ROUND(COALESCE(curr_revenue,0),2) AS CurrentMonthRevenue,
    prev_month AS PreviousMonth,
    ROUND(COALESCE(prev_revenue,0),2) AS PreviousMonthRevenue,
    ROUND(curr_revenue - prev_revenue,2) AS AbsoluteChange,
    ROUND(100.0 * (curr_revenue - prev_revenue) / NULLIF(prev_revenue,0),2) AS PercentChange
FROM month_on_month
    WHERE
        1 = 1
        AND product_category IS NOT NULL;