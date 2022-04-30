---
tweet: https://twitter.com/valeriangalliat/status/1448722067638177795
---

# Bypass SQLite exclusive lock 🔐
"Error: database is locked" is not an acceptable answer
October 14, 2021

There's a [number of ways](https://www.sqlite.org/lockingv3.html) SQLite
can lock a database file, and if you're encountering a "database is
locked" error, according to [the internet](https://stackoverflow.com/questions/151026/how-do-i-unlock-a-sqlite-database),
you have two options:

1. If you control the software that created the lock, go and fix the
   problematic queries.
1. You're fucked.

By "you're fucked" I mean that your seemingly only option is to **copy
the whole database file and query the copy**. If working off a one-time
snapshot of the database work for you, awesome, problem solved:

```console
$ echo .tables | sqlite3 db.sqlite
Error: database is locked
$ cp db.sqlite db-snapshot.sqlite
$ echo '.tables' | sqlite3 db-snapshot.sqlite
actual_table
```

But it seems that's not a good enough solution for many people (including myself)
and we're desperately trying to [perform](https://stackoverflow.com/questions/7857755/is-it-possible-to-open-a-locked-sqlite-database-in-read-only-mode)
[read-only](https://www.linuxquestions.org/questions/linux-server-73/can-i-open-sqlite-datbase-in-read-only-mode-4175578075/)
[queries](https://github.com/skeeto/emacsql/issues/34)
[on a](https://www.reddit.com/r/firefox/comments/aw01gq/how_to_disable_sqlite_database_locking_for/)
[locked](https://dba.stackexchange.com/questions/45368/how-do-i-prevent-sqlite-database-locks)
SQLite database.

This is especially useful for **Firefox** and **Chrome** SQLite files
because both browsers have a bad tendency to keep them permanently
locked, preventing us to access the database without closing the browser
first.

In my case, I want to poll a specific table, and while technically the
database is small enough that it's not a problem to copy it over and
over to query it periodically, **I just don't like this idea**
and I believe there *must* be a better way.

So let me tell you the better way.

## The better way

SQLite [allows passing](https://www.sqlite.org/c3ref/open.html) a
[`file:` URI](https://www.sqlite.org/uri.html) instead of a filename
(e.g. `file:db.sqlite` instead of `db.sqlite`), which comes with the
extra ability to pass query string parameters.

Some of those are aliases for flags you could otherwise set when opening
the connexion, for example [`mode=ro`](https://github.com/sqlite/sqlite/blob/8436f53ebe369e0d646068d3b25ea11673debf0e/src/main.c#L3023)
is equivalent to setting [`SQLITE_OPEN_READONLY`](https://www.sqlite.org/c3ref/c_open_autoproxy.html)
and [`cache=private`](https://github.com/sqlite/sqlite/blob/8436f53ebe369e0d646068d3b25ea11673debf0e/src/main.c#L3011)
the same as [`SQLITE_OPEN_PRIVATECACHE`](https://www.sqlite.org/c3ref/c_open_autoproxy.html).

But we also have other parameters that have a deeper implementation that
would otherwise be inaccessible to the SQLite user (no configuration
flags for those). In particular, [`nolock`](https://github.com/sqlite/sqlite/blob/8436f53ebe369e0d646068d3b25ea11673debf0e/src/pager.c#L4913)
and [`immutable`](https://github.com/sqlite/sqlite/blob/8436f53ebe369e0d646068d3b25ea11673debf0e/src/pager.c#L4915).

While `nolock` only prevents this connection from locking the database
and doesn't do anything about the fact a lock is already being held by
another connection, the `immutable` is especially interesting for us.
From its [documentation](https://www.sqlite.org/c3ref/open.html):

> The immutable parameter is a boolean query parameter that indicates
> that the database file is stored on read-only media. When `immutable`
> is set, SQLite assumes that the database file cannot be changed, and
> so the database is opened read-only and **all locking and change
> detection is disabled**.
>
> **Caution:** setting the immutable property on a database file that
> does in fact change can result in incorrect query results and/or
> [`SQLITE_CORRUPT`](https://www.sqlite.org/rescode.html#corrupt) errors.
>
> **See also:** [`SQLITE_IOCAP_IMMUTABLE`](https://www.sqlite.org/c3ref/c_iocap_atomic.html).

Even though `SQLITE_IOCAP_IMMUTABLE` is not an option per se, but a
particular characteristic of the IO device, we can force SQLite to treat
the database as if was on an read-only device by setting `immutable=1`,
which has the particularity of disabling all locking mechanisms,
**including that of respecting existing locks**.

With this trick, we can rewrite the previous fix:

```console
$ echo .tables | sqlite3 db.sqlite
Error: database is locked
$ echo '.tables' | sqlite3 'file:db.sqlite?immutable=1'
actual_table
```

This doesn't require creating a copy of the file that you want to
query despite it being locked by another active connection!

The only caveat is because SQLite doesn't expect that file to be
updated, changes wont be reflected in that immutable connexion, so it's
still like you're querying a snapshot, it's just that you don't have to
physically copy the database in order to read it.

Also as mentioned earlier, if the underlying database is updated, this
might result in errors when querying over the immutable connection.
Because of that, I would recommending opening a new connection every
time you want to query the database.

## Applying it to a SQLite driver

It's nice to be able to do that with the CLI, but how do we do that from
a program that uses a SQLite driver? In my case I'm using
[`sqlite3`](https://www.npmjs.com/package/sqlite3) with Node.js, but the
method should be very similar in your language of choice.

Because the `immutable` option is only available in the [URI filename](https://www.sqlite.org/uri.html)
format, we need to pass this kind of URI to our driver, e.g.
`file:db.sqlite?immutable=1` as opposed to `db.sqlite`.

The URI format is not enabled by default and you need to pass the
[`SQLITE_OPEN_URI`](https://www.sqlite.org/c3ref/c_open_autoproxy.html)
flag in order to enable it.

With `sqlite3`, this looks like this:

```js
const sqlite3 = require('sqlite3')
const db = new sqlite3.Database('file:db.sqlite?immutable=1', sqlite3.OPEN_READONLY | sqlite3.OPEN_URI)
```

We need to precise `OPEN_READONLY` because `OPEN_URI` alone is not a
valid mode, and by passing an explicit mode, we're effectively
overriding the [default](https://github.com/mapbox/node-sqlite3/blob/918052b538b0effe6c4a44c74a16b2749c08a0d2/src/database.cc#L135)
of `SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX`.

## Wrapping up

I hope you enjoyed this trick! If you find a better way to do this, or
a way that allows to reflect underlying database updates without
reloading the connection, please [let me know](/val.md#contact), I'd
love to know about it!

And as usual, keep hacking. 😜
