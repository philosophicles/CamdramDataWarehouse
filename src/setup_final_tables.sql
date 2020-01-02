
-- Column datatype limits aiming to balance compactness with potential for future edge cases
-- Frequently shorter than the prod database source datatypes, where I believe those are overly long.

drop table if exists dim_society_combo;
create table dim_society_combo(
	SocietyComboKey				smallint unsigned not null
	,SocietyKey					smallint unsigned not null
	,SocietyDisplaySortOrder	tinyint unsigned not null
	,constraint pk_dim_society_combo primary key (SocietyComboKey, SocietyKey)
);

drop table if exists dim_society;
create table dim_society(
	SocietyKey					smallint unsigned not null auto_increment primary key
	,SocietyId					smallint not null
	,SocietyName				varchar(150) not null
	,SocietyNameShort			varchar(75) not null
	,SocietyAffiliatedCollege	varchar(50) not null
);

drop table if exists dim_story;
create table dim_story(
	StoryKey			smallint unsigned not null auto_increment primary key
	,StoryName			varchar(255) not null
	,StoryAuthor		varchar(255) not null
	,StoryType			varchar(20) not null
);

drop table if exists dim_venue;
create table dim_venue(
	VenueKey				smallint unsigned not null auto_increment primary key
	,VenueId				smallint not null
	,VenueName				varchar(200) not null
	,VenueNameShort			varchar(50) not null
	,VenueAffiliatedCollege	varchar(50) not null
	,VenueLatitude			decimal(7,5)
	,VenueLongitude			decimal(8,5)
);

drop table if exists fct_performances;
create table fct_performances(
	PerformanceDateKey				mediumint unsigned not null
	,PerformanceTimeKey				smallint unsigned not null
	,VenueKey						smallint unsigned not null
	,SocietyComboKey				smallint unsigned not null
	,StoryKey						smallint unsigned not null
	,ShowId							smallint unsigned not null
	,PerformanceDateTimeStamp		datetime not null
	,MinTicketPrice_GBP				decimal(5,2)
	,MaxTicketPrice_GBP				decimal(5,2)
	,CountOfCast					tinyint unsigned
	,CountOfCrew					tinyint unsigned
	,CountOfBand					tinyint unsigned
	,constraint pk_fct_performances primary key (
		PerformanceDateKey
		,PerformanceTimeKey
		,VenueKey
		,ShowId
		)
);
