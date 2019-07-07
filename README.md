# ExtractionPoint

Tools for processing Kete data after it has been exported in
PostgreSQL importable form

## Requirements

Expects [Docker](https://www.docker.com) to be up and running and
[`docker-compose`](https://docs.docker.com/compose/) to be available
on machine.

## Overview

Extraction Point migrates Kete's data to modern PostgreSQL based
tables and columns using standard datatypes rather than Kete specific
Extended Fields, etc.

Then it makes this new version of the data available via a temporary
API that can return JSON or TSV files (like CSV files, but tab
delimited) so that you can import the data into other systems.

A typical workflow will look like this:

* grab your Kete site's original data via [Kete  extraction](https://github.com/walter/kete_extraction)
* use this project to standardize and modernize the data via initial data migration
* use this project to download JSON or TSV files for the new version of the data
* import and map the data into new system including steps to map
  audio, document, image, and video files to their corresponding data
  (this may vary a lot depending on the new system)

Extraction Point or the workflow you use should be straight forward to
modify or extend for a given projects needs.

See sections below for in detail instructions or guidance.

_Note: This is a non-destructive set of tools and the original tables and data (along with new versions of the data) are available for further querying or use via SQL, etc. or even using common tools such as `pg_dump` to create full or partial back up of the database to be imported elsewhere._

## Current limitations

Due to time constraints and the desire to cover the most common needs
of Kete sites first, some data from Kete has not yet been modernized
and therefore not made available via the included API:

* comments
* private items
* full version history meta data
* basket membership and roles
* fully resolving values of fields that included a "base URL" as
  prefix for field value via Kete's Extended Field and Choice system
* replacing URL values of fields that refer to old site URL as
  prefix for field value via Kete's Extended Field and Choice system
  -- this is best handled as bulk search and replace operation
  separately once new system URL patterns are determined

A further limitation is that no constraints or indexes are in place
for either legacy tables or modernized tables as the database is
intended as intermediate tool rather than a final application
database. If you want to base an application's database off the
Extraction Point one, we recommend you evaluate what constraints and
other changes are needed.

Again, keep in mind that all of the original tables and data are
available to work around these limitations. The project also welcomes
open source contributions or further funding to improve it.

## Usage

### Initial data migration

You'll need a sql file that is an export of a Kete site's data via
[Kete extraction](https://github.com/walter/kete_extraction).

The first step is to import that data. This will trigger `docker` and
`docker-compose` to set up the necessary images and containers on the
machine. So the first time you run any of the commands may be slow.

```sh
docker-compose run app mix extraction_point.load_sql _the_kete_export_file.sql_
```

The next step is to trigger the migration of data from Kete's specific
format to modern PostgreSQL tables and columns.

This includes _per row_ updates, so it can take a long time depending
on how much data your Kete site had.

```sh
docker-compose run app mix ecto.migrate
```

If you have a lot of data, you may want to surpress standard output
like this instead:

```sh
docker-compose run app mix ecto.migrate > /dev/null
```

_Note: If you need to undo last migration (you can do this repeatedly
until at right spot), you can rollback._

```sh
docker-compose run app mix ecto.rollback
```

Now you are ready to download the migrated data via the included
scripts that use the provided API.

### Things to know about the standardized and modernized data

Some background. Kete's fundamental organizing container is the basket
with content items (audio recordings, documents, images, videos, and
web links) and topics (which in turn are organized into site defined
topic types) grouped by basket. Comments (also referred to as
"discussion" in the UI) were then associated with a content item or
topic and also "owned" by the same basket.

These content types and topic types are the primary data that
Extraction Point exports.

Here are the common fields for the content type and topic type based
records with explanatory comments:

Column | Notes
------ | -----
`id` | id field has same value as original data table
`title` | name of item
`description` | description of item in HTML, can be long
`tags` | names of tags associated with item, multiple value field
`version` | number of last published version of item
`inserted_at` | when the item was created in the database
`updated_at` | when the item was last modified in the database
`basket_id` | id of basket in legacy baskets table
`basket_key` | name of basket as it was reflected in urls, for convenience
`license_id` | id of license in legacy licents table
`license` | text title of license for convenience
`previous_oai_identifier` | unique id in Kete's included OAI-PMH repository - useful for tracking where the record was previously in any aggregation system, E.g. Digital New Zealand, that harvested the repository
`previous_url_patterns` | where the item was previous found in Kete for various actions, useful for setting up redirects to new system
`creator_id` | id of user who created item in legacy users table
`creator_login` | unique login of user who created item in legacy users table, for convenience
`creator_name` | user chosen display name of user who created item in legacy users table, for convenience
`contributor_ids` | list of ids of users who modified item in legacy users table
`contributor_logins` | unique logins of users who modified item in legacy users table, for convenience
`contributor_names` | user chosen display names of users who modified item in legacy users table, for convenience

_Note: contributors (and creator) are only listed once even though they may have
contributed multiple versions of the item. So order in fields does not
correspond to order or number of contributions._

Then each may or may not have _additional fields_ depending on two
things.

1. fields that were specific to the type, E.g. `url` for `web_links`
   or `content_type` for `documents` to store whether the document is
   a `pdf` or `doc` file
2. what Extended Fields were set up for the type, E.g. `dob` could
   have been set up for the `person` type

Extraction Point includes a report that will describe each extracted
type and all of its columns along with how many records it has for
each type. We'll cover that in the next section.

### Downloading data in TSV or JSON format

First we need to spin up the API server with the following command in
its own shell:

```sh
docker-compose up # wait for the output to report "[info] Access ExtractionPointWeb.Endpoint at http://localhost:4000"
```

Now in another shell within the same directory, you can start
downloading the data. First up is the meta report which will guide our
further downloads.

```sh
./bin/extract_as_json.sh meta meta.json # this says to request the meta report and output it to a file named meta.json
```

For the meta report, I recommend using json output. By default the API
outputs json without extra white space which is hard to read. Either
open the file in your favorite editor and use the editor's capability
to pretty print the json or if you have
[jq](https://stedolan.github.io/jq/) handy use `jq . meta.json` to
examine it. This goes for any of the json output.

You can see that the meta report lists the extracted types with their
columns with datatypes, the number of rows they have under `count`, as
well as which baskets the rows are in.

Use this information to determine your download plan. Obviously you
can skip types that have a `count` of 0.

You may also want to skip types that are only `within_baskets` of
"about" or "help" as these are generic Kete baskets that may not
contain anything specific to your site or are not relevant to your new
system. There is also the option to skip particular baskets which
we'll talk about shortly and these baskets are good candidates to for
this option.

Now determine if you want to extract `json` or `tsv` to download your
data. This is going to depend on what you plan to do next with the
data and what requirements the system you plan on importing to has.

`tsv` is functionally equivalent to `csv`, but is handled better
by Excel when the data contains unicode characters from what we have
read. Outside of Excel, most comma separated values parser libraries
should allow for specifying tab as a delimiter.

* download standard content types
* talk about options to limit to a basket
* talk about pagination with json
* download topic types
* download users
* download relations

### Recommended order of import into new systems

* import users first
* then content types and topics types
* last import relations

### Mapping corresponding audio, document, image, and video files to data

* content types with associated files that were uploaded to Kete have
  a `relative_file_path` column
* you have to prefix this path with appropriate path that corresponds
  to whether it is public or private and its type for where the file
  will be found in the exported files from Kete Extraction. E.g. if
  `relative_file_path` for a document is `0000/0000/001/file.pdf`
  then it will be found at `public/documents/0000/0000/001/file.pdf`.
* in the future we will also handle private items and they will be
  found under the `private` directory
* still images are a special case as they have multiple image files
  associated with them, the original and also resized versions such as
  thumbnails. It has columns for `relative_original_file_path` and
  `relative_resized_file_paths` accordingly - the rezsized files will
  only be present if you opted to export them

## Appendix

### Wiping and starting again

_Note: this tool spins up a container for PostgreSQL to run. It
persists data under `docker/data/postgres` between command runs._

_If you want to start from scratch or clean things out, do
`rm -rf docker/data/postgres/*`._

### Lower level data access tools

You can also examine the data via a `psql` session or through the
Elixir application via `iex`.

For `psql` for direct sql access:

```sh
docker-compose run app psql -h db -U 'postgres` extraction_point_dev
```

Extraction Point is built using [Elixir](https://elixir-lang.org ) and
[Phoenix](https://phoenixframework.org) and has the
[`iex`](https://hexdocs.pm/iex/IEx.html) interactive shell available
for interacting with the application via Elixir:

```sh
docker-compose run app iex -S mix
```
