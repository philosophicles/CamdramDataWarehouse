# CamdramDataWarehouse

Totally work in progress currently; not in a useful state yet.

An attempt at an ETL process to convert Camdram data into a dataset that is suitably anonymized and desensitized for public analysis, and structured according to data warehousing conventions (star schema, aka Kimball method).

The Kimball method for data warehousing aligns closely with what data science now calls "tidy data"; this is mostly different industries' terminology for the same thing.

The result of this project should be easy to conduct data visualization or analysis on.

The project is pure SQL, that should (hopefully) execute on recent versions of MariaDB or MySQL. I haven't tested against other DBs yet but it's as close to ANSI SQL as possible.

It's designed to run against an existing copy of the Camdram website database on the same server (separate schema); you have to be able to make a copy of that for yourself.

The project includes declarations for the data structures, and all logic is contained within stored procedures. Eventually, the top level stored proc(s) could be called by a simple cron job or similar, on whatever data refresh schedule is desired.

## Overview of stored procedures

### Setup

These are procedures that should be run once when creating this project against an empty database schema, or when recreating during development. However, these procedures don't need to be rerun simply to refresh updated live website data into the data warehouse.

1. CREATE SCHEMA `camdram_dw` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs ;
		* Case Sensitive collation is potentially important...
2. call setup_numbers();				-- No dependencies
3. call setup_extract_tables();		-- No dependencies
4. call setup_extract_views();		-- Depends on numbers
5. call setup_dim_date();				-- Depends on numbers and some views
6. call setup_dim_time();				-- Depends on numbers

At this point there's a bunch of defined objects but no actual data.

### Regular reload process

1. call run_extract_dims();		-- Populates the extract_dim tables, 0.3s. Hits the prod database.
2. call run_extract_facts();	-- Populates extract_fct tables, 1s. Hits the prod database.

From here on, everything should be isolated within the camdram_dw database

3. TBC

