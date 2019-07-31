-- CREATE SCHEMA `camdram_dw` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs ;


/* Order to run stuff in so far

*** SETUP - RUN ONCE TO INITIALIZE DB ***

1. CREATE SCHEMA `camdram_dw` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs ;
		* Case Sensitive collation is potentially important... 
2. call setup_numbers();				-- No dependencies
3. call setup_extract_tables();		-- No dependencies
4. call setup_extract_views();		-- Depends on numbers
5. call setup_dim_date();				-- Depends on numbers and some views
6. call setup_dim_time();				-- Depends on numbers

At this point there's a bunch of defined objects but no actual data

*** REGULAR RELOAD PROCESS ***

1. call run_extract_dims();		-- Populates the extract_dim tables, 0.3s. Hits the prod database.
2. call run_extract_facts();	-- Populates extract_fct tables, 1s. Hits the prod database.

*/



SELECT * FROM camdram_prod.acts_performances
order by start_at asc
;

SELECT * FROM camdram_prod.acts_shows;

SELECT * 
FROM camdram_prod.acts_people_data
 where id = 10
;


SELECT * FROM camdram_prod.acts_access;

SELECT * FROM camdram_prod.acts_users
order by id desc;

select * 
from camdram_prod.acts_societies
where 	type=0
;


SELECT min(start_at), max(repeat_until) 
FROM camdram_prod.acts_performances
where sid is not null
;



-- Show.venid and show.venue are going away imminently, ignore them

select 	distinct venid, venue
from 	camdram_prod.acts_performances
;
-- If we have a venid it's a valid venue from the main venue list, and the venue text is irrelevant




select 	distinct 
        category
from 	camdram_prod.acts_shows
;

select 	min(timestamp), max(timestamp), count(1)
from 	camdram_prod.acts_shows
where 	category in ('0','1','2','3','4','5')
;

select 	category, title, author, timestamp
from 	camdram_prod.acts_shows
where 	category = '1'
order by category
;
-- 1 seems to be comedy and should be gone now
-- 2 musical - should all be gone now
-- 3 opera - shouldn't be any more 3s now
-- 4 maps to drama in front end but is that right, only three 4s...they are all dance
	-- there should be no 4s left in an updated database dump
-- 5 should also be gone


select 		distinct 
			email
			,locate('@', email) as AtSignIndex
            ,right(email, length(email)-locate('@', email)) as EmailDomain
from 		camdram_prod.acts_users
;

select 		distinct
			right(email, length(email)-locate('@', email)) as EmailDomain
            ,case 
				when email like '%cam.ac.uk' then 'cam.ac.uk'
                when email like '%@cantab.net' then 'cantab.net'
                else 'other'
			 end as EmailDomainCleaned
from 		camdram_prod.acts_users
-- group by 	right(email, length(email)-locate('@', email))
-- order by 	count(1) desc
;


select * 
from camdram_prod.acts_societies
where 	type=0
;



select 	max(json_length(socs_list))
from 	camdram_prod.acts_shows;

select 	row_number() over (order by id)
from 	camdram_prod.acts_shows
limit 10
;



select *
from camdram_dw.numbers
limit 50
;


SELECT max(length(SocietyComboValueRaw))
		,max(length(SocietyNameRaw))
        ,max(SocietyComboKey)
        ,max(SocietyDisplaySortOrder)
        ,max(SocietyId)
FROM camdram_dw.extractv_dim_society_combo;

select max(id) from camdram_prod.acts_societies;

select max(length(SocietyAffiliatedCollege)) from camdram_dw.extractv_dim_society_official;

select max(length(author)), max(length(title)), max(length(category))
from camdram_prod.acts_shows;


select max(id)
from camdram_prod.acts_users;

select max(length(VenueName)), max(length(VenueNameShort)), max(length(VenueAddressRaw))
from camdram_dw.extractv_dim_venue_official;
select max(length(VenueNameRaw))
from camdram_dw.extractv_dim_venue_free;


select distinct VenueLatitude, VenueLongitude
from camdram_dw.extractv_dim_venue_official;



select distinct StoryType from extract_dim_story;

-- Now work on the fact extract
-- row per performance: this is more rows than are stored in acts_performances!
-- As per Kimball as well as date and time dim keys I will eventually want a datestamp on the fact as well
-- But don't get too ahead, this is just a cols and rows extract.

-- Note, start_at appears to be always GMT (+0) not accounting for summer time etc

SELECT * FROM camdram_prod.acts_performances
order by start_at asc
;
select * from camdram_prod.acts_shows;


select * from camdram_prod.acts_shows
where id in (10,2081,3899);

