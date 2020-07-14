# Camdram Data Warehouse

An (almost) pure-SQL ETL (extract, transform, load) process to generate Camdram datasets that can be freely shared as delimited text files, and used for data analysis and visualisation.

## Why?

These datasets could, perhaps, be useful for generating new insight about the world of Cambridge student theatre, as well as about usage of Camdram itself. They might also be useful to reference while extending Camdram's functionality or the data held on the site.

By design, the data is mutated to make it easier to understand and work with, than the actual operational database used by the website itself. Camdram has been through many codebase changes over the years, and this has resulted in variations in the underlying data that don't correlate to variation on the website.

The spirit of this project is to abstract away website implementation details, gradual variations over time, and isolated data weirdness caused by bugs in the website software. This project is _not_ intended to fundamentally change the interpretation of the data from how it would look on the website, or correct data quality errors stemming from how users entered data.

Another key goal is to ensure the output is anonymous, i.e. does not contain any data identifying individual people. This makes it possible to share the data legally, in accordance with the EU General Data Protection Regulation.

## Installation

This should run on recent versions of either MariaDB or MySQL; anything that's not cross-compatible between those two is a bug.

It's designed to run against an existing copy of the Camdram website database on the same server (separate schema); you have to be able to make a copy of that for yourself.

To install, edit the first few lines of `install.sql` to specify a mysql schema/database name that will be used for the data warehouse. The stated schema will be dropped and recreated if it already existed; choose your name wisely.

The codebase assumes that the camdram website data is in a schema called `camdram_prod`.

From a shell prompt, starting in the top-level directory of this project, connect to your running `mysql` instance:

    $ mysql -u SomeUser -p

From the mysql prompt, run the installation script:

    mysql> source install.sql;

You should see a stream of "Query OK..." messages. When they're done and you're back at the mysql prompt, installation is done.

## Load or reload data

From a shell prompt in the top-level directory:

    $ mysql -u SomeUser -p -e "call run_all();" camdram_dw

Replace `camdram_dw` with the schema in which everything was installed.

This will do a full reload:

1. Extract a copy of _relevant_ data from the production camdram schema, into the camdram_dw schema
2. Process the data warehouse dimensions: society, venue, etc
3. Process the facts: currently, just performances (more might be added in the future)

Pre-existing data in the camdram_dw schema is completely removed / overwritten each time a reload takes place.

The total reload process takes 1-2 minutes on a mid-range consumer laptop.

The idea is that this can be scheduled via `cron` or equivalent, though credential management will need addressing.

## Manual validation of data out vs data in

If you wish, run the whole of `validate_rowcounts.sql` to produce a summary of the rowcounts in the production schema vs the data warehouse results. Some common-sense interpretation of these is needed but it can be used to give a basic re-assurance that data isn't being lost. If numbers are 0 or vary wildly, something is probably wrong.

Some automated validation tests could be built based on this...

## Create output files

This part is surprisingly hard to do from mysql, if the goal is standard CSV-format files. (Tab-separated files are easier but less useful for analysis tools.) We've resorted to a python-based approach for this final step, and as with the reload, the intention is for this to be automated.

Each output file relates to a single "fact type" (defined below) and should be in keeping with the notion of "tidy data" (see Google). Column names are in the first row, and should be easy to understand so long as one is familiar with how Camdram itself is used.

### First-time / installation steps

* Install python 3+ and install dependencies with `pipenv install`.
* Make config file: `cp src/config.jsonc.example src/config.jsonc` then edit accordingly
* Use the `keyring` CLI (documented online) within the virtualenv to define the password for the configured mysql account

### Every time

`pipenv run python src/output_to_csv.py`

### Camdram concepts and definitions

For anyone exploring the data who isn't intimately familiar with how Camdram itself works, here's a primer:

* Show/production: this is a specific listing with a URL starting `www.camdram.net/shows/`.

* Performance: one show typically has multiple performances, either on separate or the same date. Performances must start at a specific time, which is assumed to always be expressed in local time at the performance venue. Some show listings on Camdram don't have information about performance dates, although this is rare.

* Venue: every performance should take place somewhere. One show many have performances in more than one venue but each performance can only be in one venue. It is possible to list a show with performance dates but without venue information. Not all venues are necessarily in Cambridge, or even in the United Kingdom. Camdram has a curated list of major venues at www.camdram.net/venues, but users can type in their own venue name whenever they want.

