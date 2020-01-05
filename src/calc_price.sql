   
/*
	This process is educated guesswork at best; it's never going to be 100% right.
	Most errors will not affect the ultimate min/max values. Some of those that do
	will be best cleaned up in Camdram directly as weird one-offs. We can add
    special-case rules as required once we can see the data coming out.
    
    Principle is that we leave these facts as NULL unless we definitely know a price.
    £0 and unknown have different meanings here.
*/

drop temporary table if exists prices;    

create temporary table prices(
    Id			smallint unsigned not null auto_increment primary key
    ,RawText 	varchar(200) not null
    ,CleanText 	varchar(200) collate utf8mb4_0900_as_ci	-- we don't care about capitalization, numbers are the main interest
    ,MinPrice 	decimal(9,2)
    ,MaxPrice	decimal(9,2)
);

insert into prices (RawText, CleanText)
select 	distinct
		PriceRaw, PriceRaw
from 	extract_fct_performances
where	PriceRaw is not null	-- nulls would just lead to null Price facts anyway
;

-- Most examples of "free" mean a £0 entry band, 
-- unless it's offering free booze with the entry fee, or mentioning free online booking
-- (and we don't care about capitalisation)
update 	prices
set 	CleanText = regexp_replace(CleanText, 'free', '£0', 1, 0, 'i')	-- case insensitive replacement (normal replace() is always cs)
where 	CleanText like '%free%'
and		CleanText not like '%drink%'
and		CleanText not like '%wine%'
and		CleanText not like '%beer%'
and 	CleanText not like '%free online booking%'
;

-- Presence of 'donation' implies one CAN get in for free
-- Regardless of any suggested amount.
update 	prices
set		CleanText = regexp_replace(CleanText, 'donation', '£0', 1, 0, 'i')
where 	regexp_like(CleanText, 'donation', 'i')
;

/* Wrote all this but turns out not to be necessary!
-- Beyond the above replacements, we no longer care about A-z or most symbols
-- We definitely still care about numbers and certain characters that could be 
-- used to delimit different prices. 
-- Also remove double spaces, trim and null out any empty strings.
update	prices
set 	CleanText = nullif(trim(replace(regexp_replace(CleanText, '[^0-9£/,.; \\-]', ''), '  ', ' ')),'')
;

-- Also remove leading comma, forward-slash or hyphen, then retrim
update 	prices
set		CleanText = nullif(trim(replace(regexp_replace(CleanText, '^[,/\\-]+', ''),'  ',' ')),'')
where 	CleanText like ',%' 
or		CleanText like '-%'
or		CleanText like '/%'
;

-- And similar at the end of the string, including periods here
update 	prices
set		CleanText = nullif(trim(replace(regexp_replace(CleanText, '[,/\\-\\.]+$', ''),'  ',' ')),'')
where 	CleanText like '%,' 
or		CleanText like '%-'
or		CleanText like '%/'
or		CleanText like '%[.]'
;
*/

-- At this point, it's not perfect but we've reduced a lot of the randomness of input
-- This is ready to explode to a row per value, using our trusty numbers table

drop temporary table if exists prices_explode;

create temporary table prices_explode (
	Id smallint unsigned not null
    ,Price varchar(10)
);

insert into prices_explode (Id, Price)
select		P.Id
			,regexp_substr(P.CleanText, '[0-9\\.]+', 1, N.RowNo+1)
from		prices		P
inner join 	numbers		N	on char_length(regexp_replace(CleanText, '[^0-9\\.]', ''))-1 >= N.RowNo
;

with cteDecimal as (
	select 		Id
				,cast(Price as decimal(9,2))	as Price
	from 		prices_explode
	where		Price is not null
	and 		Price rlike '^[0-9]+\\.?[0-9]*$'	-- match ints and decimals
)
,cteMinMax as (
	select		Id
				,min(Price)	as MinPrice
                ,max(Price) as MaxPrice
	from 		cteDecimal
    group by 	Id
)
update		prices		P
inner join 	cteMinMax	C	on P.Id = C.Id
set 		P.MinPrice = C.MinPrice
			,P.MaxPrice = C.MaxPrice
;

-- Now, finally, apply the result back to the main extract fact table
-- Wiping any prior values first
update 		extract_fct_performances	FA
set 		FA.MinTicketPrice_GBP = null
			,FA.MaxTicketPrice_GBP = null
;

update 		extract_fct_performances	FA
inner join 	prices						P	on FA.PriceRaw = P.RawText
set			FA.MinTicketPrice_GBP	= P.MinPrice
			,FA.MaxTicketPrice_GBP	= P.MaxPrice
;
