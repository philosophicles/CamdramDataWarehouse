
drop procedure if exists camdram_dw.setup_dim_time;
delimiter @
create procedure camdram_dw.setup_dim_time()
begin

	drop table if exists camdram_dw.dim_time;
	create table camdram_dw.dim_time (
		TimeKey				smallint unsigned not null primary key auto_increment
		,TimeValue			time not null unique key
		,TimeDisplay_12hr	char(7) 			generated always as (date_format(TimeValue, "%l:%i%p"))
        ,TimeDisplay_24hr	char(8)				generated always as (date_format(TimeValue, "%k:%i"))
        
        ,HourNum_12hr		tinyint unsigned 	generated always as (date_format(TimeValue, "%l"))
        ,HourNum_24hr		tinyint unsigned	generated always as (date_format(TimeValue, "%k"))
        ,MinuteNum			tinyint unsigned	generated always as (date_format(TimeValue, "%i"))
        ,AmOrPm				char(2)				generated always as (date_format(TimeValue, "%p"))
        
        ,TimeOfDayFuzzy		varchar(20)			generated always as (
													case 	when HourNum_24hr between 0 and 6	then 'Night'
															when HourNum_24hr between 7 and 11	then 'Morning'
                                                            when HourNum_24hr between 12 and 17	then 'Afternoon'
                                                            when HourNum_24hr between 18 and 20	then 'Early Evening'
                                                            when HourNum_24hr between 21 and 23	then 'Late Evening'
													end 
													)
		-- Not sure what else we'd need here for now
    );

	-- Populate rows: every 5 mins, performances probably never start at 7:43pm etc.
	insert into camdram_dw.dim_time(TimeValue)
	select 		cast(date_add(cast('00:00:00' as time), interval RowNo minute) as time)
	from 		camdram_dw.numbers
	where 		RowNo % 5 = 0
	order by 	RowNo
    limit 		288
    ;

end @
delimiter ;

call camdram_dw.setup_dim_time();