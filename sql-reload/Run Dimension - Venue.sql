
drop procedure if exists camdram_dw.run_dim_venue;
delimiter @
create procedure camdram_dw.run_dim_venue()
begin
    
    -- Potential addition: Venue's address (is in extract table)
    -- Would this be useful?
    
    truncate table camdram_dw.dim_venue;
    
    -- Defaults
    insert into camdram_dw.dim_venue
    (
		VenueId
		,VenueName
        ,VenueNameShort
        ,VenueAffiliatedCollege
        ,VenueLatitude
        ,VenueLongitude
    )
    values
    (-1,'Freetext Venue', 'Freetext', 'None', 52.21273, 0.12038)	-- Location is in the middle of the Cam at Jesus Lock, 
																	-- to be obviously "fake". 
    ;
    
    insert into camdram_dw.dim_venue
    (
		VenueId
		,VenueName
        ,VenueNameShort
        ,VenueAffiliatedCollege
        ,VenueLatitude
        ,VenueLongitude
    )
    select 	VenueId
			,VenueName
			,coalesce(VenueNameShort, left(VenueName,50))
			,coalesce(VenueAffiliatedCollege, 'None')
			,VenueLatitude
			,VenueLongitude
    from 	camdram_dw.extract_dim_venue_official
    ;

end @
delimiter ;

call camdram_dw.run_dim_venue();