-- 1.Sale Analysis
SELECT
    C.customer_name,
    SUM(sales_amount) AS total_sales_amount,
    SUM(sales_qty) AS total_sales_quantity,
    ROUND(AVG(sales_amount)) AS avg_sales_per_customer
FROM
    `Atliq.customers` AS C
JOIN
    `Atliq.transactions` AS T ON C.customer_code = T.customer_code
GROUP BY
    customer_name;

-- 2.Top-selling products
SELECT 
    P.product_code,
    SUM(T.sales_qty) AS total_sales
FROM
     `Atliq.products` AS P
JOIN 
    `Atliq.transactions` AS T ON P.product_code = T.product_code
GROUP BY 
    P.product_code
ORDER BY
    total_sales DESC
LIMIT 5;

-- 3. high-value customers
SELECT 
    C.customer_code,
    C.customer_name,
    SUM(T.sales_amount) AS total_spent
FROM
    `Atliq.customers` AS C
JOIN
    `Atliq.transactions` AS T ON C.customer_code = T.customer_code
GROUP BY
     C.customer_code, C.customer_name
HAVING 
    total_spent > 1000000
ORDER BY 
    total_spent DESC;

-- 4.Market-wise revenue
SELECT 
    M.market_name,
    SUM(T.sales_amount) AS total_revenue
FROM 
    `Atliq.markets` AS M
JOIN 
    `Atliq.transactions` AS T ON M.market_code = T.market_code
GROUP BY 
    M.market_name
ORDER BY 
    total_revenue DESC;

-- 5.Yearly trends
SELECT
    EXTRACT(YEAR FROM order_date) AS year,
    market_zone,
    SUM(sales_amount) AS total_sales_amount
FROM
    `Atliq.markets` AS M
JOIN
    `Atliq.transactions` AS T ON M.market_code = T.market_code
GROUP BY
    year, market_zone
ORDER BY
    year, market_zone;

-- 6. Monthly trends
SELECT
    EXTRACT(MONTH FROM order_date) AS month,
    market_zone,
    SUM(sales_amount) AS total_sales_amount
FROM
    `Atliq.markets` AS M
JOIN
    `Atliq.transactions` AS T ON M.market_code = T.market_code
GROUP BY
    month, market_zone
ORDER BY
    month, market_zone;

-- 7.percentage contribution of each product type to total sales 
SELECT
    product_type,
    (SUM(sales_amount) / SUM(SUM(sales_amount)) OVER ()) * 100 AS percentage_contribution
FROM
    `Atliq.products` AS P
JOIN
    `Atliq.transactions` AS T ON P.product_code = T.product_code
GROUP BY
    product_type;

-- 8.customers who have not made any transactions
WITH LastSixMonths AS (
  SELECT
      customer_code,
      MAX(order_date) AS last_transaction_date
  FROM
      `Atliq.transactions` AS T
  WHERE
      order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
  GROUP BY 
      customer_code
)
SELECT
    C.customer_name
FROM
  ` Atliq.customers` AS C
LEFT JOIN
    LastSixMonths ON C.customer_code = LastSixMonths.customer_code
WHERE
    LastSixMonths.customer_code IS NOT NULL;

-- 9.Multi-Market Customer purchase
SELECT
    customer_name
FROM
    `Atliq.customers`
WHERE
    customer_code IN (
        SELECT
            customer_code
        FROM
            `Atliq.transactions`
        GROUP BY
            customer_code
        HAVING
            COUNT(DISTINCT market_code) > 2
    );

-- 10.Cross-selling recommendations based on previous purchases
WITH ProductPairs AS (
  SELECT
      t1.product_code AS product1,
      t2.product_code AS product2,
      COUNT(DISTINCT t1.customer_code) AS frequency
  FROM
      `Atliq.transactions` AS t1
      JOIN `Atliq.transactions` AS t2 ON t1.customer_code = t2.customer_code
      AND t1.product_code < t2.product_code -- Avoid counting pairs twice
  GROUP BY
      t1.product_code, t2.product_code
)
SELECT
    product1,
    product2,
    frequency,
    RANK() OVER (ORDER BY frequency DESC) AS rank
FROM
    ProductPairs
ORDER BY
    frequency DESC;
