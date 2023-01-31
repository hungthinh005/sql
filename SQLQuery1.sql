

-- Union Sales 2015 with Sales 2016 and Sales 2017
with all_sales as(
	select * 
	from sales_2015
	union
	select * 
	from sales_2016
	union
	select * 
	from sales_2017
)

-- Calculate total order of all_sales
, total_order as (
	select
	count(*) as total
	from 
	all_sales
)

-- Calculate number of order by Region
, number_order_by_region as (
	select distinct 
		t.Region,
		count (*) as num
	from all_sales c
	left join territories t on t.SalesTerritoryKey = c.TerritoryKey
	group by t.Region
)

--Join return_table to get return quantity
, return_sale as (
select 
	s.OrderDate, 
	s.StockDate, 
	s.OrderQuantity, 
	s.ProductKey, 
	s.TerritoryKey, 
	r.ReturnQuantity, 
	r.ReturnDate
from all_sales s
left join returns_table r on s.ProductKey = r.ProductKey
				and s.TerritoryKey = r.TerritoryKey
)	
	
	
-- Find Percentage of order by Region
select 
*,
cast(nu.num as float)/cast(total_order.total as float)*100 as 'percentage'
from number_order_by_region nu
cross join total_order 



-- Find number of order by productkey
select 
	ProductKey, 
	TerritoryKey, 
	SUM(cast(OrderQuantity as int)) as order_number
from all_sales
group by ProductKey, TerritoryKey


-- Calculate return rate by productkey
;with summary (ProductKey, TerritoryKey, order_number, return_number, return_qty) as(
	select 
		order_groupby.*,
		re.return_number,
		(case when re.return_number > 0 then re.return_number else 0 end) as return_qty
	from (	
		select 
			s1.ProductKey, 
			s1.TerritoryKey, 
			SUM(cast(s1.OrderQuantity as int)) as order_number
		from all_sales s1
		group by s1.ProductKey, s1.TerritoryKey
		) as order_groupby
	left join (
		select 
			r1.ProductKey, 
			r1.TerritoryKey, 
			SUM(cast(r1.ReturnQuantity as int)) as return_number
		from returns_table r1
		group by r1.ProductKey, r1.TerritoryKey ) as re on order_groupby.ProductKey = re.ProductKey
								and order_groupby.TerritoryKey = re.TerritoryKey
)

-- Create table for visualization
drop table if exists #product
create table #product (
	ProductKey numeric,
	order_number numeric, 
	return_qty numeric,  
	return_rate numeric,
	ProductSKU varchar(50), 
	ProductName varchar(50), 
	ModelName varchar(50), 
	ProductCost numeric, 
	ProductPrice numeric
)

insert into #product
	select 
		ps.ProductKey,
		ps.order_number, 
		ps.return_qty,  
		(cast(return_qty as float)/cast(order_number as float))*100 as return_rate,
		p.ProductSKU, 
		p.ProductName, 
		p.ModelName, 
		p.ProductCost, 
		p.ProductPrice
	from summary ps
	left join products p 
		on ps.ProductKey = p.ProductKey
	order by 1 asc


select * from #product

create view product as
	select 
		ps.ProductKey,
		ps.order_number, 
		ps.return_qty,  
		(cast(return_qty as float)/cast(order_number as float))*100 as return_rate,
		p.ProductSKU, 
		p.ProductName, 
		p.ModelName, 
		p.ProductCost, 
		p.ProductPrice
	from summary ps
	left join products p 
		on ps.ProductKey = p.ProductKey
	order by 1 asc
