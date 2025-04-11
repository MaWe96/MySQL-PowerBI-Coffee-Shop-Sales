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
	CONCAT((ROUND(SUM(unit_price * transaction_qty)))/1000, "K") AS Total_Sales
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
# 3. Charts, Heat map analysis:
-- 3.1 Extract key metrics by month
-- 3.2 Analyze performance by day type and store location

-- 3.1
# Extract total orders, items sold, and sales per month
SELECT
	MONTH(transaction_date) AS month,
    COUNT(transaction_id) AS Total_Orders,
	SUM(transaction_qty) AS Total_Items_Sold,
	ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM sales
# WHERE transaction_date = '2023-05-18'
GROUP BY month;

# Round the totals to thousands
SELECT
	MONTH(transaction_date) AS month,
    CONCAT(ROUND(COUNT(transaction_id)/1000,1), "K") AS Total_Orders,
	CONCAT(ROUND(SUM(transaction_qty)/1000,1), "K") AS Total_Items_Sold,
	CONCAT(ROUND(SUM(unit_price * transaction_qty),1), "K") AS Total_Sales
FROM sales
# WHERE transaction_date = '2023-05-18'
GROUP BY month;

-- 3.2
# Weekdays vs. weekends
-- weekdays (mon through fri) is index 2 to 6
-- weekends (sat, sun) is index 7, 1
SELECT
    CASE WHEN DAYOFWEEK(transaction_date) IN (2,6) THEN 'Weekdays'
    ELSE 'Weekends'
    END AS Day_Type,
    CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,1),"K") AS Total_Sales
    -- to get sales percent for weekdays vs weekends:
    #CONCAT(ROUND(SUM(unit_price * transaction_qty) * 100.0 /
	#SUM(SUM(unit_price * transaction_qty)) OVER (), 1), '%') AS Sales_Percent 
FROM sales
# WHERE MONTH(transaction_date) = 5 # To get specific month
GROUP BY Day_Type;

# By store location
SELECT store_location,
	SUM(unit_price * transaction_qty) AS Total_Sales
FROM sales
WHERE MONTH(transaction_date) = 5
GROUP BY store_location
ORDER BY Total_Sales DESC;

# Bonus: By store location, by day type
SELECT store_location,
	CASE 
		WHEN DAYOFWEEK(transaction_date) IN (2,3,4,5,6) THEN 'Weekdays'
		ELSE 'Weekends'
	END AS Day_Type,
	ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM sales
GROUP BY store_location, Day_Type
ORDER BY store_location, Day_Type;


#######################
# 4. Daily Sales, Averages, Products, Sales heat map:
-- 4.1 Daily Sales and Averages
-- 4.2 Product Categories Sales
-- 4.3 Top Selling Products
-- 4.4 Sales by Days and Hours

SELECT * FROM sales;

-- 4.1
# Takes average of daily total sales
SELECT AVG(total_sales) AS Avg_Sales
FROM (
	SELECT SUM(transaction_qty * unit_price) AS total_sales
    FROM sales
    WHERE MONTH(transaction_date) = 5
    GROUP BY transaction_date
    ) AS inner_query;

# Daily total sales
SELECT DAY(transaction_date) AS Day,
	SUM(unit_price * transaction_qty) AS Total_Sales
FROM sales
WHERE MONTH(transaction_date) = 5
GROUP BY Day;

# Above or Below average
SELECT Day,
	CASE
		WHEN Total_Sales > Avg_Sales THEN 'Above Average'
        WHEN Total_Sales < Avg_Sales THEN 'Below Average'
        ELSE 'Average'
	END AS Placement,
    Total_Sales
FROM (
	SELECT DAY(transaction_date) AS Day,
		SUM(unit_price * transaction_qty) AS Total_Sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS Avg_Sales
	FROM sales
    WHERE MONTH(transaction_date) = 5
    GROUP BY Day
    ) AS Sales_Values
ORDER BY Day;

-- 4.2
SELECT product_category,
	SUM(unit_price * transaction_qty) AS Total_Sales
FROM sales
WHERE MONTH(transaction_date) = 5
GROUP BY product_category
ORDER BY Total_Sales DESC;

-- 4.3
SELECT product_type,
	SUM(unit_price * transaction_qty) AS Total_Sales
FROM sales
WHERE MONTH(transaction_date) = 5 # AND product_category = 'Coffee'
GROUP BY product_type
ORDER BY Total_Sales DESC
LIMIT 10;

-- 4.4
SELECT SUM(unit_price * transaction_qty) AS Total_Sales,
	SUM(transaction_qty) AS Total_Items_Sold,
    COUNT(*) AS Total_Orders
FROM sales
WHERE MONTH(transaction_date) = 5
AND DAYOFWEEK(transaction_date) = 2
AND HOUR(transaction_time) = 8;

# Sales by hour
SELECT HOUR(transaction_time),
	SUM(unit_price * transaction_qty) AS Total_Sales
FROM sales
WHERE MONTH(transaction_date) = 5
GROUP BY HOUR(transaction_time)
ORDER BY HOUR(transaction_time);

# Sales by day
SELECT
	CASE
		WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        WHEN DAYOFWEEK(transaction_date) = 1 THEN 'Sunday'
	END AS Day_Name,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM sales
# WHERE MONTH(transaction_date) = 5
GROUP BY Day_Name;
        

