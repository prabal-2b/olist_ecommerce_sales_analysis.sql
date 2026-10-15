CREATE DATABASE OLIST_DATA;
USE OLIST_DATA;
SHOW TABLES;

/*
	BY USING olist_orders_dataset PERFORMING EXTRACTING INSIGHT AND VALUEABLE INFORMATION,
    SUCH LIKE -
		TOP 10 CUSTOMERS,
		TOTAL ORDERS,
        TOTAL ORDER_STATUS_COUNT,
        AVGERAGE TIME TOOKS BY DELIVERED ORDER,
        TOP CITIES WHICH GIVES MOST OF THE ORDERS IN EACH STATE,
        YEARLY SALES AND MORE VALUEABLE IMFORMATIONS.
*/

-- FINDING TOP 10 CUSTOMERS
SELECT
	customer_id,
    COUNT(*) AS cnt
FROM olist_orders_dataset
GROUP BY customer_id
ORDER BY cnt DESC
LIMIT 10;


-- CACULATED TOTAL ORDER COUNTS AND EVERY ORDER STATUS COUNT.

SELECT
	*,
    SUM(CNT) OVER() AS TOTAL_ORDERS
FROM (
	SELECT
		ORDER_STATUS,
		COUNT(*) AS CNT
	FROM olist_orders_dataset
	GROUP BY ORDER_STATUS
    ) T;

--  CALCULATING TIME TAKEN FOR WHEN THE ORDER_STATUS IS DELIVERD.

WITH TEMP AS (
	SELECT
		order_id,
		TIMESTAMPDIFF(HOUR,order_purchase_timestamp,order_delivered_customer_date) AS TOTAL_HOURS_TAKEN,
		TIMESTAMPDIFF(HOUR,order_purchase_timestamp,order_estimated_delivery_date) AS ESTIMATED_HOURS
	FROM (
		SELECT
			order_id,
			customer_id,
			order_purchase_timestamp,
			order_delivered_customer_date,
			order_estimated_delivery_date
		FROM olist_orders_dataset
		WHERE ORDER_STATUS = 'DELIVERED'
		) T
	)

-- CHEAKING HOW MANY ORDERS REACHED TO CUSTOMER ON OR BEFORE THE ESTIMATED TIME.

SELECT
	COUNT(*) AS ORDERS_ON_ESTIMATED_TIME
FROM TEMP
WHERE ESTIMATED_HOURS >= TOTAL_HOURS_TAKEN;

-- CHEAKING HOW MANY ORDERS REACHED LATE TO CUSTOMERS.
WITH TEMP AS (
	SELECT
		order_id,
		TIMESTAMPDIFF(HOUR,order_purchase_timestamp,order_delivered_customer_date) AS TOTAL_HOURS_TAKEN,
		TIMESTAMPDIFF(HOUR,order_purchase_timestamp,order_estimated_delivery_date) AS ESTIMATED_HOURS
	FROM (
		SELECT
			order_id,
			customer_id,
			order_purchase_timestamp,
			order_delivered_customer_date,
			order_estimated_delivery_date
		FROM olist_orders_dataset
		WHERE ORDER_STATUS = 'DELIVERED'
		) T
	)
    
SELECT
	COUNT(*) AS LATE_ORDERS
FROM TEMP
WHERE ESTIMATED_HOURS < TOTAL_HOURS_TAKEN;


-- CALCULATING AVERAGE TIME TAKEN FOR DELIVERED ORDERS.
WITH TEMP AS (
	SELECT
		order_id,
		TIMESTAMPDIFF(HOUR,order_purchase_timestamp,order_delivered_customer_date) AS TOTAL_HOURS_TAKEN,
		TIMESTAMPDIFF(HOUR,order_purchase_timestamp,order_estimated_delivery_date) AS ESTIMATED_HOURS
	FROM (
		SELECT
			order_id,
			customer_id,
			order_purchase_timestamp,
			order_delivered_customer_date,
			order_estimated_delivery_date
		FROM olist_orders_dataset
		WHERE ORDER_STATUS = 'DELIVERED'
		) T
	)

SELECT
	ROUND(AVG(TOTAL_HOURS_TAKEN),2) AS AVERAGE_HOURS_FOR_DELIVERY
FROM TEMP;


