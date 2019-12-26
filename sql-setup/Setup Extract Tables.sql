
drop procedure if exists camdram_dw.setup_extract_tables;
delimiter @
create procedure camdram_dw.setup_extract_tables()
begin

	-- Column datatype limits aiming to balance compactness with potential for future edge cases
    -- Frequently shorter than the prod database source datatypes, where I believe those are overly long.

	drop table if exists camdram_dw.extract_dim_society_combo;
	create table camdram_dw.extract_dim_society_combo(
		SocietyComboValueRaw		varchar(1000)		-- In theory this could get quite long
        ,SocietyComboKey			smallint unsigned
        ,SocietyDisplaySortOrder	tinyint unsigned
        ,SocietyId					smallint unsigned
        ,SocietyNameRaw				varchar(150)		-- This would be a pretty boringly long society name
        ,SocietyKey 				smallint unsigned
	);

	drop table if exists camdram_dw.extract_dim_society_free;
	create table camdram_dw.extract_dim_society_free(
		SocietyNameRaw	varchar(150)
	);

	drop table if exists camdram_dw.extract_dim_society_official;
	create table camdram_dw.extract_dim_society_official(
		SocietyId					smallint unsigned
        ,SocietyName				varchar(150)
        ,SocietyNameShort			varchar(75)
        ,SocietyAffiliatedCollege	varchar(50)
	);

	drop table if exists camdram_dw.extract_dim_story;
	create table camdram_dw.extract_dim_story(
		StoryNameRaw		varchar(255)
        ,StoryName			varchar(255)
        ,StoryAuthorRaw		varchar(255)
        ,StoryAuthor		varchar(255)
        ,StoryTypeRaw		varchar(20)
        ,StoryType			varchar(20)
	);

	drop table if exists camdram_dw.extract_dim_user;
	create table camdram_dw.extract_dim_user(
		UserId						smallint
        ,UserRegisteredDateValue	date
        ,UserLatestLoginDateValue	date
        ,UserEmailDomain			varchar(20)
	);

	drop table if exists camdram_dw.extract_dim_venue_free;
	create table camdram_dw.extract_dim_venue_free(
		VenueNameRaw		varchar(200)
	);

	drop table if exists camdram_dw.extract_dim_venue_official;
	create table camdram_dw.extract_dim_venue_official(
		VenueId					smallint unsigned
        ,VenueName				varchar(200)
        ,VenueNameShort			varchar(50)
        ,VenueAffiliatedCollege	varchar(50)
        ,VenueAddressRaw		varchar(500)
        ,VenueLatitude			decimal(7,5)
        ,VenueLongitude			decimal(8,5)
	);

	drop table if exists camdram_dw.extract_fct_performances;
    create table camdram_dw.extract_fct_performances(
		PerformanceRangeStartDateTime	datetime
        ,PerformanceRangeStartDate		date generated always as (cast(PerformanceRangeStartDateTime as date))
		,PerformanceRangeEndDate		date
        ,PerformanceRangeUTCTime		time generated always as (cast(PerformanceRangeStartDateTime as time))
		,PerformanceRangeUTCTimeKey		smallint unsigned
        ,PerformanceRangeLocalTimeKey	smallint unsigned
        ,VenueId						smallint unsigned
        ,VenueNameRaw					varchar(200)
        ,VenueKey						smallint unsigned
        ,SocietyComboValueRaw			varchar(1000)
        ,SocietyComboKey				smallint unsigned
        ,StoryNameRaw					varchar(255)
        ,StoryAuthorRaw					varchar(255)
        ,StoryType						varchar(20)
        ,StoryKey						smallint unsigned
        
        ,ShowId							smallint unsigned
        
        ,PerformanceUTCDateTimeStamp	datetime
        ,PerformanceLocalDateTimeStamp	datetime
        ,PriceRaw						varchar(200)
        ,MinTicketPrice_GBP				decimal(5,2)
        ,MaxTicketPrice_GBP				decimal(5,2)
        ,CountOfCastRoles				tinyint unsigned
        ,CountOfCrewRoles				tinyint unsigned
        ,CountOfBandRoles				tinyint unsigned
    );
    
    drop table if exists camdram_dw.extract_fct_roles;
    create table camdram_dw.extract_fct_roles(
		ShowId					smallint unsigned
        ,ParticipantId			mediumint unsigned
        ,ParticipantType		varchar(20)
        ,ParticipantRoleRaw		varchar(255)
        ,RoleDisplayOrder		smallint signed
    );

end @
delimiter ;

call camdram_dw.setup_extract_tables();