SELECT * 
FROM camdram_prod.acts_performances
where sid is not null 
and cast(start_at as char(20)) != '0000-00-00 00:00:00'
;

SELECT *, cast(start_at as char(20))
FROM camdram_prod.acts_performances
where sid=10
and cast(start_at as char(20)) != '0000-00-00 00:00:00'
;

-- Most of this is now in the extractv_fct_performances, except the breeding rows with date dim
select 		
            DA.DateValue
			,cast(PF.start_at as time)						as PerformanceTimeValue_GMT
            ,timestamp(DA.DateValue, cast(PF.start_at as time))	as PerformanceTimestamp_GMT
            
            ,PF.venid										as VenueId
            ,case when PF.venid is null then PF.venue end	as VenueNameRaw
            ,SW.socs_list									as SocietyComboValueRaw
            
            ,SW.title										as StoryNameRaw
            ,SW.author										as StoryAuthorRaw
            ,SW.category									as StoryType
            
            ,SW.id											as ddShowId
            
            ,SW.prices										as PriceRaw
            
from 		camdram_prod.acts_performances		PF
inner join 	camdram_prod.acts_shows				SW	on PF.sid = SW.id
-- Need to get the right rowset:
left join 	camdram_dw.dim_date					DA	on DA.DateValue between cast(PF.start_at as date) 
																		and PF.repeat_until
													-- This relates to some weird bad data (3 rows) when Stuart first built this
                                                    -- Manually fixed and hopefully will never happen again. The start-at values
                                                    -- were in some weird state that wasn't quite behaving like a NULL but also not a non-NULL value.
                                                    -- Don't remove them completely from the rowset, if they happen again: good to know about them.
													and cast(PF.start_at as char(20)) != '0000-00-00 00:00:00'
where 		PF.sid is not null	-- Orphan performance rows are useless
;



select min(id), max(id), max(length(prices))
from camdram_prod.acts_shows;


select min(pid), max(pid), max(length(role)), min(`order`), max(`order`)
from camdram_prod.acts_shows_people_link;

select day(repeat_until)
from camdram_prod.acts_performances
where year(repeat_until) = '2006'
and month(repeat_until) = '3'
order by repeat_until asc
;

select * from camdram_prod.acts_shows where id = 1171;
select * from camdram_prod.acts_performances where sid = 1171;


select day(repeat_until), count(1)
from camdram_prod.acts_performances
where sid is not null
group by day(repeat_until)
order by day(repeat_until);

select S.title, S.dates
		,date_add(str_to_date(concat(	year(P.repeat_until),'-'
								,month(P.repeat_until)
								,'-01'
							),'%Y-%c-%d'), interval -1 day)
		, P.*
from camdram_prod.acts_performances		P
inner join camdram_prod.acts_shows		S	on P.sid = S.id
where day(repeat_until) = 0
and sid is not null
;

select count(1) from extractv_fct_performances;

select count(1)
from 		camdram_prod.acts_performances		PF
inner join 	camdram_prod.acts_shows				SW	on PF.sid = SW.id
where 		PF.sid is not null
;


select distinct authorised
from camdram_prod.acts_shows;


/*
	Now I have a complete working extract of data in camdram_dw.
    Next steps:
		1. Process dims into a final form: until this is done, with a suitable Surrogate Key, 
			I can't put that Surrogate Key on the facts.
		2. Process facts into a final, surrogates-only, form. 
			This could either be a straight insert select where the query 
            does a bunch of joins to dimensional lookups.
            Or I could add more columns to the extract_fct tables, and then run 
            update scripts to fill them in one by one. Then do a much simpler insert
            from this table only, picking just the necessary columns.
		3. Tidy; possibly should leave the extract tables empty at the end? 
        4. Output: figure out how I'm going to write the final cleaned and processed
			facts and dims to CSV, and where, for onward analysis.
*/

-- For dims, I think I'm going to need extra columns in the extract tables
-- to do inplace updates. Think it'll be way too complex to do, in at least some cases,
-- as a single insert select with joins.
-- E.g. story, venue, society, need cleaning that considers across many rows. 
-- The final surrogate keys probably need to be decided via updates too - using row_no, dense_rank etc as necessary
-- Or maybe views on the extract tables...? That would have the row_no function etc in the view?
-- Either way, not an auto_increment field in the final table, because I don't want raw attribute cols 
-- in there, but I need the raw attribute cols to do the lookup on the fact.
-- ACTUALLY, maybe I DO want the raw versions in the final dimension... 
-- perhaps that's interesting. Perhaps sometimes people will want to look at values "as entered into Camdram"
-- and othertimes as harmonized or normalized values. 
-- The latter does imply more rows though. 

select *
from 	extract_dim_story;