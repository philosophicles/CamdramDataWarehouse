
drop procedure if exists extract_dimensions;
delimiter @
create procedure extract_dimensions()
begin

	truncate table extract_dim_society_combo;
	insert into extract_dim_society_combo
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
    from 	extractv_dim_society_combo
    ;
    
    truncate table extract_dim_society_free;
    insert into extract_dim_society_free
    (
		SocietyNameRaw
    )
    select 	SocietyNameRaw
    from 	extractv_dim_society_free
    ;
    
    truncate table extract_dim_society_official;
    insert into extract_dim_society_official
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
    from 	extractv_dim_society_official
    ;
    
    truncate table extract_dim_story;
    insert into extract_dim_story
    (
		StoryNameRaw
        ,StoryAuthorRaw
        ,StoryTypeRaw
    )
    select 	StoryNameRaw
			,StoryAuthorRaw
			,StoryType
    from 	extractv_dim_story
    ;
    
    truncate table extract_dim_user;
    insert into extract_dim_user
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
    from 	extractv_dim_user
    ;
    
    truncate table extract_dim_venue_free;
    insert into extract_dim_venue_free
    (
		VenueNameRaw
    )
    select 	VenueNameRaw
    from 	extractv_dim_venue_free
    ;
    
    truncate table extract_dim_venue_official;
    insert into extract_dim_venue_official
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
    from 	extractv_dim_venue_official
    ;

end @
delimiter ;

-- call extract_dimensions();