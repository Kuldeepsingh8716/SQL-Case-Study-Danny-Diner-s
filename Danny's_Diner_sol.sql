/*1. What is the total amount each customer spent at the restaurant?*/

select customer_id, sum(price) as total_amt_spent from sales
join menu
on sales.product_id = menu.product_id
group by customer_id;

/*How many days has each customer visited the restaurant?*/
select customer_id, count(distinct order_date) as no_of_visit
from sales
group by customer_id;

/* What was the first item from the menu purchased by each customer?*/
with cte1 as
(select customer_id, product_name, order_date,
rank() over (partition by customer_id order by order_date) as rnk
from sales
join menu
on sales.product_id = menu.product_id)

select customer_id, product_name from cte1
where rnk = 1;

SELECT sales.customer_id, menu.product_name, sales.order_date
FROM sales
JOIN menu ON sales.product_id = menu.product_id
WHERE sales.order_date = (
  SELECT MIN(order_date)
  FROM sales AS s2
  WHERE s2.customer_id = sales.customer_id
);

CREATE VIEW t1 AS
SELECT 
  s.customer_id, 
  s.order_date, 
  s.product_id AS sales_product_id,  -- Rename the duplicate column
  m.product_name, 
  m.price
FROM sales s
JOIN menu m ON s.product_id = m.product_id;


select * from t1;

/*What is the most purchased item on the menu and how many times was it purchased by all customers?*/

select product_name, count(sales_product_id) as no_of_times_ordered
from t1
group by sales_product_id, product_name
order by no_of_times_ordered desc
limit 1 ;

/*Which item was the most popular for each customer?*/
with cte1 as
(select customer_id, product_name,count(product_name) as no_of_times_ordered
from t1
group by customer_id, product_name
order by no_of_times_ordered desc),

cte2 as
(select *,
rank() over (partition by customer_id order by no_of_times_ordered desc) as rnk
from cte1)

select customer_id, product_name, no_of_times_ordered from cte2
where rnk=1
order by customer_id, no_of_times_ordered desc;


create view detail as
select s.*, m.product_name, m.price, m2.join_date
from sales s
join menu m
on s.product_id = m.product_id
join members m2
on s.customer_id = m2.customer_id;

select * from detail;

/* Which item was purchased first by the customer after they became a member?*/
with cte1 as
(select customer_id, order_date,product_name,
rank() over (partition by customer_id order by order_date) as rnk
from detail
where order_date>join_date)

select * from cte1
where rnk = 1;


/* Which item was purchased just before the customer became a member?*/

with cte1 as
(select customer_id, order_date,product_name,
rank() over (partition by customer_id order by order_date desc) as rnk
from detail
where order_date<join_date)
select * from cte1
where rnk = 1;

/* What is the total items and amount spent for each member before they became a member?*/

select customer_id, count(product_name) as no_of_items, sum(price) as total_spnt
from detail
where order_date<join_date
group by customer_id;

/* If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
- how many points would each customer have?*/
WITH cte1 AS (
    SELECT customer_id, product_name, price,
           CASE 
               WHEN product_name = 'sushi' THEN price * 20
               ELSE price * 10
           END AS points
    FROM detail
)
SELECT customer_id, SUM(points) AS total_points
FROM cte1
GROUP BY customer_id
ORDER BY customer_id;


/* In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?*/

WITH first_week_points AS (
    SELECT d.customer_id, d.product_name, d.price,
           CASE 
               WHEN d.order_date <= DATE_ADD(m.join_date, INTERVAL 6 DAY)
               THEN d.price * 20
               ELSE d.price * 10
           END AS points
    FROM detail d
    JOIN members m ON d.customer_id = m.customer_id
    WHERE d.order_date <= '2021-01-31' -- End of January
),
points_summary AS (
    SELECT customer_id, SUM(points) AS total_points
    FROM first_week_points
    GROUP BY customer_id
)
SELECT customer_id, total_points
FROM points_summary
WHERE customer_id IN ('A', 'B')
ORDER BY customer_id;

