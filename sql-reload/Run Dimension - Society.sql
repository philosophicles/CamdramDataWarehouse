
drop procedure if exists camdram_dw.run_dim_society;
delimiter @
create procedure camdram_dw.run_dim_society()
begin

	-- First build the actual Society table so we have the Surrogate keys for that
    -- Then build the Combo table
    
    truncate table camdram_dw.dim_society;
    
    -- Defaults first
    -- Longer term we might want to add in all the freetext societies
    -- With or without some cleaning
    -- For now, keeping it simple
    insert into camdram_dw.dim_society
    (
		SocietyId
        ,SocietyName
        ,SocietyNameShort
        ,SocietyAffiliatedCollege
    )
    values 
     (-1, 'Freetext Society', 'Freetext', 'N/A')
	,(-2, 'Invalid Society Id', 'Invalid', 'N/A')	-- see below for reason
    ;
    
    insert into camdram_dw.dim_society
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
    from 	camdram_dw.extract_dim_society_official
    ;   
    
    -- Apply surrogate key for "real" societies
    update 		camdram_dw.extract_dim_society_combo	SC
    inner join 	camdram_dw.dim_society					S	on SC.SocietyId = S.SocietyId
    set 		SC.SocietyKey = S.SocietyKey
    where 		SC.SocietyId is not null
    and 		SC.SocietyKey is null
    ;
    
    -- Historic data glitch: values in the SocietyId field that are not actual societies
    -- Will clean this up, but handle this if it exists
    update 		camdram_dw.extract_dim_society_combo	SC
    inner join 	camdram_dw.dim_society					S	on -2 = S.SocietyId
    set 		SC.SocietyKey = S.SocietyKey
    where 		SC.SocietyId is not null
    and 		SC.SocietyKey is null	-- (still, after previous statement)
    ;
    
    -- Apply default surrogate key (for now) for all freetext societies
    -- This is to get something working, rather than being a good long-term approach
    update 		camdram_dw.extract_dim_society_combo	SC
    inner join 	camdram_dw.dim_society					S	on -1 = S.SocietyId
    set 		SC.SocietyKey = S.SocietyKey
    where 		SC.SocietyId is null
    and 		SC.SocietyKey is null
    ;
    
    -- SC.SocietyKey should be fully populated now
    -- Because we've mapped lots of different freetext values to -1, 
    -- the combo table will not be distinct any more, hence the group by.

	truncate table camdram_dw.dim_society_combo;
	insert into camdram_dw.dim_society_combo
    (	SocietyComboKey
		,SocietyKey
		,SocietyDisplaySortOrder
	)
    select 		SocietyComboKey
				,SocietyKey
				,min(SocietyDisplaySortOrder)
    from 		camdram_dw.extract_dim_society_combo
    group by 	SocietyComboKey
				,SocietyKey
    ;

end @
delimiter ;

call camdram_dw.run_dim_society();