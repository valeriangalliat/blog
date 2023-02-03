---
tweet: https://twitter.com/valeriangalliat/status/1441563191557849090
---

# Elixir, Ecto and Heroku Postgres: unverified SSL certificates
Or attempting to trace warnings with Erlang  
September 24, 2021

This one took me a bit of time to sort out so I figured I'd write a blog
post about it in case it can help someone else.

I have a Phoenix Elixir application that I recently deployed on one of
my servers. While it's running smooth, I was bugged by the following
warning that was showing only in production when starting the app:

```elixir
[warn] Description: 'Authenticity is not established by certificate path validation'
     Reason: 'Option {verify, verify_peer} and cacertfile/cacerts is missing'
```

This message was repeated 10 times during boot. Spoiler, 10 is also my
Ecto `:pool_size`, but I didn't think about that right away.

There was no context around that, and since the app interacts with quite
a few things over SSL, it could have come from a lot of places.

## Tracing warnings in Elixir: investigation and delusion

My first reflex was to look for something similar to
[Node.js' `--trace-warnings` option](https://nodejs.org/api/cli.html#cli_trace_warnings).
This will add a stack trace to all warnings, making it very easy to
track where they're from and address them.

Sadly, I couldn't find anything similar with Elixir and Erlang. I
resorted to [asking on Elixir Forum](https://elixirforum.com/t/tracing-runtime-warnings/42576),
only to get confirmation that this wasn't possible.

## Compiling Erlang?

[The line that logged that warning](https://github.com/erlang/otp/blob/896510977b6cf1f2f4ac817394f3d5c9061f92cf/lib/ssl/src/ssl.erl#L2833)
was easy to find in the Erlang `ssl` module, but that didn't help me
identifying what code path triggers it.

I thought about compiling Erlang with a patch that raises an exception
instead of logging a warning there. While that wouldn't be the quickest
solution, it would definitely make it obvious what's triggering that
peer validation warning.

What was bugging me was that I was seeing this warning only in
production, not on my development machine. And I didn't really like the
idea of compiling my patched Erlang in production to debug in
production...

<div class="note">

**Note:** I didn't end up compiling Erlang to trace the warning that
way, because I was lucky to find after some trial and error what was
causing it.

That being said, if you run into the same kind of issue and don't find
any alternative, this is guaranteed to give you an answer, so it's
probably worth the effort at that point!

</div>

## Going for a walk

I didn't actually go for a walk, but that's the kind of thoughts that
usually happen when you take a walk, or when you're under the shower, so
I would have probably gotten that idea earlier if I did.

> If it's happening only in production, it's probably coming from one of
> the production environment variables!

For some reason, until then, I was focused on finding if there was
something odd about my Erlang build in production, or the CA
certificates configuration on the server, and while it could have come
from there, environment variables were an easy one to test.

So I configure my local machine with the production environment
variables, and bingo! I can repro the warning.

At that point it becomes very obvious to me that my database connection
is the culprit, because it's the only thing in the environment that's
related to SSL in a way or another.

## Heroku Postgres and SSL certificate verification

Now that I found the offender, it's easier to look for a specific
solution. The first result on Google for `heroku postgres ssl verify` is
[this page on the Heroku support website](https://help.heroku.com/3DELT3RK/why-can-t-my-third-party-utility-connect-to-heroku-postgres-with-ssl).

Since for some reason it requires to be logged in with an Heroku account
to view it, I'll just quote the relevant part here:

> Heroku Postgres does not currently support verifiable certificates.
> Our certificates will change when the underlying hardware has issues
> and we move your database away from it.

Sweet. So it's actually "intended" that I get a SSL verification warning
when connecting to my Heroku Postgres database over SSL.

But knowing that is not enough for me. Now I identified that this
warning was acceptable and doesn't need to be fixed per se, I need to
mute it, so that it doesn't adds noise to the logs.

**This is particularly important** because otherwise, I would hardly
notice a new SSL verification warning that would appears in another
potentially **more critical part of the codebase**, leaving me with
vulnerabilities.

## Muting this particular warning

[As we saw earlier](https://github.com/erlang/otp/blob/896510977b6cf1f2f4ac817394f3d5c9061f92cf/lib/ssl/src/ssl.erl#L2833),
for that warning to show up, we need the SSL connection's `verify` to
be set to `verify_none`, and the `ssl_logger`'s level to be configured
to show warnings.

The default value of `verify` in the `ssl` module [is indeed `verify_none`](https://github.com/erlang/otp/blob/896510977b6cf1f2f4ac817394f3d5c9061f92cf/lib/ssl/src/ssl_internal.hrl#L195),
and Ecto doesn't seem to alter it by default. Also the default
`log_level` of the `ssl_logger` [is set to `notice`](https://github.com/erlang/otp/blob/896510977b6cf1f2f4ac817394f3d5c9061f92cf/lib/ssl/src/ssl_internal.hrl#L160),
which is why we're seeing that warning.

It seems that my only option here is to configure the SSL connection
specifically for my Ecto repository to have a log level of `:error`:

```elixir
config :myapp, MyApp.Repo,
  ssl_opts: [log_level: :error]
```

<div class="note">

**Edit:** it was brought to my attention that just two months after I
wrote this post, Erlang/OTP [introduced](https://github.com/erlang/otp/commit/0557d0a6ff123ca80358bf6737ff4c3f3853793d)
a better [solution](https://www.erlang.org/doc/man/ssl.html#type-client_verify_type)
for this. Now:

> A warning will be emitted **unless `verify_none` is explicitly configured**.

This means that even if `ssl_opts: [verify: :verify_none]` is the
default behavior, explicitly setting it will now mute the warning. 🎉

```elixir
config :myapp, MyApp.Repo,
  ssl_opts: [verify: :verify_none]
```

This avoids messing around with the logger as I originally explained
below.

</div>

It took more hours than I'm willing to admit to come up with this patch
that turns out to be trivial. So I'm trying to feel better about myself
by spending even more hours writing a blog post about it to explain all
the details and subtleties. 😅

If you're here to try and solve an unverified warning issue, or trace
warnings with Elixir and Erlang in general, I hoped that it was useful
to you. Have a wonderful day!
