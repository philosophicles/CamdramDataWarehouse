
drop procedure if exists load_fct_performances;
delimiter @
create procedure load_fct_performances()
begin
      
    /*
    This is a series of in-place updates to the extract fact table,
    to apply the dimension keys and calculate facts. 
    Ended with a data movement from the extract to final table.
    */
    
    -- Wipe any pre-existing values, in case this step is being run manually
    update 		extract_fct_performances
    set 		PerformanceTimeKey = null
				,VenueKey = null
                ,SocietyComboKey = null
                ,StoryKey = null
                ,CountOfCast = null
                ,CountOfCrew = null
                ,CountOfBand = null
                ,MinTicketPrice_GBP = null
				,MaxTicketPrice_GBP = null
	;
    
    /*** Clean and look up TimeKey ***/
    
		/*	Time dim is in 5-min intervals which should be good enough for 
			any analysis we'd want to do. If shows aren't on the 5-minute interval,
            round backwards to "whole" 5-min moment, because it's better to arrive 
            early than late to a performance.
        */
    
    -- Exact matches first
	update 		extract_fct_performances		FA
    inner join 	dim_time						T	on FA.PerformanceTime = T.TimeValue
    set 		FA.PerformanceTimeKey = T.TimeKey
    ;
    
    -- Then remaining rounded matches (ugly join, but very few rows)
	update 		extract_fct_performances		FA
    inner join 	dim_time						T	on sec_to_time(300*floor((time_to_sec(FA.PerformanceTime))/300)) = T.TimeValue
    set 		FA.PerformanceTimeKey = T.TimeKey
    where 		FA.PerformanceTimeKey is null
    ;
    
    /*** VenueKey ***/
    
    -- For "real" venues
    update 		extract_fct_performances	FA
    inner join 	dim_venue					V	on FA.VenueId = V.VenueId
    set 		FA.VenueKey = V.VenueKey
    ;
    
    -- For freetext venues 
    -- (strictly, any remaining unmatched...this assumes referential integrity)
    update 		extract_fct_performances	FA
    inner join 	dim_venue					V	on -1 = V.VenueId	-- -1 = Freetext venue
    set 		FA.VenueKey = V.VenueKey
    where 		FA.VenueKey is null
    ;
    
    /*** SocietyComboKey ***/
    
    -- Need to ensure distinctness on the extract table
    with society_combo as (
		select 	distinct
				SocietyComboValueRaw
                ,SocietyComboKey
		from 	extract_dim_society_combo
    )
    update 		extract_fct_performances		FA
    inner join 	society_combo					S	on FA.SocietyComboValueRaw = S.SocietyComboValueRaw
    set 		FA.SocietyComboKey = S.SocietyComboKey
    ;
    
    /*** Look up StoryKey ***/
    -- This is slow, about 15s; I don't know if there's anything that 
    -- can be done in mysql to improve that (problem is nested-loop join on two big tables).
    update 		extract_fct_performances		FA
    inner join 	extract_dim_story				E	on FA.StoryNameRaw = E.StoryNameRaw
													and coalesce(FA.StoryAuthorRaw,'') = coalesce(E.StoryAuthorRaw,'')
													and FA.StoryType = E.StoryTypeRaw
    set 		FA.StoryKey = E.StoryKey
    ;
    
    
    /*** Calculate min and max ticket prices ***/
    
    -- Does this need a sub procedure? I think a number of steps. 
    -- Maybe take distinct non-null values into a working table, apply logic there
    -- and bring it back. 
    /*
    Logic ideas: 
		* "free" and common variations on that --> 0 / 0
        * otherwise only take values involving at least one [0-9]
        * Do some pattern matching to explode to more rows per root value
        * £ character followed by numbers up until either another £, or a /, or a space, or...what esle?
			* Do some frequency analysis, what else exists?
		* Once I have many rows, strip the punctuation etc out, then do windowed min and max per raw value
        * Then I can tie that back to facts
        
	These should remain as null unless we KNOW it's £0 (free)
    */
    
    
    /*** Calculate participant counts ***/
		-- This will leave nulls for shows which have no cast, crew, or band
        -- listed at all; those will receive a default 0 in the final fact table.
        
	with cte as (
		select 	ShowId
				,count(distinct case ParticipantType when 'cast' then ParticipantId end) as CountOfCast
				,count(distinct case ParticipantType when 'prod' then ParticipantId end) as CountOfCrew
				,count(distinct case ParticipantType when 'band' then ParticipantId end) as CountOfBand
		from 	camdram_dw.extract_fct_roles
		group by ShowId
    )
	update 		extract_fct_performances	FA
    inner join 	cte							C	on FA.ShowId = C.ShowId
    set			FA.CountOfCast = C.CountOfCast
				,FA.CountOfCrew = C.CountOfCrew
                ,FA.CountOfBand = C.CountOfBand
    ;
   
    
    /*** Populate the final fact table ***/
    truncate table fct_performances;
    
    insert into fct_performances
    (
		PerformanceDateKey
        ,PerformanceTimeKey
        ,VenueKey
        ,SocietyComboKey
        ,StoryKey
        ,ShowId
        ,PeformanceDateTimeStamp
        ,MinTicketPrice_GBP
        ,MaxTicketPrice_GBP
        ,CountOfCast
        ,CountOfCrew
        ,CountOfBand
    )
    select		
				DA.DateKey as PerformanceDateKey
				,FA.PerformanceTimeKey
                ,FA.VenueKey
                ,FA.SocietyComboKey
                ,FA.StoryKey
                ,FA.ShowId
                ,addtime(convert(DA.DateValue, datetime), FA.PerformanceTime) as PerformanceDateTimeStamp
                ,FA.MinTicketPrice_GBP
                ,FA.MaxTicketPrice_GBP
                ,FA.CountOfCast
				,FA.CountOfCrew
				,FA.CountOfBand
    
    from 		extract_fct_performances	FA
    -- Breed rows so we have a row per performance, not per performance-range:
    inner join 	dim_date					DA	on DA.DateValue between FA.PerformanceRangeStartDate
																and 	FA.PerformanceRangeEndDate
    ;

end @
delimiter ;

-- call load_fct_performances();