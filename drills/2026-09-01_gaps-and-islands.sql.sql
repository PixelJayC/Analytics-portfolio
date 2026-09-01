WITH seller_active_date AS (
    SELECT
        s.seller_id,
        DATE_TRUNC('month',MIN(o.order_purchase_timestamp)) AS min_date,
        DATE_TRUNC('month',MAX(o.order_purchase_timestamp)) AS max_date,
    FROM orders o
    INNER JOIN items i
    ON o.order_id = i.order_id
    INNER JOIN sellers s
    ON i.seller_id = s.seller_id
    GROUP BY s.seller_id
),

seller_month_spine AS (
    SELECT
        seller_id,
        UNNEST(GENERATE_SERIES(min_date, max_date, INTERVAL '1 month')) AS spine_date
    FROM seller_active_date
),

seller_month_orders AS (
    SELECT
        i.seller_id,
        DATE_TRUNC('month',o.order_purchase_timestamp) AS order_date,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM items i
    INNER JOIN orders o
    ON i.order_id = o.order_id
    GROUP BY 1,2
),

zero_months AS (
    SELECT
        sms.seller_id,
        sms.spine_date,
        COALESCE(smo.order_count,0) as order_count,
        ROW_NUMBER() OVER(PARTITION BY sms.seller_id ORDER BY sms.spine_date) AS rn
    FROM seller_month_spine sms
    LEFT JOIN seller_month_orders smo
    ON sms.seller_id = smo.seller_id
    AND sms.spine_date = smo.order_date
    WHERE COALESCE(smo.order_count,0) = 0
),

islands AS (
    SELECT
        zm.seller_id,
        zm.spine_date,
        (EXTRACT(YEAR FROM zm.spine_date) * 12 + EXTRACT(MONTH FROM zm.spine_date)) - rn AS island_key
    FROM zero_months zm
)

SELECT
    seller_id,
    MIN(spine_date) AS streak_start,
    MAX(spine_date) AS streak_end,
    COUNT(*) AS streak
FROM islands
GROUP BY seller_id, island_key
HAVING COUNT(*) >= 3;