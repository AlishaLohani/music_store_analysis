SELECT * FROM album
 
--1.who is the senior most employee based on job title?
select * from employee
order by levels desc
limit 1

--2.which countries have the most invoices
select COUNT(*) as c, billing_country from invoice
group by billing_country
order by c desc

--3. what are the top 3 values of total invoice?
select total from invoice
order by total desc
limit 3

--4. which city has the best customers? we would like to throw a promotional music festival in tht ecity we made most money
--   write a quer that returns one city that has the highest sum of invoice totals. return both the city name and sum of all invoices totals
select billing_city, SUM(total) AS invoice_total 
from invoice
group by billing_city
order by invoice_total desc

--5. who is the best customer? the customer who has spent the most money will be declared the best customer. write the query that returns the
--   person who has spent the most money
select c.customer_id,c.first_name, c.last_name, SUM(i.total) as total from customer as c
join invoice as i on
c.customer_id = i.customer_id
group by c.customer_id
order by total desc
limit 1

--6. write query to return the email,first name,last name, and genre of all rock music listeners. return your ordered list alphabetically by email starting with A.
select first_name,last_name,email from customer
join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
	select track_id from track
	join genre on track.genre_id = genre.genre_id
	where genre.name like 'Rock'
)
order by email;


--7. lets invite the artists who have written the most rock music in our dataset. write a query thta returns the artist name and total track count of the top 10 rock bands

select artist.artist_id,artist.name, count(artist.artist_id) as number_of_songs
from track
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id = track.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit 10;


--8.return all the track  names that have a song length longer that the average song length. return the name  and milliseconds for each track. order by the song length with the longest songs listed first.
select name,milliseconds
from track
where milliseconds > (
	select avg(milliseconds) as avg_track_length
	from track
)
order by milliseconds desc;


--9. find how much spent by each customer on artists. write a query to return customer name, artist name and total spent
with best_selling_artist as (
	select artist.artist_id as artist_id, artist.name as artist_name,
	sum(invoice_line.unit_price*invoice_line.quantity) as total_sales
	from invoice_line
	join track on track.track_id = invoice_line.track_id
	join album on album.album_id = track.album_id
	join artist on artist.artist_id = album.artist_id
	group by 1
	order by 3 desc
	limit 1
)

select c.customer_id,c.first_name,c.last_name,bsa.artist_name, sum(il.unit_price*il.quantity) as amount_spent
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album alb on alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = alb.artist_id
group by 1,2,3,4
order by 5 desc;

--10.we want to find out the most popular music genrefor each country.
--   we determine the most popular genre as the genre with the highest
--   amount of purchases. write a query that returns each country along with the top genre.
--   for countries where the maximum number of purchases is shared return all genres.
with popular_genre as
(
select count(invoice_line.unit_price) as purchases, customer.country, genre.name, genre.genre_id,
ROW_NUMBER() OVER(PARTITION BY customer.country order by count(invoice_line.quantity) DESC) AS RowNo
from invoice_line
join invoice on invoice.invoice_id = invoice_line.invoice_id
join customer on customer.customer_id = invoice.customer_id
join track on track.track_id = invoice_line.track_id
join genre on genre.genre_id =  track.genre_id
group by 2,3,4
order by 2 asc, 1 desc
)
select * from popular_genre where RowNo <= 1


--11. writ a query that determines the customer that has spent the most on music for each country. write a
--    query thta returns the country along with the top customer and how much they spent. for countries
--    where the top amount spent is ahred, provide all customers who spent his amount.

with recursive
     customer_with_country as (
		 select customer.customer_id,first_name,last_name,billing_country, sum(total) as total_spending
		 from invoice
		 join customer on customer.customer_id =  invoice.customer_id
		 group by 1,2,3,4
		 order by 2,3 desc),
		 
	 country_max_spending as(
		 select billing_country,max(total_spending) as max_spending
		 from customer_with_country
		 group by billing_country
	 )
select cc.billing_country,cc.total_spending, cc.first_name, cc.last_name
from customer_with_country cc
join country_max_spending ms
on cc.billing_country = ms.billing_country
where cc.total_spending = ms.max_spending
order by 1;


--or

with Customer_with_country as (
	select customer.customer_id,first_name,last_name,billing_country, sum(total) as total_spending,
	row_number() over(partition by billing_country order by sum(total) desc) as RowNo
	from invoice
	join customer on customer.customer_id = invoice.customer_id
	group by 1,2,3,4
	order by 4 asc, 5 desc
)
select * from Customer_with_country where RowNo <= 1
	 