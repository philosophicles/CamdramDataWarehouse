# CamdramDataWarehouse

An ETL process to convert Camdram data into a dataset that is suitably anonymized and desensitized for public analysis, and structured according to data warehousing conventions (star schema, aka Kimball method).

Still work-in-progress.

The Kimball method for data warehousing aligns closely with what data science now calls "tidy data"; this is mostly different industries' terminology for the same thing.

The result of this project should be easy to conduct data visualization or analysis on.

The project is pure SQL, that should (hopefully) execute on recent versions of MariaDB or MySQL.

It's designed to run against an existing copy of the Camdram website database on the same server (separate schema); you have to be able to make a copy of that for yourself.

The project includes declarations for the data structures, and all logic is contained within stored procedures. Eventually, the top level stored proc(s) could be called by a simple cron job or similar, on whatever data refresh schedule is desired.

## Installation

Edit the first few lines of `install.sql` to specify a mysql schema/database name that will be used for the data warehouse. The stated schema will be dropped and recreated if it already existed; choose your name wisely.

The codebase assumes that the camdram website data is in a schema called `camdram_prod`.

From a shell prompt, starting in the top-level directory of this project, connect to your running `mysql` instance:

    $ mysql -u SomeUser -p

From the mysql prompt, run the installation script:

    mysql> source install.sql;

You should see a stream of "Query OK..." messages. When they're done and you're back at the mysql prompt, installation is done.

## Load or reload data

From a shell prompt in the top-level directory:

    $ mysql -u SomeUser -p camdram_dw < reload.sql

Replace `camdram_dw` with the schema in which everything was installed.

This will do a full reload, calling in turn a number of stored procedures that:

1. Extract a copy of _relevant_ data from the production camdram schema, into the camdram_dw schema.
2. Process the data warehouse dimensions: society, venue, etc.
3. Process the facts: performances, etc.

Pre-existing data in the camdram_dw schema is completely removed / overwritten each time a reload takes place.

The reload process may take a couple of minutes.
