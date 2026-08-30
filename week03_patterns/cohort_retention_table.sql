WITH activity_month AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS act_month
    FROM customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
),

    user_cohort AS (
    SELECT
        customer_unique_id,
        MIN(act_month) AS cohort_month
    FROM activity_month
    GROUP BY customer_unique_id
),


    month_index AS (
    SELECT DISTINCT
        uc.customer_unique_id,
        uc.cohort_month,
        (EXTRACT(YEAR FROM am.act_month) - EXTRACT(YEAR FROM uc.cohort_month)) * 12
        + (EXTRACT(MONTH FROM am.act_month) - EXTRACT(MONTH FROM uc.cohort_month)) AS mth_idx
    FROM user_cohort uc
    INNER JOIN activity_month am
        ON uc.customer_unique_id = am.customer_unique_id
),

    cohort_size AS (
    SELECT
        cohort_month,
        COUNT(*) AS total_users
    FROM user_cohort
    GROUP BY cohort_month
),

    pivot_table AS (
    SELECT
        cs.cohort_month,
        cs.total_users,
        COUNT(*) FILTER (WHERE mi.mth_idx = 0) AS "m0",
        COUNT(*) FILTER (WHERE mi.mth_idx = 1) AS "m1",
        COUNT(*) FILTER (WHERE mi.mth_idx = 2) AS "m2",
        COUNT(*) FILTER (WHERE mi.mth_idx = 3) AS "m3",
        COUNT(*) FILTER (WHERE mi.mth_idx = 4) AS "m4",
        COUNT(*) FILTER (WHERE mi.mth_idx = 5) AS "m5",
        COUNT(*) FILTER (WHERE mi.mth_idx = 6) AS "m6",
        COUNT(*) FILTER (WHERE mi.mth_idx = 7) AS "m7",
        COUNT(*) FILTER (WHERE mi.mth_idx = 8) AS "m8",
        COUNT(*) FILTER (WHERE mi.mth_idx = 9) AS "m9",
        COUNT(*) FILTER (WHERE mi.mth_idx = 10) AS "m10",
        COUNT(*) FILTER (WHERE mi.mth_idx = 11) AS "m11"
    FROM cohort_size cs
    INNER JOIN month_index mi
        ON cs.cohort_month = mi.cohort_month
    GROUP BY cs.cohort_month, cs.total_users
)

SELECT
    cohort_month,
    ROUND(100.0 * m0 / total_users,1) AS "M0 %",
    ROUND(100.0 * m1 / total_users,1) AS "M1 %",
    ROUND(100.0 * m2 / total_users,1) AS "M2 %",
    ROUND(100.0 * m3 / total_users,1) AS "M3 %",
    ROUND(100.0 * m4 / total_users,1) AS "M4 %",
    ROUND(100.0 * m5 / total_users,1) AS "M5 %",
    ROUND(100.0 * m6 / total_users,1) AS "M6 %",
    ROUND(100.0 * m7 / total_users,1) AS "M7 %",
    ROUND(100.0 * m8 / total_users,1) AS "M8 %",
    ROUND(100.0 * m9 / total_users,1) AS "M9 %",
    ROUND(100.0 * m10 / total_users,1) AS "M10 %",
    ROUND(100.0 * m11 / total_users,1) AS "M11 %"
FROM pivot_table
ORDER BY cohort_month ASC;