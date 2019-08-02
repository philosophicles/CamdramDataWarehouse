
drop procedure if exists camdram_dw.run_dim_story;
delimiter @
create procedure camdram_dw.run_dim_story()
begin
    
    truncate table camdram_dw.dim_story;
    insert into camdram_dw.dim_story
    (
		StoryNameRaw
        ,StoryAuthorRaw
        ,StoryType
    )
    select 	StoryNameRaw
			,StoryAuthorRaw
			,StoryType
    from 	camdram_dw.extract_dim_story
    ;
    
    truncate table camdram_dw.dim_venue;
    insert into camdram_dw.dim_venue
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
    from 	camdram_dw.extract_dim_venue_official
    ;

end @
delimiter ;

call camdram_dw.run_dim_story();