
drop procedure if exists camdram_dw.setup_extract_views;
delimiter @
create procedure camdram_dw.setup_extract_views()
begin

	drop view if exists `camdram_dw`.`extractv_dim_date_terms`;
	CREATE VIEW `camdram_dw`.`extractv_dim_date_terms` AS
		SELECT 
			CAST(`camdram_prod`.`acts_time_periods`.`start_at`
				AS DATE) AS `TermStartDate`,
			CAST(`camdram_prod`.`acts_time_periods`.`end_at`
				AS DATE) AS `TermEndDate`,
			`camdram_prod`.`acts_time_periods`.`short_name` AS `TermNameShort`,
			`camdram_prod`.`acts_time_periods`.`name` AS `TermName`,
			`camdram_prod`.`acts_time_periods`.`full_name` AS `TermNameAndYear`
		FROM
			`camdram_prod`.`acts_time_periods`;

	drop view if exists `camdram_dw`.`extractv_dim_society_combo`;
	CREATE VIEW `camdram_dw`.`extractv_dim_society_combo` AS 
		with `cte` as (
			select 	distinct `S`.`socs_list` AS `SocietyComboValueRaw`
					,1+dense_rank() OVER (ORDER BY `S`.`socs_list` )  AS `SocietyComboKey`
                    ,(`N`.`RowNo` + 1) AS `SocietyDisplaySortOrder`
                    ,json_extract(`S`.`socs_list`,concat('$[',`N`.`RowNo`,']')) AS `SocietyIdOrName` 
			from 	`camdram_prod`.`acts_shows` `S` 
			join 	`camdram_dw`.`numbers` 		`N` 	on json_length(`S`.`socs_list`) > `N`.`RowNo`
			where 	`N`.`RowNo` between 0 and (	select max(json_length(`camdram_prod`.`acts_shows`.`socs_list`)) - 1 
												from `camdram_prod`.`acts_shows`
											  )
			and 	`S`.authorised = 1
            union all
            -- Empty JSON list (for shows with no societies) has len 0 so fails 
            -- the len > RowNo join condition above. It's a very special case so
            -- just manually re-add it like this:
            select	'[]', 1, 1, null
			) 
		SELECT 
			`cte`.`SocietyComboValueRaw` AS `SocietyComboValueRaw`,
			`cte`.`SocietyComboKey` AS `SocietyComboKey`,
			`cte`.`SocietyDisplaySortOrder` AS `SocietyDisplaySortOrder`,
			(CASE
				WHEN (JSON_TYPE(`cte`.`SocietyIdOrName`) = 'INTEGER') THEN `cte`.`SocietyIdOrName`
			END) AS `SocietyId`,
			(CASE
				WHEN (JSON_TYPE(`cte`.`SocietyIdOrName`) = 'STRING') THEN JSON_UNQUOTE(`cte`.`SocietyIdOrName`)
			END) AS `SocietyNameRaw`
		FROM
			`cte`;

	drop view if exists `camdram_dw`.`extractv_dim_society_free`;
	CREATE VIEW `camdram_dw`.`extractv_dim_society_free` AS 
		with `complete_list`(`SocietyIdOrName`) as (
			select  distinct 
					json_extract(`S`.`socs_list`,concat('$[',`N`.`RowNo`,']')) AS `json_extract(S.socs_list, concat('$[', N.rowno, ']'))` 
			from 	`camdram_prod`.`acts_shows` `S` 
			join 	`camdram_dw`.`numbers` 		`N` on json_length(`S`.`socs_list`) > `N`.`RowNo`
			where 	`N`.`RowNo` between 0 and (	select (max(json_length(`camdram_prod`.`acts_shows`.`socs_list`)) - 1) 
												from `camdram_prod`.`acts_shows`
											  )
			and 	`S`.authorised = 1
			) 
		SELECT 
			JSON_UNQUOTE(`complete_list`.`SocietyIdOrName`) AS `SocietyNameRaw`
		FROM
			`complete_list`
		WHERE
			JSON_TYPE(`complete_list`.`SocietyIdOrName`) = 'STRING';

	drop view if exists `camdram_dw`.`extractv_dim_society_official`;
	CREATE VIEW `camdram_dw`.`extractv_dim_society_official` AS
		SELECT 
			`camdram_prod`.`acts_societies`.`id` AS `SocietyId`,
			`camdram_prod`.`acts_societies`.`name` AS `SocietyName`,
			`camdram_prod`.`acts_societies`.`shortname` AS `SocietyNameShort`,
			`camdram_prod`.`acts_societies`.`college` AS `SocietyAffiliatedCollege`
		FROM
			`camdram_prod`.`acts_societies`;

	drop view if exists `camdram_dw`.`extractv_dim_story`;
	CREATE VIEW `camdram_dw`.`extractv_dim_story` AS
		select	distinct
				title 	collate utf8mb4_0900_as_cs 	as StoryNameRaw
				,author collate utf8mb4_0900_as_cs 	as StoryAuthorRaw
				,nullif(category,'') 				as StoryType
		from	camdram_prod.acts_shows
        where 	authorised = 1
		;

	drop view if exists `camdram_dw`.`extractv_dim_user`;
	CREATE VIEW `camdram_dw`.`extractv_dim_user` AS
		SELECT 
			`camdram_prod`.`acts_users`.`id` AS `UserId`,
			CAST(`camdram_prod`.`acts_users`.`registered_at`
				AS DATE) AS `UserRegisteredDateValue`,
			CAST(`camdram_prod`.`acts_users`.`last_login_at`
				AS DATE) AS `UserLatestLoginDateValue`,
			(CASE
				WHEN (`camdram_prod`.`acts_users`.`email` LIKE '%cam.ac.uk') THEN 'cam.ac.uk'
				WHEN (`camdram_prod`.`acts_users`.`email` LIKE '%@cantab.net') THEN 'cantab.net'
				ELSE 'other'
			END) AS `UserEmailDomain`
		FROM
			`camdram_prod`.`acts_users`;

	drop view if exists `camdram_dw`.`extractv_dim_venue_free`;
	CREATE VIEW `camdram_dw`.`extractv_dim_venue_free` AS
		SELECT DISTINCT
			`camdram_prod`.`acts_performances`.`venue` AS `VenueNameRaw`
		FROM
			`camdram_prod`.`acts_performances`
		WHERE
			(NULLIF(`camdram_prod`.`acts_performances`.`venue_id`,
					0) IS NULL)
		ORDER BY LENGTH(`camdram_prod`.`acts_performances`.`venue`);

	drop view if exists `camdram_dw`.`extractv_dim_venue_official`;
	CREATE VIEW `camdram_dw`.`extractv_dim_venue_official` AS
		SELECT 
			id AS `VenueId`,
			name AS `VenueName`,
			shortname AS `VenueNameShort`,
			college AS `VenueAffiliatedCollege`,
			address AS `VenueAddressRaw`,
			cast(round(latitude,5) as decimal(7,5)) 	AS `VenueLatitude`,
			cast(round(longitude,5) as decimal(8,5)) AS `VenueLongitude`
		FROM
			`camdram_prod`.`acts_venues`;

	drop view if exists camdram_dw.extractv_fct_performances;
    create view camdram_dw.extractv_fct_performances as
		select 		
					/* 	Avoid a weird DQ problem affecting a very few rows.
						These will also be fixed in prod data, but this helps
						avoid errors, in case it happens again.
                    */
                    case 	
						when cast(PF.start_at as char(20)) != '0000-00-00 00:00:00'
                        /* start_at appears to be adjusted backwards during BST, 
                           e.g. summertime ADC mainshows have start_at time of 18:45. 
                           AFAICT for good reason (limitations of mysql datetimes).
                           So this would be effectively storing UTC, if all
                           shows took place in the UK (which they don't!). But that part
                           doesn't matter because we're not actually interested in relative TZs
                           around the world. (We don't care that a 7pm show in Japan is
                           actually starting at 4am UK time, or whatever.)
                           
                           So, I _think_ it's appropriate at this point to convert back
                           to the time as viewed on Camdram front-end (e.g. 19:45 in the summer)
                           so our Time dimension "just works". I do have a nagging suspicion
                           that this might yet surprise me, though...
                        */
						then convert_tz(PF.start_at, '+00:00', 'Europe/London')
					end 											as PerformanceRangeStartDateTime
                    
                    /*	Another weird DQ problem with dates having 00 as day part. 
						By inspection of the 5 rows (before fixing in prod), the likely
                        truth was always the last day of the preceding month.
                    */
					,case
						when day(PF.repeat_until)=0
                        then date_add(str_to_date(concat(	year(PF.repeat_until),'-'
															,month(PF.repeat_until)
															,'-01'
								),'%Y-%c-%d'), interval -1 day)
                        else PF.repeat_until
					 end 											as PerformanceRangeEndDate
					
					,PF.venue_id										as VenueId
					,case when PF.venue_id is null then PF.venue end as VenueNameRaw
					,SW.socs_list									as SocietyComboValueRaw
					
					,SW.title										as StoryNameRaw
					,SW.author										as StoryAuthorRaw
					,SW.category									as StoryType
					
					,SW.id											as ddShowId
					
					,SW.prices										as PriceRaw
					
		from 		camdram_prod.acts_performances		PF
		inner join 	camdram_prod.acts_shows				SW	on PF.sid = SW.id
		where 		PF.sid is not null	-- Orphan performance rows are useless
        and 		SW.authorised = 1
		;


	drop view if exists camdram_dw.extractv_fct_roles;
    create view camdram_dw.extractv_fct_roles as 
		/*
			Intentionally not including names of actual humans.
            Technically public domain, but people probably wouldn't assume or 
            expect this kind of bulk data processing and availability (GDPR would say no).
            We've also shied away from releasing bulk data like this in the past for 
            more specific reasons, see e.g. https://github.com/camdram/camdram/issues/55.
        */
		select 		PL.sid			as ShowId
					,PL.pid			as ParticipantId
					,PL.`type`		as ParticipantType
					,PL.`role`		as ParticipantRoleRaw
					,PL.`order`		as RoleDisplayOrder
		from 		camdram_prod.acts_shows_people_link		PL
        inner join 	camdram_prod.acts_shows					SW	on PL.sid=SW.id
        where 		SW.authorised = 1
		;

end @
delimiter ;

call camdram_dw.setup_extract_views();