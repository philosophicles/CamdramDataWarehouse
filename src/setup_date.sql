
drop table if exists dim_date;
create table dim_date (
	DateKey					mediumint unsigned not null primary key auto_increment
	,DateValue				date not null unique key
	,DateDisplay_YMD		char(10) 			generated always as (date_format(DateValue, "%Y-%m-%d"))	-- YYYY-MM-DD
	,DateDisplay_DMY		char(10) 			generated always as (date_format(DateValue, "%d/%m/%Y"))	-- DD/MM/YYYY
	,DateDescriptionShort	varchar(15) 		generated always as (date_format(DateValue, "%e %b. %Y"))	-- D MMM. YYYY
	,DateDescriptionLong	varchar(20) 		generated always as (date_format(DateValue, "%d %M, %Y"))	-- DD MMMM, YYYY

	,CalendarYearNum      	smallint 			generated always as (date_format(DateValue, "%Y" ))		-- 2019, etc
	-- Academic years always start 1st October
	,AcademicYearNum		smallint			generated always as (date_format(date_add(DateValue, interval -9 month), "%Y"))
	,CalendarYear			char(4)				generated always as (date_format(DateValue, "%Y" ))		-- same as the Num version
	,AcademicYear			char(7)				generated always as (concat(cast(AcademicYearNum as char(4)),'/',right(cast(AcademicYearNum+1 as char(4)),2)))

	-- These three will be filled in later
	,AcademicTermNameShort		varchar(20) not null default 'Undefined'
	,AcademicTermName			varchar(20) not null default 'Undefined'
	,AcademicTermNameAndYear	varchar(50) not null default 'Undefined'

	,MonthName				varchar(15) 		generated always as (date_format(DateValue, "%M"))	-- January etc
	,MonthNameShort			char(3) 			generated always as (date_format(DateValue, "%b"))	-- Jan, Feb...
	,MonthNumInCY			tinyint unsigned 	generated always as (date_format(DateValue, "%c"))	-- 1..12 starting January
	,MonthNumInAY			tinyint unsigned	generated always as (date_format(date_add(DateValue, interval -9 month), "%c"))	-- 1..12 starting October

	,MonthNameWithCY		varchar(20)			generated always as (concat(MonthName, ' ', cast(CalendarYearNum as char(4))))
	,MonthNameWithAY		varchar(20)			generated always as (concat(MonthName, ' ', cast(AcademicYearNum as char(4))))

	,DayOfWeekName			varchar(9) 			generated always as (date_format(DateValue, "%W"))		-- Monday etc
	,DayOfWeekNameShort		char(3)				generated always as (date_format(DateValue, "%a"))		-- Mon, Tue...
	,DayNumInWeek_SunSat	tinyint unsigned 	generated always as (date_format(DateValue, "%w")+1)		-- 1..7 starting Sunday
	,DayNumInWeek_TuesMon	tinyint unsigned 	generated always as (date_format(date_add(DateValue, interval -2 day), "%w")+1)	-- 1..7 starting Tuesday
	,DayIsWeekend_Desc  	char(7) 			generated always as (
												case when date_format(DateValue, "%w") in (0,6)
												then "Weekend" else "Weekday" end
												)

	,DayNumInMonth			tinyint unsigned	generated always as (date_format(DateValue, "%e"))	-- 1..31     

	-- For most purposes we would be interested in weeks starting on either Sundays or Tuesdays
	-- Lecture weeks, starting Thursdays, less likely to be interesting.
	,WeekNumInCY_SunStart	tinyint unsigned	generated always as (date_format(DateValue, "%U"))	-- 0..52
	,WeekNumInCY_TueStart	tinyint unsigned not null default 0	-- To do if/when needed
	,WeekNumInAY_SunStart	tinyint unsigned not null default 0	-- To do if/when needed
	,WeekNumInAY_TueStart	tinyint unsigned not null default 0	-- To do if/when needed
	,WeekNumInTerm_SunStart	tinyint unsigned not null default 0	-- To do if/when needed
	,WeekNumInTerm_TueStart	tinyint unsigned not null default 0	-- To do if/when needed
);

-- Populate rows: we do have performances from early 20th century
insert into dim_date(DateValue)
select 		date_add('1914-01-01', interval RowNo day)
from 		numbers
where 		date_add( '1914-01-01', interval RowNo day) between '1914-01-01' and '2049-12-31'
order by 	RowNo
;

-- Add term information
update 		dim_date 				D
inner join 	extractv_dim_date_terms	T	on D.DateValue >= T.TermStartDate
										and D.DateValue < T.TermEndDate	-- End Dates overlap with the next Start Date
set 		D.AcademicTermNameShort = T.TermNameShort
			,D.AcademicTermName = T.TermName
			,D.AcademictermNameAndYear = T.TermNameAndYear    
;
