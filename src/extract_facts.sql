
drop procedure if exists extract_facts;
delimiter @
create procedure extract_facts()
begin
	
    truncate table extract_fct_performances;
    insert into extract_fct_performances
    (
		PerformanceRangeStartDateTime
		,PerformanceRangeEndDate
		,VenueId
		,VenueNameRaw
		,SocietyComboValueRaw
		,StoryNameRaw
		,StoryAuthorRaw
		,StoryType
		,ShowId
		,PriceRaw
    )
    select		PerformanceRangeStartDateTime
				,PerformanceRangeEndDate
				,VenueId
				,VenueNameRaw
				,SocietyComboValueRaw
				,StoryNameRaw
				,StoryAuthorRaw
				,StoryType
				,ddShowId
				,PriceRaw
    from 		extractv_fct_performances
    ;
    
    truncate table extract_fct_roles;
    insert into extract_fct_roles
    (
		ShowId
		,ParticipantId
		,ParticipantType
		,ParticipantRoleRaw
		,RoleDisplayOrder
    )
    select		ShowId
				,ParticipantId
                ,ParticipantType
                ,ParticipantRoleRaw
                ,RoleDisplayOrder
    from 		extractv_fct_roles
    ;
    
end @
delimiter ;

-- call extract_facts();

