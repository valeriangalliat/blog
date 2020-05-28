Keeping Debian clean and minimal
================================
September 25, 2014

It's been a couple of years I'm running Debian on my workstations, both
at work and school, as well as on some servers.

I always start with the latest `netinst` image, unticking everything
from the "What to install?" list, so I just have the bare minimum
packages, and I have a full control over what I install next. But the
fact is **this is not enough**.

Apt packages, along with dependencies, have two other "related packages"
lists. **Recommendations** and **suggestions**. Unlike hard
dependencies, these packages are optional -- the software can work
without them -- but you can have additional functionality with them,
that you may or may not need (protip: most of the time, you don't).

By default, Apt installs *everything*, including recommendations
and suggestions. This is how, *by default*, `imagemagick` will come as
an `nmap` suggestion/recommendation (with several layers of
indirection). Do you really expect an image manipulation tool (and all
its related image and fonts libraries) to come with a network scanner?
**I do not.**

Kill it with fire!
------------------

<figure class="left">
  <object data="http://i1.kym-cdn.com/photos/images/newsfeed/000/337/603/43f.gif" type="image/gif">
    <object data="http://img.pandawhale.com/91787-kill-it-with-fire-gif-2mNC.gif" type="image/gif">
      <object data="http://gifsec.com/wp-content/uploads/GIF/2014/03/GIF-Kill-it-with-fire.gif" type="image/gif">
        <img alt="Kill it with fire!" src="https://val.codejam.info/public/gif/kill-it-with-fire.gif">
      </object>
    </object>
  </object>
</figure>

<small>*Not Debian. Not yet. But let's begin with all these useless
packages.*</small>

We're gonna configure Apt to automatically consider those
non-explicitly installed suggestions/recommendations as orphans, so we
can easily purge them. We will also configure it so these packages
*will no longer be installed in the first place*. All you need is
<del>love</del>:

```
# /etc/apt/apt.conf
Apt::Install-Recommends false;
Apt::Install-Suggests false;
Apt::AutoRemove::RecommendsImportant false;
Apt::AutoRemove::SuggestsImportant false;
```

The first two lines tell Apt not to install recommendations and
suggestions anymore. The next lines tell Apt that existing
recommendations/suggestions are not important, thus they can be purged.

Then, running an `aptitude install` will prompt you to remove all the
packages that are not needed anymore (and there will probably be a whole
bunch of them). **However, there's maybe some of them you'll want to
keep.** Verify carefully the content of this list before confirming the
removal. Be sure to `aptitude unmarkauto` the packages you want to keep
before running the final `aptitude install`.

Don't forget to [purge the configuration files][purge] by running
`aptitude purge '~c'`!

[purge]: ../../2014/10/debian-recursive-purge.md
