# Turborepo: don't buffer logs on GitHub Actions
April 23, 2025

When using `turbo run` inside a GitHub workflow, Turborepo buffers the
logs by package so it's all neatly sorted in the output.

This is a nice feature when you're looking at the logs after a run is
completed.

However when you're trying to debug a timing-based issue _live_, this
makes it really annoying because the logs are buffered the entire time
the process runs and only spit out at the end! And then we can't see
which package logged what first because the logs got grouped by package
instead of being in a merged stream.

I ended up dissecting the source of Turborepo to figure out what causes
this behavior inside GitHub Actions. [I found it](https://github.com/vercel/turborepo/blob/90369bd86cd11ae59d5f94f60bcdbe49313d065f/crates/turborepo-ci/src/vendors.rs#L262-L285).

It's triggered by the `GITHUB_ACTIONS` environment variable being
present.

So running `unset GITHUB_ACTIONS` before running `turbo run` turns off
this behavior!

In theory that should suffice but I had the following in my notes so
I'll also leave it here in case it helps:

```sh
unset $(env | grep RUNNER | cut -d= -f1)
unset $(env | grep GITHUB | cut -d= -f1)
```
