/*
--Table & Schema Creation
create table df_orders
(
	order_id int,
	order_date date,
	ship_mode varchar(50),
	segment varchar(50),
	country varchar(50),
	city varchar(50),
	state varchar(50),
	postal_code int,
	region varchar(50),
	category varchar(50),
	sub_category varchar(50),
	product_id varchar(50),
	quantity int,
	discount decimal(7, 2),
	sales_price decimal(7, 2),
	profit decimal(7, 2)
);
*/

select * from df_orders;


--1. Find the top 10 highest revenue generating products
select top 10 * from (
select distinct product_id, sum(profit) as Revenue from df_orders
group by product_id
) a
order by a.Revenue desc

--2. Find the top 5 highest selling products in each region
with cte as(
select 
	region, 
	product_id, 
	SUM(sales_price) as sales,
	row_number() over(partition by region order by sum(sales_price) desc) as rnk
from df_orders
	group by region, product_id
	)
	select * from cte where rnk <= 5
	
--3. Find Month Over Month growth comparison for 2022 and 2023 sales eg: Jan 22 & Jan 23
with cte as(
select
	year(order_date) as order_year,
	month(order_date) as order_month,
	sum(sales_price) as sales
from df_orders
	group by year(order_date), month(order_date)
	--order by year(order_date), month(order_date)
	)
select 
	order_month,
	sum(case when order_year = 2022 then sales else 0 end) as sales_22,
	sum(case when order_year = 2023 then sales else 0 end) as sales_23,
	sum(case when order_year = 2022 then sales else 0 end) - sum(case when order_year = 2023 then sales else 0 end) as mom_change
	from cte
	group by order_month
	order by order_month

--4. Which month had the highest sales for each category
with cte as
(
select 
	category,
	month(order_date) as order_month,
	sum(sales_price) as sales,
	row_number() over(partition by category order by sum(sales_price) desc) as rnk
from df_orders
	group by category, month(order_date)
)
select
	category,
	order_month,
	sales
from cte
where rnk = 1

--5. Which subcategory had the highest growth by profit in 2023 compared to its previous year
with cte as
(
select sub_category, year(order_date) as order_year, sum(profit) as sales
from df_orders
group by sub_category, year(order_date)

)
select sub_category, 
	   sum(case when order_year = 2022 then sales else 0 end) as profit_2022,
	   sum(case when order_year = 2023 then sales else 0 end) as profit_2023,
	   sum(case when order_year = 2022 then sales else 0 end) - sum(case when order_year = 2023 then sales else 0 end) as yoy_change
	   from cte
	   group by sub_category

