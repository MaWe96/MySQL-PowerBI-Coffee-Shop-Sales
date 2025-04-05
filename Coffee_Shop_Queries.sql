# Coffee_Shop_Queries

CREATE DATABASE coffee_db;

-- 1. convert the coffe shop sales.xslx into .csv
-- 2. right click tables in coffee_db, "Table Data Import Wizard".
-- Took a long time, 2500 seconds = 40 minutes.

# First glance at table "sales"
SELECT * FROM sales;
DESCRIBE sales;


#######################
# Clean the data: 
# Make text consistent
UPDATE sales 
SET transaction_date = STR_TO_DATE(transaction_date, '%m/%d/%Y');

# Modify text to date
ALTER TABLE sales
MODIFY COLUMN transaction_date DATE;

# Now same for time
UPDATE sales
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

ALTER TABLE sales
MODIFY COLUMN transaction_time TIME;

# Adjust transaction_id column name, and set type to INT
ALTER TABLE sales
CHANGE COLUMN ï»¿transaction_id transaction_id INT; 
# right click copied the name.
# NOTE: CHANGE column can change col name (not MODIFY).

# Confirm changes
SELECT * FROM sales;
DESCRIBE sales;


#######################
# 1. Total Sales Analysis:
-- 1.1 Extract total sales for each month
-- 1.2 Determine month-on-month sales change and value differences

-- 1.1
# Extract total sales (sum of all months)
SELECT ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales 
FROM sales;

# Total sales per month
SELECT MONTH(transaction_date) AS Month,
	ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM sales
GROUP BY Month;

# Rounded to thousands
SELECT MONTH(transaction_date) AS Month,
	CONCAT((ROUND(SUM(unit_price * transaction_qty)))/1000 , "K") AS Total_Sales
FROM sales
GROUP BY MONTH(transaction_date);

 -- 1.2
SELECT
	MONTH(transaction_date) AS Month,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,
    -- Percentage change from previous month
    ROUND((SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1)
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1)
    OVER (ORDER BY MONTH(transaction_date)) * 100,2) AS Percentage_Change,
	-- Numeric difference from previous month
	ROUND(SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date))) AS Sales_Difference
FROM sales
# WHERE MONTH(transaction_date) IN (4,5) # To see only months 4 and 5.
GROUP BY Month
ORDER BY MONTH(transaction_date);


#######################
# 2. Total Orders and Quantities Analysis:
-- 2.1 Extract total nr of orders per month
-- 2.2 Determine month-on-month change and quantity differences

-- 2.1
SELECT * FROM sales;

SELECT MONTH(transaction_date) AS Month,
	COUNT(transaction_id) AS Total_Orders
FROM  sales
GROUP BY Month;

-- 2.2
SELECT
	MONTH(transaction_date) AS Month,
    DATE_FORMAT(transaction_date, '%M') AS Month_Name,
    COUNT(transaction_id) AS Total_Orders,
    -- Percentage change from previous month
    ROUND(((COUNT(transaction_id) - LAG(COUNT(transaction_id), 1)
    OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id), 1)
    OVER (ORDER BY MONTH(transaction_date))) * 100, 2) AS Percentage_Change,
    -- Numeric difference from previous month
    COUNT(transaction_id) - LAG(COUNT(transaction_id), 1)
	OVER (ORDER BY MONTH(transaction_date)) AS Orders_Difference
FROM sales
GROUP BY Month, month_name
ORDER BY Month;


#######################
# 3. Heat map analysis:

SELECT
	MONTH(transaction_date) AS month,
    COUNT(transaction_id) AS Total_Orders,
	SUM(transaction_qty) AS Total_Items_Sold,
	ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM sales
GROUP BY month;









