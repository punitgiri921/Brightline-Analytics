-- 03_validation_queries.sql
-- Run these queries to reconcile data volumes and totals across DEV, TEST, and PROD

-- 1. Table Row Counts Check
SELECT 'erp.products' AS table_name, COUNT(*) AS row_count FROM erp.products
UNION ALL
SELECT 'erp.stores', COUNT(*) FROM erp.stores
UNION ALL
SELECT 'erp.customers', COUNT(*) FROM erp.customers
UNION ALL
SELECT 'erp.sales_reps', COUNT(*) FROM erp.sales_reps
UNION ALL
SELECT 'erp.sales_transactions', COUNT(*) FROM erp.sales_transactions;

-- 2. Fact Sales Date Range & Financial Totals
SELECT 
    MIN(txn_date) AS min_txn_date,
    MAX(txn_date) AS max_txn_date,
    COUNT(*) AS total_order_lines,
    SUM(qty) AS total_units_sold,
    ROUND(SUM(qty * unit_price * (1 - discount_pct)), 2) AS total_net_revenue,
    ROUND(SUM(qty * unit_cost), 2) AS total_cogs,
    ROUND(SUM(qty * unit_price * (1 - discount_pct)) - SUM(qty * unit_cost), 2) AS gross_margin
FROM erp.sales_transactions;

-- 3. Regional Revenue Breakdown
SELECT 
    st.region,
    COUNT(DISTINCT s.store_id) AS active_stores,
    COUNT(s.txn_id) AS order_lines,
    ROUND(SUM(s.qty * s.unit_price * (1 - s.discount_pct)), 2) AS net_sales
FROM erp.sales_transactions s
JOIN erp.stores st ON s.store_id = st.store_id
GROUP BY st.region
ORDER BY net_sales DESC;
