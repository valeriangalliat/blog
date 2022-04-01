# ✍️ Blog

> My personal blog.

## Description

This repository contains the scripts to build my static blog, together
with the articles Markdown source.

Everything is built around a [makefile](Makefile). Markdown parsing is
done with the [markdown-it] library and a couple of plugins.

[markdown-it]: https://github.com/markdown-it/markdown-it

Everything in this repository is in the public domain, thanks to the
[Unlicense](http://unlicense.org/), but if you want to hack on this
project, you probably want to remove the content and keep only the
engine.

## Usage

You need Node.js and GNU `make` to build.

```sh
npm install
make -j16
```

This will create a `dist` directory that is setup to track the
`gh-pages` branch of this repository and contains the built site.

## Development

Use `make serve` to start a development server on port 8000.

Use `make watch` to watch for changes on Markdown files and
automatically run `make` to render the updated files.

For convenience, run `make dev` which does both at the same time.

## Lint

Use `make lint` to lint (and fix) `index.md` and `posts.md`, making sure
the titles and dates are consistent with that of the actual posts.

Use `make lint-js` to lint the JavaScript code.

## Deploy

After building:

```sh
cd dist
git add .
git commit -m 'Build'
git push
```

## Create a new post

```sh
make new
```

This will prompt you for a title, suggest a slug or let you use a custom
one, and will update `index.md` to add the post to the latest articles
(and remove the oldest one), as well as `posts.md`, and create the post
Markdown file with an empty template.

## Rotate compiled CSS and JS

Compiled CSS and JS files are suffixed with their compiled date, to be
able to bypass caching in a way that's agnostic of the content delivery
service the blog is hosted on.

To rotate the CSS and JS files, appending the current date at the end,
use `make rotate-css` and `make rotate-js` respectively.
