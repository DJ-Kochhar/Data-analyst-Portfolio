/*i am the owner of a movie rental company and i am going to do some analysis to look at a variety of things */

-- how many moives are in our inventory
	select distinct
		count(*)
	from
		film;
-- We have a total of 1,000 different moives in our system 

-- now, I would like to see the stock I have for each movie and the genere each movie belongs to
select
	a.film_id,
    b.title,
    d.name as genre,
	count(a.film_id) as 'quantity in stock'
from
	inventory as a
inner join 
	film as b
on
	a.film_id = b.film_id
inner join
	film_category as c
on
	b.film_id = c.film_id
inner join
	category as d
on
	c.category_id = d.category_id
group by
a.film_id,
b.title,
d.name
order by
film_id;
-- here we can see every movie we have and the quantity we have in stock for that movie. the rang of copies for a moive goes from 8 copys to 2 copys

-- how do the genres as a whole rank in terms of revenue production for our organization? This will allow us to determine which genres we should invest more in.

select
	e.name as 'genre',
    sum(a.amount) as 'revenue per category',
    sum(sum(a.amount))
		over () as 'grand total'
from
	payment as a
inner join
	rental as b
on
	a.rental_id = b.rental_id
inner join
	inventory as c
on
	b.inventory_id = c.inventory_id
inner join
	film_category as d
on
	c.film_id = d.film_id
inner join
	category as e
on
	d.category_id = e.category_id
group by
	e.name
order by 
sum(a.amount);
/* our top three revenue producing genres are Sports, Sci-Fi and Animation while our lowest revenue producing genres are Music, Travel, and Classics. 
we should consider decreasing our catelog of our lower selling genres while increasing our catelog of movies in the genres that provide our organization with more revenue.*/

-- knowing the revenue of our genres, lets determine the popularity of our moives. this will allow us to determine which moives to replace and which moives we should keep.
select
	c.title,
    dense_rank () over (order by count(a.rental_id) desc) as 'all time rental rank'
from
	rental as a
left join
	inventory as b
on a.inventory_id = b.inventory_id
inner join
	film as c
on
 c.film_id = b.film_id	
group by
	c.title
order by
	dense_rank () over (order by count(a.rental_id)) desc;
/*  bucket of brotherhood is our most popular movie while three moives are tied for last in popularity. to be more specific, lets take a look at how many times the movies have been 
rented  along with their rank*/    

-- how many times has each movie been rented?
select
	c.title,
	count(a.rental_id) 'times movie rented',
     dense_rank () over (order by count(a.rental_id) desc) as 'all time rental rank'
from
	rental as a
left join
	inventory as b
on a.inventory_id = b.inventory_id
inner join
	film as c
on
 c.film_id = b.film_id	
group by
	c.title
order by
	count(a.rental_id) desc;
/* the query above provides us a much more complete picture. we can see that the number 1 move rented from our inventory is  bucket brotherhood, which was rented out the most at 34 times. 
the least popular moives we have in our stock is a three-way tie between Hardley Robbers, Mixed Doors, and Train Bunch who all have only been rented out 4 times each. */

-- how much money has each movie brought to the company?
select
	d.title,
    sum(a.amount) as 'revenue per movie'
from
	payment as a
inner join
	rental as b
on
	a.rental_id = b.rental_id
inner join
	inventory as c
on
	b.inventory_id = c.inventory_id
inner join
	film as d
on
	c.film_id = d.film_id
group by
	d.title with rollup
order by
	sum(a.amount) desc;


-- we now have a good understanding of our inventory. Lets look at customer habits and sales to see if we can gain some valuable insights.

-- First, I need to know how many customers have rented a movie from us.
select
	count(*)
from
	customer;
