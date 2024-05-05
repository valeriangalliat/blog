# Knex: timeout acquiring a connection, the pool is probably full
May 5, 2024

```
Error: Knex: Timeout acquiring a connection. The pool is probably full. Are you missing a .transacting(trx) call?
```

Yes, you're probably missing a `.transacting(trx)` call, but what's
going on exactly?

Knex maintains a connection pool to your database, which you configure
with the [`pool` `min` and `max` options](https://knexjs.org/guide/#pool).
If `max` is 5, then Knex will keep up to 5 connections to your database
in the pool.

If you're attempting to make a query and the pool is full, then it'll
wait that one of the connection frees up in order to use it.

Sometimes however, it will timeout doing so. One common case is a
deadlock when mixing queries inside and outside a transaction.

Let's say that you start 5 transactions, but within those transactions,
you're performing some queries _outside_ of the transaction:

```js
await knex.transaction(trx => {
  await trx.raw('...')
  await knex.raw('...')
})
```

Here, the `knex.raw` statement will execute outside of the transaction
(despite being in the function, because it doesn't use `trx`). This
means that it will use its own connection from the pool, on top of the
one `knex.transaction` already uses.

If you have enough of those running in parallel, you can hit a case
where there's no available connection to execute the `knex.raw` bit. So
it's waiting that a connection frees up. **But no connection get freed up
because all the transactions are waiting for the `knex.raw` bit to
complete in order to commit!**

See the deadlock here?

So the solution is to make sure that all the queries you perform inside
the transaction actually use that transaction. In the above example,
it's very obvious, but it can get trickier when you call a function that
calls another function that calls a method that makes a query but didn't
accept a `trx` parameter and so ends up needing its own connection. 😬

Now you know what to look for. 👀
