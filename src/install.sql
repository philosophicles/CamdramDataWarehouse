
-- Create schema/database to hold the data warehouse
-- MODIFY THESE LINES if you want to use a different schema/database name
drop schema if exists camdram_dw;
create schema camdram_dw
	default character set utf8mb4 collate utf8mb4_0900_as_cs
;
use camdram_dw;

-- END part to modify; everything below will use the stated schema.

-- Create basic objects, and in some cases pre-populate them
source setup_numbers.sql
source setup_extract_tables.sql
source setup_extract_views.sql
source setup_final_tables.sql
source setup_time.sql
source setup_date.sql

-- Create stored procedures (but not execute them)
source extract_dimensions.sql
source extract_facts.sql
source load_dim_society.sql
source load_dim_story.sql
source load_dim_venue.sql
source load_fct_performances.sql
source runners.sql
