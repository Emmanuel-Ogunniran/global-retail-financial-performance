CREATE DATABASE IF NOT EXISTS global_retail
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE global_retail;

DROP TABLE IF EXISTS dim_product;

CREATE TABLE dim_product (
    product_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    sub_category VARCHAR(100) NOT NULL,
    unit_cost DECIMAL(12,2) NOT NULL,

    PRIMARY KEY (product_id)
);

DROP TABLE IF EXISTS dim_store;

CREATE TABLE dim_store (
    store_id VARCHAR(20) NOT NULL,
    store_name VARCHAR(255) NOT NULL,
    region VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    store_size VARCHAR(50) NOT NULL,
    open_date DATE NOT NULL,

    PRIMARY KEY (store_id)
);

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    `date` DATE NOT NULL,
    day INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter VARCHAR(10) NOT NULL,
    year INT NOT NULL,
    fiscal_period VARCHAR(20) NOT NULL,

    PRIMARY KEY (`date`)
);

DROP TABLE IF EXISTS promotions;

CREATE TABLE promotions (
    promotion_id VARCHAR(30) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    discount_pct DECIMAL(5,4) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    promotion_duration_days INT NOT NULL,

    PRIMARY KEY (promotion_id)
);

DROP TABLE IF EXISTS store_expenses;

CREATE TABLE store_expenses (
    store_id VARCHAR(20) NOT NULL,
    `date` DATE NOT NULL,
    rent DECIMAL(14,2) NOT NULL,
    utilities DECIMAL(14,2) NOT NULL,
    labor DECIMAL(14,2) NOT NULL,
    other_costs DECIMAL(14,2) NOT NULL,
    operating_cost DECIMAL(14,2) NOT NULL,
    non_labour_cost DECIMAL(14,2) NOT NULL,
    rent_share DECIMAL(8,6) NOT NULL,
    labor_share DECIMAL(8,6) NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_serial INT NOT NULL,

    PRIMARY KEY (store_id, `date`)
);

DROP TABLE IF EXISTS sales_cleaned;

CREATE TABLE sales_cleaned (
    order_id VARCHAR(50) NOT NULL,
    `date` DATE NOT NULL,
    store_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(14,2) NULL,
    discount_pct DECIMAL(5,4) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    price_data_quality_flag VARCHAR(50) NOT NULL,

    gross_revenue DECIMAL(16,4) NULL,
    discount_value DECIMAL(16,4) NULL,
    net_revenue DECIMAL(16,4) NULL,

    `year` INT NOT NULL,

    unit_cost DECIMAL(14,2) NOT NULL,
    product_cost DECIMAL(16,4) NULL,
    gross_profit DECIMAL(16,4) NULL,
    gross_margin_percentage DECIMAL(8,6) NULL,

    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,

    PRIMARY KEY (order_id)
);

CREATE INDEX idx_sales_store
ON sales_cleaned(store_id);

CREATE INDEX idx_sales_product
ON sales_cleaned(product_id);

CREATE INDEX idx_sales_date
ON sales_cleaned(`date`);

CREATE INDEX idx_sales_year
ON sales_cleaned(`year`);

CREATE INDEX idx_expenses_store
ON store_expenses(store_id);

CREATE INDEX idx_expenses_date
ON store_expenses(`date`);

CREATE INDEX idx_promotions_product
ON promotions(product_id);

CREATE INDEX idx_promotions_dates
ON promotions(start_date, end_date);

SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/HP/OneDrive/Desktop/global_retail_data/Dim_Product_Clean.csv'
INTO TABLE dim_product
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(product_id, product_name, category, sub_category, unit_cost);
SHOW WARNINGS;

LOAD DATA LOCAL INFILE 'C:/Users/HP/OneDrive/Desktop/global_retail_data/Dim_Store_Clean.csv'
INTO TABLE dim_store
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    store_id,
    store_name,
    region,
    city,
    country,
    store_size,
    @open_date
)
SET open_date = STR_TO_DATE(@open_date, '%m/%d/%Y');
SHOW WARNINGS;

