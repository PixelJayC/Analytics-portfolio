/*******************************************************************************
  SQL PATTERNS INTERVIEW REFERENCE SHEET
  ------------------------------------------------------------------------------
  This file consolidates 5 core SQL techniques for data analytics & interviews:
  1. Date Spine
  2. Gaps-and-Islands
  3. Time Bucketing & Cross-Tabulation
  4. Pivot & Unpivot (Wide <-> Long Format)
  5. Self-Joins (Market Basket Analysis)
*******************************************************************************/


-- =============================================================================
-- 1. DATE SPINE
-- Grain: One row per calendar day.
-- Objective: Ensure complete continuous date coverage by left-joining daily 
--            orders to a full calendar series, replacing missing dates with 0.
-- =============================================================================

WITH date_spine AS (
    SELECT
        date_table
    FROM generate_series(
        (SELECT MIN(o.order_purchase_timestamp):: DATE FROM orders o),
        (SELECT MAX(o.order_purchase_timestamp):: DATE FROM orders o),
        INTERVAL '1 day'
        ) AS d(date_table)
    ),

    daily_orders AS (
        SELECT
            order_purchase_timestamp:: DATE AS order_date,
            COUNT(*) AS order_count
        FROM orders
        GROUP BY 1
    )

SELECT
    ds.date_table AS OrderDate,
    COALESCE(d_orders.order_count,0) AS OrderCount
FROM date_spine ds
LEFT JOIN daily_orders d_orders
    ON ds.date_table = d_orders.order_date
ORDER BY ds.date_table ASC;


-- =============================================================================
-- 2. GAPS-AND-ISLANDS
-- Grain: Seller x Month run.
-- Objective: Identify sellers with 3+ consecutive months of zero orders.
-- Technique: (Month Index - ROW_NUMBER) generates a constant ID for contiguous runs.
-- =============================================================================

WITH month_spine AS (
    SELECT
        month_date
    FROM generate_series(
        (SELECT DATE_TRUNC('month',MIN(order_purchase_timestamp)):: DATE FROM orders),
        (SELECT DATE_TRUNC('month',MAX(order_purchase_timestamp)):: DATE FROM orders),
        INTERVAL '1 month'
        ) AS date_table(month_date)
    ),

    seller_month_spine AS (
        SELECT DISTINCT --Distinct is needed since if there is no distinct
            s.seller_id,
            ms.month_date
        FROM month_spine ms
        CROSS JOIN sellers s
    ),

    seller_month_orders AS (
        SELECT
            i.seller_id,
            DATE_TRUNC('month',o.order_purchase_timestamp):: DATE AS order_month,
            COUNT(*) AS order_count
        FROM items i
        INNER JOIN orders o
        ON i.order_id = o.order_id
        GROUP BY 1,2
    ),

    seller_fullmonth_orders AS (
        SELECT
            sms.seller_id,
            sms.month_date,
            COALESCE(smo.order_count,0) AS order_count
        FROM seller_month_spine sms
        LEFT JOIN seller_month_orders smo
            ON sms.seller_id = smo.seller_id
            AND sms.month_date = smo.order_month

    ),

    zero_months AS (
        SELECT
            seller_id,
            month_date,
            ROW_NUMBER() OVER(PARTITION BY seller_id ORDER BY month_date) as rn
        FROM seller_fullmonth_orders
        WHERE order_count = 0
    ),

    island AS (
        SELECT
            seller_id,
            month_date,
            (EXTRACT(YEAR FROM month_date) * 12 + EXTRACT(MONTH FROM month_date)) - rn AS island_idx
        FROM zero_months
    )

    SELECT
        seller_id,
        MIN(month_date) AS streak_start,
        MAX(month_date) AS streak_end,
        COUNT(*) AS streak_count
    FROM island
    GROUP BY seller_id, island_idx
    HAVING COUNT(*) >= 3;


-- =============================================================================
-- 3. TIME BUCKETING & CROSS-TABULATION
-- Objective: Measure delivery duration in days, bucket into discrete ranges, 
--            and cross-tabulate against review scores.
-- =============================================================================