/*
	CHEAKING FOR WHICH LOCATION HAVE MOST OF THE DELIVERED COUNT AND OTHER STATUS COUNT.
    FOR EXTRACT THESE INFORMATION WE HAVE TO JOIN ORDERS TABLE WITH THE CUSTOMERS TABLE SO THAT WE CAN 
	FETCH CUSTOMERS LOCATION.
*/

SELECT
	customer_state,
    order_status,
    COUNT(*) AS CNT
FROM (
	SELECT
		T2.order_id,
		T1.customer_id,
		T2.order_status,
		T1.customer_city,
		T1.customer_state    
	FROM olist_customers_dataset AS T1
	INNER JOIN olist_orders_dataset AS T2
	ON T1.customer_id = T2.customer_id
    ) T
GROUP BY 
	customer_state,
    order_status
ORDER BY 
	customer_state,
    order_status,
    cnt DESC;


-- FINDING TOP CITY IN EACH STATE WHICH GIVES HIGEST ORDERS TILL NOW.
SELECT
	state,
    city,
    total_orders
FROM (
	SELECT
		*,
		DENSE_RANK() OVER(PARTITION BY state ORDER BY total_orders DESC) AS TOP_CITY
	FROM (
		SELECT
			customer_state AS state,
			customer_city AS city,
			COUNT(*) AS total_orders
		FROM (
			SELECT
				T2.order_id,
				T1.customer_state,
				T1.customer_city
			FROM olist_customers_dataset AS T1
			INNER JOIN olist_orders_dataset AS T2
			ON T1.customer_id = T2.customer_id
			) T
		GROUP BY 
			customer_state,
			customer_city
		) F
	) F2
WHERE TOP_CITY = 1;


/*
EXTRACTING YEARLY SALES-
	THERE IS MULTIPLE ORDER_STATUS TYPE SO WE HAVE TO ENSURE THAT THERE WILL ONLY TWO PART EITHER DELIVERED OR CANCELED,
    SO THAT WE CAN EASILY DEAL WITH ORDERS AND PERFORM OPERATIONS AND CALCULATIONS.
*/

-- ADDING A CATEGORY COLUMN WHERE FILTERING THE ORDER STATUS.

WITH TEMP AS (
	SELECT
		*,
		CASE
			WHEN ORDER_STATUS IN ('unavailable','canceled') THEN 'CANCELED'
			ELSE 'DELIVERED'
		END new_order_status
	FROM olist_orders_dataset
    )

/*
	USING FILTERD DATA (TEMP) JOINNIG IT WITH THE olist_order_items_dataset FOR EXTRACT THE ORDER PRICE AND MORE INFO AFTER THAT GROUPED ALL THE
    SALES BASED ON YEAR.
*/

SELECT
	year_of_order,
    ROUND(sum(price) + sum(freight_value),2) AS yearly_sales_including_freight
FROM (
	SELECT
		T1.order_id,
		YEAR(T1.order_purchase_timestamp) AS year_of_order,
		T2.price,
		T2.freight_value
	FROM TEMP AS T1
	INNER JOIN olist_order_items_dataset AS T2
	ON T1.order_id = T2.order_id
	WHERE T1.new_order_status = 'DELIVERED'
    ) T
GROUP BY year_of_order
ORDER BY year_of_order;


/*
	BY USING TABLE olist_order_payments_dataset FINDING THE PAYMENT METHODS CUSTOMERS LIKE PAY BY.
*/


SELECT
	payment_type,
    COUNT(*) AS cnt
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY cnt DESC;


-- FINDING TOP CATEGORY BASED ON SALES.
SELECT
	product_category_name,
    count(*) AS cnt
FROM olist_order_items_dataset AS T1
INNER JOIN olist_products_dataset AS T2
ON T1.product_id = T2.product_id
GROUP BY product_category_name
ORDER BY cnt DESC;


-- TOP CATEGORY BASED ON REVENUE INCLUDING freight_value.
SELECT
	product_category_name,
    ROUND(sum(price) + sum(freight_value),2) AS total_revenue
FROM olist_order_items_dataset AS T1
INNER JOIN olist_products_dataset AS T2
ON T1.product_id = T2.product_id
GROUP BY product_category_name
ORDER BY total_revenue DESC;