* Society: shows are typically produced or funded by one or more societies. Not all shows have any related societies. Because of the "one or more" relationship, a `combo` table is required to link facts to the society dimension. Like venues, Camdram curates a list of major societies (https://www.camdram.net/societies) but societies can also be user-entered.

* Story: this concept is not overtly present in Camdram itself, but for data analysis purposes a 'story' is a unique combination of a title, author, and show category. This allows different productions of the same basic story or script (for example, Hamlet by William Shakespeare) to be associated.

* Show categories: Camdram allows the creator of show listings to choose a category, such as drama, comedy, or musical. This property is currently not used much or at all in the Camdram web user interface, and it is possible that some show listing creators do not set it correctly.


### Fact types

1. Performances

A row for every discrete performance happening in a venue at a specific datetime, of a single production.

This is a powerful fact for analysing most angles of _what has happened_. It's not a good choice for most questions related to participation levels, though, because the same people tend to participate in many different performances (and aren't identified individually here).

_Other facts coming soon, primarily to tackle participation..._

### Measure information

1. Counting rows or distinct values

A lot of information here is contained in simple counted measures:

* count of fact rows equates to number of discrete performances
* `count(distinct ShowId)` for number of shows
* counts of dimension identifiers like `VenueId`, `SocietyId`, etc

In this dataset, the utility of just counting things shouldn't be underestimated.

2. Min and Max ticket price

The data collected by Camdram about ticket prices is sparse, and text-based.

Numeric price information is calculated heuristically by looking for numbers in the raw data and assuming they are ticket prices.

In some cases, that will not be true, which may lead to extreme outlier values, or plausible but incorrect values.

Where no price information was entered into Camdram, these measures will show `NULL`, to distinguish from where price information was entered and a £0 price exists.

Many shows on Camdram have more than two ticket prices applicable during their performance run. Prices often vary between weeknights and weekends, and may have one or more concessionary rates in addition to a standard rate. With this much variability, it made most sense to simply model the lowest and highest price listed.

Camdram doesn't directly record the relationship between price and specific performances. Therefore, this price information is repeated for every performance of a `ShowId`. In most cases, you should calculate the max (or min) value for each measure column per ShowId, before aggregating further. In any case, it does not make sense to sum prices - these measures should be averaged, or the min/max values of a wider fact scope obtained.

Prices are assumed to always be in Pounds Sterling (GBP), although it is possible that some price information might have been entered into Camdram in other currencies.

3. Count of Cast, Crew, Band

This represents how many human participants are listed in each of the three categories that Camdram uses for production credits. "Crew" is shorthand for "Production Team" as visible on the website.

If one person is listed against two roles in the same category, this will still only count for 1 in these facts. If two people share a role, that counts for 2.

The counts for each of the three categories are independent: if one person is listed in two or all three categories, they would be double-counted.

Because the same participants apply to every performance of a show, the measure values are repeated for all rows with the same `ShowId`. These measures should therefore not be summed across ShowId. Calculate max (or min) values per ShowId first, then sum to obtain a total across all shows. Note, however, that this will overstate how many people have really been involved, because some people will be involved with multiple shows.

Because of that, these measures lend themselves better to average-based aggregations.

A separate fact table is planned, with greater granularity about show participation, to allow calculations that account for the same person being involved in many shows.

Note, there are many shows for which no production credits are provided. These measures will show 0 in all such cases.

## Understanding the data structures within the data warehouse process

The design of the internal tables/views in this solution is based on widely-used conventions in the data warehousing world. These files comprise what is often called a "star schema" or "dimensional model".

Tables with a `fct` prefix and plural name are facts: lots of rows, few columns. Columns either contain _measurements_ (values that measure something tangible, and can be aggregated meaningfully via functions like `sum` or `average`) or compact integer "surrogate" keys referring to dimension tables.

Tables with a `dim` prefix and singular name are dimensions: lots of columns, generally fewer rows. Dimensions describe and differentiate the fact measurements. Many fact rows will reference the same dimension row. Beyond the surrogate key that links the tables together, dimension attributes are mostly descriptive and can be used to group or filter the fact data.

`Key` suffixes on columns imply a dimension surrogate key, the fields used to link facts to dimensions - the joins should be easy to figure out. Only one column from each table should be needed to join to each other table (no compound keys).

This kind of design is called a star schema because a single fact table links directly to a number of dimension tables, that are commonly drawn in diagrams surrounding the central fact table like points of a star. If the denormalization of data values in the dimensions makes you uncomfortable: remember that this data is only ever being recreated in bulk, never row-by-row. Minimizing join "hops" makes data processing and analysis easier; keeping the separation between "row-heavy" facts and "column-heavy" dimensions keeps performance and storage requirements tolerable.

We ultimately fully flatten the data to a single CSV file for sharing, because some data analysis tools cannot perform joins between different table/frame objects. We could additionally output the final dimensional tables (fct_ and dim_) for analytic cases where that was preferred.
