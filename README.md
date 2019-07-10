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

See sections below for detailed instructions or guidance.

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

## Installation

* set up Docker and docker-compose locally
* clone this repository and `cd` into its directory

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
`previous_url_patterns` | url patterns (using glob wildcards) for where the item was previous found in Kete for various actions, useful for setting up redirects to new system
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

`json` is recommeneded for the meta report. By default the API
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

#### Downloading the standard content types

Kete standard content types are `audio_recordings`, `documents`,
`still_images`, and `web_links`. There are also two special case
content types, `comments` which we are skipping for now, and `users`
which we'll cover later.

Start by downloading these types. Check the meta report for those that
have a `count` of more than zero for their content.

Here's the most basic way to download `still_images`, the same pattern
can be used for the other content types.

```sh
./bin/extract_as_json.sh still-images
```

First use the appropriate export script, in this case
`bin/extract_as_json.sh`, but if you want `tsv`, use
`bin/extract_as_tsv.sh`. Then specify the type in url style dash
separated plural form (i.e. kebab case).

There are two additional arguments that you can specify for the
script. Output file and options.

Output file is relative path of the file you would like created with
the data.

```sh
./bin/extract_as_json.sh still-images path-to/file.json
```

Options are in the form of a URL query string and they should be
separated by an escaped appersand, `\&`. They specify any
options you want for manipulating the data.

Here are the options currently supported:

Option | Notes
----- | -----
`except_baskets` | comma separated (no spaces) list of basket keys that should be excluded from results
`only_baskets` | comma separated (no spaces) list of basket keys of those baskets that data should be limited to
`limit` | number of results to limit to, used in combination with `offset` to paginate results
`offset` | number of record in results to start after, E.g. when used in combination with `limit`, `limit=10\&offset=10` would say to only return results 11 - 20 or "page 2"

Arguments for the scripts are positional, so options require that the
output file parameter is also specified!

Here's how to request the first and second 100 results for still images in two
successive files:

```sh
./bin/extract_as_json.sh still-images still-images-page-1.json limit=100\&offset=0
./bin/extract_as_json.sh still-images still-images-page-2.json limit=100\&offset=100
```

Using limit and offset for pagination is probably most useful for
breaking up `json` into more managable chunks.

Here's how to request results in `tsv` for all documents only in a
specific basket:

```sh
./bin/extract_as_json.sh documents community-group-a-documents.json only_baskets=community_group_a

```

Here's how to request results in `tsv` for all web links as long as
they are not in the generic "about" and "help" baskets:

```sh
./bin/extract_as_json.sh web-links web-links.json except_baskets=about,help

```

#### Downloading topic types

The other types listed in the meta report, except for the special
content type`users` and the `relations` type for linking records which
we'll cover last, are topic types.

Some of these come standard with Kete, such as `topic` while others
are dynamicall added by site admins and therefore their names are not
known ahead of time.

You can derive the type name for a topic type by looking at the
`table_name` in the meta report and dropping the `extracted_` prefix.

How you download the data for a type is the same as for content types
_except you use singular form for the type argument_! Here's how to
get the person type's data in `json` with limit and offset:

```sh
./bin/extract_as_json.sh person people-page-1.json limit=100\&offset=0
```

#### Downloading users and relations

You may also want to bring across `users` for your new system as well
as the mapping of which pieces of content are related to which topics
via the `relations` data.

The same scripts will work for them, however the `except_baskets`
and `only_baskets` options are not relevant.

E.g.

```sh
./bin/extract_as_json.sh users # or relations as type
```

will give you the data for each.

_Note: extracted `users` data doesn't include the hashed passwords,
although they are available in the legacy table. Email addresses are
included, so be careful not expose extracted data publicly.

That's everything at this point.

#### Shutting down temporary API and cleaning out docker images

Once you are done with downlding data from the API, you can shut it
down in the shell it was running in with `control-c control-c`.

Then you can clean out any stuff `docker-compose up` left around with
`docker-compose down`.

### Recommended order of import into new systems

* import users first
* then content types and topics types
* last import relations

### Mapping corresponding audio, document, image, and video files to data

* content types with associated files that were uploaded to Kete have
  a `relative_file_path` column (`still_images` have different column
  names, but same idea, should be self explanatory)
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

## Credits

This project was developed by [Walter McGinnis](waltermcginnis.com) for
migrating data from the  [Kete](old.kete.net.nz) open source
application and was funded by [Digital New Zealand](digitalnz.org).

## COPYRIGHT AND LICENSING  

GNU GENERAL PUBLIC LICENCE, VERSION 3  

Except as indicated in code, this project is Crown copyright (C) 2019,
New Zealand Government.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses /
http://www.gnu.org/licenses/gpl-3.0.txt
