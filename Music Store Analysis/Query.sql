-- Q1: Who is the senior most employee based on the job title?

select first_name, last_name, title, levels 
from employee
order by levels desc 
limit 1;

-- Q2: Which countries have the most invoices?

select billing_country as country, count(invoice_id) as invoices 
from invoice 
group by country 
order by invoices desc;

-- Q3: Which city has the best customers? We would like to 
-- throw a promotional Music Festival in the city where 
-- we made the most money. Write a query that returns one 
-- city that has the highest sum of invoice totals.

select billing_city, round(sum(total),2) as invoice_total 
from invoice 
group by billing_city 
order by invoice_total desc 
limit 1;

-- Q4: Write a query that returns the person who has spent 
-- the most money.

select customer.customer_id, first_name, last_name,
round(sum(invoice.total),2) as amount_spent
from customer 
join invoice on customer.customer_id = invoice.customer_id
group by customer_id, first_name, last_name
order by amount_spent desc 
limit 1;

-- Q5: Write a query to return the email, first name, last name, 
-- and genre of all Rock Music listeners. Return your list 
-- ordered alphabetically by email.

select distinct first_name, last_name, email from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
	select track_id from track 
	join genre on track.genre_id = genre.genre_id
	where genre.name like 'Rock'
)
order by email asc;

-- Q6: Let's invite the artists who have written the most rock 
-- music in our dataset. Write a query that returns the Artist 
-- name and total track count of the top 7 rock bands.

select artist.name, count(track.track_id) as total_track 
from artist
join album2 on artist.artist_id = album2.artist_id
join track on album2.album_id = track.album_id
join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock'
group by artist.name 
order by total_track desc 
limit 7;

-- Q7: Return all the track names that have a song length longer 
-- than the average song length. Return the Name and 
-- Milliseconds for each track. Order by the song length with 
-- the longest songs listed first.

select name, milliseconds 
from track
where milliseconds > 
	(select avg(milliseconds) from track)
order by milliseconds desc;

-- Q8: Find how much amount spent by each customer on artists. 
-- Write a query to return the customer name, artist name, 
-- and total spent.

with best_selling_artist as(
	select artist.artist_id, artist.name as artist_name, 
	sum(invoice_line.unit_price*invoice_line.quantity) 
	from invoice_line
	join track on invoice_line.track_id = track.track_id
	join album2 on track.album_id = album2.album_id
	join artist on album2.artist_id = artist.artist_id
	group by 1,2
	order by 3 desc limit 1
)
select c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
round(sum(invoice_line.unit_price*invoice_line.quantity),2) 
as total_spent from customer c
join invoice on c.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
join track on invoice_line.track_id = track.track_id
join album2 on track.album_id = album2.album_id
join best_selling_artist bsa on album2.artist_id = bsa.artist_id
group by 1,2,3,4 
order by 5 desc;

-- Q9: We want to find out the most popular music Genre for each
-- country. We determine the most popular genre as the genre with 
-- the highest amount of purchases. Write a query that returns
-- each country along with the top Genre. For countries where the 
-- maximum number of purchases is shared return all Genres.

with popular_genre as(
	select c.country, count(invoice_line.quantity) as purchases, 
	genre.genre_id as genre_id, genre.name as genre_name,
	row_number() over(partition by c.country order by 
    count(invoice_line.quantity) desc) as rn
	from customer c
	join invoice on c.customer_id = invoice.customer_id
	join invoice_line on invoice.invoice_id = invoice_line.invoice_id
	join track on invoice_line.track_id = track.track_id
	join genre on track.genre_id = genre.genre_id
	group by c.country, genre_id, genre_name
	order by c.country asc, purchases desc
)
select * from popular_genre where rn <= 1;

-- Q10: Write a query that determines the customer that has spent the 
-- most on music for each country. Write a query that returns the 
-- country along with the top customer and how much they spent.
-- For countries where the top amount spent is shared, provide 
-- all customers who spent this amount.

with customer_with_country as(
	select c.first_name, c.last_name, invoice.billing_country, 
	round(sum(invoice.total),2) as amount_spent,
	row_number() over(partition by invoice.billing_country 
    order by sum(invoice.total) desc) as rn
	from customer c
	join invoice on c.customer_id = invoice.customer_id
	group by 1,2,3 
    order by 3 asc, 4 desc
)
select * from customer_with_country where rn<=1;  