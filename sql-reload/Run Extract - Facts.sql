

drop procedure if exists camdram_dw.run_extract_facts;
delimiter @
create procedure camdram_dw.run_extract_facts()
begin
	
    truncate table camdram_dw.extract_fct_performances;
    insert into camdram_dw.extract_fct_performances
    (
		PerformanceRangeStartDateTime
		,PerformanceRangeEndDate
		,VenueId
		,VenueNameRaw
		,SocietyComboValueRaw
		,StoryNameRaw
		,StoryAuthorRaw
		,StoryType
		,ddShowId
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
    from 		camdram_dw.extractv_fct_performances
    ;
    
    truncate table camdram_dw.extract_fct_roles;
    insert into camdram_dw.extract_fct_roles
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
    from 		camdram_dw.extractv_fct_roles
    ;
    
end @
delimiter ;

call camdram_dw.run_extract_facts();

