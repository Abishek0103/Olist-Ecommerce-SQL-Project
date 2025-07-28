/*Adding new column*/
alter TABLE olist_products_dataset add COLUMN	product_category_name_english varchar(255)
UPDATE olist_products_dataset
SET product_category_name_english = (
  SELECT product_category_name_english
  FROM product_category_name_translation
  WHERE product_category_name_translation.product_category_name = olist_products_dataset.product_category_name
)
WHERE product_category_name IN (
  SELECT product_category_name
  FROM product_category_name_translation
);

/*checking Null/missing values*/
select count(*) from olist_products_dataset where product_category_name_english is null
/*Timeframe of the dataset*/
select min(order_purchase_timestamp) as start_date, max(order_purchase_timestamp)
as end_date from olist_orders_dataset

select order_status, count(*) from olist_orders_dataset where order_delivered_customer_date is null GROUP
by order_status

/*Total revenue*/
select round(sum(payment_value),0) as Total_Revenue from olist_order_payments_dataset p 
join olist_orders_dataset o on o.order_id=p.order_id where o.order_status!='canceled' AND
o.order_delivered_customer_date is not null

/*Total Revenue Over Time (Year-wise)*/
select strftime('%Y', o.order_delivered_customer_date) as The_Year, round(sum(payment_value),0) as Total_Revenue
from olist_orders_dataset o join olist_order_payments_dataset p WHERE
o.order_delivered_customer_date is not null and o.order_status != 'canceled'
group by strftime('%Y', o.order_delivered_customer_date)
order by strftime('%Y', o.order_delivered_customer_date)

select count(*) from olist_orders_dataset where order_status!='canceled'
and order_delivered_customer_date is not null

/*Total Revenue Over Time (Year-month-wise)*/
select strftime('%Y', order_purchase_timestamp) as the_year, strftime('%m', order_purchase_timestamp) as the_month,
count(*) Total_orders from olist_orders_dataset
where order_status!='canceled' and order_delivered_customer_date is not null 
GROUP by the_year, the_month
order by the_year, the_month


select count(oi.product_id) from olist_order_items_dataset oi join olist_orders_dataset o
on oi.order_id=o.order_id where o.order_status!='canceled' and o.order_delivered_customer_date is not null

/*Category Sales with Percent of Total*/
SELECT 
    p.product_category_name_english AS category,
    COUNT(oi.order_item_id) AS total_items_sold, round(100.0*COUNT(oi.order_item_id)/(select count(*) from 
    olist_order_items_dataset),2) percentage
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
join olist_orders_dataset o on oi.order_id=o.order_id
where o.order_status!='canceled' and o.order_delivered_customer_date is not null
GROUP BY category
ORDER BY total_items_sold DESC

/*Top-Selling Products*/
SELECT 
  pd.product_id,
  COUNT(oi.order_item_id) AS items_sold                         /* Total items sold per product */
FROM olist_order_items_dataset oi join olist_products_dataset pd on oi.product_id=pd.product_id
join olist_orders_dataset o on o.order_id=oi.order_id
where o.order_status!='canceled' and o.order_delivered_customer_date is not null
GROUP BY pd.product_id
ORDER BY items_sold DESC

/*Sales Trend of Top 5 Products Over Time*/
/* Step 1: Get the Top 5 Products */
WITH top_products AS (
  SELECT product_id
  FROM olist_order_items_dataset
  GROUP BY product_id
  ORDER BY COUNT(*) DESC
  LIMIT 5
)

/* Step 2: Get Monthly Trend for those Top Products */
SELECT 
  oi.product_id,
  strftime('%Y-%m', o.order_purchase_timestamp) AS month,
  COUNT(oi.order_item_id) AS items_sold
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o ON oi.order_id = o.order_id
JOIN top_products tp ON oi.product_id = tp.product_id
WHERE o.order_status != 'canceled'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.product_id, month
ORDER BY oi.product_id, month;


/*Top Cities by Number of Orders*/
SELECT 
  c.customer_city,
  COUNT(o.order_id) AS total_orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
where o.order_status!='canceled' and o.order_delivered_customer_date is not null
GROUP BY c.customer_city
ORDER BY total_orders DESC

/*Most Common Payment Types*/
SELECT 
  payment_type,
  COUNT(payment_type) AS count
FROM olist_order_payments_dataset p
join olist_orders_dataset o on p.order_id=o.order_id
where o.order_delivered_customer_date is not null and o.order_status!='canceled'
GROUP BY payment_type
ORDER BY count DESC;

/*Average Order Value*/
select round(sum(p.payment_value)/count(distinct o.order_id),0) as AOV FROM
olist_orders_dataset o JOIN olist_order_payments_dataset p on p.order_id=o.order_id
where o.order_delivered_customer_date is not null and o.order_status!='canceled'

select pd.product_category_name_english category, round(sum(p.payment_value)/count(distinct oi.order_id),0) as aov from olist_products_dataset pd join olist_order_items_dataset oi
 on pd.product_id=oi.product_id join olist_order_payments_dataset p on p.order_id = oi.order_id
                                               join olist_orders_dataset o on o.order_id=oi.order_id
                                               where o.order_status!='canceled' AND
                                               o.order_delivered_customer_date  is not null
                                               group by category order by aov desc