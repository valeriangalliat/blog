Blog
====

> My personal blog.

Description
-----------

This repository contains the scripts to build my static blog, together
with the articles Markdown source.

Everything is built around a [makefile](Makefile). Markdown parsing is
done with the [markdown-it] library, [Jade] is used for pages
templating, [Stylus] for CSS preprocessing, and the awesome [Babel] to
transpile ES6 to ES5.

[markdown-it]: https://github.com/markdown-it/markdown-it
[Jade]: http://jade-lang.com/
[Stylus]: http://learnboost.github.io/stylus/
[Babel]: https://babeljs.io/

Everything in this repository is in the public domain, thanks to the
[Unlicense](http://unlicense.org/), but if you want to hack on this
project, you probably want to remove the content and keep only the
engine; just remove everything in the `public` directory except the
`*.list` files (used for index, posts list and RSS feed).

I may separate the engine from the content if there is some need to
reuse the engine elsewhere, to make it more maintainable.

Installation
------------

You need a Node.js compliant environment, and GNU `make` to build.

```sh
npm install
make
```

Usage
-----

### Update everything

```sh
make
```

Only the stuff that changed since last compilation will be updated.

### Create a new post

```sh
make new
```

This will drop you in your editor, in a new prepared draft, with a title
and the current date. When exiting, the post will be moved to a dated
directory, with a slug derived from the page title.

Make sure to update the site after!

### Create a new page

Just create a Markdown file anywhere in the `public` directory, and it
will be compiled to HTML upon next build. You probably want to link to
this page from another page/post, otherwise it won't be discoverable.
