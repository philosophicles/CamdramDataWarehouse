
drop procedure if exists load_dim_society;
delimiter @
create procedure load_dim_society()
begin

	-- First build the actual Society table so we have the Surrogate keys for that
    -- Then build the Combo table
    
    truncate table dim_society;
    
    -- Defaults first
    -- Longer term we might want to add in all the freetext societies
    -- With or without some cleaning
    -- For now, keeping it simple
    insert into dim_society
    (
		SocietyId
        ,SocietyName
        ,SocietyNameShort
        ,SocietyAffiliatedCollege
    )
    values 
     (-1, 'Freetext Society', 'Freetext', 'N/A')
	,(-2, 'Invalid Society Id', 'Invalid', 'N/A')	-- see below for reason
    ,(-3, 'No Society Specified', 'None', 'N/A')
    ;
    
    insert into dim_society
    (
		SocietyId
        ,SocietyName
        ,SocietyNameShort
        ,SocietyAffiliatedCollege
    )
    select 	SocietyId
			,SocietyName
			,SocietyNameShort
			,ifnull(SocietyAffiliatedCollege, 'N/A')
    from 	extract_dim_society_official
    ;
    
    -- One special case is where there is no SocietyId or NameRaw - for shows with
    -- no specified society
    update 		extract_dim_society_combo	SC
    inner join 	dim_society					S	on -3 = S.SocietyId
    set 		SC.SocietyKey = S.SocietyKey
    where 		SC.SocietyComboValueRaw = '[]'
    and 		SC.SocietyKey is null
    ;
    
    -- Apply surrogate key for "real" societies
    update 		extract_dim_society_combo	SC
    inner join 	dim_society					S	on SC.SocietyId = S.SocietyId
    set 		SC.SocietyKey = S.SocietyKey
    where 		SC.SocietyId is not null	-- strictly superfluous, here for clarity
    and 		SC.SocietyKey is null
    ;
    
    -- Historic data glitch: values in the SocietyId field that are not actual societies
    -- Will clean this up, but handle this if it exists
    update 		extract_dim_society_combo	SC
    inner join 	dim_society					S	on -2 = S.SocietyId
    set 		SC.SocietyKey = S.SocietyKey
    where 		SC.SocietyId is not null
    and 		SC.SocietyKey is null	-- (still, after previous statement)
    ;
    
    -- Apply default surrogate key (for now) for all freetext societies
    -- This is to get something working, rather than being a good long-term approach
    update 		extract_dim_society_combo	SC
    inner join 	dim_society					S	on -1 = S.SocietyId
    set 		SC.SocietyKey = S.SocietyKey
    where 		SC.SocietyId is null
    and 		SC.SocietyNameRaw is not null
    and 		SC.SocietyKey is null
    ;
    
    -- SC.SocietyKey should be fully populated now
    -- Because we've mapped lots of different freetext values to -1, 
    -- the combo table will not be distinct any more, hence the group by.

	truncate table dim_society_combo;
	insert into dim_society_combo
    (	SocietyComboKey
		,SocietyKey
		,SocietyDisplaySortOrder
	)
    select 		SocietyComboKey
				,SocietyKey
				,min(SocietyDisplaySortOrder)
    from 		extract_dim_society_combo
    group by 	SocietyComboKey
				,SocietyKey
    ;

end @
delimiter ;

-- call load_dim_society();