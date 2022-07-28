---
canonical: https://www.busbud.com/blog/automatically-index-heroku-postgres-database-dexter/
hero: ../../img/2017/06/automatically-index-postgres-dexter.jpg
focus: 50% 25%
heroCredit: Benjamin Pley
heroCreditUrl: https://unsplash.com/photos/WiSeaZ4E6ZI
---

# Automatically index your Heroku Postgres database with Dexter
Your database is clever enough to index itself  
June 28, 2017

<div class="note">

**Note:** this is a mirror of the blog post originally published on
[Busbud blog](https://www.busbud.com/blog/automatically-index-heroku-postgres-database-dexter/)!

</div>

[Dexter] is a new tool that just came out with a mind-blowing idea:
automatically figuring out the indexes you need based on your database
logs.

> Your database knows which queries are running. It also has a pretty
> good idea of which index is best for a given query.
>
> [Introducing Dexter, the Automatic Indexer for Postgres][introducing-dexter] — Andrew Kane

[Dexter]: https://github.com/ankane/dexter
[introducing-dexter]: https://medium.com/@ankane/introducing-dexter-the-automatic-indexer-for-postgres-5f8fa8b28f27

You should read the above introduction if you want to learn more about
Dexter itself.

Basically, it uses hypothetical indexes through the [HypoPG] extension
to test if adding an index on a column would have improved a given query
performance, based on the logs of your production Postgres server.

[HypoPG]: https://github.com/dalibo/hypopg

This article won't cover in details Dexter itself, since the
[introduction][introducing-dexter] is pretty complete. However it
mentions that **because Dexter needs the HypoPG extension, we can't use it
with Heroku or Amazon RDS.**

Today, we'll see how to use Dexter with Heroku (or RDS with a few
tweaks).

## The idea

Dexter only needs access to the database with HypoPG for testing the
query plan with and without hypothetical indexes, to see if they would
help speed up some queries. Unless you want to let it automatically add
indexes to your production database, there's no real need for it to run
on directly on production. Only the production **logs** are important.

Here, we're going to feed the production logs from Heroku Postgres to
Dexter, but let it analyze the queries and hypothetical indexes on a
local Postgres, running with Docker.

## Postgres Docker image with HypoPG

We're going to build the following Dockerfile to use Postgres (9.6 in
our case) with HypoPG:

```dockerfile
FROM postgres:9.6

RUN apt-get update && apt-get -y install wget build-essential postgresql-server-dev-9.6

RUN wget https://github.com/dalibo/hypopg/archive/1.0.0.tar.gz && \
    tar xf 1.0.0.tar.gz && \
    cd hypopg-1.0.0 && \
    make && \
    make install
```

```sh
docker build -t postgres-hypo .
```

## Preparing the data directory

I assume you already have a local database with the same schema as the
production database, let's say in `/usr/local/var/postgresql`. Make
sure Postgres is stopped, and make a copy to work on it with Dexter:

```sh
cp -r /usr/local/var/postgresql ~/dexter-postgres
```

We're gonna extract the default configuration of the dockerized
Postgres, because we don't want to run it with your local config (which
might listen on an UNIX socket instead of a TCP port, and use a different
access configuration):

```sh
mkdir ~/postgres-default
docker run --name=postgres -v ~/postgres-default:/var/lib/postgresql/data postgres-hypo
^C
cp ~/postgres-default/*.conf ~/dexter-postgres
```

This will run the server on an empty data directory in `~/postgres-default`,
and let it initialize the default configuration. Then we kill it and copy the
container configuration to the real data directory.

## Run the server

```sh
docker run --name=postgres -v ~/dexter-postgres:/var/lib/postgresql/data -p 5432 postgres-hypo
```

This will mount your `~/dexter-postgres` in the container data
directory, and bind the `5432` port from the container to your host.

You can connect to it with:

```sh
docker run -it --rm --link postgres postgres-hypo psql -h postgres -U <user> <db>
```

Then run the following to enable HypoPG:

```sql
CREATE EXTENSION hypopg;
```

## Running Dexter

Install Dexter with:

```sh
gem install pgdexter
```

Then pipe your production logs to Dexter, and connect it to your local
copy:

```sh
heroku logs -a your-app -p postgres -t \
    | sed 's/^.*: \[[A-Z0-9_]*] \[[0-9-]*]//' \
    | dexter --log-level debug postgres://<user>@localhost:5432/<db> \
    | tee dexter.log
```

The `sed` part is to strip the prefix of Heroku Postgres logs that
Dexter does not recognize; before stripping it, the logs looks like:

```
2017-06-28T15:10:02+00:00 app[postgres.13761]: [DATABASE] [7-1]  sql_error_code = 00000 LOG:  duration: 4822.012 ms  statement: BEGIN READ ONLY;
2017-06-28T15:10:02+00:00 app[postgres.13761]: [DATABASE] [7-2]       SELECT column
2017-06-28T15:10:02+00:00 app[postgres.13761]: [DATABASE] [7-3]         FROM table
2017-06-28T15:10:02+00:00 app[postgres.13761]: [DATABASE] [7-4]        WHERE condition
```

And we need it to be like:

```
sql_error_code = 00000 LOG:  duration: 4822.012 ms  statement: BEGIN READ ONLY;
     SELECT column
       FROM table
      WHERE condition
```

I also use `--log-level debug` so Dexter outputs the queries that would
be optimized with a given index suggestion, so we can make more sense
of why that index would help. It also outputs the query cost before and
after the index which is very neat.

Finally, I `tee` the Dexter output to `dexter.log` (so I can see it live
but also access it in that file later).

After a couple minutes, Dexter analyzed a bunch of tables and tried
different hypothetical indexes based on the slow queries it saw through
the production logs.

Here's an example output for our case:

```
2017-06-30T11:38:58-04:00 Index found: tickets (reference)
2017-06-30T11:38:58-04:00 Query 018d8cd6e02ac3fe61bf30cf0ca8f4c8cfb809b0d8 (Cost: 122555.87 -> 16.08)

SELECT stuff FROM tickets WHERE reference = 'some-reference';
```

Dexter tells us that we should add an index on the `reference` columns
of the `tickets` table, and that would change the cost of the given
query from 122555.87 to 16.08.

## Conclusion

Who else better than your database can index your database?

Even though this is not entirely true, and you should definitely review
those found indexes and ask if it's the right thing for your app and the
queries you want to optimize for, having an automated tool suggesting
indexes based on the queries you actually run in productions is of great
value.

It could even make sense that at some point, database engines add a
layer that manages indexes automatically, without the need for external
tooling, by analyzing the queries you run the most and identifying the
tables where you would benefit more from write or read performance.
