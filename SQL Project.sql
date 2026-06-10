-- 													SWIGGY SQL PROJECT

use swiggy_data;

--                             						TOTAL ROWS IN OUR DATASET

select count(*) from dataset;

-- 													CHECK FOR NULL VALUES IN EACH COLUMN

select 
	sum(case when state is null then 1 else 0 end) as null_state,
    sum(case when city is null then 1 else 0 end) as null_city,
    sum(case when order_date is null then 1 else 0 end) as null_order_date,
    sum(case when restaurant_name is null then 1 else 0 end) as null_restaurant_name,
    sum(case when location is null then 1 else 0 end) as null_location,
    sum(case when category is null then 1 else 0 end) as null_category,
    sum(case when dish_name is null then 1 else 0 end) as null_dish_name,
    sum(case when price_inr is null then 1 else 0 end) as null_price_inr,
    sum(case when rating is null then 1 else 0 end) as null_rating,
    sum(case when rating_count is null then 1 else 0 end) as rating_count
from dataset;

-- 													CHECKING BLANK OR EMPTY RECORDS IN DIMENSION TABLE

select * 
from dataset
where state = '' or city = '' or restaurant_name = '' or location = '' or category = '' or dish_name = '';

-- 													CHECK DUPLICATE FOR 

select state, city, order_date, restaurant_name, location, category, dish_name, price_inr, rating, rating_count, count(*) as ct
from dataset
group by state, city, order_date, restaurant_name, location, category, dish_name, price_inr, rating, rating_count
having ct > 1
order by state;

-- 													ADDING INDEXING

alter table dataset 
add column id int auto_increment primary key;

-- 													DELETE DUPLICATE ROWS

WITH cte AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY state, city, order_date, restaurant_name, location, category, dish_name, price_inr, rating, rating_count 
               ORDER BY (SELECT NULL)
           ) AS num
    FROM dataset
)	
DELETE d
FROM dataset AS d
JOIN cte AS c ON d.id = c.id AND c.num > 1;


-- 														TOTAL ORDERS

select count(*) as total_order 
from fact_table;

-- 														TOTAL REVENUE

select concat(round((sum(price_inr)/10000000),2),' Cr') as total_revenue 
from fact_table;

-- 														AVERAGE DISH PRICE

select round(avg(price_inr),2) as avg_dish_price
from fact_table;

-- 														AVERAGE RATING

select round(avg(rating),1) as avg_rating
from fact_table;

-- 														DEEP-DIVE BUSINESS ANALYSIS
-- 														MONTHLY REVENUE TREND

select d.years,d.month_name, d.month, CONCAT(ROUND(((sum(f.price_inr))/100000),2),' LAKH') as total_revenue
from date_table as d
join fact_table as f
on d.date_id = f.date_id
group by d.years, d.month_name, d.month
order by d.month asc;

-- 														QUARTERLY ORDER TREND

select d.quarter, count(f.order_id) as total_order
from fact_table as f
join date_table as d
on f.date_id = d.date_id
group by d.quarter
order by d.quarter asc;

-- 														YEARLY ORDER TREND

select d.years, count(f.order_id) as total_sales
from fact_table as f
join date_table as d
on f.date_id = d.date_id
group by d.years;

-- 														DAY WISE ORDER TREND

select d.day_name,d.weekday_num, count(f.order_id) as total_order
from fact_table as f
join date_table as d
on f.date_id = d.date_id
group by d.day_name,d.weekday_num
order by d.weekday_num asc;

-- 														LOCATION WISE ANALYSIS
-- 														TOP 10 CITY BY ORDER VOLUME

select l.city, count(f.order_id) as total_order
from fact_table as f
join location_table as l
on f.location_id = l.location_id
group by l.city
order by count(f.order_id) desc
limit 10;

-- 														REVENUE CONTRIBUTION BY STATE
								
select l.state, sum(f.price_inr) as total_revenue
from fact_table as f
join location_table as l
on f.location_id = l.location_id
group by l.state
order by sum(f.price_inr) desc;

-- 														FOOD PERFORMANCE
-- 														TO 10 RESTAURANT BY ORDER

select r.rest_name, count(f.order_id) as total_order
from fact_table as f
join restaurant_table as r
on f.rest_id = r.rest_id
group by r.rest_name
order by count(f.order_id) desc
limit 10;

-- 														TOP CATEGORIES BY ORDERS

select c.category_name, count(f.order_id) as total_order
from fact_table as f
join category_table as c
on f.category_id = c.category_id
group by c.category_name
order by count(f.order_id) desc
limit 5;

-- 														MOST ORDERED DISHES

select d.dish_name, count(f.order_id) as total_order
from fact_table as f
join dish_table as d
on f.dish_id = d.dish_id
group by d.dish_name
order by count(f.order_id) desc
limit 5;

-- 														CUISINE PERFORMANCE --> ORDRES + AVG RATING

select c.category_name, count(f.order_id) as total_order, round(avg(f.rating),1) as avg_rating
from fact_table as f
join category_table as c
on f.category_id = c.category_id
group by c.category_name
order by count(f.order_id) desc;

-- 														CITY WISE MONTH WISE TOTAL ORDERS

select l.city, d.month_name,d.month, count(f.order_id) as total_order
from fact_table as f
join location_table as l
on f.location_id = l.location_id
join date_table as d
on f.date_id = d.date_id
group by l.city, d.month_name, d.month
order by l.city asc, d.month asc;
