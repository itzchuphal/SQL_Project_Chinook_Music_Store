/***
--> Digital Music Store - Data Analysis
Data Analysis project to help Chinook Digital Music Store to help how they can
optimize their business opportunities and to help answering business related questions.
***/

select * from Album; -- 347
select * from Artist; -- 275
select * from Customer; -- 59
select * from Employee; -- 8
select * from Genre; -- 25
select * from Invoice; -- 412
select * from InvoiceLine; -- 2240
select * from MediaType; -- 5
select * from Playlist; -- 18
select * from PlaylistTrack; -- 8715
select * from Track; -- 3503



-- Using SQL solve the following problems using the chinook database.


/***1) Find the artist who has contributed with the maximum no of albums. Display the artist name and the no of albums.***/



with cte as
		(select artistid, count(1) as total_albums
		, rank() over(order by count(1) desc) rnk
		from album 
		group by artistid
		order by count(1) desc)
select at.name as artist_name, cte.total_albums
from artist at
join cte on cte.artistid = at.artistid
where cte.rnk = 1;



/***2) Find the employee who has supported the most no of customers. Display the employee name and designation.***/



select employee_name, title
from 
		(select e.firstname||' '||e.lastname as employee_name, e.title, count(1) as sales
		, rank() over(order by count(1) desc) as rnk
		from employee e
		join customer c on c.supportrepid = e.employeeid
		join invoice i on i.customerid = c.customerid
		group by e.firstname||' '||e.lastname, e.title) s
where s.rnk = 1;



/***3) Which city genrerates most revenue?***/



with cte as
		(select billingcity as city, sum(total) as top_city
		, rank() over(order by sum(total) desc) as rnk
		from invoice 
		group by billingcity)
select city
from cte
where rnk = 1;



/***4) The highest number of invoices belongs to which country?***/



with cte as 
		(select billingcountry as country, count(1) as most_invoices
		, rank() over(order by count(1) desc) as rnk
		from invoice
		group by billingcountry)
select country
from cte
where rnk = 1;



/***5) Name the best customer (customer who spent the most money).***/



with cte as 
		(select customerid, sum(total) as total_purchase
		, rank() over(order by sum(total) desc) as rnk
		from invoice
		group by customerid)
select c.firstname||' '||c.lastname as customer_name, cte.total_purchase
from cte
join customer c on c.customerid = cte.customerid
where rnk = 1;



/***6) Which city would be a great place to host a Rock concert?***/



with cte as 
		(select billingcity as rock_city, count(1) as most_sales
		, rank() over(order by count(1) desc) as rnk
		from invoice i
		join invoiceline il on i.invoiceid = il.invoiceid
		join track tr on tr.trackid = il.trackid
		join genre gr on gr.genreid = tr.genreid
		where gr.name = 'Rock'
		group by billingcity)
select rock_city
from cte
where rnk = 1;



/***7) Identify all the albums who have less then 5 track under them.
    Display the album name, artist name and the no of tracks in the respective album.***/



select ab.title as album_name, at.name as artist_name, count(1) no_of_tracks
from album ab
join artist at on ab.artistid = at.artistid
join track tr on ab.albumid = tr.albumid
group by ab.title, at.name
having count(1) < 5



/***8) Display the track, album, artist and the genre for all tracks which are not purchased.***/



select tr.name as track_name, ab.title as album_name, at.name as artist_name, gr.name as genre
from track tr
join album ab on ab.albumid = tr.albumid
join artist at on at.artistid = ab.artistid
join genre gr on gr.genreid = tr.genreid
where not exists (
				   select * 
				   from invoiceline il 
				   where il.trackid = tr.trackid
				   );



/***9) Find artist who have performed in multiple genres. Diplay the aritst name and the genre.***/



with cte as 
		(select at.name as artist_name, gr.name as genre
		from album ab
		join artist at on at.artistid = ab.artistid
		join track tr on tr.albumid = ab.albumid
		join genre gr on gr.genreid = tr.genreid
		group by at.name, gr.name
		order by 1),
	 cte2 as 
		(select artist_name
		from cte
		group by artist_name
		having count(1) > 1)
select cte2.artist_name, cte.genre
from cte
join cte2 on cte.artist_name = cte2.artist_name



/***10) Which is the most popular and least popular genre? Popularity is defined based on how many times it has been purchased.***/



with cte as
		(select gr.name as genre_name, count(1) as popularity
		,rank() over(order by count(1) desc) as rnk
		from invoiceline il
		join track tr on tr.trackid = il.trackid
		join genre gr on gr.genreid = tr.genreid
		group by gr.name),
	cte2 as 
		(select  max(rnk) as max_rnk
		from cte)
select cte.genre_name, case when cte.rnk = 1 then 'Most_popular' else 'Least_popular' end 
from cte
join cte2 on cte.rnk = 1
	      or cte.rnk = cte2.max_rnk;



/***11) Identify if there are tracks more expensive than others. 
      If there are then display the track name along with the album title and artist name for these expensive tracks.***/



select tr.name as track_name,ab.title as album_name,  at.name as artist_name
from artist at 
join album ab on at.artistid = ab.artistid
join track tr on ab.albumid = tr.albumid
where tr.unitprice > (select min(unitprice)
		    		  from track);



/***12) Identify the 5 most popular artist for the most popular genre.
        Popularity is defined based on how many songs an artist has performed in for the particular genre.
        Display the artist name along with the no of songs.***/



with cte as
		(
		select gr.name as genre_name, count(1) as popularity
		, rank() over(order by count(1) desc) as rnk 
		from invoiceline il
		join track tr on il.trackid = tr.trackid
		join genre gr on gr.genreid = tr.genreid
		group by gr.name
		order by 2 desc
		),
	 cte2 as
		(select at.name as artist_name, count(1) as no_of_tracks
		, rank() over(order by count(1) desc) as rk
		from artist at
		join album ab on at.artistid = ab.artistid
		join track tr on tr.albumid = ab.albumid
		join genre gr on gr.genreid = tr.genreid
		where gr.name = (select genre_name
						 from cte
						 where rnk = 1)
		group by at.name)
select artist_name, no_of_tracks
from cte2
where rk <= 5;



/***13) Find the artist who has contributed with the maximum no of songs/tracks. Display the artist name and the no of songs.***/



with cte as
		(select at.name as artist_name, count(1) as no_of_songs
		, rank() over(order by count(1) desc) as rnk
		from artist at
		join album ab on at.artistid = ab.artistid
		join track tr on tr.albumid = ab.albumid
		group by at.name)
select artist_name, no_of_songs
from cte
where rnk = 1;




