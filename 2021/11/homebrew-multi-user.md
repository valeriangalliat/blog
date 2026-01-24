---
tweet: https://x.com/valeriangalliat/status/1461136995544096773
---

# Using Homebrew on a multi-user system (don't)
November 17, 2021

I've recently [started working at a new company](https://x.com/valeriangalliat/status/1460337357094326275),
where I've got the freedom to use my own rig, which is especially nice
if I want to work while travelling without having to bring two laptops
with me.

But setting up a work environment on my personal computer actually
brings a number of concerns, mainly about:

* Environment variables.
* Development tools and configurations.
* Shell history.

Whether it's my personal Google Cloud context leaking in my work
environment, work SSH keys being available in my personal projects,
various unrelated developer tokens and credentials cohabiting in the
same environment, and work-specific commands popping in my personal
shell history and making me press the up arrow even more than I already
do, it quickly feels like poor hygiene to keep everything under the same
user.

And while some of those tools allow to authenticate with multiple
accounts and offer ways to configure them individually and switch
between contexts, I've seen enough mistakes happen by juggling between
staging and production environments in the same session that adding my
personal credentials to the mix sounds like a recipe for disaster.

So after realizing that merging my personal projects with my
professional environment was a bad idea, I decided to create a dedicated
user for work, this way everything would be neatly contained. Meet the
multi-user system.

## Sharing a homebrew is nice 🍺, but `brew` not so much

The main issue I ran doing that was about running [Homebrew](https://brew.sh/),
the tool I install macOS packages with, and which I happen to use both
personally and for work.

Out of the box, if you install it from one user, it'll just fail to do
anything when run from another user because of permission issues.

### The evil: shared group writable permissions

Turns out I'm
[not](https://medium.com/@leifhanack/homebrew-multi-user-setup-e10cb5849d59)
[the](https://stackoverflow.com/questions/41840479/how-to-use-homebrew-on-a-multi-user-macos-sierra-setup)
[only](https://gist.github.com/jaibeee/9a4ea6aa9d428bc77925)
[one](https://newbedev.com/how-to-use-homebrew-on-a-multi-user-macos-sierra-setup)
to try to do this, a simple search for this yields a fuckton of results!
And they all mostly share the same "tip" which is some variant of:

```sh
chgrp -R admin /usr/local/*
chmod -R g+w /usr/local/*
```

Some variants use `brew --prefix` instead of hardcoding `/usr/local`,
some use a custom group instead of `admin`. Either way, it's all the
same, and it appears to work at first, until it doesn't.

The problem is that Homebrew is *not* designed to be used by multiple
Unix users. A given Homebrew installation is only meant to be used by a
single non-root user.

By giving write access to a given group (in the above example, `admin`),
that is shared by all the users you want to call `brew` from, you get
the illusion that you allowed `brew` to be used by multiple users.

But the issue is that the default [`umask`](https://en.wikipedia.org/wiki/Umask)
that `brew` uses doesn't add group write access, meaning that as you
use `brew`, more and more parts of the state will not be writable by the
other users in your group.

For example if after running the earlier hack, you run `brew install
some-package` as user `foo`, then you won't be able to `brew uninstall
some-package` or `brew update some-package` as user `bar`, because the
permission for the newly created files won't have group write access.

This means that if you instal packages from different users, `brew
update` will very quickly fail to run on *any* of those users because
none have access to *everything* anymore. Sure, you can solve that by
running the `chmod` hack again, but that's flaky and won't event prevent
every edge cases.

You see setups as crazy as running the `chmod` command in `~/.zshrc` or
similar to prevent this, which will still fall apart if you don't open a
new terminal session every time right before running `brew`, on top of
being a performance nightmare!

### The bad: separate Homebrew installations

Another approach that's [not](https://stackoverflow.com/a/55021458/4324668)
[as](https://docs.brew.sh/Installation#alternative-installs)
[widespread](https://code.roygreenfeld.com/cookbook/homebrew-multi-user-setup.html)
as the first one is to maintain a separate `brew` installation per user,
e.g. somewhere under the home directory as opposed to the default global
location.

That sounds like a great idea and would be my favorite way if it wasn't
for the fact that **pretty much every package I wanted to install needed
to be compiled from source because the prebuilt binaries only works with
the default global prefix**!

This makes `brew` effectively unusable as it can take ages to compile
complete dependency trees that way.

On top of that you can read the following in the [official documentation](https://docs.brew.sh/Installation#alternative-installs)
which definitely doesn't make me want to go that way:

> However do yourself a favour and use the installer to install to the
> default prefix. Some things may not build when installed elsewhere.
> One of the reasons Homebrew just works relative to the competition is
> **because** we recommend installing here. *Pick another prefix at your
> peril!*

This confirms my first feeling about this method: Homebrew is *not*
designed to be installed outside of its default prefix and you'll run
into all sort of issues if you do. I don't like spending my time fixing
issues like these so I'll pass.

### The good: dedicate a single user account to Homebrew

This is what's recommended for multi-user systems
[in the Homebrew FAQ](https://docs.brew.sh/FAQ#why-does-homebrew-say-sudo-is-bad).
Sadly this page is not well ranked when looking for how to to use
Homebrew in a multi-user system (unlike the previous hacks) and I only
found it write writing this post. The fun thing is that it's also the
approach that I decided to use for myself and was about to document
here!

> If you need to run Homebrew in a multi-user environment, consider
> creating a separate user account especially for use of Homebrew.

So while I'm in fact not inventing anything new here, hopefully I can
help this solution to be better ranked and prevent people from running
into the issues that are guaranteed to happen with the earlier hacks!

The solution is simple. Because **Homebrew is not designed to be used by
multiple users**, and it's **not designed to be installed anywhere else than
the default location**, what you want to do instead is to install
Homebrew in its **default location** with a **dedicated user** that you
switch to in order to use it.

Sounds annoying? Just use `sudo`! While Homebrew
[documents](https://docs.brew.sh/FAQ#why-does-homebrew-say-sudo-is-bad)
that it "refuses to work using `sudo`", this is not exactly true.
Homebrew refuses to work as root, but you can still use `sudo` to use it
as another, non-root user!

Typically, if you installed Homebrew in its default location from the
user `foo`, and now you're user `bar` and want to run `brew update`:

```sh
sudo -Hu foo brew update
```

* The `-H` option will make sure that the `HOME` directory is set
  to that of the impersonated user (here `foo`) instead of the
  *impersonating user* (here `bar`), so that Homebrew can maintain its
  cache and other local state in the proper user's home.
* The `-u` option allows to specify the user to impersonate instead of
  the default of `root`.

<div class="note">

**Note:** I've [had](https://x.com/sachithm2/status/1657010919107600384)
[reports](https://stackoverflow.com/questions/41840479/how-to-use-homebrew-on-a-multi-user-macos-sierra-setup/70012833#comment126730172_70012833)
that some people also needed the `-i` option (makes `sudo` start a login
shell). Depending on where you set your shell environment variables, you
may or may not need that. Try it for yourself!

</div>

This will effectively run `brew update` like if you had switched to user
`foo` prior to running it, but without going through the hassle of
actually switching users every single time.

And for what it's worth, you don't need to create a new, dedicated user
for `brew`. In my case, since both my users are effectively, me, I
simply installed Homebrew from my personal user and use `sudo` to run
`brew` commands from my work user.

To make things even nicer, you can even add an alias in the `~/.zshrc`
of the user that needs to use `sudo`:

```sh
alias brew='sudo -Hu foo brew'
```

## Wrapping up

That's all for today. I hope this helped you figure your bug-free,
multi-user Homebrew situation! Peace. ✌️