LOAD DATA LOCAL INFILE 'C:/Users/HP/OneDrive/Desktop/global_retail_data/Dim_Date_Clean.csv'
INTO TABLE dim_date
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    @date,
    day,
    month,
    month_name,
    quarter,
    `year`,
    fiscal_period
)
SET `date` = STR_TO_DATE(@date, '%m/%d/%Y');
SHOW WARNINGS;

LOAD DATA LOCAL INFILE 'C:/Users/HP/OneDrive/Desktop/global_retail_data/Promotions_Clean.csv'
INTO TABLE promotions
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    promotion_id,
    product_id,
    discount_pct,
    @start_date,
    @end_date,
    promotion_duration_days
)
SET
    start_date = STR_TO_DATE(@start_date, '%m/%d/%Y'),
    end_date = STR_TO_DATE(@end_date, '%m/%d/%Y');
SHOW WARNINGS;

LOAD DATA LOCAL INFILE 'C:/Users/HP/OneDrive/Desktop/global_retail_data/Store_Expenses_Clean.csv'
INTO TABLE store_expenses
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    store_id,
    @date,
    rent,
    utilities,
    labor,
    other_costs,
    operating_cost,
    non_labour_cost,
    rent_share,
    labor_share,
    month_name,
    month_serial
)
SET `date` = STR_TO_DATE(@date, '%m/%d/%Y');
SHOW WARNINGS;

LOAD DATA LOCAL INFILE 'C:/Users/HP/OneDrive/Desktop/global_retail_data/Sales_Cleaned.csv'
INTO TABLE sales_cleaned
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    order_id,
    @date,
    store_id,
    product_id,
    quantity,
    @unit_price,
    discount_pct,
    transaction_type,
    price_data_quality_flag,
    @gross_revenue,
    @discount_value,
    @net_revenue,
    `year`,
    unit_cost,
    @product_cost,
    @gross_profit,
    @gross_margin_percentage,
    product_name,
    category
)
SET
    `date` = STR_TO_DATE(@date, '%m/%d/%Y'),

    unit_price =
        NULLIF(TRIM(@unit_price), ''),

    gross_revenue =
        NULLIF(TRIM(@gross_revenue), ''),

    discount_value =
        NULLIF(TRIM(@discount_value), ''),

    net_revenue =
        NULLIF(TRIM(@net_revenue), ''),

    product_cost =
        NULLIF(TRIM(@product_cost), ''),

    gross_profit =
        NULLIF(TRIM(@gross_profit), ''),

    gross_margin_percentage =
        NULLIF(TRIM(@gross_margin_percentage), '');
SHOW WARNINGS;
        
SELECT 'sales_cleaned' AS table_name, COUNT(*) AS row_count
FROM sales_cleaned

UNION ALL

SELECT 'dim_product', COUNT(*)
FROM dim_product

UNION ALL

SELECT 'dim_store', COUNT(*)
FROM dim_store

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM dim_date

UNION ALL

SELECT 'promotions', COUNT(*)
FROM promotions

UNION ALL

SELECT 'store_expenses', COUNT(*)
FROM store_expenses;

SELECT
    'sales_cleaned' AS table_name,
    MIN(`date`) AS min_date,
    MAX(`date`) AS max_date
FROM sales_cleaned

UNION ALL

SELECT
    'dim_date',
    MIN(`date`),
    MAX(`date`)
FROM dim_date

UNION ALL

SELECT
    'promotions',
    MIN(start_date),
    MAX(end_date)
FROM promotions

UNION ALL

SELECT
    'store_expenses',
    MIN(`date`),
    MAX(`date`)
FROM store_expenses;

SELECT
    COUNT(*) AS missing_price_rows
FROM sales_cleaned
WHERE unit_price IS NULL;

SELECT
    transaction_type,
    price_data_quality_flag,
    COUNT(*) AS row_count
FROM sales_cleaned
GROUP BY
    transaction_type,
    price_data_quality_flag
ORDER BY
    transaction_type,
    price_data_quality_flag;