/* we have a total of 599 customers who have rented a movie with us. next lets determine where our customers are located. 
more specificaly, lets take a look at which countires our customers are located in and which country holds the largest percentage of our customers*/


    WITH cte_customers (country, num_customers, perecnt_of_total_population) AS
    (
		select
			d.country,
			count(a.customer_id) as 'number of customers',
            round(count(a.customer_id) / sum(count(a.customer_id)) over () * 100, 2) as 'pct_of_total'
		from
			customer as a
		inner join
			address as b
		on
			a.address_id = b.address_id
		inner join
			city as c
		on
			b.city_id = c.city_id
		inner join
			country as d
		on
			c.country_id = d.country_id
		group by
			d.country
		order by
			count(a.customer_id))
      select
		*
	from
		cte_customers;
	/*india, China, and the USA have the largest group of our customers. These three countires account for 25% of our customer population.  
    is the porportion of our custer population per country consistent with revenue per country? */
    
    WITH cte_customers (country, num_customers, perecnt_of_total_population, total_sales_per_country, Perect_of_total_sales ) AS
    (
    select
	e.country,
    count(distinct(b.customer_id)) as 'number of customers',
            round(count(distinct(b.customer_id)) / sum(count(distinct(b.customer_id))) over () * 100, 2) as 'pct_of_total_population',
	sum(a.amount) as 'total sum by country',
    round(sum(a.amount) / sum(sum(a.amount)) over () * 100, 2) as 'percent of total'
from
	payment as a
inner join
		customer as b
on a.customer_id = b.customer_id
	inner join
		address as c
	on
		b.address_id = c.address_id
	inner join
		city as d
	on
     c.city_id = d.city_id
	inner join
		country as e
	on
		d.country_id = e.country_id
	group by
		e.country
	order by
		sum(a.amount))
	
    select
		*
	from
		cte_customers;
-- for the most part, the percent of total customers per country is consistent with the percent of sales revenue that country provides our organization.

-- Lets take a look at our customers from a more granular level. How many movies have been rented from us and total revenue all time?
select
	count(a.rental_id) as 'total moives rented',
    sum(b.amount) as 'total revenue',
    round(count(a.rental_id)/ count(distinct(a.customer_id)), 0) as 'average number of rentals per customer',
    round(sum(b.amount)/ count(distinct(b.customer_id)), 2) as 'average spent per customer'
from
	rental as a
join
	payment as b
on
	a.rental_id = b.rental_id;
-- we have had a total of 16044 rentals bringing our company a total of $67,406.56 with each customer renting on average 27 movies with us. Our customers have spent an average of 112.53 with us.

-- which customers have spent the most on our movies?
select
	a.customer_id,
    a.first_name,
    a.last_name,
    sum(b.amount) as 'amount spent'
from
	customer as a
right join
	payment as b
on
	a.customer_id = b.customer_id
group by
	customer_id
order by
	sum(amount) desc;
    
-- Karl seal was our number 1 spending customer at a total of $221.55 spent on movies. while Caroline Bowman has spent the least on moives thus far at only $50.85

-- lets take a look at how revenue from each customer compares to the average revenue per customer
select
	a.customer_id,
    a.first_name,
    a.last_name,
    sum(b.amount) as 'amount spent',
    Round(avg(sum(amount)) over (), 2) as 'average spent',
    sum(b.amount) - Round(avg(sum(amount)) over (), 2) as 'difference from average'
from
	customer as a
right join
	payment as b
on
	a.customer_id = b.customer_id
group by
	customer_id
order by
	sum(amount) desc;
/*for simplicity, lets group our customers where if they spent more then the average of $112.53 then they are clasified as above average, and if they spent less then the average,
they are clasified as below average. lets also lable the highest spender and lowest spenders*/

select
	a.customer_id,
    a.first_name,
    a.last_name,
    sum(b.amount) as 'total spent on movies',
	case
		when
			rank () over (order by sum(amount) desc) = 1 then 'TOP SPENDER'
		when 
			sum(b.amount) > Round(avg(sum(amount)) over (), 2) then 'above average'
		when
			sum(b.amount) = Round(avg(sum(amount)) over (), 2) then 'average'
		when
			rank () over (order by sum(amount) asc) = 1 then 'LOWEST SPENDER'
			else 'below average'
		end 'spend level'
    
from
	customer as a
right join
	payment as b
on
	a.customer_id = b.customer_id
group by
	customer_id
order by
	a.customer_id;
    

