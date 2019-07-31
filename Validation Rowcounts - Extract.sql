-- VALIDATION OF EXTRACTED ROWCOUNTS - MANUAL INSPECTION

select 'extract_dim_society_combo', count(1) from camdram_dw.extract_dim_society_combo
union all
select 'extract_dim_society_free', count(1) from camdram_dw.extract_dim_society_free
union all
select 'extract_dim_society_official', count(1) from camdram_dw.extract_dim_society_official
union all
select 'extract_dim_story', count(1) from camdram_dw.extract_dim_story
union all
select 'extract_dim_user', count(1) from camdram_dw.extract_dim_user
union all
select 'extract_dim_venue_free', count(1) from camdram_dw.extract_dim_venue_free
union all
select 'extract_dim_venue_official', count(1) from camdram_dw.extract_dim_venue_official
union all
select 'acts_users', count(1) from camdram_prod.acts_users
union all
select 'acts_shows', count(1) from camdram_prod.acts_shows
union all
select 'acts_societies', count(1) from camdram_prod.acts_societies
union all 
select 'extract_fct_performances', count(1) from camdram_dw.extract_fct_performances
union all
select 'extract_fct_roles', count(1) from camdram_dw.extract_fct_roles
union all
select 'acts_performances', count(1) from camdram_prod.acts_performances
union all
select 'acts_shows_people_link', count(1) from camdram_prod.acts_shows_people_link
;