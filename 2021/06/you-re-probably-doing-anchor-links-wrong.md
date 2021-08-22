---
hero: https://photography.codejam.info/photos/hd/P2600039.jpg
focus: 50% 80%
---

# You're (probably) doing anchor links wrong
Studying the accessibility of anchor links  
June 15, 2021

I'm the original author of [markdown-it-anchor](https://github.com/valeriangalliat/markdown-it-anchor),
a [markdown-it](https://github.com/markdown-it/markdown-it) plugin to
automatically add an `id` attribute to headings, and optionally add
anchor links (permalinks).

There's been [some](https://amberwilson.co.uk/blog/are-your-anchor-links-accessible/)
[activity](https://nicolas-hoizey.com/articles/2021/02/25/accessible-anchor-links-with-markdown-it-and-eleventy/)
[lately][accessibility-issue] [about](https://twitter.com/nhoizey/status/1365064686094471173)
[proper](https://twitter.com/nhoizey/status/1366479047065239562)
[accessibility](https://twitter.com/KittyGiraudel/status/1376789257176690688)
of heading permalinks, and this was [brought to my attention][accessibility-issue]
to improve markdown-it-anchor's way of rendering permalinks out of the box.

[accessibility-issue]: https://github.com/valeriangalliat/markdown-it-anchor/issues/82

If you want to get directly to the heart of the subject, you can jump
to [another take on accessible permalinks](#another-take-on-accessible-permalinks).
Otherwise, I'll start by giving a bit of backstory on the way
markdown-it-anchor handles permalinks.

## History of markdown-it-anchor's permalinks

When I originally built this plugin back in 2015, I gave a boolean
option to enable permalink generation, which would then default to a
GitHub-style permalink. The markup was the following.

```html
<h2 id="title">
  <a class="header-anchor" href="#title">¶</a>
  Title
</h2>
```

You could configure the permalink class (defaulting to `header-anchor`),
permalink symbol (defaulting for some reason to `¶` which is actually a
paragraph symbol) or provide your own renderer function where you could
directly manipulate the markdown-it token stream.

I decided closely after the first release to
[add `aria-hidden="true"` to the permalink](https://github.com/valeriangalliat/markdown-it-anchor/commit/bd2c324da38b0cfbb32f7ba0871b14877e273f41)
to fully mimic GitHub's behaviour, under the premise that the permalinks
weren't relevant to screen reader users, and that GitHub was probably a
good example to follow about doing the Right Thing(tm).

This was fine for the next couple of years, until...

## First accessibility request

In 2019, we get our [first accessibility issue](https://github.com/valeriangalliat/markdown-it-anchor/issues/58),
pointing out that using `aria-hidden` was incorrect here because those
links would be useful to screen reader users too, and especially,
accessibility linting tools were flagging them because having
`aria-hidden` focusable elements is considered a bad practice.

This issue was opened by Zach, the author of
[Eleventy](https://www.11ty.dev/), a static site generator, and he
[patched the output](https://github.com/11ty/11ty-website/commit/28ba29e9d61d5d1ce74e9f56c47eb6d42ad9273a)
of markdown-it-anchor in Eleventy to remove the `aria-hidden` attribute
[until it was fixed upstream](https://github.com/11ty/11ty-website/pull/448).

Fabio, a core contributor of markdown-it-anchor, tackled that issue and
[removed `aria-hidden` from permalinks](https://github.com/valeriangalliat/markdown-it-anchor/commit/e276fe53e259bcd2bf6045b6093f82d3cd606f8c)
after [doing some research](https://github.com/valeriangalliat/markdown-it-anchor/issues/58#issuecomment-542385189)
to confirm this was the right thing to do.

## First issue with the fix

Do you know that feeling when you fix a bug, only to discover it
introduced at least another bug?

This is basically what happened by removing the `aria-hidden` attribute.

Just a few months after the fix, and this time on the Eleventy repo,
[an issue is opened by Oliver](https://github.com/11ty/11ty-website/issues/222)
to point out that the permalinks are still not accessible, because
they're not keyboard focusable and don't have an accessible name (issue
which gets a PR more than a year later [suggesting to add `aria-labelledby`](https://github.com/11ty/11ty-website/pull/970)).

He then [suggests](https://github.com/valeriangalliat/markdown-it-anchor/issues/62)
that markdown-it-anchor include an option to add custom attributes to
the permalink, without having to write a custom renderer, and then
went on and [implemented the `permalinkAttrs` option](https://github.com/valeriangalliat/markdown-it-anchor/pull/63).
This allowed, for example, to configure a generic `aria-label` on the
permalink (e.g. "heading permalink"), but we'll see later that this is
not an ideal solution either.

## The hard truth

Exactly a year later, Binyamin brings back the `aria-hidden` topic,
explaining that [the default behaviour is still not accessible](https://github.com/valeriangalliat/markdown-it-anchor/issues/58#issuecomment-716849952),
because screen readers read out the permalink symbol instead of a
meaningful label.

He notes that GitHub (still) sets `aria-hidden="true"` on the
permalinks, likely to suggest that we could do the same --- which would
bring us back to the original behaviour. 😜

*Even though I didn't answer then, it is while reading this notification
that I realized that the accessibility of permalinks was a complex
topic, and that it was going to be hard, if not impossible, to satisfy
everybody.*

The question of accessible permalinks stayed in my mind, until...

## The *very* simple solution

About at the same time, my friend [Kitty](https://twitter.com/KittyGiraudel/),
is [switching from Jekyll to Eleventy](https://kittygiraudel.com/2020/11/30/from-jekyll-to-11ty/),
and finds my plugin while looking for a way to add `id`s to headings. 😎

Since one of Kitty's area of expertise is accessibility, I was secretly
hoping that they enabled markdown-it-anchor permalinks, so that I could
learn from their implementation to make markdown-it-anchor's default
permalinks more accessible.

But it turns out that Kitty *doesn't use permalinks*, only header `id`s.

After trying to make permalinks accessible without luck, I started to
think that the best solution might be to *not* use them at all. With
just `id`s, you can already link to your own titles and build a table of
contents. More technical users can still inspect the page to find
the `id`s and use them as anchors.

Sometimes, the smartest way to implement a nonstandard feature, might be
to... not?

## Another take on accessible permalinks

Just two weeks later, [Amber](https://twitter.com/ambrwlsn90) publishes
a post about [designing truly accessible anchor links](https://amberwilson.co.uk/blog/are-your-anchor-links-accessible/).

This is an awesome article that I highly recommend reading. Amber
explains the 5 iterations she went through to make accessible anchor
links on her own blog, including the details of her research.

But it's 3 months later that I hear about it, when [Nicolas](https://twitter.com/nhoizey)
opens an issue on the markdown-it-anchor repo, after also writing
[a blog post on the subject](https://nicolas-hoizey.com/articles/2021/02/25/accessible-anchor-links-with-markdown-it-and-eleventy/).

That was a lot of new information for me to unpack, but I was really
happy to see some updates on this topic which had long been an
unanswered question in my mind.

Sadly that solution was a bit more complex than what I hoped, in a way
that would *require* configuration from markdown-it-anchor's
perspective, making it unsuitable as a default. While it's one of the
best solutions from an accessibility point of view, the implementation
affects other aspects of the permalink and headings, including browsers
"reader mode", RSS readers, <abbr title="Search engine result pages">SERP</abbr>,
and adds extra challenges about [internationalization](https://github.com/valeriangalliat/markdown-it-anchor/issues/82#issuecomment-787204964).

Nicolas [tweeted about this](https://twitter.com/nhoizey/status/1366476887992729601)
to gather more insights on the subject, which brought quite some
activity on the tweet as well as the GitHub issue, with high quality
suggestions from Kitty, Amber, as well as [Barry](https://twitter.com/tunetheweb)
and [Thierry](https://twitter.com/7h1322yk0813n72) who both dug in depth
on the alternative solution of turning headers themselves into links
(the style used by [MDN] and [Web Almanac]). They also found creative
ways of making the markup of header links behave like the original
implementation, so be sure to check out the [GitHub issue](https://github.com/valeriangalliat/markdown-it-anchor/issues/82#issuecomment-788268457)
to find out about all of this!

## Conclusion #0: no one solution can satisfy all users

This discussion made me realize that until there is a standard and
native way of implementing anchor links, no solution is going to satisfy
all users.

As we saw with the various accessibility issues opened on
markdown-it-anchor and Eleventy as we tweaked the markup in the past,
what one user will consider a fix will be a bug for another one. A
solution might meet one user needs, but at the cost of other aspects
that a different person will find important.

> There is no silver bullet, and you probably won't even have a
> consensus from screen reader users, especially when their experience
> and habits vary based on their browser and assistive technology of
> choice. What's important is to come to a solution that makes it
> possible for people to link to a specific title of an article, without
> it being a chore.
>
> --- [Kitty Giraudel](https://github.com/KittyGiraudel), [March 1, 2021](https://github.com/valeriangalliat/markdown-it-anchor/issues/82#issuecomment-788234788)

Because of this, I switched my goal from finding a single bulletproof
solution, to **giving more visibility to all the available solutions**
that were identified and carefully analyzed, explaining their pros and
cons, **so that markdown-it-anchor users can make an educated choice on
what suits their website and audience best**.

## Conclusion #1: no default is better than a bad default

The absolute default (and main purpose) of markdown-it-anchor is to
automatically add an `id` attribute on headings. Adding permalinks is an
*option*, and doesn't *need* a default.

Since I realized that no single default would make everybody happy, and
it's not essential to have one for this option anyway, I decided to
modify the API to require explicit configuration of the permalink
*behaviour* if it is going to be enabled.

This makes sure that the user reads about the existing options and their
tradeoffs, so they explicitly chose the one that makes the most sense to
them.

While utopically it would have been nice to make every
markdown-it-anchor user's permalinks accessible with a `npm update`, we
don't have a single solution that suits every use case and wouldn't
break existing markup and styling, so this is not a realistic option.

## Final implementation

I made a [pull request](https://github.com/valeriangalliat/markdown-it-anchor/pull/89)
that deprecates the `permalink: true` way of using a default (poorly
accessible) renderer, and instead made the `permalink` option accept a
function to render the permalink (previously called `renderPermalink`).

Additionally, I provided a number of built-in renderers, documenting
their upsides and caveats. All of this can be found on the
[project's repo](https://github.com/valeriangalliat/markdown-it-anchor),
and it's part of the 8.0.0 release. Here's an overview of what was
added.

### Header link

```js
md.use(anchor, {
  permalink: anchor.permalink.headerLink()
})
```

```html
<h2 id="title">
  <a class="header-anchor" href="#title">Title</a>
</h2>
```

This was one of my favorite solutions that came out of the discussion,
because it's the simplest one. You can see it used on the [MDN] as well
as [HTTP Archive] and their [Web Almanac], and is the one I chose to use
on this blog as well.

[MDN]: https://developer.mozilla.org/en-US/docs/Web
[HTTP Archive]: https://httparchive.org/reports/state-of-the-web
[Web Almanac]: https://almanac.httparchive.org/en/2020/table-of-contents

The main problem with this kind of permalink is that you cannot include
links inside headers, since they're already a link.

It's also not as widespread as other patterns, which might confuse some
users, and it makes it harder to select parts of the header text (I only
learnt during that discussion that you can use <kbd>Option</kbd> (macOS)
or <kbd>Alt</kbd> to partially select any link text, so this is probably
not common knowledge) but you can use some
[tricks](https://codepen.io/thierry/pen/qBqYmgw) to make that markup
look and feel like other more recognized implementations.

Keep in mind that this pattern currently
[breaks reader mode in Safari](https://www.leereamsnyder.com/blog/making-headings-with-links-show-up-in-safari-reader),
an issue you can also notice on the referenced websites above. This was
already [reported to Apple](https://bugs.webkit.org/show_bug.cgi?id=225609#c2)
but their bug tracker is not public.

### Link after header

```js
md.use(anchor, {
  permalink: anchor.permalink.linkAfterHeader({
    style: 'visually-hidden',
    assistiveText: title => `Permalink to “${title}”`,
    visuallyHiddenClass: 'visually-hidden'
  })
})
```

```html
<h2 id="title">Title</h2>
<a class="header-anchor" href="#title">
  <span class="visually-hidden">Permalink to “Title”</span>
  <span aria-hidden="true">#</span>
</a>
```

This is the solution proposed by Amber and Nicolas, and backed by Kitty.
It's the one that arguably provides the clearest experience in screen
readers.

Note that making sure that the assistive text contains the title is
important here:

> Regarding anchor link text, you can't use just "Link to this section"
> because screen reader users often ask for the list of links in the
> page (they also ask for the list of headings), and they would get
> multiple times the same "Link to this section".
>
> --- [Nicolas Hoizey](https://github.com/nhoizey), [March 1, 2021](https://github.com/valeriangalliat/markdown-it-anchor/issues/82#issuecomment-788222895)

The downsides are that it requires a bit more effort to style and
localize, causes the visually hidden text to show in SERP and RSS
readers, and adds extra padding below headers in reader mode. Not bad,
considering.

### ARIA hidden

```js
md.use(anchor, {
  permalink: anchor.permalink.ariaHidden({
    placement: 'before'
  })
})
```

```html
<h2 id="title">
  <a class="header-anchor" href="#title" aria-hidden="true">#</a>
  Title
</h2>
```

Finally, this is the GitHub inspired way of implementing permalinks, and
legacy default of markdown-it-anchor. It needs little to no extra
styling and behaves in the way most users will expect out of the box,
but it's explicitly made *inaccessible*.

This might or might not be an issue for you, but it's definitely worth
thinking about, and considering the options above instead.

## Try it with a screen reader yourself!

Are you wondering if the experience on your website is accessible to
screen reader users? Reading about accessibility is great, but nothing
can teach you as much as actually using a screen reader.

This was much easier than I expected, at least on macOS. The system
ships with VoiceOver, which you can turn on by pressing
<kbd>Command</kbd> + <kbd>F5</kbd>. I recommend using it in
Safari as I've found the behaviour to be more quirky in other browsers.

We saw earlier that "screen reader users often ask for the list of
links in the page", as well as the list of headings.

> According to [a WebAim survey from 2014](https://webaim.org/projects/screenreadersurvey5/#finding),
> two-thirds of screen reader users scan headings as the first step of
> trying to find information on a long web page, so this should stay
> clean and intact above all.
>
> --- [Kitty Giraudel](https://github.com/KittyGiraudel), [March 1, 2021](https://github.com/valeriangalliat/markdown-it-anchor/issues/82#issuecomment-788234788)

In VoiceOver, you can open the "rotor" by pressing
[<kbd>Caps Lock</kbd>](https://support.apple.com/en-ca/guide/voiceover/unac048/mac) + <kbd>U</kbd>,
which allows you to list all the links and headings of the page. You
can browse through the lists by using the arrow keys. Make sure that
those are usable on your website!

## Final word

As a newbie to the topic of accessibility, it was wonderful getting to
learn from many knowledgeable peers who documented that aspect of anchor
links, and contributed to the discussion in [markdown-it-anchor's
related issue][accessibility-issue] and on Twitter.

Shoutout to [Amber](https://twitter.com/ambrwlsn90),
[Nicolas](https://twitter.com/nhoizey),
[Kitty](https://twitter.com/KittyGiraudel/),
[Barry](https://twitter.com/tunetheweb) and
[Thierry](https://twitter.com/7h1322yk0813n72) for taking the time to
research this issue and sharing their findings!

Finally, if I said anything wrong or inaccurate in this post, please
[let me know](/val.md#links), I'll be more than happy to fix mistakes
and integrate improvements!
