
drop procedure if exists camdram_dw.run_dim_venue;
delimiter @
create procedure camdram_dw.run_dim_venue()
begin
    
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

call camdram_dw.run_dim_venue();