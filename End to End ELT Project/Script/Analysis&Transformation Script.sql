---------------------------------------------------
--Transformations
---------------------------------------------------
---------------------------------------------------
-- T1: Handling Foreign characters
---------------------------------------------------
--Table & Schema creation
CREATE TABLE [dbo].[netflix_raw](
	[show_id] [varchar](10) primary key,
	[type] [varchar](10) NULL,
	[title] [nvarchar](200) NULL,
	[director] [varchar](250) NULL,
	[cast] [varchar](1000) NULL,
	[country] [varchar](150) NULL,
	[date_added] [varchar](20) NULL,
	[release_year] [int] NULL,
	[rating] [varchar](10) NULL,
	[duration] [varchar](10) NULL,
	[listed_in] [varchar](100) NULL,
	[description] [varchar](500) NULL
);


---------------------------------------------------
-- T2: Remove Duplicates
---------------------------------------------------
--Checking for duplicates by PK
select 
	show_id, 
	count(*) duplicate_records
from
	netflix_raw
group by 
	show_id
having count(*) > 1;

--Checking for duplicates by another column
select
	title,
	type,
	count(*) duplicate_records
from
	netflix_raw
group by
	title, type
having count(*) > 1;

--Removing duplicates
with cte as
(
select 
	*,
	row_number() over(partition by title, type order by show_id) as rnk
from
	netflix_raw
)
select * from cte where rnk = 1

---------------------------------------------------------------------
-- T3: New Table for the columns: listed in, director, cast, country
---------------------------------------------------------------------

select 
	show_id,
	trim(value) as director
into 
	netflix_directors
from
	netflix_raw
cross apply string_split(director, ',');

select 
	show_id,
	trim(value) as cast
into 
	netflix_cast
from
	netflix_raw
cross apply string_split(cast, ',');

select 
	show_id,
	trim(value) as country
into 
	netflix_country
from
	netflix_raw
cross apply string_split(country, ',');

select 
	show_id,
	trim(value) as genre
into 
	netflix_genre
from
	netflix_raw
cross apply string_split(listed_in, ',');

select * from netflix_cast
select * from netflix_country
select * from netflix_genre
select * from netflix_directors

---------------------------------------------------------------------
-- T4: Data type conversion - data_added column
---------------------------------------------------------------------

with cte as
(
select 
	*,
	row_number() over(partition by title, type order by show_id) as rnk
from
	netflix_raw
)
select 
show_id, type, title, cast(date_added as date) as date_added, release_year, rating, duration, description
from cte where rnk = 1

---------------------------------------------------------------------------
-- T5: Populate missing values in duration & Create a new transformed table
---------------------------------------------------------------------------
select * from netflix_raw
where duration is null

with cte as
(
select 
	*,
	row_number() over(partition by title, type order by show_id) as rnk
from
	netflix_raw
)
select 
show_id, type, title, cast(date_added as date) as date_added, release_year, rating, 
case when duration is null then rating else duration end as duration, description
into netflix
from cte 
where rnk = 1

---------------------------------------------------------------------------
--Analysis
---------------------------------------------------------------------------

--1. For each director count the no of movies and Tv shows by them in separate columns

select 
	d.director, 
	sum(case when n.type = 'Movie' then 1 else 0 end) as total_movies,
	sum(case when n.type = 'TV Show' then 1 else 0 end) as total_shows
from 
	netflix n
inner join 
	netflix_directors d
on 
	n.show_id = d.show_id
group by 
	d.director;

--2. Whixh country has produced highest number of comedy movies

select 
	top 1 c.country, 
	count(*) as total_movies 
from 
	netflix_country c
inner join 
	netflix_genre g
on 
	c.show_id = g.show_id
where 
	g.genre = 'Comedies'
group by 
	c.country
order by 
	total_movies desc;

--3. For each year, which director has released the maximum number of movies
with cte as
(
select 
	year(n.date_added) as year_added,
	d.director,
	count(*) total_movies_released,
	rank() over(partition by year(n.date_added) order by count(*) desc) rnk
from 
	netflix n 
inner join
	netflix_directors d
on 
	n.show_id = d.show_id
where 
	n.type = 'Movie'
group by
	year(n.date_added),
	d.director
)
select year_added, director, total_movies_released 
from cte
where rnk = 1


--4. Average duration of movies in each genre
with cte as
(
select
	g.genre,
	cast(substring(n.duration, 1, CHARINDEX(' ', n.duration)-1) as int) as duration_int
from 
	netflix n
inner join 
	netflix_genre g
on 
	n.show_id = g.show_id
where 
	n.type = 'Movie'
group by 
	g.genre,
	n.duration
)
select 
	genre, 
	avg(duration_int) as avg_duration
from 
	cte
group by 
	genre
order by 
	avg_duration desc

--5(i). Find the list of directors who has created both horror & comedy movies
-- (ii) display director names along with the no of comedy and horror movies directed by them

select 
	distinct d.director,
	sum(case when genre = 'Horror Movies' then 1 else 0 end) as total_horror_movies,
	sum(case when genre = 'Comedies' then 1 else 0 end) as total_comedy_movies
from 
	netflix_directors d
inner join 
	netflix_genre g
on
	d.show_id = g.show_id
where
	g.genre = 'Horror Movies' OR g.genre = 'Comedies'
group by
	d.director

