# Camdram Data Warehouse

A pure-SQL ETL (extract, transform, load) process to generate Camdram datasets that can be freely shared as delimited text files, and used for data analysis and visualisation.

## Why?

These datasets could, perhaps, be useful for generating new insight about the world of Cambridge student theatre, as well as about usage of Camdram itself. They might also be useful to reference while extending Camdram's functionality or the data held on the site.

This ETL process does necessarily mutate the Camdram data in the interests of making it easier to understand and work with. Camdram has been through many codebase changes over the years, and this has resulted in variations in the underlying data that don't correlate to variation on the website. The spirit of this project is that changes to abstract away website implementation details and database variability are fine, as are changes to iron out isolated "weirdness" in the data due to historic bugs in the website codebase.

It is not the goal of this project to fundamentally change the data beyond recognition, or to attempt to programmatically correct data quality errors stemming from how users entered data into the site.

## Installation

This should run on recent versions of either MariaDB or MySQL; anything that's not cross-compatible is a bug.

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

The total reload process takes 1-2 minutes on the mid-grade hardware it was developed on.

## Create output files

**This part is in need of some refinement!**

Fill in suitable connection details into `generate_output.sh` (don't commit them to source control!) and run it.

A set of TSV (tab-separated values) files will be created in the `output` directory. Rerunning will overwrite them.

It might make sense to make this part of the existing reload process, rather than a separate step.

## About the output files

The design and relationships between data files is based on widely-used conventions in the data warehousing world. These files comprise what is often called a "star schema", "dimensional model", or "Kimball model" (after Ralph Kimball, who co-defined and popularised the practice).

This design also closely aligns with what the data science community now calls "tidy data"; this is mostly different industries' terminology for the same thing.

Files with a `fct` prefix and plural name are fact tables: lots of rows, few columns. Columns either contain _measurements_ (values that measure something tangible, and can be aggregated meaningfully via functions like `sum` or `average`) or integer "surrogate" keys referring to dimension tables.

Files with a `dim` prefix and singular name are dimension tables: lots of columns, generally fewer rows. Dimensions describe and differentiate the fact measurements. Many fact rows will reference the same dimension row. Beyond the surrogate key that links the tables together, dimension attributes are mostly descriptive and can be used to group or filter the fact data.

Column names are in the first row of the output files, and should be easy to understand so long as one is familiar with how Camdram itself is used.

`Key` suffixes on columns imply a dimension surrogate key, the fields used to link facts to dimensions - the joins should be easy to figure out. Only one column from each table should be needed to join to each other table.

### Camdram concepts and definitions

For anyone exploring the data who isn't intimately familiar with how Camdram itself works, here's a primer:

* Show/production: this is a specific listing with a URL starting `www.camdram.net/shows/`.

* Performance: one show typically has multiple performances, either on separate or the same date. Performances must start at a specific time, which is assumed to always be expressed in local time at the performance venue. Some show listings on Camdram don't have information about performance dates, although this is rare.

* Venue: every performance should take place somewhere. One show many have performances in more than one venue but each performance can only be in one venue. It is possible to list a show with performance dates but without venue information. Not all venues are necessarily in Cambridge, or even in the United Kingdom. Camdram has a curated list of major venues at www.camdram.net/venues, but users can type in their own venue name whenever they want.

* Society: shows are typically produced or funded by one or more societies. Not all shows have any related societies. Because of the "one or more" relationship, a `combo` table is required to link facts to the society dimension. Like venues, Camdram curates a list of major societies (https://www.camdram.net/societies) but societies can also be user-entered.

* Story: this concept is not overtly present in Camdram itself, but for data analysis purposes a 'story' is a unique combination of a title, author, and show category. This allows different productions of the same basic story or script (for example, Hamlet by William Shakespeare) to be associated.

* Show categories: Camdram allows the creator of show listings to choose a category, such as drama, comedy, or musical. This property is currently not used much or at all in the Camdram web user interface, and it is possible that some show listing creators do not set it correctly.


### Fact tables

1. Performances

This fact table contains a row for every discrete performance happening in a venue at a specific datetime, of a single production.

_Other facts coming soon..._

### Measure information

1. Counting rows or distinct values

A lot of information here is contained in simple counted measures:

* count of fact rows equates to number of discrete performances
* `count(distinct ShowId)` for number of shows
* counts of dimension identifiers like `VenueId`, `SocietyId`, etc

In this dataset, counting shouldn't be underestimated.

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
