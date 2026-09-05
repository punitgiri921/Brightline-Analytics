-- 02_schema.sql
-- ERP schema DDL for Brightline Distribution Pvt. Ltd.
-- Run this script inside EACH of the 3 databases: brightline_dev, brightline_test, and brightline_prod

CREATE SCHEMA IF NOT EXISTS erp;

-- 1. Dim Products
DROP TABLE IF EXISTS erp.products CASCADE;
CREATE TABLE erp.products (
    product_id   INT PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    brand        VARCHAR(100) NOT NULL,
    category     VARCHAR(100) NOT NULL,
    subcategory  VARCHAR(100) NOT NULL,
    unit_cost    NUMERIC(12, 2) NOT NULL
);

-- 2. Dim Stores
DROP TABLE IF EXISTS erp.stores CASCADE;
CREATE TABLE erp.stores (
    store_id     INT PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    territory    VARCHAR(100) NOT NULL,
    region       VARCHAR(50) NOT NULL,
    opened_date  DATE NOT NULL
);

-- 3. Dim Customers
DROP TABLE IF EXISTS erp.customers CASCADE;
CREATE TABLE erp.customers (
    customer_id  INT PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    segment      VARCHAR(50) NOT NULL -- 'Modern Trade', 'General Trade', 'Online'
);

-- 4. Dim Sales Reps
DROP TABLE IF EXISTS erp.sales_reps CASCADE;
CREATE TABLE erp.sales_reps (
    rep_id       INT PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    email        VARCHAR(150) NOT NULL,
    territory    VARCHAR(100) NOT NULL
);

-- 5. Fact Sales Transactions
DROP TABLE IF EXISTS erp.sales_transactions CASCADE;
CREATE TABLE erp.sales_transactions (
    txn_id        BIGINT PRIMARY KEY,
    txn_date      DATE NOT NULL,
    store_id      INT NOT NULL REFERENCES erp.stores(store_id),
    product_id    INT NOT NULL REFERENCES erp.products(product_id),
    customer_id   INT NOT NULL REFERENCES erp.customers(customer_id),
    rep_id        INT NOT NULL REFERENCES erp.sales_reps(rep_id),
    qty           INT NOT NULL,
    unit_price    NUMERIC(12, 2) NOT NULL,
    discount_pct  NUMERIC(5, 4) NOT NULL DEFAULT 0.0,
    unit_cost     NUMERIC(12, 2) NOT NULL,
    last_modified TIMESTAMP NOT NULL
);

-- Indexes for Query Folding & Incremental Refresh Range Filtering
CREATE INDEX IF NOT EXISTS idx_sales_txn_date ON erp.sales_transactions (txn_date);
CREATE INDEX IF NOT EXISTS idx_sales_last_modified ON erp.sales_transactions (last_modified);
CREATE INDEX IF NOT EXISTS idx_sales_store_id ON erp.sales_transactions (store_id);
CREATE INDEX IF NOT EXISTS idx_sales_product_id ON erp.sales_transactions (product_id);
