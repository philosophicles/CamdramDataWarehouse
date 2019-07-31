

drop procedure if exists camdram_dw.run_extract_dims;
delimiter @
create procedure camdram_dw.run_extract_dims()
begin

	truncate table camdram_dw.extract_dim_society_combo;
	insert into camdram_dw.extract_dim_society_combo
    (	SocietyComboValueRaw
		,SocietyComboKey
		,SocietyDisplaySortOrder
		,SocietyId
		,SocietyNameRaw
	)
    select 	SocietyComboValueRaw
			,SocietyComboKey
            ,SocietyDisplaySortOrder
            ,SocietyId
            ,SocietyNameRaw
    from 	camdram_dw.extractv_dim_society_combo
    ;
    
    truncate table camdram_dw.extract_dim_society_free;
    insert into camdram_dw.extract_dim_society_free
    (
		SocietyNameRaw
    )
    select 	SocietyNameRaw
    from 	camdram_dw.extractv_dim_society_free
    ;
    
    truncate table camdram_dw.extract_dim_society_official;
    insert into camdram_dw.extract_dim_society_official
    (
		SocietyId
		,SocietyName
        ,SocietyNameShort
        ,SocietyAffiliatedCollege
    )
    select 	SocietyId
			,SocietyName
			,SocietyNameShort
			,SocietyAffiliatedCollege
    from 	camdram_dw.extractv_dim_society_official
    ;
    
    truncate table camdram_dw.extract_dim_story;
    insert into camdram_dw.extract_dim_story
    (
		StoryNameRaw
        ,StoryAuthorRaw
        ,StoryType
    )
    select 	StoryNameRaw
			,StoryAuthorRaw
			,StoryType
    from 	camdram_dw.extractv_dim_story
    ;
    
    truncate table camdram_dw.extract_dim_user;
    insert into camdram_dw.extract_dim_user
    (
		UserId
        ,UserRegisteredDateValue
        ,UserLatestLoginDateValue
        ,UserEmailDomain
    )
    select 	UserId
			,UserRegisteredDateValue
			,UserLatestLoginDateValue
			,UserEmailDomain
    from 	camdram_dw.extractv_dim_user
    ;
    
    truncate table camdram_dw.extract_dim_venue_free;
    insert into camdram_dw.extract_dim_venue_free
    (
		VenueNameRaw
    )
    select 	VenueNameRaw
    from 	camdram_dw.extractv_dim_venue_free
    ;
    
    truncate table camdram_dw.extract_dim_venue_official;
    insert into camdram_dw.extract_dim_venue_official
    (
		VenueId
		,VenueName
        ,VenueNameShort
        ,VenueAffiliatedCollege
        ,VenueAddressRaw
        ,VenueLatitude
        ,VenueLongitude
    )
    select 	VenueId
			,VenueName
			,VenueNameShort
			,VenueAffiliatedCollege
			,VenueAddressRaw
			,VenueLatitude
			,VenueLongitude
    from 	camdram_dw.extractv_dim_venue_official
    ;

end @
delimiter ;

call camdram_dw.run_extract_dims();